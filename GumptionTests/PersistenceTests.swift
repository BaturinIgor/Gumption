import SwiftData
import XCTest
@testable import Gumption

@MainActor
final class PersistenceTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func localContainer(at url: URL) throws -> ModelContainer {
        let config = ModelConfiguration(schema: Persistence.schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: Persistence.schema, configurations: config)
    }

    /// D1: a saved task is on disk; a fresh container (like a relaunch) sees it.
    func testSavedTaskSurvivesReopen() throws {
        let url = tempDir.appending(path: "test.store")
        do {
            let container = try localContainer(at: url)
            let context = ModelContext(container)
            context.insert(TaskItem(title: "Reply to landlord email"))
            Persistence.save(context)
        }
        let reopened = try localContainer(at: url)
        let tasks = try ModelContext(reopened).fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.map(\.title), ["Reply to landlord email"])
    }

    /// D7: soft-deleted tasks stay until 30 days pass, then are purged.
    func testSoftDeleteIsPurgedOnlyAfter30Days() throws {
        let container = try Persistence.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let now = Date.now
        let recent = TaskItem(title: "recent")
        recent.deletedAt = now.addingTimeInterval(-10 * 86_400)
        let old = TaskItem(title: "old")
        old.deletedAt = now.addingTimeInterval(-31 * 86_400)
        context.insert(recent)
        context.insert(old)
        try context.save()

        try Persistence.purgeExpired(context, now: now)

        let titles = try context.fetch(FetchDescriptor<TaskItem>()).map(\.title)
        XCTAssertEqual(titles, ["recent"])
    }

    /// D8: a backup is taken when the app version changes, and can be restored.
    func testBackupOnVersionChangeAndRestore() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let url = tempDir.appending(path: "app.store")
        try Data("v1".utf8).write(to: url)

        try StoreBackup.backupIfVersionChanged(storeURL: url, appVersion: "1.0(1)", defaults: defaults)
        try StoreBackup.backupIfVersionChanged(storeURL: url, appVersion: "1.0(1)", defaults: defaults)
        XCTAssertEqual(try StoreBackup.backups(storeURL: url).count, 1, "same version must not back up again")

        try Data("broken".utf8).write(to: url)
        try StoreBackup.restoreLatest(storeURL: url)
        XCTAssertEqual(try String(contentsOf: url), "v1")
    }

    /// D2: a running session is stored with its start timestamp.
    func testFocusSessionStoresStartTimestamp() throws {
        let container = try Persistence.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let start = Date(timeIntervalSince1970: 1_000_000)
        context.insert(FocusSession(taskID: UUID(), stepID: nil, plannedSeconds: 120, startedAt: start))
        try context.save()
        let session = try XCTUnwrap(context.fetch(FetchDescriptor<FocusSession>()).first)
        XCTAssertEqual(session.startedAt, start)
        XCTAssertNil(session.endedAt)
    }
}
