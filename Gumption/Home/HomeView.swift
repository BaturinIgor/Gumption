import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.deletedAt == nil && $0.completedAt == nil },
           sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    @State private var draft = ""
    @State private var focusTask: TaskItem?
    @State private var lastDeleted: TaskItem?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("What's one thing?")
                    .font(.largeTitle.bold())

                HStack {
                    TextField("Type it…", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(add)
                    Button("Add", action: add)
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                List {
                    ForEach(tasks) { task in
                        Button(task.title) { focusTask = task }
                            .swipeActions {
                                Button("Delete", systemImage: "trash") { softDelete(task) }
                                    .tint(.gray)
                            }
                    }
                }
                .listStyle(.plain)

                if let lastDeleted {
                    Button("Undo delete of \u{201C}\(lastDeleted.title)\u{201D}") { undoDelete() }
                }

                Button {
                    focusTask = tasks.randomElement()
                } label: {
                    Label("Pick for me & start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tasks.isEmpty)
            }
            .padding()
            .fullScreenCover(item: $focusTask) { task in
                FocusView(task: task)
            }
        }
    }

    private func add() {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        context.insert(TaskItem(title: title))
        Persistence.save(context) // D1: saved immediately
        draft = ""
    }

    private func softDelete(_ task: TaskItem) {
        task.deletedAt = .now
        task.updatedAt = .now
        Persistence.save(context)
        lastDeleted = task
        Task {
            try? await Task.sleep(for: .seconds(5))
            if lastDeleted === task { lastDeleted = nil }
        }
    }

    private func undoDelete() {
        lastDeleted?.deletedAt = nil
        lastDeleted?.updatedAt = .now
        Persistence.save(context)
        lastDeleted = nil
    }
}
