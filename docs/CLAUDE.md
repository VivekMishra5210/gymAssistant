# Gym Assistant

Read SPEC.md before doing anything. Build one phase at a time from §13.
After each phase: run `flutter analyze` and `flutter test`, fix all issues, then stop and tell me what to test on the phone.

SPEC.md is the source of truth. Don't add features outside it. If a rule there is ambiguous, ask before guessing.

## What it is
Personal, fully offline Android app that runs a workout and enforces rest between sets. No backend, no login, no network. Units: kg. Target: Redmi Note 13 5G (HyperOS).

## Stack
- Flutter (Dart), Android only
- SQLite via `sqflite` + `path`
- State: `provider` with `ChangeNotifier`
- `flutter_local_notifications`, `timezone`, `flutter_timezone`, `permission_handler`, `wakelock_plus`, `vibration`, `audioplayers`, `table_calendar`, `intl`
- Add packages with `flutter pub add <name>` (current versions). Don't add packages outside SPEC §11 without asking.

## Structure (SPEC §10)
```
lib/
  main.dart, app.dart          # app, dark theme, routes
  core/db/                     # app_database.dart: open, onCreate, migrations
  core/time/clock.dart         # injectable "now"
  core/notifications/          # rest_notifier.dart
  data/models/                 # SplitEntry, Exercise, PlanExercise, Session, SetLog...
  data/repositories/           # plan_, session_, state_repository.dart
  logic/                       # cycle_service, rest_timer_controller, streak_calculator, workout_controller
  ui/                          # dashboard/ workout/ day_detail/ settings/ onboarding/ widgets/
test/                          # streak_calculator_test, cycle_service_test, rest_timer_test
```
The project isn't created yet. Create it in this folder (SPEC.md stays at the root): `flutter create --project-name gym_assistant --platforms android .`

## Conventions
- Business logic lives in `lib/logic/`, pure and testable. UI and repositories stay thin.
- Never call `DateTime.now()` in logic. Use the injected `Clock` so tests control time.
- Timestamps: epoch ms (int). Dates: `TEXT 'yyyy-mm-dd'`, local time.
- Rest timer: store `rest_ends_at` and compute remaining from it. Never trust a running countdown (SPEC §7).
- Split cycle advances only from finished sessions and elapsed rest days, never from the weekday (SPEC §6).
- History copies names. Editing the plan never rewrites past sessions. A running session uses its start-time snapshot.
- DB: `PRAGMA foreign_keys = ON` in `onConfigure`. Use `version` + `onUpgrade` migrations from day one. Only one `in_progress` session at a time.
- UI: dark theme, high contrast, tap targets ≥48 dp.

## Run
```
flutter doctor            # Flutter + Android toolchain should be ✓
flutter devices           # phone must be listed (USB debugging on, SPEC §2)
flutter pub get
flutter run               # installs and launches on the phone
```
After the first install, on the phone: Battery saver → No restrictions, Autostart → ON, allow notifications.

## Test
```
flutter analyze
flutter test
flutter test test/streak_calculator_test.dart   # one file
```
Required unit cases are listed in SPEC §14. Manual phone checks are also in §14. Name the relevant ones when a phase is done.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
