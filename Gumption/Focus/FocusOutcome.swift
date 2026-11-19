import Foundation

/// Values stored in `FocusSession.outcome`. Stored as strings so old stores stay readable.
enum FocusOutcome {
    static let done = "done"
    static let stuck = "stuck"
    /// Session ended for a break. The break runs from `endedAt` for the break length,
    /// so it survives a relaunch without any extra state (D2).
    static let breakTime = "break"
}

/// Plain values copied out of `FocusSession`, so stats math is testable without a store.
struct SessionRecord: Equatable {
    var taskID: UUID?
    var startedAt: Date
    var endedAt: Date?

    init(taskID: UUID?, startedAt: Date, endedAt: Date?) {
        self.taskID = taskID
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    init(_ session: FocusSession) {
        self.init(taskID: session.taskID, startedAt: session.startedAt, endedAt: session.endedAt)
    }

    /// Focus time of a finished session. Running sessions count up to `now`.
    func seconds(now: Date) -> TimeInterval {
        max(0, (endedAt ?? now).timeIntervalSince(startedAt))
    }
}

struct TaskSummary: Equatable {
    var stepsDone: Int
    var focusSeconds: TimeInterval

    var focusMinutes: Int { Int((focusSeconds / 60).rounded()) }

    static func make(stepsDone: Int, sessions: [SessionRecord], now: Date = .now) -> TaskSummary {
        TaskSummary(stepsDone: stepsDone,
                    focusSeconds: sessions.reduce(0) { $0 + $1.seconds(now: now) })
    }
}
