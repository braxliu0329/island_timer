import AppKit
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var timerManager: TimerManager

    // Mock data for now - in a real app, this would come from a persistence layer
    let completedWorkSessions: Int = 24
    let totalWorkTime: TimeInterval = 12 * 60 * 60 // 12 hours
    let currentStreak: Int = 7
    let longestStreak: Int = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("统计")
                    .font(.title)
                Text("你的专注成就")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)

            // Streaks
            VStack(alignment: .leading, spacing: 8) {
                Text("连续专注")
                    .font(.headline)

                HStack(spacing: 12) {
                    StatView(title: "当前", count: currentStreak, subtitle: "天")
                    StatView(title: "最长", count: longestStreak, subtitle: "天")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Session Stats
            VStack(alignment: .leading, spacing: 8) {
                Text("专注统计")
                    .font(.headline)

                HStack(spacing: 12) {
                    StatView(title: "完成", count: completedWorkSessions, subtitle: "次")
                    StatView(title: "总计", count: Int(totalWorkTime / 3600), subtitle: "小时")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("近期活动")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    ActivityRow(day: "今天", duration: 125, completed: true)
                    ActivityRow(day: "昨天", duration: 95, completed: true)
                    ActivityRow(day: "前天", duration: 45, completed: false)
                    ActivityRow(day: "周一", duration: 145, completed: true)
                    ActivityRow(day: "周日", duration: 75, completed: true)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .frame(minWidth: 350, minHeight: 150)
    }
}

struct StatView: View {
    let title: String
    let count: Int
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct ActivityRow: View {
    let day: String
    let duration: Int // in minutes
    let completed: Bool

    var body: some View {
        HStack {
            Text(day)
                .frame(width: 50, alignment: .leading)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(nsColor: .quaternaryLabelColor))
                    .frame(height: 8)

                Capsule()
                    .fill(completed ? Color.green : Color.orange)
                    .frame(width: CGFloat(duration) / 150 * 200, height: 8)
                    .animation(.easeInOut(duration: 0.6), value: duration)
            }
            .frame(height: 8)

            Text("\(duration)分钟")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)

            Image(systemName: completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(completed ? .green : .orange)
        }
        .frame(height: 20)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(timerManager: TimerManager())
    }
}
