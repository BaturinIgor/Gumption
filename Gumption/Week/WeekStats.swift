import Foundation

/// The "Your week" numbers. Counted on device only, no streaks, nothing resets.
struct WeekStats: Equatable {
    struct Day: Equatable, Identifiable {
        var date: Date
        var focusMinutes: Int
        var id: Date { date }
    }

    /// Seven days, oldest first, ending today.
    var days: [Day]
    /// Distinct tasks that had at least one focus session this week.
    var tasksStarted: Int
    var totalFocusSeconds: TimeInterval
    var stepsDone: Int

    static func make(
        sessions: [SessionRecord],
        stepDoneDates: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WeekStats {
        let today = calendar.startOfDay(for: now)
        let dayStarts = (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        guard let weekStart = dayStarts.first else {
            return WeekStats(days: [], tasksStarted: 0, totalFocusSeconds: 0, stepsDone: 0)
        }

        let inWeek = sessions.filter { $0.startedAt >= weekStart && $0.startedAt <= now }
        var secondsByDay: [Date: TimeInterval] = [:]
        for session in inWeek {
            secondsByDay[calendar.startOfDay(for: session.startedAt), default: 0] += session.seconds(now: now)
        }

        let days = dayStarts.map { Day(date: $0, focusMinutes: Int(((secondsByDay[$0] ?? 0) / 60).rounded())) }
        let started = Set(inWeek.compactMap(\.taskID)).count
        let total = inWeek.reduce(0) { $0 + $1.seconds(now: now) }
        let steps = stepDoneDates.filter { $0 >= weekStart && $0 <= now }.count

        return WeekStats(days: days, tasksStarted: started, totalFocusSeconds: total, stepsDone: steps)
    }

    /// "45m", "2h 40m" in English; other languages get their own abbreviations.
    static func formatDuration(_ seconds: TimeInterval, locale: Locale = .current) -> String {
        let minutes = Int((seconds / 60).rounded())
        var calendar = Calendar.current
        calendar.locale = locale
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = minutes < 60 ? [.minute] : [.hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
    }
}
