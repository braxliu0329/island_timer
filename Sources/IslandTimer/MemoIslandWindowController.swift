import AppKit
import Combine
import SwiftUI

final class MemoIslandDisplaySettings: ObservableObject {
    @Published var isHovered: Bool = false
    
    let notchWidth: CGFloat = 200
    let notchHeight: CGFloat = 35
    
    func currentWidth() -> CGFloat {
        isHovered ? 380 : notchWidth
    }
    
    func currentHeight() -> CGFloat {
        isHovered ? 160 : notchHeight
    }
}

final class MemoIslandWindow: NSPanel {
    private var isAutoHidden = false
    private var wasVisibleBeforeAutoHide = false
    private var frameBeforeAutoHide: NSRect?
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    init(memo: MemoItem, index: Int, displaySettings: MemoIslandDisplaySettings, featureManager: FeatureManager) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 35),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        backgroundColor = .clear
        hasShadow = false
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        ignoresMouseEvents = false
        
        var view = MemoIslandView(memo: memo, displaySettings: displaySettings, featureManager: featureManager)
        view.onSizeChange = { [weak self] newSize in
            self?.updateWindowSize(to: newSize, index: index, displaySettings: displaySettings)
        }
        
        contentView = NSHostingView(rootView: view)
        updateWindowSize(to: .zero, index: index, displaySettings: displaySettings)
    }
    
    private func updateWindowSize(to size: CGSize, index: Int, displaySettings: MemoIslandDisplaySettings) {
        guard let screen = self.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        
        let modeledWidth = displaySettings.currentWidth()
        let modeledHeight = displaySettings.currentHeight()
        let finalWidth = max(size.width, modeledWidth, displaySettings.notchWidth)
        let finalHeight = max(size.height, modeledHeight, displaySettings.notchHeight)
        
        let baseOffset: CGFloat = 35 + 12
        let stackOffset: CGFloat = CGFloat(index) * (displaySettings.notchHeight + 10)
        let topY = screenFrame.maxY - baseOffset - stackOffset
        
        let x = screenFrame.midX - finalWidth / 2
        let y = topY - finalHeight
        
        let targetFrame = NSRect(x: x, y: y, width: finalWidth, height: finalHeight)
        
        let f = frame
        let epsilon = 0.5
        let needsUpdate =
            abs(f.width - finalWidth) > epsilon
            || abs(f.height - finalHeight) > epsilon
            || abs(f.minX - targetFrame.minX) > epsilon
            || abs(f.minY - targetFrame.minY) > epsilon
        
        if needsUpdate {
            setFrame(targetFrame, display: true, animate: false)
        }
    }
    
    func setAutoHidden(_ hidden: Bool) {
        guard hidden != isAutoHidden else { return }
        isAutoHidden = hidden
        
        if hidden {
            wasVisibleBeforeAutoHide = isVisible
            frameBeforeAutoHide = frame
            orderOut(nil)
            return
        }
        
        guard wasVisibleBeforeAutoHide else { return }
        if let frameBeforeAutoHide {
            setFrame(frameBeforeAutoHide, display: false, animate: false)
        }
        orderFrontRegardless()
        wasVisibleBeforeAutoHide = false
        frameBeforeAutoHide = nil
    }
    
    func applyWindowCaptureExclusion(enabled: Bool) {
        sharingType = enabled ? .none : .readWrite
    }
}

extension MemoIslandWindow: CaptureExcludableWindow {}

final class MemoIslandWindowController: NSObject {
    private(set) var memo: MemoItem
    private(set) var window: MemoIslandWindow
    private let displaySettings: MemoIslandDisplaySettings
    private let featureManager: FeatureManager
    private var cancellables = Set<AnyCancellable>()
    private var hoverMonitor: Timer?
    private var collapseWorkItem: DispatchWorkItem?
    
    init(memo: MemoItem, index: Int, featureManager: FeatureManager) {
        self.memo = memo
        self.displaySettings = MemoIslandDisplaySettings()
        self.featureManager = featureManager
        self.window = MemoIslandWindow(memo: memo, index: index, displaySettings: displaySettings, featureManager: featureManager)
        super.init()
        
        displaySettings.$isHovered
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if let view = self.window.contentView as? NSHostingView<MemoIslandView> {
                    view.rootView.onSizeChange?(.zero)
                }
            }
            .store(in: &cancellables)

        featureManager.$activeFeature
            .receive(on: DispatchQueue.main)
            .sink { [weak self] feature in
                self?.handleFeatureChanged(feature)
            }
            .store(in: &cancellables)

        startHoverMonitor()
    }

    deinit {
        stopHoverMonitor()
        collapseWorkItem?.cancel()
    }
    
    func show() {
        window.orderFrontRegardless()
    }

    private func handleFeatureChanged(_ feature: AppFeature) {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil

        if displaySettings.isHovered {
            displaySettings.isHovered = false
        }
        WindowTriggerCoordinator.shared.endTrigger(owner: .memo)

        if feature == .memo {
            show()
        } else {
            window.orderOut(nil)
        }
    }

    private func startHoverMonitor() {
        guard hoverMonitor == nil else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.evaluateHoverState()
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverMonitor = timer
    }

    private func stopHoverMonitor() {
        hoverMonitor?.invalidate()
        hoverMonitor = nil
    }

    private func evaluateHoverState(mouseLocation: CGPoint = NSEvent.mouseLocation) {
        guard featureManager.activeFeature == .memo, window.isVisible else {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            return
        }

        switch MemoIslandHoverPolicy.decision(
            isHovered: displaySettings.isHovered,
            mouseLocation: mouseLocation,
            windowFrame: window.frame
        ) {
        case .noChange:
            break
        case .beginHover:
            collapseWorkItem?.cancel()
            collapseWorkItem = nil

            guard WindowTriggerCoordinator.shared.beginTrigger(owner: .memo) else { return }
            displaySettings.isHovered = true
        case .cancelPendingCollapse:
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
        case .scheduleCollapse:
            scheduleCollapse()
        }
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.featureManager.activeFeature == .memo, self.window.isVisible else { return }

            let mouseLocation = NSEvent.mouseLocation
            guard !MemoIslandHoverPolicy.isMouseInsideInteractiveArea(mouseLocation, windowFrame: self.window.frame) else {
                return
            }

            self.displaySettings.isHovered = false
            WindowTriggerCoordinator.shared.endTrigger(owner: .memo)
        }

        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: item)
    }
}
