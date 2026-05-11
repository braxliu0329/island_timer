import Foundation
import SwiftUI

class DisplaySettings: ObservableObject {
    @Published var isHovered: Bool = false
    @Published var isPinned: Bool = false
    
    let notchWidth: CGFloat = 200
    let notchHeight: CGFloat = 35
    
    func currentHeight(status: TimerManager.TimerStatus, isRunning: Bool) -> CGFloat {
        if status == .finished && (isHovered || isPinned) { return 110 }
        if isHovered || isPinned { return 85 }
        if isRunning { return 55 }
        return notchHeight
    }
    
    func currentWidth(status: TimerManager.TimerStatus, isRunning: Bool) -> CGFloat {
        if status == .finished && (isHovered || isPinned) { return 420 }
        if isHovered || isPinned { return 340 }
        if isRunning { return 110 }
        return notchWidth
    }
}
