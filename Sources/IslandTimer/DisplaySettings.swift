import Foundation
import SwiftUI

class DisplaySettings: ObservableObject {
    @Published var isHovered: Bool = false
    @Published var isPinned: Bool = false
    
    let notchWidth: CGFloat = 200
    let notchHeight: CGFloat = 35
    
    func currentHeight(status: TimerManager.TimerStatus, isRunning: Bool, activeFeature: AppFeature) -> CGFloat {
        if activeFeature == .memo {
            return (isHovered || isPinned) ? 220 : notchHeight
        }
        if status == .finished { return 120 }
        if activeFeature == .timer, (isHovered || isPinned) { return 94 }
        if isRunning { return 62 }
        return notchHeight
    }
    
    func currentWidth(status: TimerManager.TimerStatus, isRunning: Bool, activeFeature: AppFeature) -> CGFloat {
        if activeFeature == .memo {
            return (isHovered || isPinned) ? 420 : notchWidth
        }
        if status == .finished { return 460 }
        if activeFeature == .timer, (isHovered || isPinned) { return 380 }
        if isRunning { return 150 }
        return notchWidth
    }
}
