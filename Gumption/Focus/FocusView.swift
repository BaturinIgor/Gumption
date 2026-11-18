import SwiftData
import SwiftUI

/// Focus → (stuck / break) → next step → task complete. All state lives in
/// `FocusSession` timestamps, so a relaunch resumes exactly where it was (D2).
struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.sessionMinutesKey) private var sessionMinutes = AppSettings.defaultSessionMinutes
    @AppStorage(AppSettings.breakMinutesKey) private var breakMinutes = AppSettings.defaultBreakMinutes

    let task: TaskItem

    enum Phase: Equatable {
        case focusing
        case onBreak(startedAt: Date)
        case complete
    }

    @State private var session: FocusSession?
    @State private var phase: Phase = .focusing
    @State private var showStuck = false
    @State private var praise: String?

    var body: some View {
        Group {
            switch phase {
            case .focusing:
                focusContent
            case .onBreak(let startedAt):
                BreakView(timer: FocusTimer(startedAt: startedAt, plannedSeconds: breakMinutes * 60),
                          breakMinutes: breakMinutes,
                          stepText: currentText,
                          onResume: startSession,
                          onStop: { dismiss() })
            case .complete:
                TaskCompleteView(task: task, summary: summary(), onDone: { dismiss() })
            }
        }
        .onAppear(perform: resumeOrStart)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sheet(isPresented: $showStuck) {
            StuckSheet(stepText: currentText,
                       breakMinutes: breakMinutes,
                       onSmallerStep: makeSmaller,
                       onBreak: takeBreak,
                       onSwitch: switchTask)
                .presentationDetents([.medium, .large])
        }
    }

    private var currentText: String {
        task.nextStep?.text ?? task.title
    }

    private var stepLabel: String {
        let steps = task.orderedSteps
        guard let next = task.nextStep, let index = steps.firstIndex(where: { $0.id == next.id }) else {
            return task.title
        }
        return "Step \(index + 1) of \(steps.count) · \(task.title)"
    }

    private var focusContent: some View {
        VStack(spacing: 24) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .frame(width: 44, height: 44)
                        .background(Palette.focusSurface, in: Circle())
                }
                .accessibilityLabel("Minimize")
                Spacer()
            }
            .foregroundStyle(Palette.focusText)

            Text(stepLabel)
                .font(.subheadline)
                .foregroundStyle(Palette.focusMuted)
            Text(currentText)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.focusText)

            if let session {
                RingTimer(timer: FocusTimer(startedAt: session.startedAt, plannedSeconds: session.plannedSeconds),
                          caption: "of \(session.plannedSeconds / 60) min")
            }

            Text(praise ?? "I'm right here. Tap Done when you're through.")
                .font(.callout)
                .foregroundStyle(praise == nil ? Palette.focusMuted : Palette.praise)
                .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: 12) {
                Button("I'm stuck") { showStuck = true }
                    .buttonStyle(PrimaryButtonStyle(tint: Palette.focusSurface, foreground: Palette.focusText))
                Button("Done", action: markDone)
                    .buttonStyle(PrimaryButtonStyle(tint: Palette.focusRing, foreground: Palette.focusBackground))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.focusBackground.ignoresSafeArea())
    }

    // MARK: - State from the store

    private func resumeOrStart() {
        guard session == nil, phase == .focusing else { return }
        let taskID = task.id
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.taskID == taskID },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))) ?? []

        if let running = sessions.first(where: { $0.endedAt == nil }) {
            session = running
            return
        }
        // A break that is still running resumes as a break.
        if let last = sessions.first, last.outcome == FocusOutcome.breakTime, let ended = last.endedAt,
           Date.now.timeIntervalSince(ended) < TimeInterval(breakMinutes * 60) {
            phase = .onBreak(startedAt: ended)
            return
        }
        startSession()
    }

    private func startSession() {
        let step = task.nextStep
        let new = FocusSession(taskID: task.id, stepID: step?.id,
                               plannedSeconds: (step?.minutes ?? sessionMinutes) * 60)
        context.insert(new)
        Persistence.save(context)
        session = new
        phase = .focusing
    }

    private func endSession(_ outcome: String) {
        session?.endedAt = .now
        session?.outcome = outcome
        Persistence.save(context)
        session = nil
    }

    private func summary() -> TaskSummary {
        let taskID = task.id
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.taskID == taskID }
        ))) ?? []
        let stepsDone = task.orderedSteps.filter { $0.doneAt != nil }.count
        return TaskSummary.make(stepsDone: stepsDone, sessions: sessions.map(SessionRecord.init))
    }

    // MARK: - Actions

    private func markDone() {
        endSession(FocusOutcome.done)
        if let step = task.nextStep {
            TaskActions.setStepDone(step, done: true, in: context)
        }
        if let next = task.nextStep {
            praise = "Nice. Next up: \(next.text)"
            startSession()
        } else {
            TaskActions.complete(task, in: context)
            phase = .complete
        }
    }

    private func makeSmaller(_ text: String) {
        showStuck = false
        endSession(FocusOutcome.stuck)
        TaskActions.insertSmallerStep(text, before: task.nextStep, in: task, context: context)
        praise = "Smaller is smart."
        startSession()
    }

    private func takeBreak() {
        showStuck = false
        let started = Date.now
        endSession(FocusOutcome.breakTime)
        phase = .onBreak(startedAt: started)
    }

    private func switchTask() {
        showStuck = false
        endSession(FocusOutcome.stuck)
        dismiss()
    }
}

struct StuckSheet: View {
    let stepText: String
    let breakMinutes: Int
    let onSmallerStep: (String) -> Void
    let onBreak: () -> Void
    let onSwitch: () -> Void

    @State private var smaller = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("That's normal. Let's make it easier.")
                .font(.system(.title2, design: .rounded, weight: .heavy))

            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Make the step smaller")
                Text("What's the tiniest part of \u{201C}\(stepText)\u{201D}?")
                    .font(.callout).foregroundStyle(Palette.muted)
                HStack {
                    TextField("Just open the…", text: $smaller)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .onSubmit { onSmallerStep(smaller) }
                    Button("Start") { onSmallerStep(smaller) }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.accent)
                        .disabled(smaller.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Button("Take a \(breakMinutes)-minute break", action: onBreak)
                .buttonStyle(PrimaryButtonStyle(tint: Palette.accentSoft, foreground: Palette.accentInk))
            Button("Switch to another task", action: onSwitch)
                .buttonStyle(PrimaryButtonStyle(tint: Palette.background, foreground: Palette.ink))

            Text("Your progress on this step is saved.")
                .font(.footnote).foregroundStyle(Palette.muted)
        }
        .padding(24)
    }
}

struct BreakView: View {
    let timer: FocusTimer
    let breakMinutes: Int
    let stepText: String
    let onResume: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Break · your step is paused and saved")
                .font(.subheadline).foregroundStyle(Palette.focusMuted)
            RingTimer(timer: timer, ring: Palette.breakRing, caption: "of \(breakMinutes) min")
                .padding(.top, 12)
            Text("Rest is part of the plan.")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(Palette.focusText)

            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Ideas, if you want one", color: Palette.focusMuted)
                HStack {
                    ForEach(["Drink some water", "Stretch", "Look outside"], id: \.self) { idea in
                        Text(idea)
                            .font(.footnote)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(Palette.focusSurface, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Palette.focusText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Back to: \(stepText)", action: onResume)
                .buttonStyle(PrimaryButtonStyle(tint: Palette.focusRing, foreground: Palette.focusBackground))
                .lineLimit(1)
            Button("Stop for today, that's fine", action: onStop)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Palette.focusRing)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.focusBackground.ignoresSafeArea())
    }
}

struct TaskCompleteView: View {
    let task: TaskItem
    let summary: TaskSummary
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Palette.praise)
                    .frame(width: 96, height: 96)
                    .background(Palette.praiseSoft, in: Circle())
                Text("\(task.title): done.")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .multilineTextAlignment(.center)
                Text("That was the hard part, and you did it.")
                    .foregroundStyle(Palette.muted)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.top, 24)

            HStack(spacing: 8) {
                stat("\(summary.stepsDone)", "steps")
                stat("\(summary.focusMinutes)m", "focused")
            }

            Spacer()

            Button("I'm done for now", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title2, design: .rounded, weight: .heavy))
            Text(label).font(.footnote).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
