import Foundation
import Combine

class ScreenShareExclusionSettings: ObservableObject {
    @Published var isExclusionEnabled = true

    init() {
        isExclusionEnabled = UserDefaults.standard.bool(forKey: "screenShareExclusionEnabled")

        $isExclusionEnabled
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "screenShareExclusionEnabled")
            }
            .store(in: &self.cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}
