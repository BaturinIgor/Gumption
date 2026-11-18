import SwiftData
import SwiftUI

struct WeekView: View {
    @Query private var sessions: [FocusSession]
    @Query(filter: #Predicate<TaskStep> { $0.doneAt != nil }) private var doneSteps: [TaskStep]

    private var stats: WeekStats {
        WeekStats.make(sessions: sessions.map(SessionRecord.init),
                       stepDoneDates: doneSteps.compactMap(\.doneAt))
    }

    var body: some View {
        let stats = self.stats
        let maxMinutes = max(1, stats.days.map(\.focusMinutes).max() ?? 1)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(headline(stats))
                        .foregroundStyle(Palette.ink)
                    HStack(alignment: .bottom) {
                        ForEach(stats.days) { day in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(day.focusMinutes == 0 ? Palette.background : Palette.accent)
                                    .frame(width: 28, height: max(8, 96 * CGFloat(day.focusMinutes) / CGFloat(maxMinutes)))
                                Text(day.date, format: .dateTime.weekday(.narrow))
                                    .font(.caption).foregroundStyle(Palette.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text("\(day.focusMinutes) minutes on ") + Text(day.date, format: .dateTime.weekday(.wide)))
                        }
                    }
                    .frame(height: 120, alignment: .bottom)
                    Text("Focus minutes per day. Rest days are normal, not gaps.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                }
                .padding(20)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack(spacing: 8) {
                    tile(WeekStats.formatDuration(stats.totalFocusSeconds), "total focus")
                    tile("\(stats.stepsDone)", "tiny steps done")
                }

                Text("Counted on your device only. No streaks, nothing resets.")
                    .font(.footnote).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Palette.background)
        .navigationTitle("Your week")
    }

    private func headline(_ stats: WeekStats) -> String {
        switch stats.tasksStarted {
        case 0: return "A quiet week. Whenever you're ready, one tiny step is enough."
        case 1: return "You started 1 thing this week. Starting is the skill."
        default: return "You started \(stats.tasksStarted) things this week. Starting is the skill, and you're practicing it."
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(.title2, design: .rounded, weight: .heavy))
            Text(label).font(.footnote).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
