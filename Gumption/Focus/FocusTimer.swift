import Foundation

/// Pure timer math from a stored start timestamp (D2): the result is the same
/// after backgrounding, termination or relaunch.
struct FocusTimer: Equatable {
    let startedAt: Date
    let plannedSeconds: Int

    func elapsed(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(startedAt))
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, TimeInterval(plannedSeconds) - elapsed(at: now))
    }

    /// 1.0 when just started, 0.0 when time is up.
    func fractionRemaining(at now: Date) -> Double {
        guard plannedSeconds > 0 else { return 0 }
        return remaining(at: now) / TimeInterval(plannedSeconds)
    }

    func isFinished(at now: Date) -> Bool {
        remaining(at: now) == 0
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
