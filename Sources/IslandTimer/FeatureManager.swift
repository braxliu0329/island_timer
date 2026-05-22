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

    private let defaults = UserDefaults.standard

    init() {
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

        // 通知 WindowTriggerCoordinator 当前的 feature
        WindowTriggerCoordinator.shared.setActiveFeature(activeFeature)
    }

    private static let activeFeatureKey = "islandTimer.activeFeature"
    private static let memoTextKey = "islandTimer.memoText"
    private static let memoItemsKey = "islandTimer.memoItems"

    private func persistActiveFeature() {
        UserDefaults.standard.set(activeFeature.rawValue, forKey: Self.activeFeatureKey)
    }

    private func persistMemoText() {
        UserDefaults.standard.set(memoText, forKey: Self.memoTextKey)
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
        UserDefaults.standard.set(data, forKey: Self.memoItemsKey)
    }
}
