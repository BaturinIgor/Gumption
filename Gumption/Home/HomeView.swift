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
            VStack(alignment: .leading, spacing: 18) {
                Text("What's one thing?")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))

                HStack(spacing: 8) {
                    TextField("Type it…", text: $draft)
                        .submitLabel(.done)
                        .onSubmit(add)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Button(action: add) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .frame(width: 52, height: 52)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Add")
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if tasks.isEmpty {
                    Spacer()
                    Text("Nothing here yet. What's one thing on your mind?")
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    List {
                        ForEach(tasks) { task in
                            row(task)
                                .listRowBackground(Palette.surface)
                                .swipeActions {
                                    Button("Remove", systemImage: "archivebox") { remove(task) }
                                        .tint(Palette.muted)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -20)
                }

                if let lastDeleted {
                    HStack {
                        Text("Removed \u{201C}\(lastDeleted.title)\u{201D}")
                            .lineLimit(1)
                            .foregroundStyle(Palette.focusText)
                        Spacer()
                        Button("Undo", action: undoRemove)
                            .font(.callout.weight(.bold))
                            .padding(.horizontal, 14).frame(height: 40)
                            .background(Palette.focusRing, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Palette.focusBackground)
                    }
                    .padding(.leading, 16).padding(.trailing, 8).padding(.vertical, 8)
                    .background(Palette.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    focusTask = tasks.randomElement()
                } label: {
                    Label("Pick for me & start", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(tasks.isEmpty)
            }
            .padding(20)
            .background(Palette.background.ignoresSafeArea())
            .foregroundStyle(Palette.ink)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("gumption")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Palette.accent)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink { WeekView() } label: { Image(systemName: "chart.bar") }
                        .accessibilityLabel("Your week")
                    NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .fullScreenCover(item: $focusTask) { task in
                FocusView(task: task)
            }
            .animation(.default, value: lastDeleted?.id)
        }
        .tint(Palette.accent)
    }

    private func row(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                TaskDetailView(task: task)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).font(.body.weight(.medium))
                    if let next = task.nextStep {
                        Text("Next: \(next.text)").font(.footnote).foregroundStyle(Palette.muted)
                    }
                }
            }
            Button { focusTask = task } label: {
                Image(systemName: "play.fill")
                    .frame(width: 40, height: 40)
                    .background(Palette.accentSoft, in: Circle())
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Start \(task.title)")
        }
        .padding(.vertical, 4)
    }

    private func add() {
        if TaskActions.addTask(draft, in: context) != nil { draft = "" }
    }

    private func remove(_ task: TaskItem) {
        TaskActions.softDelete(task, in: context)
        lastDeleted = task
        Task {
            try? await Task.sleep(for: .seconds(5))
            if lastDeleted === task { lastDeleted = nil }
        }
    }

    private func undoRemove() {
        if let lastDeleted { TaskActions.restore(lastDeleted, in: context) }
        lastDeleted = nil
    }
}
