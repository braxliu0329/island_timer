import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var screenShareSettings: ScreenShareExclusionSettings

    @State private var workMinutes: Int = 25
    @State private var breakMinutes: Int = 8
    
    private static let workMinutesRange = 5...120
    private static let breakMinutesRange = 1...60
    
    private static let minutesFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.allowsFloats = false
        f.minimum = 0
        return f
    }()

    init(timerManager: TimerManager, screenShareSettings: ScreenShareExclusionSettings) {
        self.timerManager = timerManager
        self.screenShareSettings = screenShareSettings
        _workMinutes = State(initialValue: timerManager.workDurationMinutes)
        _breakMinutes = State(initialValue: timerManager.breakDurationMinutes)
    }
    
    private func timeString(minutes: Int) -> String {
        let totalSeconds = max(0, minutes) * 60
        let hours = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d:00", hours, mins)
        }
        return String(format: "%02d:00", mins)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Island Timer 设置")
                    .font(.title)
                Text("自定义你的专注体验")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)

            // Timer Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("计时器设置")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("专注时长")
                        Spacer()
                        Text(timeString(minutes: workMinutes))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        TextField("", value: $workMinutes, formatter: Self.minutesFormatter)
                            .frame(width: 52)
                        Text("分钟")
                            .foregroundColor(.secondary)
                        Stepper("", value: $workMinutes, in: Self.workMinutesRange, step: 1)
                            .labelsHidden()
                    }

                    HStack {
                        Text("休息时长")
                        Spacer()
                        Text(timeString(minutes: breakMinutes))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        TextField("", value: $breakMinutes, formatter: Self.minutesFormatter)
                            .frame(width: 52)
                        Text("分钟")
                            .foregroundColor(.secondary)
                        Stepper("", value: $breakMinutes, in: Self.breakMinutesRange, step: 1)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            // Screen Sharing Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("屏幕共享")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("隐藏岛屿窗口", isOn: $screenShareSettings.isExclusionEnabled)
                        .help("在屏幕共享或录屏时自动隐藏专注岛屿窗口")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 360, minHeight: 200)
        .onChange(of: workMinutes) { newValue in
            let clamped = min(max(newValue, Self.workMinutesRange.lowerBound), Self.workMinutesRange.upperBound)
            if clamped != newValue {
                workMinutes = clamped
                return
            }
            timerManager.setWorkDuration(minutes: clamped)
        }
        .onChange(of: breakMinutes) { newValue in
            let clamped = min(max(newValue, Self.breakMinutesRange.lowerBound), Self.breakMinutesRange.upperBound)
            if clamped != newValue {
                breakMinutes = clamped
                return
            }
            timerManager.setBreakDuration(minutes: clamped)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            timerManager: TimerManager(),
            screenShareSettings: ScreenShareExclusionSettings()
        )
    }
}
