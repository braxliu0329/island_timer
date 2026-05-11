import AppKit
import SwiftUI

import AppKit
import SwiftUI
import Combine

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
        let bounds = self.bounds
        
        let isRunning = timerManager.status == .running || timerManager.status == .paused
        let width = displaySettings.currentWidth(status: timerManager.status, isRunning: isRunning)
        let height = displaySettings.currentHeight(status: timerManager.status, isRunning: isRunning)
        
        // The Capsule Rect is the only area that should intercept clicks
        let xStart = (bounds.width - width) / 2
        let islandRect = NSRect(x: xStart, y: bounds.height - height, width: width, height: height)
        
        if islandRect.contains(point) {
            return super.hitTest(point)
        }
        
        // Return nil for all other areas (including the invisible notch trigger)
        // This allows clicks to pass through to windows behind the notch.
        return nil
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
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
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
        
        let islandView = IslandView(timerManager: timerManager, displaySettings: displaySettings)
        self.contentView = IslandHostingView(rootView: islandView, displaySettings: displaySettings, timerManager: timerManager)
        
        setupSubscriptions()
        updatePosition()
    }
    
    private func setupSubscriptions() {
        // Observe all properties that affect window size
        Publishers.CombineLatest3(
            timerManager.$status,
            displaySettings.$isHovered,
            displaySettings.$isPinned
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.updatePosition()
        }
        .store(in: &cancellables)
    }
    
    func updatePosition() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        let isRunning = timerManager.status == .running || timerManager.status == .paused
        let contentWidth = displaySettings.currentWidth(status: timerManager.status, isRunning: isRunning)
        let contentHeight = displaySettings.currentHeight(status: timerManager.status, isRunning: isRunning)
        
        // Target window size
        let targetWidth = max(contentWidth, displaySettings.notchWidth)
        let targetHeight = contentHeight
        
        let x = screenFrame.origin.x + (screenFrame.width - targetWidth) / 2
        let y = screenFrame.origin.y + screenFrame.height - targetHeight
        let targetFrame = NSRect(x: x, y: y, width: targetWidth, height: targetHeight)
        
        if !self.frame.equalTo(targetFrame) {
            let isExpanding = targetFrame.width > self.frame.width || targetFrame.height > self.frame.height
            
            if isExpanding {
                // When expanding, increase window size immediately so SwiftUI content has room to animate
                self.setFrame(targetFrame, display: true, animate: false)
            } else {
                // When collapsing, animate the window frame change to match SwiftUI's transition
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.4
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.animator().setFrame(targetFrame, display: true)
                }, completionHandler: nil)
            }
        }
    }
}
