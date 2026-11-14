import Foundation

@Observable
class StatsManager {
    static let shared = StatsManager()

    var todayZapped: Int = 0
    var totalZapped: Int = 0
    var successRate: Double = 0

    private let appGroup = AppGroupManager.shared

    private init() {
        loadStats()
    }

    func loadStats() {
        appGroup.refreshDailyIfNeeded()
        todayZapped = appGroup.todayZapped
        totalZapped = appGroup.totalZapped
        let attempted = appGroup.totalAttempted
        let rejected = appGroup.totalRejected
        successRate = attempted > 0 ? Double(rejected) / Double(attempted) : 0
    }

    func refresh() {
        loadStats()
    }
}
