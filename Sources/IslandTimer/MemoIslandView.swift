import SwiftUI

struct MemoIslandView: View {
    let memo: MemoItem
    @ObservedObject var displaySettings: MemoIslandDisplaySettings
    var onSizeChange: ((CGSize) -> Void)? = nil
    var featureManager: FeatureManager
    
    @State private var memoScrollY: CGFloat = 0

    var notchWidth: CGFloat { displaySettings.notchWidth }
    var notchHeight: CGFloat { displaySettings.notchHeight }

    var currentWidth: CGFloat { displaySettings.currentWidth() }
    var currentHeight: CGFloat { displaySettings.currentHeight() }

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
                .shadow(color: .black.opacity(displaySettings.isHovered ? 0.4 : 0), radius: 10, x: 0, y: 5)

                ZStack(alignment: .topLeading) {
                    if displaySettings.isHovered {
                        expandedView
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        collapsedView
                    }
                }
                .padding(.top, notchHeight)
                .frame(width: currentWidth, height: currentHeight, alignment: .topLeading)
                .foregroundColor(.white)
                .clipped()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: currentWidth)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: currentHeight)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: displaySettings.isHovered)
            .contentShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: currentHeight * 0.45,
                bottomTrailingRadius: currentHeight * 0.45,
                topTrailingRadius: 0,
                style: .continuous
            ))
            .onHover { hovering in
                if hovering {
                    guard featureManager.activeFeature == .memo else {
                        print("MemoIslandView: Failed to begin trigger for memo mode")
                        return
                    }

                    guard WindowTriggerCoordinator.shared.beginTrigger(owner: .memo) else {
                        print("MemoIslandView: Failed to begin trigger for memo mode")
                        return
                    }

                    displaySettings.isHovered = true
                    print("MemoIslandView: Entered hover state for memo mode")
                } else {
                    displaySettings.isHovered = false
                    print("MemoIslandView: Exited hover state for memo mode")
                }
            }

            Color.white.opacity(0.001)
                .frame(width: notchWidth, height: notchHeight)
                .onHover { hovering in
                    guard featureManager.activeFeature == .memo else { return }
                    if hovering {
                        guard WindowTriggerCoordinator.shared.beginTrigger(owner: .memo) else { return }
                        displaySettings.isHovered = true
                    }
                }
        }
        .onPreferenceChange(IslandSizeKey.self) { size in
            DispatchQueue.main.async {
                onSizeChange?(size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .onAppear {
            memoScrollY = featureManager.memoItemScrollPositionY(for: memo.id)
        }
        .onChange(of: memoScrollY) { newValue in
            featureManager.setMemoItemScrollPositionY(newValue, for: memo.id)
        }
        .onChange(of: displaySettings.isHovered) { hovered in
            if hovered {
                memoScrollY = featureManager.memoItemScrollPositionY(for: memo.id)
            } else {
                featureManager.setMemoItemScrollPositionY(memoScrollY, for: memo.id)
                featureManager.flushScrollPositionsPersist()
            }
        }
    }

    private var collapsedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
            Text("备忘")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue.opacity(0.95))
                Text("备忘")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }

            SmoothScrollingTextEditor(
                text: Binding.constant(memo.text),
                scrollY: $memoScrollY
            )
            .frame(height: 100)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
