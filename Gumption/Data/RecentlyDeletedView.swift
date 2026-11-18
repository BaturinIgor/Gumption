import SwiftData
import SwiftUI

/// Removed tasks stay here for 30 days with all their steps (D7).
struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.deletedAt != nil },
           sort: \TaskItem.deletedAt, order: .reverse)
    private var deleted: [TaskItem]

    var body: some View {
        List {
            Section {
                Text("Removed tasks stay here for 30 days, with all their steps, then quietly go.")
                    .font(.callout)
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Color.clear)
            }
            if deleted.isEmpty {
                Text("Nothing here. Everything you have is in your list.")
                    .foregroundStyle(Palette.muted)
            }
            ForEach(deleted) { task in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title).font(.body.weight(.medium))
                        Text(detail(task)).font(.footnote).foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Button("Restore") { TaskActions.restore(task, in: context) }
                        .buttonStyle(.bordered)
                        .tint(Palette.accent)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Recently deleted")
    }

    private func detail(_ task: TaskItem) -> String {
        let steps = task.steps?.count ?? 0
        let days = task.deletedAt.map { TaskActions.daysLeft(deletedAt: $0) } ?? 30
        let stepText = steps == 1 ? "1 step" : "\(steps) steps"
        let dayText = days == 1 ? "1 day left" : "\(days) days left"
        return "\(stepText) · \(dayText)"
    }
}
