import SwiftUI
import SwiftData

@main
struct CookieZapApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        ReviewPromptService.registerFirstLaunchIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [ZapEvent.self, WhitelistSite.self])
    }
}
