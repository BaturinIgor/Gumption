# Data safety

Rule: a user never loses a task or a minute of a session, in any scenario, and never has to set anything up for that to be true. A lost list is rarely rebuilt by someone with ADHD; they drop the app instead.

Every requirement below is a release blocker for 1.0.

| # | Requirement | Protects against | How we test it |
| --- | --- | --- | --- |
| D1 | Every action is saved on device immediately, in a transaction. There is no Save button | Crash, dead battery, the system killing the app | Automated: kill the process right after input; the task is there on relaunch |
| D2 | Timer and session state are stored as a start timestamp, never as an in-memory counter | Session reset after backgrounding | Close the app for 10 minutes; the timer continues correctly |
| D3 | Automatic sync to the user's private iCloud database (CloudKit), no sign-up | Lost or broken phone | A new device with the same Apple ID has all data within 1 minute |
| D4 | Reinstalling restores all data and the purchase | Deleting the app on impulse and coming back | Delete, reinstall: tasks, history and subscription are back with no action |
| D5 | Everything except AI works offline; changes queue and sync when online | Subway, flights, bad signal | Airplane mode for a day, then everything syncs |
| D6 | Sync conflicts never delete data: last write wins per field; a disputed task is duplicated | Editing on iPhone and iPad at once | Two devices offline, edit both, reconnect |
| D7 | Soft delete: "Recently deleted" for 30 days and a 5-second Undo | Accidental swipe | Delete and restore a task with all its steps |
| D8 | A local backup is taken before every schema migration; a failed migration rolls back | An app update wiping data | CI runs migrations against stores from every previous version |
| D9 | Data is never locked behind the paywall; everything stays available after a subscription ends | Holding data hostage | Cancel in the sandbox; all data is still there |
| D10 | Export all data to JSON and CSV from Settings, and import it back | iCloud switched off, wanting an own copy | Export, clean install, import: data matches |
| D11 | Settings shows "All saved to iCloud, 2 min ago"; if iCloud is off, one calm warning | Believing a backup exists when it does not | Turn iCloud off and see the warning |
| D12 | Task text sent to the AI is not stored by us and not used for training; analytics never contain task text | Leaking personal data (tasks are often about health and money) | Review logs and the AI provider agreement |

Release gate: all 12 checks pass on real devices, and a 2-week TestFlight beta with 50–100 people has zero data-loss reports.

## Implementation notes

- SwiftData with `ModelConfiguration(cloudKitDatabase: .automatic)`. CloudKit requires every model property to be optional or have a default value, no `@Attribute(.unique)`, and optional relationships.
- Model the data so it is independent of iCloud (stable UUIDs, plain value types), so export and import (D10) are lossless.
