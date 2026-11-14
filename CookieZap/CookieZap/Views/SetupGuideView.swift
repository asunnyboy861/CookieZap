import SwiftUI
import UIKit

struct SetupGuideView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                steps
                actions
                footnote
            }
            .padding(20)
        }
        .navigationTitle("Set up CookieZap")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "safari.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("One switch. Then it runs silently.")
                .font(.title2.bold())

            Text("CookieZap lives inside Safari. Turn it on once and it keeps rejecting cookie banners on every site you visit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 14) {
            step(
                number: 1,
                icon: "gearshape.fill",
                title: "Open Settings",
                detail: "iOS 18: Settings › Apps › Safari › Extensions.\niOS 17: Settings › Safari › Extensions."
            )
            step(
                number: 2,
                icon: "checkmark.circle.fill",
                title: "Turn on CookieZap",
                detail: "Tap CookieZap, switch it on, and allow access when Safari asks."
            )
            step(
                number: 3,
                icon: "safari.fill",
                title: "Open any website",
                detail: "The first cookie banner you meet disappears on its own."
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
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
                    openURL(url)
                }
            } label: {
                Label("Test CookieZap", systemImage: "play.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Can't find CookieZap in Extensions?")
                .font(.footnote.bold())
            Text("Open the CookieZap app once, then check Settings again. Make sure Safari is your browser — extensions don't run in other browsers.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func step(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(number). \(title)")
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AcknowledgementsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cookie rejection rules")
                        .font(.subheadline.bold())
                    Text("CookieZap uses the open-source DuckDuckGo Autoconsent rule library (version \(Constants.ruleLibraryVersion)) to recognise and refuse cookie banners on \(Constants.ruleCount.formatted()) consent platforms.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Licensed under the Mozilla Public License 2.0.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("View Autoconsent on GitHub") {
                    openURL(URL(string: "https://github.com/duckduckgo/autoconsent")!)
                }
                Button("Read the MPL 2.0 license") {
                    openURL(URL(string: "https://www.mozilla.org/MPL/2.0/")!)
                }
            }

            Section {
                Text("Safari, iPhone and iPad are trademarks of Apple Inc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
