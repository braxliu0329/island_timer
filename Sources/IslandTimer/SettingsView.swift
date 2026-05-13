import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("工作时长 (分钟)")
                    Spacer()
                    Stepper("\(timerManager.workDurationMinutes)", value: $timerManager.workDurationMinutes, in: 1...120)
                }
                
                HStack {
                    Text("休息时长 (分钟)")
                    Spacer()
                    Stepper("\(timerManager.breakDurationMinutes)", value: $timerManager.breakDurationMinutes, in: 1...60)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
