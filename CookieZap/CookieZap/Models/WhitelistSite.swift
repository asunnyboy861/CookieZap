import Foundation
import SwiftData

@Model
final class WhitelistSite {
    var domain: String
    var addedAt: Date
    var isTemporary: Bool

    init(domain: String, isTemporary: Bool = false) {
        self.domain = domain
        self.addedAt = .now
        self.isTemporary = isTemporary
    }
}
