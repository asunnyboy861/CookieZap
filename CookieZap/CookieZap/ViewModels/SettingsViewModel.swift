import SwiftUI
import SwiftData

@Observable
class SettingsViewModel {
    var isEnabled: Bool = true
    var blockingMode: String = "smart"
    var autoUpdateRules: Bool = true
    var newWhitelistDomain: String = ""

    private let appGroup = AppGroupManager.shared

    func loadSettings() {
        isEnabled = appGroup.isEnabled
        blockingMode = appGroup.blockingMode
    }

    /// The App Group is the single source of truth because the Safari popup can
    /// pause a site without launching the app. Mirror it into SwiftData so the
    /// list users edit here always matches what the extension actually does.
    func syncWhitelist(modelContext: ModelContext) {
        let shared = Set(appGroup.whitelistDomains)
        let existing = (try? modelContext.fetch(FetchDescriptor<WhitelistSite>())) ?? []

        var existingDomains = Set<String>()
        for site in existing {
            if shared.contains(site.domain) {
                existingDomains.insert(site.domain)
            } else {
                modelContext.delete(site)
            }
        }

        for domain in shared where !existingDomains.contains(domain) {
            modelContext.insert(WhitelistSite(domain: domain))
        }

        try? modelContext.save()
    }

    func toggleEnabled() {
        appGroup.isEnabled = isEnabled
    }

    func changeBlockingMode() {
        appGroup.blockingMode = blockingMode
    }

    func addWhitelistSite(modelContext: ModelContext) {
        let domain = newWhitelistDomain
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
            .components(separatedBy: "/").first ?? ""

        guard !domain.isEmpty, domain.contains(".") else { return }

        let site = WhitelistSite(domain: domain)
        modelContext.insert(site)
        appGroup.addWhitelistDomain(domain)
        newWhitelistDomain = ""
    }

    func removeWhitelistSite(_ site: WhitelistSite, modelContext: ModelContext) {
        appGroup.removeWhitelistDomain(site.domain)
        modelContext.delete(site)
    }
}
