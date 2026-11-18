import XCTest
@testable import Gumption

final class FocusTimerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    func testRemainingIsComputedFromStartTimestamp() {
        let timer = FocusTimer(startedAt: start, plannedSeconds: 120)
        XCTAssertEqual(timer.remaining(at: start), 120)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(36)), 84)
        XCTAssertEqual(FocusTimer.format(timer.remaining(at: start.addingTimeInterval(36))), "1:24")
    }

    func testTimerSurvivesLongBackgrounding() {
        // D2: 10 minutes in the background must not reset or freeze the timer.
        let timer = FocusTimer(startedAt: start, plannedSeconds: 1500)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(600)), 900)
    }

    func testTimerNeverGoesNegative() {
        let timer = FocusTimer(startedAt: start, plannedSeconds: 60)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(3600)), 0)
        XCTAssertTrue(timer.isFinished(at: start.addingTimeInterval(61)))
        XCTAssertEqual(timer.fractionRemaining(at: start.addingTimeInterval(30)), 0.5, accuracy: 0.0001)
    }
}
