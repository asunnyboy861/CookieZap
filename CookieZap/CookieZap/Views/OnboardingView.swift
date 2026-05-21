import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            onboardingPage(
                icon: "bolt.circle.fill",
                title: "Zap Cookie Popups",
                subtitle: "Automatically reject cookie consent popups while you browse",
                tag: 0
            )
            onboardingPage(
                icon: "shield.checkered",
                title: "Smart Detection",
                subtitle: "CookieZap finds and clicks \"Reject\" buttons for you — no setup needed",
                tag: 1
            )
            onboardingPage(
                icon: "safari",
                title: "Enable in Safari",
                subtitle: "After setup, open Safari Settings → Extensions → turn on CookieZap",
                tag: 2
            )
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func onboardingPage(icon: String, title: String, subtitle: String, tag: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text(title)
                .font(.title.bold())

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .tag(tag)
    }
}
