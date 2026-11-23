import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([TaskItem.self, TaskStep.self, FocusSession.self])
    static let softDeleteRetention: TimeInterval = 30 * 24 * 60 * 60

    /// Opens the store on device, synced to the user's private iCloud database when
    /// the iCloud entitlement and account are available (D3). Takes a backup of the
    /// store first when the app version changed, so a failed migration can be rolled back (D8).
    static func makeContainer(
        inMemory: Bool = false,
        storeURL: URL = defaultStoreURL,
        appVersion: String = currentAppVersion
    ) throws -> ModelContainer {
        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: config)
        }

        try StoreBackup.backupIfVersionChanged(storeURL: storeURL, appVersion: appVersion)

        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Migration or open failed: restore the pre-update copy and try once more.
            try StoreBackup.restoreLatest(storeURL: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        }
    }

    static var defaultStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "Gumption.store")
    }

    static var currentAppVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short)(\(build))"
    }

    /// Saves right away. Called after every user action (D1).
    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // Keep the change in the context; SwiftData retries on the next save.
            assertionFailure("Save failed: \(error)")
        }
    }

    /// Removes tasks soft-deleted more than 30 days ago (D7).
    static func purgeExpired(_ context: ModelContext, now: Date = .now) throws {
        let cutoff = now.addingTimeInterval(-softDeleteRetention)
        let expired = try context.fetch(FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.deletedAt != nil && task.deletedAt! < cutoff
            }
        ))
        for task in expired { context.delete(task) }
        try context.save()
    }
}

enum StoreBackup {
    private static let versionKey = "gumption.lastStoreVersion"

    static func backupDirectory(for storeURL: URL) -> URL {
        storeURL.deletingLastPathComponent().appending(path: "StoreBackups", directoryHint: .isDirectory)
    }

    /// SQLite keeps data in the main file plus -wal and -shm; all three are copied.
    static func storeFiles(_ storeURL: URL) -> [URL] {
        [storeURL,
         URL(fileURLWithPath: storeURL.path + "-wal"),
         URL(fileURLWithPath: storeURL.path + "-shm")]
    }

    static func backupIfVersionChanged(
        storeURL: URL,
        appVersion: String,
        defaults: UserDefaults = .standard
    ) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { defaults.set(appVersion, forKey: versionKey) }

        guard fm.fileExists(atPath: storeURL.path),
              defaults.string(forKey: versionKey) != appVersion else { return }

        let folder = backupDirectory(for: storeURL)
            .appending(path: "\(Int(Date.now.timeIntervalSince1970))", directoryHint: .isDirectory)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in storeFiles(storeURL) where fm.fileExists(atPath: file.path) {
            try fm.copyItem(at: file, to: folder.appending(path: file.lastPathComponent))
        }
        try pruneOldBackups(storeURL: storeURL, keep: 3)
    }

    static func restoreLatest(storeURL: URL) throws {
        let fm = FileManager.default
        guard let latest = try backups(storeURL: storeURL).last else { return }
        for file in storeFiles(storeURL) {
            if fm.fileExists(atPath: file.path) { try fm.removeItem(at: file) }
            let source = latest.appending(path: file.lastPathComponent)
            if fm.fileExists(atPath: source.path) { try fm.copyItem(at: source, to: file) }
        }
    }

    static func backups(storeURL: URL) throws -> [URL] {
        let dir = backupDirectory(for: storeURL)
        guard FileManager.default.fileExists(atPath: dir.path) else { return [] }
        return try FileManager.default
            .contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func pruneOldBackups(storeURL: URL, keep: Int) throws {
        let all = try backups(storeURL: storeURL)
        for old in all.dropLast(keep) { try FileManager.default.removeItem(at: old) }
    }
}
