import Foundation

@Observable
class AppGroupManager {
    static let shared = AppGroupManager()

    /// App Group is the source of truth shared with the Safari extensions.
    /// If the entitlement is missing (e.g. a local build without a provisioning
    /// profile), fall back to standard defaults so the app and the extension
    /// never crash or silently lose every write.
    private let store: UserDefaults

    private init() {
        store = UserDefaults(suiteName: AppGroupIDs.shared) ?? .standard
    }

    var defaultsRef: UserDefaults { store }

    var isEnabled: Bool {
        get { store.object(forKey: "is_enabled") as? Bool ?? true }
        set { store.set(newValue, forKey: "is_enabled") }
    }

    var blockingMode: String {
        get { store.string(forKey: "blocking_mode") ?? "smart" }
        set { store.set(newValue, forKey: "blocking_mode") }
    }

    var todayZapped: Int {
        get { store.integer(forKey: "today_zapped") }
        set { store.set(newValue, forKey: "today_zapped") }
    }

    var totalZapped: Int {
        get { store.integer(forKey: "total_zapped") }
        set { store.set(newValue, forKey: "total_zapped") }
    }

    var totalRejected: Int {
        get { store.integer(forKey: "total_rejected") }
        set { store.set(newValue, forKey: "total_rejected") }
    }

    var totalAttempted: Int {
        get { store.integer(forKey: "total_attempted") }
        set { store.set(newValue, forKey: "total_attempted") }
    }

    var ruleVersion: String {
        get { store.string(forKey: "rule_version") ?? "1.1.0" }
        set { store.set(newValue, forKey: "rule_version") }
    }

    var whitelistDomains: [String] {
        get { store.stringArray(forKey: "whitelist_domains") ?? [] }
        set { store.set(newValue, forKey: "whitelist_domains") }
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

    /// Resets the daily counter when the calendar day rolled over while the
    /// app was in the background. Called before every dashboard read.
    func refreshDailyIfNeeded() {
        let today = Calendar.current.startOfDay(for: .now)
        let lastReset = store.object(forKey: "last_daily_reset") as? Date ?? .distantPast
        if today > lastReset {
            todayZapped = 0
            store.set(today, forKey: "last_daily_reset")
        }
    }

    func recordZap(action: String) {
        refreshDailyIfNeeded()

        todayZapped += 1
        totalZapped += 1
        totalAttempted += 1
        if action == "rejected" {
            totalRejected += 1
        }
        store.set(Date(), forKey: "last_zap_at")
    }
}
