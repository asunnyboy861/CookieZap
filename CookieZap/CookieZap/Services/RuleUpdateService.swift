import Foundation

@Observable
class RuleUpdateService {
    var isUpdating = false
    var lastUpdate: Date = .distantPast
    var currentVersion: String = "1.0.0"

    private let appGroup = AppGroupManager.shared

    func checkForUpdates() async {
        isUpdating = true
        defer { isUpdating = false }

        guard let url = URL(string: Constants.ruleUpdateURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let versionInfo = try JSONDecoder().decode(RuleVersion.self, from: data)

            if versionInfo.version > appGroup.ruleVersion {
                try await downloadRules(version: versionInfo.version)
                appGroup.ruleVersion = versionInfo.version
                appGroup.lastUpdateTimestamp = .now
                currentVersion = versionInfo.version
                lastUpdate = .now
            }
        } catch {
            print("Rule update failed: \(error)")
        }
    }

    private func downloadRules(version: String) async throws {
        let ruleFiles = ["cmp-rules.json", "blocker-rules.json"]

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupIDs.shared
        ) else { return }

        for file in ruleFiles {
            guard let url = URL(string: "\(Constants.ruleBaseURL)\(file)") else { continue }
            let (data, _) = try await URLSession.shared.data(from: url)
            let destURL = containerURL.appendingPathComponent(file)
            try data.write(to: destURL)
        }
    }
}

struct RuleVersion: Codable {
    let version: String
    let timestamp: String
}
