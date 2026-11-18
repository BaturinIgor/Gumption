import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: TaskItem

    @State private var newStep = ""
    @State private var focusing = false

    private let energyLabels = [String(localized: "Low"), String(localized: "Some"), String(localized: "Lots")]

    var body: some View {
        List {
            Section {
                TextField("Task name", text: $task.title, axis: .vertical)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .onChange(of: task.title) { save() }
            }

            Section {
                Picker("Energy it needs", selection: $task.energy) {
                    ForEach(energyLabels.indices, id: \.self) { Text(energyLabels[$0]).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: task.energy) { save() }

                Stepper(value: estimateBinding, in: 0...240, step: 5) {
                    HStack {
                        Text("About how long?")
                        Spacer()
                        Text(task.estimateMinutes.map { String(localized: "~\($0) min") } ?? String(localized: "Not sure"))
                            .foregroundStyle(Palette.accent)
                    }
                }
            } header: {
                SectionLabel(text: "Energy and time")
            }

            Section {
                ForEach(task.orderedSteps) { step in
                    StepRow(step: step, isNext: step.id == task.nextStep?.id) { done in
                        TaskActions.setStepDone(step, done: done, in: context)
                    }
                }
                .onMove(perform: moveSteps)

                HStack {
                    TextField("+ Add a step", text: $newStep)
                        .submitLabel(.done)
                        .onSubmit(addStep)
                    if !newStep.isEmpty {
                        Button("Add", action: addStep)
                    }
                }
            } header: {
                SectionLabel(text: "Steps")
            }

            Section {
                Button("Remove task (you can restore it for 30 days)") {
                    TaskActions.softDelete(task, in: context)
                    dismiss()
                }
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .safeAreaInset(edge: .bottom) {
            Button(startLabel) { focusing = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .toolbar { EditButton() }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $focusing) {
            FocusView(task: task)
        }
    }

    private var startLabel: String {
        guard let next = task.nextStep,
              let index = task.orderedSteps.firstIndex(where: { $0.id == next.id }) else { return String(localized: "Start") }
        return String(localized: "Start step \(index + 1)")
    }

    private var estimateBinding: Binding<Int> {
        Binding(
            get: { task.estimateMinutes ?? 0 },
            set: {
                task.estimateMinutes = $0 == 0 ? nil : $0
                save()
            }
        )
    }

    private func save() {
        task.updatedAt = .now
        Persistence.save(context)
    }

    private func addStep() {
        if TaskActions.addStep(newStep, to: task, in: context) != nil { newStep = "" }
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        var steps = task.orderedSteps
        steps.move(fromOffsets: source, toOffset: destination)
        TaskActions.reorder(steps, in: context)
    }
}

private struct StepRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var step: TaskStep
    let isNext: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle(step.doneAt == nil)
            } label: {
                Image(systemName: step.doneAt == nil ? "circle" : "checkmark")
                    .foregroundStyle(step.doneAt == nil ? (isNext ? Palette.accent : Palette.muted) : Palette.saved)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(step.doneAt == nil ? "Mark done" : "Mark not done")

            TextField("Step", text: $step.text, axis: .vertical)
                .strikethrough(step.doneAt != nil)
                .foregroundStyle(step.doneAt == nil ? Palette.ink : Palette.muted)
                .fontWeight(isNext ? .semibold : .regular)
                .onChange(of: step.text) { Persistence.save(context) }

            if let minutes = step.minutes {
                Text("\(minutes) min").font(.footnote).foregroundStyle(Palette.muted)
            }
        }
    }
}
