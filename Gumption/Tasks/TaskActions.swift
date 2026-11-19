import Foundation
import SwiftData

/// Every user action on tasks goes through here, and each one saves right away (D1).
enum TaskActions {
    @discardableResult
    static func addTask(_ title: String, in context: ModelContext) -> TaskItem? {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let task = TaskItem(title: clean)
        context.insert(task)
        Persistence.save(context)
        return task
    }

    @discardableResult
    static func addStep(_ text: String, minutes: Int? = nil, to task: TaskItem, in context: ModelContext) -> TaskStep? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let step = TaskStep(text: clean, order: (task.orderedSteps.last?.order ?? -1) + 1, minutes: minutes)
        context.insert(step)
        step.task = task
        touch(task)
        Persistence.save(context)
        return step
    }

    /// "Need a smaller step": puts a tinier step right before the current one.
    @discardableResult
    static func insertSmallerStep(_ text: String, before current: TaskStep?, in task: TaskItem,
                                  context: ModelContext) -> TaskStep? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let position = current?.order ?? ((task.orderedSteps.last?.order ?? -1) + 1)
        for step in task.orderedSteps where step.order >= position {
            step.order += 1
        }
        let step = TaskStep(text: clean, order: position, minutes: 1)
        context.insert(step)
        step.task = task
        touch(task)
        Persistence.save(context)
        return step
    }

    static func setStepDone(_ step: TaskStep, done: Bool, in context: ModelContext) {
        step.doneAt = done ? .now : nil
        if let task = step.task { touch(task) }
        Persistence.save(context)
    }

    /// Rewrites `order` as 0, 1, 2… following the given sequence.
    static func reorder(_ steps: [TaskStep], in context: ModelContext) {
        for (index, step) in steps.enumerated() { step.order = index }
        if let task = steps.first?.task { touch(task) }
        Persistence.save(context)
    }

    static func complete(_ task: TaskItem, in context: ModelContext) {
        task.completedAt = .now
        touch(task)
        Persistence.save(context)
    }

    /// Soft delete (D7): hidden now, restorable for 30 days.
    static func softDelete(_ task: TaskItem, in context: ModelContext) {
        task.deletedAt = .now
        touch(task)
        Persistence.save(context)
    }

    static func restore(_ task: TaskItem, in context: ModelContext) {
        task.deletedAt = nil
        touch(task)
        Persistence.save(context)
    }

    static func daysLeft(deletedAt: Date, now: Date = .now) -> Int {
        let expires = deletedAt.addingTimeInterval(Persistence.softDeleteRetention)
        return max(0, Int(ceil(expires.timeIntervalSince(now) / 86_400)))
    }

    private static func touch(_ task: TaskItem) {
        task.updatedAt = .now
    }
}
