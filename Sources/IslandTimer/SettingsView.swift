import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var screenShareSettings: ScreenShareExclusionSettings

    @State private var workDuration: TimeInterval = 25 * 60
    @State private var breakDuration: TimeInterval = 8 * 60

    init(timerManager: TimerManager, screenShareSettings: ScreenShareExclusionSettings) {
        self.timerManager = timerManager
        self.screenShareSettings = screenShareSettings
        _workDuration = State(initialValue: timerManager.workDuration)
        _breakDuration = State(initialValue: timerManager.breakDuration)
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
                        Stepper("\(Int(workDuration / 60)) 分钟", value: $workDuration, in: 5...120, step: 5)
                            .labelsHidden()
                    }

                    HStack {
                        Text("休息时长")
                        Spacer()
                        Stepper("\(Int(breakDuration / 60)) 分钟", value: $breakDuration, in: 1...60, step: 1)
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
