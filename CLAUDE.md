# Gumption

iOS app that helps people with ADHD start tasks: quick capture, AI breakdown into tiny steps, an AI buddy, a visual timer on the lock screen. Product docs are in `docs/`; read `docs/requirements.md` and `docs/data-safety.md` before changing behaviour.

## Stack and constraints

- Swift and SwiftUI only, iOS 17+. Apple platforms only (iPhone, later iPad, Watch, Mac). No Android, no web, no cross-platform frameworks.
- Storage: SwiftData synced to the user's private CloudKit database. No accounts and no own sync server.
- Avoid third-party dependencies unless there is no reasonable Apple framework for the job.

## Data safety is a release blocker

Every rule in `docs/data-safety.md` applies to every change. In particular:
- Save on every action, in a transaction. Never hold user data only in memory.
- Store timer state as timestamps, not counters.
- CloudKit-compatible models: every property optional or defaulted, no `@Attribute(.unique)`, optional relationships.
- Deletes are soft (30-day "Recently deleted").
- Every schema change ships with a migration and a test against stores from previous versions.
- Never put task text into analytics or logs.

## Product rules for UI and copy

- At most two taps from launch to a running focus session.
- No red, no "overdue", no streaks that reset, no guilt copy.
- UI copy is English (US).
