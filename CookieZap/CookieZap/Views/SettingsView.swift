import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WhitelistSite.addedAt) private var whitelistSites: [WhitelistSite]

    var body: some View {
        NavigationStack {
            Form {
                masterToggleSection
                blockingModeSection
                whitelistSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadSettings() }
        }
    }

    private var masterToggleSection: some View {
        Section {
            Toggle("Enable CookieZap", isOn: $viewModel.isEnabled)
                .onChange(of: viewModel.isEnabled) { viewModel.toggleEnabled() }
        } footer: {
            Text("When enabled, CookieZap automatically rejects cookie popups in Safari")
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
            Text("Blocking Mode")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.blockingMode == "smart" {
                    Text("Finds and clicks \"Reject\" buttons automatically")
                } else if viewModel.blockingMode == "hide" {
                    Text("Hides cookie popups with CSS — no button interaction")
                } else {
                    Text("Blocks cookie-related network requests entirely")
                }
            }
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
            Text("Whitelist")
        } footer: {
            Text("Sites on the whitelist will not have popups blocked")
        }
    }

    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: Constants.supportURL)!) {
                Label("Support", systemImage: "questionmark.circle")
            }
            Link(destination: URL(string: Constants.privacyURL)!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Us", systemImage: "envelope")
            }
        } header: {
            Text("About")
        }
    }
}
