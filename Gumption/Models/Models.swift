import Foundation
import SwiftData

// CloudKit-compatible models (docs/data-safety.md):
// every property is optional or has a default, no unique constraints,
// relationships are optional. Stable UUIDs keep export/import lossless (D10).

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// Energy the task needs: 0 low, 1 some, 2 lots.
    var energy: Int = 1
    var estimateMinutes: Int?
    var completedAt: Date?
    /// Soft delete (D7). A task with `deletedAt` set is hidden and purged after 30 days.
    var deletedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \TaskStep.task)
    var steps: [TaskStep]? = []

    init(title: String, energy: Int = 1, estimateMinutes: Int? = nil) {
        self.title = title
        self.energy = energy
        self.estimateMinutes = estimateMinutes
    }

    var orderedSteps: [TaskStep] {
        (steps ?? []).sorted { $0.order < $1.order }
    }

    var nextStep: TaskStep? {
        orderedSteps.first { $0.doneAt == nil }
    }
}

@Model
final class TaskStep {
    var id: UUID = UUID()
    var text: String = ""
    var order: Int = 0
    var minutes: Int?
    var doneAt: Date?
    var task: TaskItem?

    init(text: String, order: Int, minutes: Int? = nil) {
        self.text = text
        self.order = order
        self.minutes = minutes
    }
}

@Model
final class FocusSession {
    var id: UUID = UUID()
    var taskID: UUID?
    var stepID: UUID?
    /// Timer state is stored as timestamps, never as a counter (D2).
    var startedAt: Date = Date.now
    var plannedSeconds: Int = 120
    var endedAt: Date?
    /// "done", "stuck" or nil while running.
    var outcome: String?

    init(taskID: UUID?, stepID: UUID?, plannedSeconds: Int, startedAt: Date = .now) {
        self.taskID = taskID
        self.stepID = stepID
        self.plannedSeconds = plannedSeconds
        self.startedAt = startedAt
    }
}
