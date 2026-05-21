import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statsGrid
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("CookieZap")
            .onAppear {
                viewModel.loadStats()
                viewModel.loadRecentEvents(modelContext: modelContext)
            }
            .refreshable {
                viewModel.loadStats()
                viewModel.loadRecentEvents(modelContext: modelContext)
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("\(viewModel.todayZapped)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Popups Zapped Today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "Total Zapped",
                value: "\(viewModel.totalZapped)",
                icon: "shield.checkered",
                color: .green
            )
            StatCardView(
                title: "Success Rate",
                value: viewModel.successRate.formatted(.percent.precision(.fractionLength(0))),
                icon: "chart.pie",
                color: .orange
            )
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if viewModel.recentEvents.isEmpty {
                ContentUnavailableView(
                    "No Activity Yet",
                    systemImage: "cookie",
                    description: Text("Start browsing to see cookie popups zapped here")
                )
                .frame(height: 120)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    HStack {
                        Image(systemName: event.action == "rejected" ? "xmark.shield.fill" : "eye.slash.fill")
                            .foregroundStyle(event.action == "rejected" ? .green : .orange)
                            .frame(width: 28)

                        VStack(alignment: .leading) {
                            Text(event.domain)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(event.cmp)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(event.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
