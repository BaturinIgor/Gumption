import XCTest
@testable import Gumption

final class StatsTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private let now = ISO8601DateFormatter().date(from: "2026-11-18T15:00:00Z")!

    private func at(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    func testTaskSummaryAddsFinishedAndRunningSessions() {
        let start = at("2026-11-18T14:00:00Z")
        let sessions = [
            SessionRecord(taskID: nil, startedAt: start, endedAt: start.addingTimeInterval(600)),
            SessionRecord(taskID: nil, startedAt: now.addingTimeInterval(-120), endedAt: nil),
        ]
        let summary = TaskSummary.make(stepsDone: 3, sessions: sessions, now: now)
        XCTAssertEqual(summary.focusSeconds, 720)
        XCTAssertEqual(summary.focusMinutes, 12)
        XCTAssertEqual(summary.stepsDone, 3)
    }

    func testWeekStatsBucketsByDayAndIgnoresOlderSessions() {
        let a = UUID(), b = UUID()
        let sessions = [
            SessionRecord(taskID: a, startedAt: at("2026-11-18T09:00:00Z"), endedAt: at("2026-11-18T09:10:00Z")),
            SessionRecord(taskID: a, startedAt: at("2026-11-18T10:00:00Z"), endedAt: at("2026-11-18T10:05:00Z")),
            SessionRecord(taskID: b, startedAt: at("2026-11-13T09:00:00Z"), endedAt: at("2026-11-13T09:25:00Z")),
            // 8 days ago: outside the week
            SessionRecord(taskID: UUID(), startedAt: at("2026-11-10T09:00:00Z"), endedAt: at("2026-11-10T10:00:00Z")),
        ]
        let steps = [at("2026-11-18T09:09:00Z"), at("2026-11-01T09:00:00Z")]
        let stats = WeekStats.make(sessions: sessions, stepDoneDates: steps, now: now, calendar: calendar)

        XCTAssertEqual(stats.days.count, 7)
        XCTAssertEqual(stats.days.first?.date, at("2026-11-12T00:00:00Z"))
        XCTAssertEqual(stats.days.last?.date, at("2026-11-18T00:00:00Z"))
        XCTAssertEqual(stats.days.map(\.focusMinutes), [0, 25, 0, 0, 0, 0, 15])
        XCTAssertEqual(stats.tasksStarted, 2)
        XCTAssertEqual(stats.totalFocusSeconds, 40 * 60)
        XCTAssertEqual(stats.stepsDone, 1)
    }

    func testDurationFormatting() {
        XCTAssertEqual(WeekStats.formatDuration(45 * 60), "45m")
        XCTAssertEqual(WeekStats.formatDuration(120 * 60), "2h")
        XCTAssertEqual(WeekStats.formatDuration(160 * 60), "2h 40m")
    }
}
