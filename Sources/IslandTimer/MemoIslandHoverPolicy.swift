import CoreGraphics

enum MemoIslandHoverMonitorDecision: Equatable {
    case noChange
    case beginHover
    case cancelPendingCollapse
    case scheduleCollapse
}

enum MemoIslandHoverPolicy {
    private static let edgeEpsilon: CGFloat = 0.5

    static func decision(isHovered: Bool, mouseLocation: CGPoint, windowFrame: CGRect) -> MemoIslandHoverMonitorDecision {
        guard isMouseInsideInteractiveArea(mouseLocation, windowFrame: windowFrame) else {
            return isHovered ? .scheduleCollapse : .noChange
        }

        return isHovered ? .cancelPendingCollapse : .beginHover
    }

    static func isMouseInsideInteractiveArea(_ mouseLocation: CGPoint, windowFrame: CGRect) -> Bool {
        guard !windowFrame.isNull, !windowFrame.isEmpty else { return false }

        return mouseLocation.x >= (windowFrame.minX - edgeEpsilon)
            && mouseLocation.x <= (windowFrame.maxX + edgeEpsilon)
            && mouseLocation.y >= (windowFrame.minY - edgeEpsilon)
            && mouseLocation.y <= (windowFrame.maxY + edgeEpsilon)
    }
}
