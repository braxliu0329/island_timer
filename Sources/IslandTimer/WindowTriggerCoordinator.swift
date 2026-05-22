import Foundation
import AppKit

class WindowTriggerCoordinator: ObservableObject {
    static let shared = WindowTriggerCoordinator()

    private init() {}

    private var triggers: [String: Bool] = [:]

    enum TriggerOwner: String {
        case timer
        case memo
    }

    func beginTrigger(owner: TriggerOwner) -> Bool {
        let key = owner.rawValue
        if triggers[key] == true {
            return false // Already triggered
        }

        triggers[key] = true
        return true
    }

    func endTrigger(owner: TriggerOwner) {
        triggers[owner.rawValue] = false
    }

    func setActiveFeature(_ feature: AppFeature) {
        // This method can be used to communicate feature changes
        // Currently just prints for debugging
        print("WindowTriggerCoordinator: Set active feature to \(feature)")
    }
}