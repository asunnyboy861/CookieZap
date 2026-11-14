import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \WhitelistSite.addedAt) private var whitelistSites: [WhitelistSite]

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                masterToggleSection
                blockingModeSection
                setupSection
                whitelistSection
                supportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadSettings()
                viewModel.syncWhitelist(modelContext: modelContext)
            }
        }
    }

    private var masterToggleSection: some View {
        Section {
            Toggle("Enable CookieZap", isOn: $viewModel.isEnabled)
                .onChange(of: viewModel.isEnabled) { viewModel.toggleEnabled() }
        } footer: {
            Text("When enabled, CookieZap refuses cookie banners in Safari automatically.")
        }
    }

    private var blockingModeSection: some View {
        Section {
            Picker("Mode", selection: $viewModel.blockingMode) {
                Text("Smart Reject").tag("smart")
                Text("Hide Only").tag("hide")
                Text("Block All").tag("block")
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.blockingMode) { viewModel.changeBlockingMode() }
        } header: {
            Text("Blocking mode")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.blockingMode == "smart" {
                    Text("Finds the banner and taps “Reject” or “Necessary only” for you.")
                } else if viewModel.blockingMode == "hide" {
                    Text("Hides known cookie banners without clicking any buttons.")
                } else {
                    Text("Hides banners and blocks known consent scripts at the network level.")
                }
            }
        }
    }

    private var setupSection: some View {
        Section {
            NavigationLink {
                SetupGuideView()
            } label: {
                Label("How to enable in Safari", systemImage: "safari")
            }

            Button {
                if let url = URL(string: Constants.testURL) { openURL(url) }
            } label: {
                Label("Open the test page", systemImage: "play.circle")
            }
        } header: {
            Text("Setup & test")
        } footer: {
            Text("The test page shows a real cookie banner. If it disappears on its own, CookieZap is working.")
        }
    }

    private var whitelistSection: some View {
        Section {
            HStack {
                TextField("example.com", text: $viewModel.newWhitelistDomain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button(action: { viewModel.addWhitelistSite(modelContext: modelContext) }) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(viewModel.newWhitelistDomain.isEmpty)
            }

            ForEach(whitelistSites) { site in
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                    Text(site.domain)
                    Spacer()
                    Button(role: .destructive) {
                        viewModel.removeWhitelistSite(site, modelContext: modelContext)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        } header: {
            Text("Paused sites")
        } footer: {
            Text("Sites on this list are left alone. You can also pause a site from the Safari toolbar popup.")
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact us", systemImage: "envelope")
            }

            Button {
                if let url = URL(string: Constants.reviewURL) { openURL(url) }
            } label: {
                Label("Rate CookieZap", systemImage: "star")
            }

            ShareLink(item: "CookieZap refuses cookie popups automatically in Safari: \(Constants.appStoreURL)") {
                Label("Share CookieZap", systemImage: "square.and.arrow.up")
            }

            Link(destination: URL(string: Constants.supportURL)!) {
                Label("Support page", systemImage: "questionmark.circle")
            }

            Link(destination: URL(string: Constants.privacyURL)!) {
                Label("Privacy policy", systemImage: "hand.raised")
            }
        } header: {
            Text("Support")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(versionLabel)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Cookie rules")
                Spacer()
                Text("\(Constants.ruleCount.formatted()) platforms")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                AcknowledgementsView()
            } label: {
                Label("Acknowledgements", systemImage: "doc.text")
            }
        } header: {
            Text("About")
        } footer: {
            Text("CookieZap runs entirely on your device. No account, no analytics, no browsing data leaves your iPhone or iPad.")
        }
    }
}
