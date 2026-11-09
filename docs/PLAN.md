# Plan: Gym Assistant

**Source**: `SPEC.md` (§13 build phases)
**Complexity**: Large overall. Each milestone is Small–Medium.

## Summary
Build the offline Flutter app from SPEC.md in 6 milestones (M0 setup + SPEC phases 1–5). Each milestone ends with `flutter analyze` and `flutter test` clean and something to try on the phone. Stop after each one for a phone check before starting the next.

## Patterns to Mirror
No app code exists yet (repo has only SPEC.md, CLAUDE.md). The patterns come from the spec, not existing code:

| Category | Source | Pattern |
|---|---|---|
| Naming | SPEC §10 | `snake_case.dart` files, `PascalCase` classes, `*_repository.dart`, `*_service.dart`, `*_controller.dart` |
| Logic | SPEC §10 | Pure logic in `lib/logic/`, time from an injected `Clock`, no `DateTime.now()` in logic |
| State | SPEC §10 | `provider` + `ChangeNotifier` controllers |
| Data access | SPEC §9 | Repositories wrap `sqflite`; FK on in `onConfigure`; `version` + `onUpgrade` |
| Errors | SPEC §9 | DB `CHECK` constraints are the last guard; validate input in UI/controllers before writes |
| Tests | SPEC §14 | `flutter_test`, one file per logic unit in `test/`, fake `Clock` |

## Milestones

### M0: Project setup
- `flutter create --project-name gym_assistant --platforms android .` in repo root (keeps SPEC.md, CLAUDE.md).
- `flutter pub add provider intl vibration` (only what M1 needs; add the rest per milestone).
- App name "Gym Assistant", dark theme, `app.dart` with `MaterialApp`.
- `lib/core/time/clock.dart`: `Clock` with `now()`; `SystemClock` + `FakeClock` for tests.
- **Validate**: `flutter analyze`, `flutter test`, `flutter run` shows an empty dark app on the phone.

### M1: Workout + rest timer, hardcoded (SPEC Phase 1)
Files:
| File | Action |
|---|---|
| `lib/logic/rest_timer_controller.dart` | CREATE: `rest_ends_at` state, `restDurationAfter(set, exercise, next)` rule, ±15s (min now), skip, resume check |
| `lib/logic/workout_controller.dart` | CREATE: hardcoded workout (Lat Pulldown 4×120, Seated Row 4×120, Barbell Curl 4×90, Hammer Curl 4×90), set state, tick/edit/undo |
| `lib/ui/workout/*` | CREATE: Active Workout screen, set rows (±2.5 kg, ±1 rep, numeric keyboard), sticky rest panel with ring, End Workout button (simple confirm for now) |
| `lib/ui/workout/rest_over_dialog.dart` | CREATE: full-screen popup + ~1 s vibration pattern |
| `test/rest_timer_test.dart` | CREATE |

Tasks:
1. Rest rule (SPEC §4/§7): between sets = current exercise rest; after last set = next exercise rest; last set of last exercise = no rest, session done.
2. `Timer.periodic(1s)` only redraws `remaining = rest_ends_at − now`, clamped at 0.
3. `WidgetsBindingObserver`: on `resumed`, if `rest_ends_at` is past → popup once and clear.
4. Ticking ✓ during rest restarts the timer for the new set. Undo does not restart it.
5. ✓ disabled until weight and reps are filled (no history yet in M1).

- **Tests**: between-sets rest; after-last-set uses next exercise; last-of-last → no rest; +15/−15 clamp at now; resume after end → popup once.
- **Phone check**: a whole workout; lock phone mid-rest, unlock → timer correct, popup shows if it ended.

### M2: Database + flexible split (SPEC Phase 2)
- `flutter pub add sqflite path`
- `lib/core/db/app_database.dart`: full §9 schema, version 1, FK pragma, seed `app_state` row and one template split.
- `lib/data/models/*`, `plan_repository.dart`, `session_repository.dart`, `state_repository.dart`.
- `lib/logic/cycle_service.dart` (§6): advance with wrap, rest catch-up on open/resume, finish on D → `pointer_since = D+1`, Train anyway, Start next anyway, pointer clamp.
- Swap the hardcoded workout for the current split entry. Start Workout snapshots into `session_exercise`; every ✓ writes `set_log`; enforce a single `in_progress` session.
- Persist `rest_ends_at` / `rest_next_label` in `app_state`.
- Resume an in-progress session after the app is killed.
- Pre-fill query (§9) with fallback to the exercise's most recent set.
- Full End Workout flow (§5.5): reason chips (required) → second confirm → `ended_early`, split advances.
- Minimal temporary home screen with Start / Resume (replaced in M3).
- **Tests** (`test/cycle_service_test.dart`): wrap-around; 3 rest entries = 3 days; back after 10 days → lands on workout; finish D with next Rest → rest on D+1; Train anyway skips rests without logging; clamp after delete. Use `sqflite_common_ffi` (dev dep) or keep the cycle math pure and test it without a DB. Prefer pure.
- **Phone check**: kill app mid-workout → resume with sets intact; End Workout with sets left; next day shows the next entry.

### M3: Dashboard, calendar, streak, day detail (SPEC Phase 3)
- `flutter pub add table_calendar`
- `lib/logic/streak_calculator.dart` (§8): pure, takes workout dates + rest dates + grace + today; current and best streak.
- Dashboard: Today card (4 states from §6), streak row (current, best, total), calendar dots (green completed, orange ended early, hollow rest, today outlined).
- Day Detail (§5.6): status, reason, times, sets with timestamps, total volume.
- Run rest-day catch-up on open/resume and at local midnight while the app is open.
- **Tests** (`test/streak_calculator_test.dart`): consecutive; 1 miss survives; 2 misses break; rest days neutral; today-not-yet-trained doesn't break; best over history; grace 0 and 2.
- **Phone check**: dashboard after a few logged days; tap past day → detail.

### M4: Settings + onboarding (SPEC Phase 4)
- Onboarding (§5.1): templates 6/1, 5/2, 4/3 or empty → Split Editor.
- Split Editor: add Workout/Rest, drag reorder, rename, delete (block last Workout), 1–14 entries, show and set "next up". Pointer follows its entry on reorder/delete, else clamp.
- Workout Editor: exercises with sets 1–10 and rest 15–600 step 15 (mm:ss), drag reorder, pick or create exercise.
- Exercises screen: rename / muscle group / archive.
- Toggles: grace 0–3, keep screen on, sound, vibration, default rest.
- **Phone check**: create split from a template, edit, change split mid-cycle → old Day Detail keeps old names.

### M5: Background notification + polish (SPEC Phase 5)
- `flutter pub add flutter_local_notifications timezone flutter_timezone permission_handler wakelock_plus audioplayers`
- `lib/core/notifications/rest_notifier.dart`: channel "Rest timer", `zonedSchedule` id 1 at `rest_ends_at`, `exactAllowWhileIdle`, fallback to inexact if exact alarm denied; cancel on foreground end / skip / finish / end.
- Manifest permissions + receivers per the package README; desugaring; notification icon.
- Request `POST_NOTIFICATIONS` at first Start Workout.
- Notification tap → Active Workout, popup on resume.
- Sound (`assets/sounds/rest_done.mp3`), wakelock (setting), summary sheet (duration, sets, volume).
- Empty states; session crossing midnight keeps its start date.
- **Phone check**: all manual items in SPEC §14 (locked phone, Spotify in front, kill/resume, end early, split change, midnight).

## Dependencies
- M1 → M2 (controllers move onto the DB) → M3 (needs history) → M4 (edits plan data) → M5 (needs the full flow).
- Flutter SDK + Android toolchain installed, phone in USB debugging (SPEC §1–2). Not checked yet.
- A short `rest_done.mp3` must be supplied before M5.

## Validation (every milestone)
```bash
flutter analyze
flutter test
flutter run
```

## Risks
| Risk | Likelihood | Mitigation |
|---|---|---|
| HyperOS kills or delays the app/alarms | High | End-time based timer (M1); exact alarm + fallback (M5); battery/autostart settings (SPEC §2) |
| Exact-alarm permission denied on Android 12+ | Medium | Inexact fallback; popup still fires on resume |
| `flutter_local_notifications` setup drift (receivers, desugaring, minSdk) | Medium | Follow current README at M5, not memory |
| Date/time bugs (midnight, timezone, DST) | Medium | All logic takes `Clock`; dates as local `yyyy-mm-dd`; tests with fixed dates |
| Pointer bugs when editing the split | Medium | Track pointer by entry id during edits; tests for clamp |
| M1 → M2 rework of controllers | Low | Keep M1 controllers storage-agnostic so M2 only adds persistence |

## Open questions (ask before the milestone that needs them)
1. M2: what does deleting an exercise do: archive (`is_archived = 1`) or block if it's used in a plan? Plan assumes archive.
2. M3: does "Start next anyway" on the same day count as one workout day for the streak? Plan assumes yes (the streak counts days, not sessions).
3. M4: when a split entry is deleted, its `plan_exercise` rows cascade. Should the user be warned first? Plan assumes a simple confirm dialog.

## Acceptance
- [ ] M0–M5 complete, each checked on the phone
- [ ] `flutter analyze` clean, `flutter test` green
- [ ] All SPEC §14 unit cases covered
- [ ] Nothing built outside SPEC v1
