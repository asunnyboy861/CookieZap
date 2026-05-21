import Foundation

class BlockerRequestHandler: NSObject {

    func beginRequest(with context: NSExtensionContext) {
        guard let url = Bundle.main.url(forResource: "blockerlist", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            context.completeRequest(returningItems: [])
            return
        }

        let attachment = NSItemProvider(item: data as NSData, typeIdentifier: "application/json")
        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequest(returningItems: [item])
    }
}
