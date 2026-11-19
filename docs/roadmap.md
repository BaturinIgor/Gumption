# Version plan

Version 1.0 does one thing: helps start a task in two taps and never loses user data. Later versions add live people nearby, habits and the watch, then Mac. Each version ships only after the previous one retains users. Durations assume 1–2 iOS developers and a designer.

| Version | Goal | Build time | Move on when |
| --- | --- | --- | --- |
| 1.0 | Start a task, never lose data, charge fairly, in 20 languages | 12–15 weeks | median time to start under 10 s, week-4 retention over 20%, 0 data-loss incidents |
| 1.1 | Live people nearby, buddy voice | +4–6 weeks | retention grows for people who join the room |
| 1.2 | Habits and the watch: routines, templates, Apple Watch, Siri | +4–6 weeks | trial to paid over 8% |
| 2.0 | The whole Apple ecosystem: Mac, shared lists | +6–8 weeks | reviews ask for Mac |

## 1.0: must have

See [requirements.md](requirements.md) and [data-safety.md](data-safety.md).

Localisation is part of 1.0 (decided 2026-11-18): 20 languages, see requirement 20. Strings are translated after the beta copy freeze, so copy changes during the beta touch English only.

## 1.1: people nearby

- Quiet room: a counter and anonymous avatars of people focusing right now, the task in one word, reactions only, no chat. Word filter and one-tap report.
- Buddy voice (2–3 voices) and background sounds: café, rain, white noise.
- Buddy personalities (calm, cheerful, brief) so it doesn't get old.
- Compare retention with and without the room.

## 1.2: habits and the watch

- Routines and ready-made step templates (cleaning, email, paperwork, mornings), repeats without streaks.
- Apple Watch: timer, Done, haptic check-in on the wrist.
- Siri and Shortcuts: "Add a task", "Pick for me"; quick capture from the widget.
- A weekly summary without judgement: what was started and done, which time of day works best.
- iPad.

## 2.0: the whole Apple ecosystem

- Mac app from the same SwiftUI code base: timer in the menu bar, quick capture by hotkey.
- Shared lists through CloudKit sharing: household tasks with a partner, a buddy friend via a link.
- No Android and no web: Gumption is Apple-only, built in Swift.

## Later, if demand is confirmed

- Read the calendar so "Pick for me" knows free time.
- Block distracting apps during focus (Screen Time API).
