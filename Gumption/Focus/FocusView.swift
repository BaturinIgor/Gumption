import SwiftData
import SwiftUI

struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem
    @State private var session: FocusSession?

    var body: some View {
        VStack(spacing: 28) {
            Text(task.nextStep?.text ?? task.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            if let session {
                let timer = FocusTimer(startedAt: session.startedAt, plannedSeconds: session.plannedSeconds)
                TimelineView(.periodic(from: .now, by: 1)) { tl in
                    ZStack {
                        Circle().fill(.quaternary)
                        Circle()
                            .trim(from: 0, to: timer.fractionRemaining(at: tl.date))
                            .stroke(.tint, style: StrokeStyle(lineWidth: 40))
                            .rotationEffect(.degrees(-90))
                            .padding(20)
                        Text(FocusTimer.format(timer.remaining(at: tl.date)))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .frame(width: 220, height: 220)
                    .accessibilityLabel("\(FocusTimer.format(timer.remaining(at: tl.date))) left")
                }
            }

            Text("I'm right here. Tap Done when you're through.")
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Button("I'm stuck") { finish("stuck") }
                    .buttonStyle(.bordered)
                Button("Done") { finish("done") }
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding()
        .onAppear(perform: startOrResume)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    /// Resumes a running session for this task if one exists (survives relaunch, D2).
    private func startOrResume() {
        let taskID = task.id
        let running = try? context.fetch(FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.taskID == taskID && $0.endedAt == nil }
        )).first
        if let running {
            session = running
            return
        }
        let step = task.nextStep
        let new = FocusSession(taskID: task.id, stepID: step?.id,
                               plannedSeconds: (step?.minutes ?? 2) * 60)
        context.insert(new)
        Persistence.save(context)
        session = new
    }

    private func finish(_ outcome: String) {
        session?.endedAt = .now
        session?.outcome = outcome
        if outcome == "done" {
            if let step = task.nextStep {
                step.doneAt = .now
            } else {
                task.completedAt = .now
            }
            task.updatedAt = .now
        }
        Persistence.save(context)
        dismiss()
    }
}
