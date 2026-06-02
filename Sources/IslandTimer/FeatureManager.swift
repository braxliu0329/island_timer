import Foundation
import SwiftUI

enum AppFeature: String, CaseIterable, Identifiable {
    case timer
    case memo
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .timer: return "计时器"
        case .memo: return "备忘"
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .timer: return "timer"
        case .memo: return "note.text"
        }
    }
}

struct MemoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var createdAt: Date
    
    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

final class FeatureManager: ObservableObject {
    @Published var activeFeature: AppFeature {
        didSet {
            persistActiveFeature()
            print("FeatureManager: Propagated feature change to WindowTriggerCoordinator")
            WindowTriggerCoordinator.shared.setActiveFeature(activeFeature)
        }
    }

    @Published var memoText: String {
        didSet { persistMemoText() }
    }

    @Published private(set) var memoItems: [MemoItem] {
        didSet { persistMemoItems() }
    }

    private let defaults: UserDefaults
    private var memoTextScrollY: CGFloat
    private var memoItemScrollY: [UUID: CGFloat]
    private var pendingScrollPersistWorkItem: DispatchWorkItem?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 初始化 activeFeature
        if let savedFeatureRaw = defaults.string(forKey: Self.activeFeatureKey),
           let savedFeature = AppFeature(rawValue: savedFeatureRaw) {
            self.activeFeature = savedFeature
        } else {
            self.activeFeature = .timer
            defaults.set(AppFeature.timer.rawValue, forKey: Self.activeFeatureKey)
        }

        // 初始化 memoText
        self.memoText = defaults.string(forKey: Self.memoTextKey) ?? ""

        // 初始化 memoItems
        if let data = defaults.data(forKey: Self.memoItemsKey),
           let decoded = try? JSONDecoder().decode([MemoItem].self, from: data) {
            self.memoItems = decoded
        } else {
            self.memoItems = []
        }

        if defaults.object(forKey: Self.memoTextScrollYKey) != nil {
            self.memoTextScrollY = CGFloat(defaults.double(forKey: Self.memoTextScrollYKey))
        } else {
            self.memoTextScrollY = 0
        }

        if let data = defaults.data(forKey: Self.memoItemScrollYKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            var result: [UUID: CGFloat] = [:]
            result.reserveCapacity(decoded.count)
            for (key, value) in decoded {
                if let id = UUID(uuidString: key) {
                    result[id] = CGFloat(value)
                }
            }
            self.memoItemScrollY = result
        } else {
            self.memoItemScrollY = [:]
        }

        // 通知 WindowTriggerCoordinator 当前的 feature
        WindowTriggerCoordinator.shared.setActiveFeature(activeFeature)
    }

    private static let activeFeatureKey = "islandTimer.activeFeature"
    private static let memoTextKey = "islandTimer.memoText"
    private static let memoItemsKey = "islandTimer.memoItems"
    private static let memoTextScrollYKey = "islandTimer.memoTextScrollY"
    private static let memoItemScrollYKey = "islandTimer.memoItemScrollY"

    private func persistActiveFeature() {
        defaults.set(activeFeature.rawValue, forKey: Self.activeFeatureKey)
    }

    private func persistMemoText() {
        defaults.set(memoText, forKey: Self.memoTextKey)
    }

    func addMemo(text: String) -> MemoItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = MemoItem(text: trimmed)
        memoItems.insert(item, at: 0)
        return item
    }

    private func persistMemoItems() {
        guard let data = try? JSONEncoder().encode(memoItems) else { return }
        defaults.set(data, forKey: Self.memoItemsKey)
    }

    func memoTextScrollPositionY() -> CGFloat {
        memoTextScrollY
    }

    func setMemoTextScrollPositionY(_ y: CGFloat) {
        memoTextScrollY = y
        scheduleScrollPositionsPersist()
    }

    func memoItemScrollPositionY(for memoID: UUID) -> CGFloat {
        memoItemScrollY[memoID] ?? 0
    }

    func setMemoItemScrollPositionY(_ y: CGFloat, for memoID: UUID) {
        memoItemScrollY[memoID] = y
        scheduleScrollPositionsPersist()
    }

    func flushScrollPositionsPersist() {
        pendingScrollPersistWorkItem?.cancel()
        pendingScrollPersistWorkItem = nil
        persistScrollPositions()
    }
}

private extension FeatureManager {
    func scheduleScrollPositionsPersist() {
        pendingScrollPersistWorkItem?.cancel()

        let item = DispatchWorkItem { [weak self] in
            self?.persistScrollPositions()
        }
        pendingScrollPersistWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    func persistScrollPositions() {
        defaults.set(Double(memoTextScrollY), forKey: Self.memoTextScrollYKey)

        let payload: [String: Double] = memoItemScrollY.reduce(into: [:]) { partialResult, element in
            partialResult[element.key.uuidString] = Double(element.value)
        }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: Self.memoItemScrollYKey)
    }
}
