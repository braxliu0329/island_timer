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
    @Published private(set) var workDuration: TimeInterval
    @Published private(set) var breakDuration: TimeInterval
    
    private let statisticsStore: FocusStatisticsStore
    private let defaults: UserDefaults
    
    private var plannedDuration: TimeInterval = 25 * 60
    
    private static let workDurationKey = "islandTimer.timer.workDurationSeconds"
    private static let breakDurationKey = "islandTimer.timer.breakDurationSeconds"
    
    init(
        statisticsStore: FocusStatisticsStore = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.statisticsStore = statisticsStore
        self.defaults = defaults
        
        if defaults.object(forKey: Self.workDurationKey) != nil {
            self.workDuration = defaults.double(forKey: Self.workDurationKey)
        } else {
            self.workDuration = 25 * 60
        }
        
        if defaults.object(forKey: Self.breakDurationKey) != nil {
            self.breakDuration = defaults.double(forKey: Self.breakDurationKey)
        } else {
            self.breakDuration = 8 * 60
        }
        
        self.workDuration = Self.clampWorkDurationSeconds(self.workDuration)
        self.breakDuration = Self.clampBreakDurationSeconds(self.breakDuration)
        self.timeRemaining = self.workDuration
        self.plannedDuration = self.timeRemaining
    }
    
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
        plannedDuration = timeRemaining
    }
    
    func skipToFinished() {
        timeRemaining = 0
        handleTimerEnd()
    }
    
    func toggleMode() {
        mode = (mode == .work) ? .breakTime : .work
        reset()
    }

    var canSkipBreak: Bool {
        mode == .breakTime && status != .finished
    }

    func skipBreak() {
        guard mode == .breakTime else { return }

        timer?.cancel()
        mode = .work
        status = .running
        timeRemaining = workDuration
        plannedDuration = timeRemaining
        setupTimer()
    }
    
    func setWorkDuration(minutes: Int) {
        let seconds = TimeInterval(minutes * 60)
        let clamped = Self.clampWorkDurationSeconds(seconds)
        workDuration = clamped
        defaults.set(clamped, forKey: Self.workDurationKey)
        
        if mode == .work, status != .running {
            timeRemaining = clamped
            plannedDuration = clamped
        }
    }
    
    func setBreakDuration(minutes: Int) {
        let seconds = TimeInterval(minutes * 60)
        let clamped = Self.clampBreakDurationSeconds(seconds)
        breakDuration = clamped
        defaults.set(clamped, forKey: Self.breakDurationKey)
        
        if mode == .breakTime, status != .running {
            timeRemaining = clamped
            plannedDuration = clamped
        }
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
        
        if mode == .work {
            statisticsStore.recordWorkSession(durationSeconds: plannedDuration)
        }
        
        NSSound(named: "Glass")?.play()
    }
    
    var timeString: String {
        let totalSeconds = max(0, Int(timeRemaining.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var workDurationMinutes: Int {
        max(1, Int(workDuration.rounded() / 60))
    }
    
    var breakDurationMinutes: Int {
        max(1, Int(breakDuration.rounded() / 60))
    }
    
    private static func clampWorkDurationSeconds(_ seconds: TimeInterval) -> TimeInterval {
        let minSeconds: TimeInterval = 5 * 60
        let maxSeconds: TimeInterval = 120 * 60
        return min(max(seconds, minSeconds), maxSeconds)
    }
    
    private static func clampBreakDurationSeconds(_ seconds: TimeInterval) -> TimeInterval {
        let minSeconds: TimeInterval = 1 * 60
        let maxSeconds: TimeInterval = 60 * 60
        return min(max(seconds, minSeconds), maxSeconds)
    }
}

final class FocusStatisticsStore: ObservableObject {
    static let shared = FocusStatisticsStore()
    
    struct Snapshot: Equatable {
        var completedWorkSessions: Int
        var totalWorkTimeSeconds: TimeInterval
        var currentStreakDays: Int
        var longestStreakDays: Int
        var recentActivities: [RecentActivity]
    }
    
    struct RecentActivity: Identifiable, Equatable {
        var id: String { dayKey }
        let dayKey: String
        let label: String
        let durationMinutes: Int
        let completed: Bool
    }
    
    private struct StoredDay: Codable, Equatable {
        var workMinutes: Int
        var completedWorkSessions: Int
    }
    
    private struct StoredState: Codable, Equatable {
        var days: [String: StoredDay]
    }
    
    @Published private(set) var snapshot: Snapshot
    
    private let defaults: UserDefaults
    private let defaultsKey = "islandTimer.statistics.v1"
    private let calendar: Calendar
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        self.calendar = cal
        
        let state = Self.load(defaults: defaults, key: defaultsKey)
        self.snapshot = Self.makeSnapshot(state: state, calendar: cal, referenceDate: Date())
    }
    
    func recordWorkSession(durationSeconds: TimeInterval, date: Date = Date()) {
        let minutes = max(1, Int((durationSeconds / 60).rounded()))
        var state = Self.load(defaults: defaults, key: defaultsKey)
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        var day = state.days[dayKey] ?? StoredDay(workMinutes: 0, completedWorkSessions: 0)
        day.workMinutes += minutes
        day.completedWorkSessions += 1
        state.days[dayKey] = day
        Self.save(state: state, defaults: defaults, key: defaultsKey)
        snapshot = Self.makeSnapshot(state: state, calendar: calendar, referenceDate: date)
    }
    
    private static func load(defaults: UserDefaults, key: String) -> StoredState {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return StoredState(days: [:])
        }
        return decoded
    }
    
    private static func save(state: StoredState, defaults: UserDefaults, key: String) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
    
    private static func makeSnapshot(state: StoredState, calendar: Calendar, referenceDate: Date) -> Snapshot {
        let completedWorkSessions = state.days.values.reduce(0) { $0 + $1.completedWorkSessions }
        let totalMinutes = state.days.values.reduce(0) { $0 + $1.workMinutes }
        
        let todayKey = dayKey(for: referenceDate, calendar: calendar)
        let currentStreakDays = computeCurrentStreakDays(state: state, calendar: calendar, todayKey: todayKey)
        let longestStreakDays = computeLongestStreakDays(state: state, calendar: calendar)
        let recentActivities = makeRecentActivities(state: state, calendar: calendar, referenceDate: referenceDate, limit: 5)
        
        return Snapshot(
            completedWorkSessions: completedWorkSessions,
            totalWorkTimeSeconds: TimeInterval(totalMinutes * 60),
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            recentActivities: recentActivities
        )
    }
    
    private static func computeCurrentStreakDays(state: StoredState, calendar: Calendar, todayKey: String) -> Int {
        guard let todayDate = date(fromDayKey: todayKey, calendar: calendar) else { return 0 }
        var streak = 0
        
        for offset in 0..<366 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: todayDate) else { break }
            let key = dayKey(for: date, calendar: calendar)
            let hasCompleted = (state.days[key]?.completedWorkSessions ?? 0) > 0
            if hasCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private static func computeLongestStreakDays(state: StoredState, calendar: Calendar) -> Int {
        let keys = state.days.keys.sorted()
        guard !keys.isEmpty else { return 0 }
        
        var longest = 0
        var current = 0
        var previousDate: Date?
        
        for key in keys {
            guard let date = date(fromDayKey: key, calendar: calendar) else { continue }
            let hasCompleted = (state.days[key]?.completedWorkSessions ?? 0) > 0
            if !hasCompleted {
                current = 0
                previousDate = date
                continue
            }
            
            if let prev = previousDate,
               let expected = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(date, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            
            longest = max(longest, current)
            previousDate = date
        }
        
        return longest
    }
    
    private static func makeRecentActivities(
        state: StoredState,
        calendar: Calendar,
        referenceDate: Date,
        limit: Int
    ) -> [RecentActivity] {
        let today = calendar.startOfDay(for: referenceDate)
        let weekdayLabels = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        
        return (0..<limit).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = dayKey(for: date, calendar: calendar)
            let day = state.days[key]
            let minutes = day?.workMinutes ?? 0
            let completed = (day?.completedWorkSessions ?? 0) > 0
            
            let label: String
            switch offset {
            case 0: label = "今天"
            case 1: label = "昨天"
            case 2: label = "前天"
            default:
                let weekday = calendar.component(.weekday, from: date)
                label = weekdayLabels[max(0, min(weekdayLabels.count - 1, weekday - 1))]
            }
            
            return RecentActivity(dayKey: key, label: label, durationMinutes: minutes, completed: completed)
        }
    }
    
    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let y = components.year ?? 0
        let m = components.month ?? 0
        let d = components.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
    
    private static func date(fromDayKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").map(String.init)
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }
}
