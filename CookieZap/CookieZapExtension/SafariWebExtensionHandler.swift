import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(subsystem: "com.zzoutuo.CookieZap.extension", category: "SafariWebExtensionHandler")

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]

        logger.info("Received message from browser: \(message)")

        if let action = message["action"] as? String {
            switch action {
            case "zapEvent":
                handleZapEvent(message)
            case "getSettings":
                sendSettings(context: context)
                return
            default:
                break
            }
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["status": "ok"]]
        context.completeRequest(returningItems: [response])
    }

    private func handleZapEvent(_ message: [String: Any]) {
        let domain = message["domain"] as? String ?? "unknown"
        let action = message["action"] as? String ?? "unknown"
        let cmp = message["cmp"] as? String ?? "Unknown"

        let appGroup = AppGroupManager.shared
        appGroup.recordZap(action: action)

        logger.info("Zap event: \(domain) - \(action) via \(cmp)")
    }

    private func sendSettings(context: NSExtensionContext) {
        let appGroup = AppGroupManager.shared
        let settings: [String: Any] = [
            "isEnabled": appGroup.isEnabled,
            "blockingMode": appGroup.blockingMode,
            "whitelistDomains": appGroup.whitelistDomains
        ]

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: settings]
        context.completeRequest(returningItems: [response])
    }
}
