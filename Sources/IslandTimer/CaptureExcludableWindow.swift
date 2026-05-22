import AppKit

// Protocol for windows that can have screen sharing exclusion applied
protocol CaptureExcludableWindow {
    func applyWindowCaptureExclusion(enabled: Bool)
}