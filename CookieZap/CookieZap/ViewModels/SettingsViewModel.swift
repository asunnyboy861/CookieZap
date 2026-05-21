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
