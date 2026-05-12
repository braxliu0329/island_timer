import Foundation
import Combine
import AppKit

class TimerManager: ObservableObject {
    enum TimerMode {
        case work
        case breakTime
    }
    
    enum TimerStatus {
        case idle
        case running
        case paused
        case finished
    }
    
    @Published var mode: TimerMode = .work
    @Published var status: TimerStatus = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    
    private var timer: AnyCancellable?
    private let workDuration: TimeInterval = 25 * 60
    private let breakDuration: TimeInterval = 8 * 60
    
    func start() {
        if status == .idle || status == .finished {
            reset()
        }
        status = .running
        setupTimer()
    }
    
    func pause() {
        status = .paused
        timer?.cancel()
    }
    
    func reset() {
        timer?.cancel()
        status = .idle
        timeRemaining = (mode == .work) ? workDuration : breakDuration
    }
    
    func skipToFinished() {
        timeRemaining = 0
        handleTimerEnd()
    }
    
    func toggleMode() {
        mode = (mode == .work) ? .breakTime : .work
        reset()
    }
    
    private func setupTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.handleTimerEnd()
                }
            }
    }
    
    private func handleTimerEnd() {
        timer?.cancel()
        status = .finished
        
        // Play system notification sound
        NSSound(named: "Glass")?.play()
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
