import Foundation

@Observable
class AppGroupManager {
    static let shared = AppGroupManager()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: AppGroupIDs.shared)
    }

    var isEnabled: Bool {
        get { defaults?.bool(forKey: "is_enabled") ?? true }
        set { defaults?.set(newValue, forKey: "is_enabled") }
    }

    var blockingMode: String {
        get { defaults?.string(forKey: "blocking_mode") ?? "smart" }
        set { defaults?.set(newValue, forKey: "blocking_mode") }
    }

    var todayZapped: Int {
        get { defaults?.integer(forKey: "today_zapped") ?? 0 }
        set { defaults?.set(newValue, forKey: "today_zapped") }
    }

    var totalZapped: Int {
        get { defaults?.integer(forKey: "total_zapped") ?? 0 }
        set { defaults?.set(newValue, forKey: "total_zapped") }
    }

    var totalRejected: Int {
        get { defaults?.integer(forKey: "total_rejected") ?? 0 }
        set { defaults?.set(newValue, forKey: "total_rejected") }
    }

    var totalAttempted: Int {
        get { defaults?.integer(forKey: "total_attempted") ?? 0 }
        set { defaults?.set(newValue, forKey: "total_attempted") }
    }

    var lastUpdateTimestamp: Date {
        get { defaults?.object(forKey: "last_update_timestamp") as? Date ?? .distantPast }
        set { defaults?.set(newValue, forKey: "last_update_timestamp") }
    }

    var ruleVersion: String {
        get { defaults?.string(forKey: "rule_version") ?? "1.0.0" }
        set { defaults?.set(newValue, forKey: "rule_version") }
    }

    var whitelistDomains: [String] {
        get { defaults?.stringArray(forKey: "whitelist_domains") ?? [] }
        set { defaults?.set(newValue, forKey: "whitelist_domains") }
    }

    func addWhitelistDomain(_ domain: String) {
        var domains = whitelistDomains
        if !domains.contains(domain) {
            domains.append(domain)
            whitelistDomains = domains
        }
    }

    func removeWhitelistDomain(_ domain: String) {
        var domains = whitelistDomains
        domains.removeAll { $0 == domain }
        whitelistDomains = domains
    }

    func recordZap(action: String) {
        let today = Calendar.current.startOfDay(for: .now)
        let lastReset = defaults?.object(forKey: "last_daily_reset") as? Date ?? .distantPast

        if today > lastReset {
            defaults?.set(0, forKey: "today_zapped")
            defaults?.set(today, forKey: "last_daily_reset")
        }

        todayZapped += 1
        totalZapped += 1
        totalAttempted += 1
        if action == "rejected" {
            totalRejected += 1
        }
    }
}
