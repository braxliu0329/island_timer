import SwiftUI

struct StatisticsView: View {
    @ObservedObject var timerManager: TimerManager
    
    let quotes = [
        ("种一棵树最好的时间是十年前，其次是现在。", "丹碧萨·莫约"),
        ("天才就是百分之一的灵感加上百分之九十九的汗水。", "托马斯·爱迪生"),
        ("不积跬步，无以至千里；不积小流，无以成江海。", "荀子"),
        ("业精于勤，荒于嬉；行成于思，毁于随。", "韩愈"),
        ("你不能把今天的时间留给明天，所以你必须每一天都努力。", "佚名"),
        ("放弃不难，但坚持一定很酷。", "佚名"),
        ("生活坏到一定程度就会好起来，因为它无法更坏。努力过后，才知道许多事情，坚持坚持，就过来了。", "《龙猫》"),
        ("只要不失去你的方向，你就不会失去你自己。", "佚名")
    ]
    
    @State private var selectedQuote: (String, String) = ("", "")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("今日统计")
                .font(.headline)
            
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("专注")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(timerManager.todayStats.workSessions) 次")
                        .font(.title2)
                        .bold()
                    Text(formatTime(timerManager.todayStats.totalWorkTime))
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("休息")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(timerManager.todayStats.breakSessions) 次")
                        .font(.title2)
                        .bold()
                    Text(formatTime(timerManager.todayStats.totalBreakTime))
                        .font(.body)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 5) {
                Text(selectedQuote.0)
                    .font(.body)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                Text("—— \(selectedQuote.1)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            if selectedQuote.0.isEmpty {
                selectedQuote = quotes.randomElement()!
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}
