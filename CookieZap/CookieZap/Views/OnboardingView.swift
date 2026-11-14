import SwiftUI
import UIKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            valuePage.tag(0)
            coveragePage.tag(1)
            setupPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground))
    }

    private var valuePage: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 68))
                .foregroundStyle(.blue)

            Text("Cookie popups, gone.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("CookieZap finds the consent banner and taps “Reject” for you. No account, no setup, no interruptions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            mockBanner
                .padding(.horizontal, 32)
                .padding(.top, 6)

            Spacer()

            nextButton
        }
    }

    private var mockBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.orange)
                Text("We value your privacy")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
            }

            Text("We and our partners use cookies to personalise content and ads…")
                .font(.caption)
                .foregroundStyle(.secondary)
                .strikethrough(true, color: .secondary)

            HStack(spacing: 8) {
                Text("Accept all")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.secondary)
                Text("Reject")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }

            Label("CookieZap taps this for you", systemImage: "arrow.up")
                .font(.caption2)
                .foregroundStyle(.blue)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var coveragePage: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "checklist.checked")
                .font(.system(size: 68))
                .foregroundStyle(.blue)

            Text("Works on \(Constants.ruleCount.formatted()) platforms")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("CookieZap runs the open-source DuckDuckGo Autoconsent rules, so it recognises the consent systems most sites actually use.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            FlowChips(items: ["OneTrust", "Cookiebot", "Didomi", "Usercentrics", "Quantcast", "Sourcepoint", "TrustArc", "Osano", "CookieYes", "Iubenda"])
                .padding(.horizontal, 32)

            Spacer()

            nextButton
        }
    }

    private var setupPage: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "safari.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Turn it on once")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                stepRow(number: 1, text: "Settings › Safari › Extensions")
                stepRow(number: 2, text: "Turn on CookieZap and allow access")
                stepRow(number: 3, text: "Open any website — that's it")
            }
            .padding(.horizontal, 32)

            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                Button {
                    if let url = URL(string: Constants.testURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Test CookieZap", systemImage: "play.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("I've enabled it — Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation { currentPage += 1 }
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())
                .padding(.top, 2)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

private struct FlowChips: View {
    let items: [String]

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
