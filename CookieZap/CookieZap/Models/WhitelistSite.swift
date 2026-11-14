import Foundation
import SwiftData

@Model
final class WhitelistSite {
    var domain: String
    var addedAt: Date

    init(domain: String) {
        self.domain = domain
        self.addedAt = .now
    }
}
