import StoreKit
import UIKit

/// Asks for an App Store rating only after the user has actually received
/// value: at least 10 zapped popups, at least two days of use, and once per
/// app version. iOS rate-limits the prompt itself, so this is intentionally
/// conservative.
enum ReviewPromptService {
    static func registerFirstLaunchIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "first_launch_date") == nil {
            defaults.set(Date(), forKey: "first_launch_date")
        }
    }

    @MainActor
    static func requestIfAppropriate(totalZapped: Int) {
        let defaults = UserDefaults.standard
        registerFirstLaunchIfNeeded()

        guard totalZapped >= 10 else { return }
        guard let firstLaunch = defaults.object(forKey: "first_launch_date") as? Date else { return }
        let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: .now).day ?? 0
        guard days >= 2 else { return }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
        guard defaults.string(forKey: "review_requested_version") != version else { return }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        defaults.set(version, forKey: "review_requested_version")
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
