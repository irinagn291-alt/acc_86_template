import SwiftUI

@MainActor
final class ArcDashboardModel: ObservableObject {
    @Published var sets: [SwingSet] = []
    @Published var records: [SwingRecord] = []
    @Published var dailySet: SwingSet?
    @Published var todayRecord: SwingRecord?
    @Published var expandedSetId: UUID?
    @Published var showArena = false
    @Published var arenaSet: SwingSet?
    @Published var showResult = false
    @Published var lastLanded: ArcSegment?

    var streak: Int { SwingStreakCalculator.currentStreak(from: records) }
    var weekActivity: [Bool] { SwingStreakCalculator.weekActivity(from: records) }

    func reload(services: PenduloraServices) {
        sets = (try? services.setRepository.fetchAll()) ?? []
        records = (try? services.recordRepository.fetchAll()) ?? []
        todayRecord = (try? services.recordRepository.fetchToday())?.first

        if let preferredId = services.preferences.defaultDailySetId,
           let preferred = sets.first(where: { $0.id == preferredId }) {
            dailySet = preferred
        } else {
            dailySet = sets.first
        }
    }

    func toggleExpanded(_ set: SwingSet) {
        expandedSetId = expandedSetId == set.id ? nil : set.id
        LuxHaptics.shared.selection()
    }

    func openArena(for set: SwingSet) {
        arenaSet = set
        showArena = true
    }

    func handleLanding(segment: ArcSegment, services: PenduloraServices) {
        guard let set = arenaSet else { return }
        lastLanded = segment
        let record = SwingRecord(
            swingSetId: set.id,
            swingSetName: set.name,
            landedTitle: segment.title,
            landedDetails: segment.details
        )
        try? services.recordRepository.insert(record)
        todayRecord = record
        records.insert(record, at: 0)
        showArena = false
        showResult = true
        LuxHaptics.shared.success()
    }
}

struct ArcDashboard: View {
    @EnvironmentObject private var services: PenduloraServices
    @StateObject private var model = ArcDashboardModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    PendulumHeroDecoration(
                        segmentCount: model.dailySet?.segments.count ?? 5,
                        reduceMotion: services.preferences.reduceAnimations
                    )
                    .padding(.horizontal, 4)
                    ChainLinkStreak(streak: model.streak, weekActivity: model.weekActivity)
                    todayCard
                    packsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                model.reload(services: services)
                LuxHaptics.shared.setEnabled(services.preferences.hapticsEnabled)
            }
            .fullScreenCover(isPresented: $model.showArena) {
                if let set = model.arenaSet {
                    SwingArenaView(swingSet: set) { segment in
                        model.handleLanding(segment: segment, services: services)
                    }
                }
            }
            .sheet(isPresented: $model.showResult) {
                if let segment = model.lastLanded, let set = model.arenaSet ?? model.dailySet {
                    SwingResultSheet(setName: set.name, segment: segment) {
                        model.showResult = false
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline)
                .foregroundStyle(LuxPalette.textMuted)
            Text(AppConstants.appName)
                .luxCormorant(36)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "A refined morning"
        case 12..<17: return "An elegant afternoon"
        default: return "A graceful evening"
        }
    }

    private var todayCard: some View {
        LuxGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                LuxSectionHeader(
                    title: "Today's Arc",
                    subtitle: model.dailySet?.name ?? "Select a swing set"
                )
                if let record = model.todayRecord {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Landed on")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LuxPalette.secondary)
                        Text(record.landedTitle).luxCormorant(22)
                    }
                } else if let set = model.dailySet {
                    LuxPrimaryButton("Swing the Pendulum", icon: "arrow.triangle.2.circlepath") {
                        model.openArena(for: set)
                    }
                }
            }
        }
    }

    private var packsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LuxSectionHeader(title: "Swing Packs", subtitle: "Curated arcs of decision")
            ForEach(model.sets) { set in
                LuxAccordionPack(
                    set: set,
                    isExpanded: model.expandedSetId == set.id,
                    onToggle: { model.toggleExpanded(set) },
                    onSwing: { model.openArena(for: set) }
                )
            }
        }
    }
}

extension SwingSet: @retroactive Identifiable {}
