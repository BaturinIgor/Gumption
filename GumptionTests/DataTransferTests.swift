import SwiftData
import XCTest
@testable import Gumption

/// D10: export and import are lossless, and import never overwrites.
@MainActor
final class DataTransferTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        ModelContext(try Persistence.makeContainer(inMemory: true))
    }

    private func seed(_ context: ModelContext) throws -> TaskItem {
        let task = try XCTUnwrap(TaskActions.addTask("Clean the kitchen", in: context))
        task.energy = 2
        task.estimateMinutes = 25
        let step = try XCTUnwrap(TaskActions.addStep("Put 3 dishes in the sink", minutes: 2, to: task, in: context))
        TaskActions.setStepDone(step, done: true, in: context)
        TaskActions.addStep("Wipe the counter, \"quickly\"", minutes: 3, to: task, in: context)
        let session = FocusSession(taskID: task.id, stepID: step.id, plannedSeconds: 120,
                                   startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        session.endedAt = Date(timeIntervalSince1970: 1_700_000_100)
        session.outcome = FocusOutcome.done
        context.insert(session)
        try context.save()
        return task
    }

    func testJSONRoundTripIntoEmptyStore() throws {
        let source = try makeContext()
        _ = try seed(source)
        let exported = try DataTransfer.snapshot(source)
        let decoded = try DataTransfer.decode(try DataTransfer.json(exported))

        let target = try makeContext()
        let result = try DataTransfer.importFile(decoded, into: target)
        XCTAssertEqual(result, ImportResult(tasksAdded: 1, tasksSkipped: 0, sessionsAdded: 1))

        let reexported = try DataTransfer.snapshot(target, now: exported.exportedAt)
        XCTAssertEqual(normalized(reexported), normalized(exported))
    }

    func testImportSkipsExistingTasksAndKeepsLocalEdits() throws {
        let context = try makeContext()
        let task = try seed(context)
        let file = try DataTransfer.snapshot(context)

        task.title = "Clean the kitchen (edited)"
        try context.save()

        let result = try DataTransfer.importFile(file, into: context)
        XCTAssertEqual(result.tasksAdded, 0)
        XCTAssertEqual(result.tasksSkipped, 1)
        XCTAssertEqual(result.sessionsAdded, 0)
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.map(\.title), ["Clean the kitchen (edited)"])
    }

    func testNewerFileVersionIsRejected() throws {
        let json = #"{"version": 99, "exportedAt": "2026-11-18T10:00:00Z", "tasks": [], "sessions": []}"#
        XCTAssertThrowsError(try DataTransfer.decode(Data(json.utf8)))
    }

    func testCSVEscapesCommasAndQuotes() throws {
        let context = try makeContext()
        _ = try seed(context)
        let csv = DataTransfer.csv(try DataTransfer.snapshot(context))
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3) // header + 2 steps
        XCTAssertTrue(csv.contains(#""Wipe the counter, ""quickly""""#))
    }

    /// ISO 8601 drops sub-second precision, so compare at whole seconds.
    private func normalized(_ file: ExportFile) -> ExportFile {
        func r(_ d: Date) -> Date { Date(timeIntervalSince1970: d.timeIntervalSince1970.rounded(.down)) }
        func r(_ d: Date?) -> Date? { d.map(r) }
        var copy = file
        copy.exportedAt = r(file.exportedAt)
        copy.tasks = file.tasks.map { t in
            var t = t
            t.createdAt = r(t.createdAt); t.updatedAt = r(t.updatedAt)
            t.completedAt = r(t.completedAt); t.deletedAt = r(t.deletedAt)
            t.steps = t.steps.map { s in var s = s; s.doneAt = r(s.doneAt); return s }
            return t
        }
        copy.sessions = file.sessions.map { s in
            var s = s; s.startedAt = r(s.startedAt); s.endedAt = r(s.endedAt); return s
        }
        return copy
    }
}
