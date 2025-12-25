import UIKit

enum HapticsService {
    static func lightImpact(enabled: Bool = true) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(enabled: Bool = true) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
