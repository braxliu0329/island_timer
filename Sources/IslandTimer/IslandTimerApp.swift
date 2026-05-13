import SwiftUI
import AppKit

@main
struct IslandTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use a custom window managed by AppDelegate for better control
        // but we can keep a dummy WindowGroup to satisfy SwiftUI requirements
        // if needed, or just an empty scene.
        #if os(macOS)
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: IslandWindow?
    var settingsWindow: NSWindow?
    var statisticsWindow: NSWindow?
    let timerManager = TimerManager()
    let displaySettings = DisplaySettings()
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon if you want it to be a pure menu bar app
        // NSApp.setActivationPolicy(.accessory)
        
        window = IslandWindow(timerManager: timerManager, displaySettings: displaySettings)
        window?.makeKeyAndOrderFront(nil)
        
        setupStatusItem()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Island Timer")
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            openSettings()
        } else {
            // Left click - show menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "统计...", action: #selector(openStatistics), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            // Reset menu to nil so the next click triggers the action again
            statusItem?.menu = nil
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(timerManager: timerManager)
            let hostingController = NSHostingController(rootView: settingsView)
            
            // Set the content size to match the view's requirements
            hostingController.view.frame.size = hostingController.view.intrinsicContentSize
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.center()
            settingsWindow?.contentViewController = hostingController
            settingsWindow?.title = "Island Timer 设置"
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.standardWindowButton(.zoomButton)?.isHidden = true
            settingsWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openStatistics() {
        if statisticsWindow == nil {
            let statsView = StatisticsView(timerManager: timerManager)
            let hostingController = NSHostingController(rootView: statsView)
            
            hostingController.view.frame.size = hostingController.view.intrinsicContentSize
            
            statisticsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            statisticsWindow?.center()
            statisticsWindow?.contentViewController = hostingController
            statisticsWindow?.title = "统计"
            statisticsWindow?.isReleasedWhenClosed = false
            statisticsWindow?.standardWindowButton(.zoomButton)?.isHidden = true
            statisticsWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
        
        statisticsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
