import Foundation
import SwiftData

/// Export and import of all user data (D10). Export is always free (D9).
/// Import only adds: a task whose id already exists is skipped, never overwritten.
struct ExportFile: Codable, Equatable {
    static let currentVersion = 1

    var version: Int = ExportFile.currentVersion
    var exportedAt: Date
    var tasks: [ExportTask]
    var sessions: [ExportSession]
}

struct ExportTask: Codable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var energy: Int
    var estimateMinutes: Int?
    var completedAt: Date?
    var deletedAt: Date?
    var steps: [ExportStep]
}

struct ExportStep: Codable, Equatable {
    var id: UUID
    var text: String
    var order: Int
    var minutes: Int?
    var doneAt: Date?
}

struct ExportSession: Codable, Equatable {
    var id: UUID
    var taskID: UUID?
    var stepID: UUID?
    var startedAt: Date
    var plannedSeconds: Int
    var endedAt: Date?
    var outcome: String?
}

struct ImportResult: Equatable {
    var tasksAdded = 0
    var tasksSkipped = 0
    var sessionsAdded = 0
}

enum DataTransferError: Error {
    case unsupportedVersion(Int)
}

enum DataTransfer {
    static func snapshot(_ context: ModelContext, now: Date = .now) throws -> ExportFile {
        let tasks = try context.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdAt)]))
        let sessions = try context.fetch(FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startedAt)]))
        return ExportFile(
            exportedAt: now,
            tasks: tasks.map { task in
                ExportTask(
                    id: task.id, title: task.title, createdAt: task.createdAt, updatedAt: task.updatedAt,
                    energy: task.energy, estimateMinutes: task.estimateMinutes,
                    completedAt: task.completedAt, deletedAt: task.deletedAt,
                    steps: task.orderedSteps.map {
                        ExportStep(id: $0.id, text: $0.text, order: $0.order, minutes: $0.minutes, doneAt: $0.doneAt)
                    }
                )
            },
            sessions: sessions.map {
                ExportSession(id: $0.id, taskID: $0.taskID, stepID: $0.stepID, startedAt: $0.startedAt,
                              plannedSeconds: $0.plannedSeconds, endedAt: $0.endedAt, outcome: $0.outcome)
            }
        )
    }

    static func json(_ file: ExportFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> ExportFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(ExportFile.self, from: data)
        guard file.version <= ExportFile.currentVersion else {
            throw DataTransferError.unsupportedVersion(file.version)
        }
        return file
    }

    /// One row per step (a task without steps gets one row), readable in any spreadsheet.
    static func csv(_ file: ExportFile) -> String {
        let iso = ISO8601DateFormatter()
        func date(_ d: Date?) -> String { d.map { iso.string(from: $0) } ?? "" }

        var lines = ["task_id,task,created,completed,deleted,step_order,step,step_minutes,step_done"]
        for task in file.tasks {
            let head = [task.id.uuidString, task.title, date(task.createdAt),
                        date(task.completedAt), date(task.deletedAt)]
            if task.steps.isEmpty {
                lines.append((head + ["", "", "", ""]).map(escape).joined(separator: ","))
            }
            for step in task.steps {
                let row = head + [String(step.order), step.text,
                                  step.minutes.map(String.init) ?? "", date(step.doneAt)]
                lines.append(row.map(escape).joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Adds what is not there yet, in one save (D1). Never deletes or overwrites.
    @discardableResult
    static func importFile(_ file: ExportFile, into context: ModelContext) throws -> ImportResult {
        let existingTasks = Set(try context.fetch(FetchDescriptor<TaskItem>()).map(\.id))
        let existingSessions = Set(try context.fetch(FetchDescriptor<FocusSession>()).map(\.id))
        var result = ImportResult()

        for item in file.tasks {
            guard !existingTasks.contains(item.id) else {
                result.tasksSkipped += 1
                continue
            }
            let task = TaskItem(title: item.title, energy: item.energy, estimateMinutes: item.estimateMinutes)
            task.id = item.id
            task.createdAt = item.createdAt
            task.updatedAt = item.updatedAt
            task.completedAt = item.completedAt
            task.deletedAt = item.deletedAt
            context.insert(task)
            for s in item.steps {
                let step = TaskStep(text: s.text, order: s.order, minutes: s.minutes)
                step.id = s.id
                step.doneAt = s.doneAt
                context.insert(step)
                step.task = task
            }
            result.tasksAdded += 1
        }

        for s in file.sessions where !existingSessions.contains(s.id) {
            let session = FocusSession(taskID: s.taskID, stepID: s.stepID,
                                       plannedSeconds: s.plannedSeconds, startedAt: s.startedAt)
            session.id = s.id
            session.endedAt = s.endedAt
            session.outcome = s.outcome
            context.insert(session)
            result.sessionsAdded += 1
        }

        try context.save()
        return result
    }
}
