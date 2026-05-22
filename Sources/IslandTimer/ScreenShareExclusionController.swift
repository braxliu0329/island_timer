import AppKit
import Combine

class ScreenShareExclusionController: ObservableObject {
    private var windows: [NSWindow]
    private var settings: ScreenShareExclusionSettings
    private var windowObservers: [ObjectIdentifier: NSKeyValueObservation] = [:]

    private var cancellables = Set<AnyCancellable>()

    init(windows: [NSWindow], settings: ScreenShareExclusionSettings) {
        self.windows = windows
        self.settings = settings

        // Apply initial state
        applyExclusion(enabled: settings.isExclusionEnabled)

        // Observe settings changes
        settings.$isExclusionEnabled
            .sink { [weak self] enabled in
                self?.applyExclusion(enabled: enabled)
            }
            .store(in: &cancellables)
    }

    func addWindow(_ window: NSWindow) {
        guard !windows.contains(where: { $0 === window }) else { return }
        windows.append(window)
        applyExclusion(enabled: settings.isExclusionEnabled, to: window)
    }

    func removeWindow(_ window: NSWindow) {
        windows.removeAll { $0 === window }
        stopObserving(window: window)
    }

    private func applyExclusion(enabled: Bool, to window: NSWindow? = nil) {
        let windowsToApply = window.map { [$0] } ?? windows
        windowsToApply.forEach { applyExclusion(enabled: enabled, to: $0) }
    }

    private func applyExclusion(enabled: Bool, to window: NSWindow) {
        stopObserving(window: window)

        if enabled {
            window.sharingType = .none

            let observation = window.observe(\.isVisible) { [weak self] window, _ in
                guard self?.settings.isExclusionEnabled == true else { return }
                window.sharingType = .none
            }
            windowObservers[ObjectIdentifier(window)] = observation
        } else {
            window.sharingType = .readWrite
        }
    }

    private func stopObserving(window: NSWindow) {
        windowObservers.removeValue(forKey: ObjectIdentifier(window))
    }

    deinit {
        windowObservers.removeAll()
    }
}
