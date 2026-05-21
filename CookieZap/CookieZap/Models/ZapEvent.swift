import Foundation
import SwiftData

@Model
final class ZapEvent {
    var domain: String
    var action: String
    var cmp: String
    var timestamp: Date

    init(domain: String, action: String, cmp: String, timestamp: Date = .now) {
        self.domain = domain
        self.action = action
        self.cmp = cmp
        self.timestamp = timestamp
    }
}
