import SwiftUI

@main
struct IslandTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Remove the Settings scene to prevent the blank window from appearing
        #if os(macOS)
        // This is a dummy scene that won't create a window
        MenuBarExtra("Island Timer", systemImage: "timer") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        #else
        WindowGroup {
            EmptyView()
        }
        #endif
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: IslandWindow?
    let timerManager = TimerManager()
    let displaySettings = DisplaySettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = IslandWindow(timerManager: timerManager, displaySettings: displaySettings)
        window?.makeKeyAndOrderFront(nil)
    }
}
