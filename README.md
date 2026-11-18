# Gumption

An iOS app that helps people with ADHD **start** a task: one tap to get the first tiny step, a buddy beside you while you do it, and a timer you can see from the lock screen.

Not a planner. A start button.

## Status

Early development. Working in the app so far:

- Quick capture, task list, remove with 5-second undo
- Task detail: name, energy, estimate, steps (add, tick, reorder, edit)
- Focus with a ring timer, step by step, "I'm stuck" (smaller step, break, switch), break screen, task complete
- Your week (things started, focus minutes per day, steps done)
- Settings, Your data (iCloud status, safety copies, JSON/CSV export, additive import), Recently deleted

Not yet: AI breakdown and buddy, voice capture, widgets and Live Activity, reminders, subscription.

## Product docs

- [Requirements (MVP 1.0)](docs/requirements.md)
- [Version plan](docs/roadmap.md)
- [Data safety requirements](docs/data-safety.md)

## Stack

- Swift, SwiftUI, iOS 17+
- SwiftData for local storage, synced to the user's private iCloud database (CloudKit)
- No account, no own sync server
- A thin backend only as a proxy to the AI provider (1.0) and for the quiet-room counter (1.1)

Apple platforms only: iPhone first, then iPad, Apple Watch and Mac. No Android, no web.

## Build

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
xcodegen generate
xcodebuild test -project Gumption.xcodeproj -scheme Gumption \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

The `.xcodeproj` is generated from `project.yml` and is not committed.
