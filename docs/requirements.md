# Requirements: version 1.0

Gumption 1.0 covers one flow end to end: capture a task, tap Start, do the first tiny step with a buddy and a visible timer, get praised. iPhone, iOS 17+, English, US and UK.

Why: people with ADHD drop task apps because setup burns the energy they don't have, the app shames them for missed days, and subscriptions are expensive and hard to cancel. No competitor combines instant start, a buddy (body doubling) and a visual timer.

## Product principles

1. At most two taps from opening the app to a running focus session. No required setup; onboarding is the first session.
2. One screen, one task. Show the next step, never the whole day.
3. No shame. No red, no "overdue", streaks never reset.
4. The buddy is always there. No booking, no camera.
5. Time is always visible: lock screen, Dynamic Island, widget.
6. Honest pricing. Yearly total shown, reminder 2 days before a trial ends, cancel in one tap.

## Features

| # | Feature | Done when |
| --- | --- | --- |
| 1 | Quick capture, text and voice | Task saved in under 3 s, no dates, folders or tags |
| 2 | "Pick for me" by energy level (low / some / lots) | One task suggested, up to 3 re-rolls |
| 3 | AI breakdown into steps, "smaller / fewer" toggle | 3–7 steps in under 2 s, first step under 2 min; manual steps work offline |
| 4 | Focus screen with visual timer | Screen stays on; timer survives backgrounding and app termination |
| 5 | AI buddy (text) | Greeting, mid-session check-in, end-of-session question; canned lines offline |
| 6 | "I'm stuck": smaller step, 5-min break, switch task | One tap, no judgemental copy |
| 7 | Praise and a weekly "things started" count | No red and no word "overdue" anywhere |
| 8 | Live Activity, Dynamic Island, "Next step" widget | Done and Stuck work from the lock screen |
| 9 | Gentle reminders | At most 2 a day, local notifications, work offline |
| 10 | Free tier and honest subscription | 7-day trial, reminder 2 days before charge, lifetime option |
| 11 | Data safety | Every requirement in [data-safety.md](data-safety.md) passes |
| 12 | Analytics and crash reporting | Funnel events without task text; 99.5% crash-free sessions |

Out of scope for 1.0: calendar, projects, video, chat between people, leaderboards.

## Pricing hypothesis

Free forever: capture, timer, 3 breakdowns and 3 buddy sessions a day. Gumption Plus: $5.99/month, $39.99/year, $89 lifetime.

## Success metrics

| Metric | Target |
| --- | --- |
| Median time from app open to focus start | under 10 s |
| Sessions where at least the first step is done | over 70% |
| Week-4 retention | over 20–25% |
| Trial to paid conversion | over 8% |
| Data-loss incidents | 0 |

Source research: user complaints from App Store, Trustpilot and reviews of Tiimo, Inflow, Structured, Routinery, Focusmate, dubbii, Goblin Tools and Forest (November 2026).
