import SwiftUI
import SwiftData

@Observable
class DashboardViewModel {
    var todayZapped: Int = 0
    var totalZapped: Int = 0
    var weekZapped: Int = 0
    var recentEvents: [ZapEvent] = []

    private let statsManager = StatsManager.shared
    private let appGroup = AppGroupManager.shared

    var minutesSaved: Int {
        // A cookie banner typically costs about eight seconds of tapping.
        totalZapped * 8 / 60
    }

    func refresh(modelContext: ModelContext) {
        statsManager.refresh()
        todayZapped = statsManager.todayZapped
        totalZapped = statsManager.totalZapped

        syncPendingEvents(modelContext: modelContext)
        loadEvents(modelContext: modelContext)
        ReviewPromptService.requestIfAppropriate(totalZapped: totalZapped)
    }

    private func loadEvents(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<ZapEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 500

        guard let events = try? modelContext.fetch(descriptor) else {
            recentEvents = []
            weekZapped = 0
            return
        }

        recentEvents = Array(events.prefix(8))

        let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now)) ?? .distantPast
        weekZapped = events.filter { $0.timestamp >= weekStart }.count
    }

    private func syncPendingEvents(modelContext: ModelContext) {
        let pendingKey = "pending_zap_events"
        guard let data = appGroup.defaultsRef.data(forKey: pendingKey),
              let events = try? JSONDecoder().decode([ZapEventPayload].self, from: data),
              !events.isEmpty else {
            return
        }

        for event in events {
            let zapEvent = ZapEvent(
                domain: event.domain,
                action: event.action,
                cmp: event.cmp,
                timestamp: event.timestamp
            )
            modelContext.insert(zapEvent)
        }

        try? modelContext.save()
        appGroup.defaultsRef.removeObject(forKey: pendingKey)
    }
}

private struct ZapEventPayload: Codable {
    let domain: String
    let action: String
    let cmp: String
    let timestamp: Date
}
