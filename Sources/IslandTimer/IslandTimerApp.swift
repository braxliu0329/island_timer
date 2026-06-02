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
    let statisticsStore = FocusStatisticsStore.shared
    lazy var timerManager = TimerManager(statisticsStore: statisticsStore)
    let displaySettings = DisplaySettings()
    let featureManager = FeatureManager()
    var statusItem: NSStatusItem?
    let screenShareSettings = ScreenShareExclusionSettings()
    var screenShareController: ScreenShareExclusionController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate: Application didFinishLaunching")
        print("AppDelegate: Initial active feature: \(featureManager.activeFeature)")

        // Hide the dock icon if you want it to be a pure menu bar app
        // NSApp.setActivationPolicy(.accessory)

        window = IslandWindow(timerManager: timerManager, displaySettings: displaySettings, featureManager: featureManager)
        window?.makeKeyAndOrderFront(nil)

        print("AppDelegate: Created IslandWindow")

        if let window {
            screenShareController = ScreenShareExclusionController(windows: [window], settings: screenShareSettings)
            print("AppDelegate: Created ScreenShareExclusionController")
        }

        setupStatusItem()
        print("AppDelegate: Setup complete.")
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

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        makeIconDockMenu()
    }

    func makeIconDockMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let switchToTimer = NSMenuItem(title: "切换到计时器", action: #selector(switchToTimerMode), keyEquivalent: "1")
        switchToTimer.target = self
        menu.addItem(switchToTimer)

        let switchToMemo = NSMenuItem(title: "切换到备忘", action: #selector(switchToMemoMode), keyEquivalent: "2")
        switchToMemo.target = self
        menu.addItem(switchToMemo)

        menu.addItem(NSMenuItem.separator())

        let settings = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let statistics = NSMenuItem(title: "统计...", action: #selector(openStatistics), keyEquivalent: ";")
        statistics.target = self
        menu.addItem(statistics)

        return menu
    }

    @objc func statusItemClicked(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        let menu = makeIconDockMenu()

        if let event = NSApp.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: button)
        } else {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }
    
    @objc private func switchToTimerMode() {
        print("App: Switching to timer mode from: \(featureManager.activeFeature)")
        featureManager.activeFeature = .timer
        window?.orderFrontRegardless()
        print("App: Switched to timer mode. Current: \(featureManager.activeFeature)")
    }

    @objc private func switchToMemoMode() {
        print("App: Switching to memo mode from: \(featureManager.activeFeature)")
        featureManager.activeFeature = .memo
        window?.orderFrontRegardless()
        print("App: Switched to memo mode. Current: \(featureManager.activeFeature)")
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(timerManager: timerManager, screenShareSettings: screenShareSettings)
            let hostingController = NSHostingController(rootView: settingsView)
            
            // Set the content size to match the view's requirements
            hostingController.view.frame.size = hostingController.view.intrinsicContentSize
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
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
            let statsView = StatisticsView(timerManager: timerManager, statisticsStore: statisticsStore)
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
