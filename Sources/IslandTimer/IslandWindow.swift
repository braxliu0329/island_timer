import AppKit
import Combine
import SwiftUI

class IslandHostingView<Content: View>: NSHostingView<Content> {
    var displaySettings: DisplaySettings
    var timerManager: TimerManager
    
    init(rootView: Content, displaySettings: DisplaySettings, timerManager: TimerManager) {
        self.displaySettings = displaySettings
        self.timerManager = timerManager
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Since the window now dynamically resizes to match the island size,
        // we can simply check if the point is within the window's bounds.
        // The window size is kept in sync with the capsule via onSizeChange.
        
        if self.frame.size.width > 0 && self.frame.size.height > 0 {
            return super.hitTest(point)
        }
        
        return nil
    }
    
    override func layout() {
        super.layout()
        if let container = superview, !NSEqualRects(frame, container.bounds) {
            frame = container.bounds
        }
    }
}

class IslandWindow: NSPanel {
    private var displaySettings: DisplaySettings
    private var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()

    init(timerManager: TimerManager, displaySettings: DisplaySettings) {
        self.timerManager = timerManager
        self.displaySettings = displaySettings
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 35),
            // Do not combine `.fullSizeContentView` with `.borderless`: full-size content is for
            // titled windows; with a borderless panel it can mislay the content rect and shift
            // SwiftUI horizontally on notched Macs.
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isOpaque = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.ignoresMouseEvents = false
        
        var islandView = IslandView(timerManager: timerManager, displaySettings: displaySettings)
        islandView.onSizeChange = { [weak self] newSize in
            self?.updateWindowSize(to: newSize)
        }
        
        self.contentView = IslandHostingView(rootView: islandView, displaySettings: displaySettings, timerManager: timerManager)

        // `onSizeChange` from preferences may not fire when width changes; re-center when state
        // that affects width/height changes (hover, pin, timer status).
        displaySettings.$isHovered
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateWindowSize(to: .zero) }
            .store(in: &cancellables)
        displaySettings.$isPinned
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateWindowSize(to: .zero) }
            .store(in: &cancellables)
        timerManager.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateWindowSize(to: .zero) }
            .store(in: &cancellables)
    }
    
    private func updateWindowSize(to size: CGSize) {
        // Prefer the screen that actually contains this panel so horizontal centering
        // matches the display the user sees (not always the same as NSScreen.main).
        guard let screen = self.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        
        let isRunning = timerManager.status == .running || timerManager.status == .paused
        let modeledWidth = displaySettings.currentWidth(status: timerManager.status, isRunning: isRunning)
        let modeledHeight = displaySettings.currentHeight(status: timerManager.status, isRunning: isRunning)
        // Prefer the larger of layout-reported size and the modeled UI size so the panel is never
        // narrower than the SwiftUI content (which would look horizontally shifted / clipped).
        let finalWidth = max(size.width, modeledWidth, displaySettings.notchWidth)
        let finalHeight = max(size.height, modeledHeight, displaySettings.notchHeight)
        
        // 2–3. Center on the screen’s full frame (same coordinate space as setFrame).
        let x = screenFrame.midX - finalWidth / 2
        
        // 4. Flush to the top of this screen
        let y = screenFrame.maxY - finalHeight
        
        let targetFrame = NSRect(x: x, y: y, width: finalWidth, height: finalHeight)
        
        let f = self.frame
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
}
