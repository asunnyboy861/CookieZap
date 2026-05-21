import SwiftUI
import SwiftData

@Observable
class DashboardViewModel {
    var todayZapped: Int = 0
    var totalZapped: Int = 0
    var successRate: Double = 0
    var recentEvents: [ZapEvent] = []

    private let statsManager = StatsManager.shared

    func loadStats() {
        statsManager.refresh()
        todayZapped = statsManager.todayZapped
        totalZapped = statsManager.totalZapped
        successRate = statsManager.successRate
    }

    func loadRecentEvents(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ZapEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let events = try? modelContext.fetch(descriptor) {
            recentEvents = Array(events.prefix(5))
        }
    }
}
