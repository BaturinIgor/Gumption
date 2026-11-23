import SwiftData
import XCTest
@testable import Gumption

@MainActor
final class TaskActionsTests: XCTestCase {
    private var context: ModelContext!

    override func setUpWithError() throws {
        context = ModelContext(try Persistence.makeContainer(inMemory: true))
    }

    func testAddTaskIgnoresBlankInput() throws {
        XCTAssertNil(TaskActions.addTask("   ", in: context))
        XCTAssertNotNil(TaskActions.addTask("  Book dentist ", in: context))
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.map(\.title), ["Book dentist"])
    }

    func testStepsAreAppendedInOrder() throws {
        let task = try XCTUnwrap(TaskActions.addTask("Clean the kitchen", in: context))
        TaskActions.addStep("Put 3 dishes in the sink", to: task, in: context)
        TaskActions.addStep("Wipe the counter", to: task, in: context)
        XCTAssertEqual(task.orderedSteps.map(\.text), ["Put 3 dishes in the sink", "Wipe the counter"])
        XCTAssertEqual(task.orderedSteps.map(\.order), [0, 1])
    }

    func testSmallerStepGoesBeforeTheCurrentOne() throws {
        let task = try XCTUnwrap(TaskActions.addTask("Pay the bill", in: context))
        let first = try XCTUnwrap(TaskActions.addStep("Find the email", to: task, in: context))
        TaskActions.addStep("Pay", to: task, in: context)
        TaskActions.setStepDone(first, done: true, in: context)

        let current = task.nextStep
        XCTAssertEqual(current?.text, "Pay")
        TaskActions.insertSmallerStep("Open the bank app", before: current, in: task, context: context)

        XCTAssertEqual(task.orderedSteps.map(\.text), ["Find the email", "Open the bank app", "Pay"])
        XCTAssertEqual(task.nextStep?.text, "Open the bank app")
        XCTAssertEqual(task.nextStep?.minutes, 1)
    }

    func testReorderRewritesOrder() throws {
        let task = try XCTUnwrap(TaskActions.addTask("Laundry", in: context))
        TaskActions.addStep("A", to: task, in: context)
        TaskActions.addStep("B", to: task, in: context)
        TaskActions.addStep("C", to: task, in: context)
        var steps = task.orderedSteps
        steps.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        TaskActions.reorder(steps, in: context)
        XCTAssertEqual(task.orderedSteps.map(\.text), ["C", "A", "B"])
    }

    /// D7: remove keeps the task and its steps, restore brings both back.
    func testSoftDeleteAndRestoreKeepSteps() throws {
        let task = try XCTUnwrap(TaskActions.addTask("Renew passport", in: context))
        TaskActions.addStep("Find the old passport", to: task, in: context)
        TaskActions.softDelete(task, in: context)
        XCTAssertNotNil(task.deletedAt)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskStep>()).count, 1)

        TaskActions.restore(task, in: context)
        XCTAssertNil(task.deletedAt)
        XCTAssertEqual(task.orderedSteps.count, 1)
    }

    func testDaysLeftCountsDownFrom30() {
        let deleted = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(TaskActions.daysLeft(deletedAt: deleted, now: deleted), 30)
        XCTAssertEqual(TaskActions.daysLeft(deletedAt: deleted, now: deleted.addingTimeInterval(18 * 86_400)), 12)
        XCTAssertEqual(TaskActions.daysLeft(deletedAt: deleted, now: deleted.addingTimeInterval(31 * 86_400)), 0)
    }
}
