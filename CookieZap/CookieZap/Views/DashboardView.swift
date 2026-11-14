import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    statsRow

                    if viewModel.totalZapped == 0 {
                        getStartedCard
                    } else {
                        activityCard
                    }

                    shareCard
                    attribution
                }
                .padding()
            }
            .navigationTitle("CookieZap")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText, subject: Text("CookieZap"), message: Text(shareText)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .task { refresh() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { refresh() }
            }
            .refreshable { refresh() }
        }
    }

    private var shareText: String {
        "CookieZap has killed \(viewModel.totalZapped) cookie popups for me. It's a Safari extension that rejects those banners automatically: \(Constants.appStoreURL)"
    }

    private func refresh() {
        viewModel.refresh(modelContext: modelContext)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Today", systemImage: "bolt.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(viewModel.todayZapped > 0 ? "Protection active" : "Watching")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.18), in: Capsule())
                    .foregroundStyle(.white)
            }

            Text("\(viewModel.todayZapped)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(viewModel.todayZapped == 1 ? "cookie popup rejected" : "cookie popups rejected")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            if viewModel.minutesSaved > 0 {
                Text("About \(viewModel.minutesSaved) minutes saved so far")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.48, blue: 0.96), Color(red: 0.25, green: 0.72, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "All time",
                value: "\(viewModel.totalZapped)",
                icon: "shield.checkered",
                color: .green
            )
            StatCardView(
                title: "Last 7 days",
                value: "\(viewModel.weekZapped)",
                icon: "calendar",
                color: .orange
            )
        }
    }

    private var getStartedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Get started in 3 steps")
                .font(.headline)

            miniStep(number: 1, text: "Open Settings › Safari › Extensions and turn on CookieZap.")
            miniStep(number: 2, text: "Open a website and accept nothing — banners are refused for you.")
            miniStep(number: 3, text: "Come back here to watch your counter grow.")

            HStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                Button {
                    if let url = URL(string: Constants.testURL) { openURL(url) }
                } label: {
                    Label("Test page", systemImage: "play.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                        )
                        .foregroundStyle(.primary)
                }
            }

            NavigationLink {
                SetupGuideView()
            } label: {
                Text("See the full setup guide")
                    .font(.footnote.bold())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent activity")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    SetupGuideView()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.recentEvents.isEmpty {
                Text("Your totals are synced. New activity shows up here after you browse the web.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    activityRow(event)
                    if event.id != viewModel.recentEvents.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func activityRow(_ event: ZapEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.action == "rejected" ? "xmark.shield.fill" : "eye.slash.fill")
                .foregroundStyle(event.action == "rejected" ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.domain)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(event.action == "rejected" ? "Rejected · \(event.cmp)" : "Hidden · \(event.cmp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(event.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var shareCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tell a friend")
                .font(.headline)

            Text("Cookie popups are annoying for everyone. One tap shares CookieZap with someone who needs it.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ShareLink(item: shareText) {
                    Label("Share CookieZap", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                Button {
                    if let url = URL(string: Constants.reviewURL) { openURL(url) }
                } label: {
                    Label("Rate us", systemImage: "star")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                        )
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var attribution: some View {
        VStack(spacing: 4) {
            Text("Rules by \(Constants.ruleLibraryName) · \(Constants.ruleCount.formatted()) platforms")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Everything stays on your device.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 4)
    }

    private func miniStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue, in: Circle())

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
