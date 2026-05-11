import SwiftUI

struct IslandView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var displaySettings: DisplaySettings
    
    var notchWidth: CGFloat { displaySettings.notchWidth }
    var notchHeight: CGFloat { displaySettings.notchHeight }
    
    var isExpanded: Bool {
        displaySettings.isHovered || displaySettings.isPinned || timerManager.status == .finished
    }
    
    var isRunning: Bool {
        timerManager.status == .running || timerManager.status == .paused
    }
    
    var currentHeight: CGFloat {
        displaySettings.currentHeight(status: timerManager.status, isRunning: isRunning)
    }
    
    var currentWidth: CGFloat {
        displaySettings.currentWidth(status: timerManager.status, isRunning: isRunning)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. The Interactive Island Group
            ZStack(alignment: .top) {
                // Background Shape
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: currentHeight * 0.4,
                    bottomTrailingRadius: currentHeight * 0.4,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(Color.black)
                .frame(width: currentWidth, height: currentHeight)
                .shadow(color: .black.opacity(isExpanded ? 0.5 : 0), radius: 10, x: 0, y: 5)
                
                // Content
                ZStack(alignment: .top) {
                    if timerManager.status == .finished {
                        finishedView
                            .padding(.top, notchHeight)
                            .opacity(isExpanded ? 1 : 0)
                    } else if isExpanded {
                        expandedView
                            .padding(.top, notchHeight)
                            .opacity(1)
                    } else if isRunning {
                        compactRunningView
                            .padding(.top, notchHeight)
                            .opacity(1)
                    } else {
                        collapsedView
                    }
                }
                .frame(width: currentWidth, height: currentHeight)
                .foregroundColor(.white)
                .clipped()
            }
            // CRITICAL: This contentShape ensures only the black capsule is interactive
            .contentShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: currentHeight * 0.4,
                bottomTrailingRadius: currentHeight * 0.4,
                topTrailingRadius: 0,
                style: .continuous
            ))
            .onHover { hovering in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                    displaySettings.isHovered = hovering
                }
            }
            
            // 2. Invisible Notch Trigger (Always present for initial hover)
            Color.white.opacity(0.001)
                .frame(width: notchWidth, height: notchHeight)
                .onHover { hovering in
                    if hovering {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                            displaySettings.isHovered = true
                        }
                    }
                }
        }
        // Remove fixed frame to allow window to control size
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Subviews
    
    var compactRunningView: some View {
        Text(timerManager.timeString)
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .transition(.opacity)
    }
    
    var collapsedView: some View {
        EmptyView()
    }
    
    var expandedView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: timerManager.mode == .work ? "brain.head.profile" : "cup.and.saucer.fill")
                        .foregroundColor(timerManager.mode == .work ? .orange : .green)
                        .font(.system(size: 9))
                    Text(timerManager.mode == .work ? "Work" : "Break")
                        .font(.system(size: 8, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                }
                
                Text(timerManager.timeString)
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
            }
            .padding(.leading, 25)
            
            Spacer()
            
            HStack(spacing: 15) {
                if timerManager.status == .running {
                    controlButton(icon: "pause.fill", color: .white.opacity(0.1)) {
                        timerManager.pause()
                    }
                } else {
                    controlButton(icon: "play.fill", color: .orange) {
                        timerManager.start()
                    }
                }
                
                controlButton(icon: "arrow.clockwise", color: .white.opacity(0.05)) {
                    timerManager.reset()
                }
            }
            .padding(.trailing, 25)
        }
        .opacity(isExpanded ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }
    
    var finishedView: some View {
        VStack(spacing: 15) {
            Text(timerManager.mode == .work ? "Focus Done!" : "Rest Done!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.orange)
            
            HStack(spacing: 15) {
                Button(action: {
                    timerManager.toggleMode()
                    timerManager.start()
                }) {
                    Text(timerManager.mode == .work ? "Start Break" : "Start Work")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    timerManager.reset()
                }) {
                    Text("End")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(isExpanded ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }
    
    func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .buttonStyle(.plain)
    }
}

struct IslandView_Previews: PreviewProvider {
    static var previews: some View {
        IslandView(timerManager: TimerManager(), displaySettings: DisplaySettings())
            .padding()
            .background(Color.gray)
    }
}
