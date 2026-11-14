import SafariServices
import os.log

struct PendingEventData: Codable {
    let domain: String
    let action: String
    let cmp: String
    let timestamp: Date
}

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(subsystem: "com.zzoutuo.CookieZap.extension", category: "SafariWebExtensionHandler")

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]

        let action = message["action"] as? String ?? ""
        var responseData: [String: Any] = ["status": "ok"]

        switch action {
        case "zapEvent":
            handleZapEvent(message)
        case "getSettings":
            responseData = getSettingsDict()
        case "updateSettings":
            handleUpdateSettings(message)
        case "getStats":
            responseData = getStatsDict()
        default:
            break
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: responseData]
        context.completeRequest(returningItems: [response])
    }

    private func handleZapEvent(_ message: [String: Any]) {
        let domain = message["domain"] as? String ?? "unknown"
        let action = message["actionType"] as? String ?? "unknown"
        let cmp = message["cmp"] as? String ?? "Unknown"

        guard shouldRecord(domain: domain, action: action, cmp: cmp) else { return }

        let appGroup = AppGroupManager.shared
        appGroup.recordZap(action: action)
        savePendingEvent(domain: domain, action: action, cmp: cmp)

        logger.info("Zap event: \(domain) - \(action) via \(cmp)")
    }

    /// Content scripts already dedupe per page, but multiple frames and SPA
    /// re-detections can still arrive in bursts. Ignore identical events that
    /// land within three seconds of each other.
    private func shouldRecord(domain: String, action: String, cmp: String) -> Bool {
        let defaults = AppGroupManager.shared.defaultsRef
        let now = Date()

        let lastDomain = defaults.string(forKey: "last_event_domain")
        let lastAction = defaults.string(forKey: "last_event_action")
        let lastCmp = defaults.string(forKey: "last_event_cmp")
        let lastTime = defaults.object(forKey: "last_event_time") as? Date ?? .distantPast

        defaults.set(domain, forKey: "last_event_domain")
        defaults.set(action, forKey: "last_event_action")
        defaults.set(cmp, forKey: "last_event_cmp")
        defaults.set(now, forKey: "last_event_time")

        if lastDomain == domain, lastAction == action, lastCmp == cmp, now.timeIntervalSince(lastTime) < 3 {
            return false
        }
        return true
    }

    private func savePendingEvent(domain: String, action: String, cmp: String) {
        let defaults = AppGroupManager.shared.defaultsRef
        let pendingKey = "pending_zap_events"

        var events: [PendingEventData] = []
        if let existing = defaults.data(forKey: pendingKey),
           let decoded = try? JSONDecoder().decode([PendingEventData].self, from: existing) {
            events = decoded
        }

        events.append(PendingEventData(domain: domain, action: action, cmp: cmp, timestamp: .now))

        let recent = Array(events.suffix(100))
        if let encoded = try? JSONEncoder().encode(recent) {
            defaults.set(encoded, forKey: pendingKey)
        }
    }

    private func getSettingsDict() -> [String: Any] {
        let appGroup = AppGroupManager.shared
        return [
            "isEnabled": appGroup.isEnabled,
            "blockingMode": appGroup.blockingMode,
            "whitelistDomains": appGroup.whitelistDomains,
            "ruleVersion": appGroup.ruleVersion
        ]
    }

    private func handleUpdateSettings(_ message: [String: Any]) {
        let appGroup = AppGroupManager.shared

        if let isEnabled = message["isEnabled"] as? Bool {
            appGroup.isEnabled = isEnabled
        }
        if let blockingMode = message["blockingMode"] as? String {
            appGroup.blockingMode = blockingMode
        }
        if let whitelistDomains = message["whitelistDomains"] as? [String] {
            appGroup.whitelistDomains = whitelistDomains
        }
    }

    private func getStatsDict() -> [String: Any] {
        let appGroup = AppGroupManager.shared
        appGroup.refreshDailyIfNeeded()
        return [
            "todayZapped": appGroup.todayZapped,
            "totalZapped": appGroup.totalZapped,
            "totalRejected": appGroup.totalRejected,
            "totalAttempted": appGroup.totalAttempted,
            "isEnabled": appGroup.isEnabled,
            "blockingMode": appGroup.blockingMode
        ]
    }
}
