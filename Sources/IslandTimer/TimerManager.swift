import Foundation
import Combine
import AppKit

struct DailyStats: Codable {
    var workSessions: Int = 0
    var breakSessions: Int = 0
    var totalWorkTime: TimeInterval = 0
    var totalBreakTime: TimeInterval = 0
}

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
    
    // Default values in minutes
    @Published var workDurationMinutes: Int = 25 {
        didSet {
            UserDefaults.standard.set(workDurationMinutes, forKey: "workDurationMinutes")
            if mode == .work && (status == .idle || status == .finished) {
                reset()
            }
        }
    }
    @Published var breakDurationMinutes: Int = 8 {
        didSet {
            UserDefaults.standard.set(breakDurationMinutes, forKey: "breakDurationMinutes")
            if mode == .breakTime && (status == .idle || status == .finished) {
                reset()
            }
        }
    }
    
    @Published var todayStats: DailyStats = DailyStats()
    
    init() {
        self.workDurationMinutes = UserDefaults.standard.integer(forKey: "workDurationMinutes")
        if self.workDurationMinutes == 0 { self.workDurationMinutes = 25 }
        
        self.breakDurationMinutes = UserDefaults.standard.integer(forKey: "breakDurationMinutes")
        if self.breakDurationMinutes == 0 { self.breakDurationMinutes = 8 }
        
        self.timeRemaining = TimeInterval(self.workDurationMinutes * 60)
        
        loadStats()
    }
    
    private func loadStats() {
        let today = getCurrentDateString()
        let lastSavedDate = UserDefaults.standard.string(forKey: "lastSavedDate") ?? ""
        if today == lastSavedDate, let data = UserDefaults.standard.data(forKey: "dailyStats"), let stats = try? JSONDecoder().decode(DailyStats.self, from: data) {
            self.todayStats = stats
        } else {
            self.todayStats = DailyStats()
            saveStats()
        }
    }
    
    private func saveStats() {
        UserDefaults.standard.set(getCurrentDateString(), forKey: "lastSavedDate")
        if let data = try? JSONEncoder().encode(todayStats) {
            UserDefaults.standard.set(data, forKey: "dailyStats")
        }
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    var workDuration: TimeInterval { TimeInterval(workDurationMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(breakDurationMinutes * 60) }
    
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
        
        // Update statistics
        loadStats() // Ensure we are still on the same day
        if mode == .work {
            todayStats.workSessions += 1
            todayStats.totalWorkTime += workDuration
        } else {
            todayStats.breakSessions += 1
            todayStats.totalBreakTime += breakDuration
        }
        saveStats()
        
        // Play system notification sound
        NSSound(named: "Glass")?.play()
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
