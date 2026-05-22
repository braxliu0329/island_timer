import SwiftUI

struct IslandSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct IslandView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var displaySettings: DisplaySettings
    @ObservedObject var featureManager: FeatureManager
    
    var onSizeChange: ((CGSize) -> Void)? = nil
    
    var notchWidth: CGFloat { displaySettings.notchWidth }
    var notchHeight: CGFloat { displaySettings.notchHeight }
    
    var isExpanded: Bool {
        if featureManager.activeFeature == .timer {
            return displaySettings.isPinned || timerManager.status == .finished || displaySettings.isHovered
        }
        return displaySettings.isPinned || displaySettings.isHovered
    }
    
    var isRunning: Bool {
        timerManager.status == .running || timerManager.status == .paused
    }
    
    var currentHeight: CGFloat {
        displaySettings.currentHeight(status: timerManager.status, isRunning: isRunning, activeFeature: featureManager.activeFeature)
    }
    
    var currentWidth: CGFloat {
        displaySettings.currentWidth(status: timerManager.status, isRunning: isRunning, activeFeature: featureManager.activeFeature)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: currentHeight * 0.45,
                    bottomTrailingRadius: currentHeight * 0.45,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(Color.black)
                .frame(width: currentWidth, height: currentHeight)
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: IslandSizeKey.self, value: geo.size)
                    }
                )
                .shadow(color: .black.opacity(isExpanded || timerManager.status == .finished ? 0.4 : 0), radius: 10, x: 0, y: 5)
                
                ZStack(alignment: .top) {
                    if featureManager.activeFeature == .memo {
                        if isExpanded {
                            memoExpandedView
                                .id("memoExpanded")
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            memoCollapsedView
                                .id("memoCollapsed")
                        }
                    } else if timerManager.status == .finished {
                        Group {
                            if timerManager.mode == .work {
                                workFinishedView
                                    .id("workFinished")
                            } else {
                                breakFinishedView
                                    .id("breakFinished")
                            }
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                    } else if isExpanded {
                        expandedView
                            .id("expanded")
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if isRunning {
                        compactRunningView
                            .id("running")
                            .transition(.opacity)
                    } else {
                        collapsedView
                            .id("collapsed")
                    }
                }
                .padding(.top, notchHeight)
                .frame(width: currentWidth, height: currentHeight, alignment: .top)
                .foregroundColor(.white)
                .clipped()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0), value: currentWidth)
            .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0), value: currentHeight)
            .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0), value: timerManager.status)
            .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0), value: displaySettings.isHovered)
            .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0), value: displaySettings.isPinned)
            .contentShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: currentHeight * 0.45,
                bottomTrailingRadius: currentHeight * 0.45,
                topTrailingRadius: 0,
                style: .continuous
            ))
            .onHover { hovering in
                handleHover(hovering)
            }

            Color.white.opacity(0.001)
                .frame(width: notchWidth, height: notchHeight)
                .onHover { hovering in
                    handleHover(hovering)
                }
        }
        .onPreferenceChange(IslandSizeKey.self) { size in
            DispatchQueue.main.async {
                onSizeChange?(size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
    }
    
    private var collapsedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
            Text(timerManager.timeString)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var memoCollapsedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
            Text("备忘")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var memoExpandedView: some View {
        VStack(spacing: 0) {
            SmoothScrollingTextEditor(text: $featureManager.memoText)
                .padding(10)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func handleHover(_ hovering: Bool) {
        let owner: WindowTriggerCoordinator.TriggerOwner = (featureManager.activeFeature == .memo) ? .memo : .timer

        if hovering {
            if WindowTriggerCoordinator.shared.beginTrigger(owner: owner) {
                displaySettings.isHovered = true
            }
        } else {
            displaySettings.isHovered = false
            WindowTriggerCoordinator.shared.endTrigger(owner: owner)
        }
    }

    private var compactRunningView: some View {
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
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var expandedView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: timerManager.mode == .work ? "brain.head.profile" : "cup.and.saucer.fill")
                        .foregroundColor(timerManager.mode == .work ? .orange : .green)
                        .font(.system(size: 10))
                    Text(timerManager.mode == .work ? "Work" : "Break")
                        .font(.system(size: 9, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                }

                Text(timerManager.timeString)
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.leading, 22)

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
            .padding(.trailing, 22)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    var workFinishedView: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            .padding(.leading, 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("专注结束！")
                    .font(.system(size: 18, weight: .bold))
                Text("辛苦了，喝杯水休息一下吧。")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    timerManager.toggleMode()
                    timerManager.start()
                }) {
                    Text("进入休息")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    timerManager.reset()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var breakFinishedView: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .padding(.leading, 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("休息结束！")
                    .font(.system(size: 18, weight: .bold))
                Text("能量已充满，开始下一段专注吗？")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    timerManager.toggleMode()
                    timerManager.start()
                }) {
                    Text("开始专注")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    timerManager.reset()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var notchControls: some View {
        EmptyView()
    }
}

struct IslandView_Previews: PreviewProvider {
    static var previews: some View {
        IslandView(timerManager: TimerManager(), displaySettings: DisplaySettings(), featureManager: FeatureManager())
            .padding()
            .background(Color.gray)
    }
}
