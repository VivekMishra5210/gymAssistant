# Graph Report - gymApp  (2026-11-10)

## Corpus Check
- 44 files · ~22,118 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: .xml 7, (none) 4, .properties 2)

## Summary
- 742 nodes · 1030 edges · 46 communities (39 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e3afba72`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- workout_screen.dart
- SQLite Data Model
- pubspec.yaml
- Plan: Gym Assistant
- workout_editor_screen.dart
- workout_controller.dart
- cycle_service.dart
- main.dart
- rest_timer_controller.dart
- analysis_options.yaml
- plan_exercise.dart
- dashboard_screen.dart
- rest_timer_test.dart
- MainActivity.kt
- gym_assistant
- State
- session_repository.dart
- app_database.dart
- common.dart
- dates.dart
- WorkoutStore
- state_repository.dart
- plan_repository.dart
- WorkoutController
- split_editor_screen.dart
- rest_notifier.dart
- day_detail_screen.dart
- StatelessWidget
- streak_calculator.dart
- Project structure (lib/ layout)
- onboarding_view.dart
- graphify Knowledge Graph (graphify-out/)
- MaterialPageRoute
- stats.dart
- exercises_screen.dart
- stats_screen.dart
- bmi_screen.dart
- app.dart
- settings_screen.dart
- Clock
- package:flutter/material.dart
- _EndReasonDialog
- _NumberDialog

## God Nodes (most connected - your core abstractions)
1. `Clock` - 18 edges
2. `CycleService` - 14 edges
3. `PlanRepository` - 13 edges
4. `dependencies` - 13 edges
5. `SQLite Data Model` - 11 edges
6. `StateRepository` - 10 edges
7. `Split cycle logic (pointer_position / pointer_since)` - 10 edges
8. `Plan: Gym Assistant` - 9 edges
9. `Streak algorithm` - 9 edges
10. `Project structure (lib/ layout)` - 9 edges

## Surprising Connections (you probably didn't know these)
- `RecordingAlerts` --implements--> `RestAlerts`  [EXTRACTED]
  test/rest_timer_test.dart → lib/core/notifications/rest_notifier.dart
- `_add` --references--> `StateRepository`  [EXTRACTED]
  lib/ui/settings/workout_editor_screen.dart → lib/data/repositories/state_repository.dart
- `RecordingStore` --implements--> `WorkoutStore`  [EXTRACTED]
  test/rest_timer_test.dart → lib/logic/workout_controller.dart
- `graphify Knowledge Graph (graphify-out/)` --conceptually_related_to--> `Gym Assistant App`  [INFERRED]
  CLAUDE.md → SPEC.md
- `_BmiScreenState` --references--> `Clock`  [EXTRACTED]
  lib/ui/bmi/bmi_screen.dart → lib/core/time/clock.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Session history tables snapshotting the plan** — spec_workout_session_table, spec_session_exercise_table, spec_set_log_table, spec_history_vs_plan_snapshot [EXTRACTED 1.00]
- **Rest-end alert flow (end-time timer, popup, notification fallback)** — spec_rest_timer_logic, lib_logic_rest_timer_controller, spec_rest_finished_popup, spec_local_notification, spec_exact_alarm_fallback, spec_app_state_table [EXTRACTED 1.00]
- **Pure, Clock-injected testable logic layer** — lib_logic_cycle_service, lib_logic_rest_timer_controller, lib_logic_streak_calculator, spec_clock, spec_test_checklist [INFERRED 0.85]

## Communities (46 total, 7 thin omitted)

### Community 0 - "workout_screen.dart"
Cohesion: 0.05
Nodes (36): _confirmEnd, createState, _ctrl, didChangeAppLifecycleState, dispose, _doneSetMenu, _editNumber, _endReasons (+28 more)

### Community 1 - "SQLite Data Model"
Cohesion: 0.06
Nodes (51): Active Workout screen, Advance (pointer % count + 1), Android config (permissions, dark theme), app_state table, Best streak (computed on load), Build phases, Dashboard month calendar, Dashboard screen (+43 more)

### Community 2 - "pubspec.yaml"
Cohesion: 0.07
Nodes (27): dependencies, audioplayers, cupertino_icons, flutter, flutter_local_notifications, intl, path, provider (+19 more)

### Community 3 - "Plan: Gym Assistant"
Cohesion: 0.12
Nodes (15): Acceptance, Dependencies, M0: Project setup, M1: Workout + rest timer, hardcoded (SPEC Phase 1), M2: Database + flexible split (SPEC Phase 2), M3: Dashboard, calendar, streak, day detail (SPEC Phase 3), M4: Settings + onboarding (SPEC Phase 4), M5: Background notification + polish (SPEC Phase 5) (+7 more)

### Community 4 - "workout_editor_screen.dart"
Cohesion: 0.12
Nodes (13): _add, build, _card, createState, _defaultSets, entry, _entryId, initState (+5 more)

### Community 5 - "workout_controller.dart"
Cohesion: 0.04
Nodes (46): alerts, bumpReps, bumpWeight, _busy, canTick, _clock, complete, completed (+38 more)

### Community 6 - "cycle_service.dart"
Cohesion: 0.04
Nodes (44): advance, afterFinish, alerts, at, _c, catchUp, clampPosition, _clock (+36 more)

### Community 7 - "main.dart"
Cohesion: 0.17
Nodes (8): clock, cycle, db, fromNotification, main, notifier, plan, state

### Community 8 - "rest_timer_controller.dart"
Cohesion: 0.09
Nodes (16): adjust, _clear, _clock, e, _endsAt, isResting, nextLabel, null (+8 more)

### Community 9 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 10 - "plan_exercise.dart"
Cohesion: 0.40
Nodes (4): name, PlanExercise, restSeconds, sets

### Community 11 - "dashboard_screen.dart"
Cohesion: 0.06
Nodes (24): History, _armMidnight, _clock, color, createState, _cycle, _Data, didChangeAppLifecycleState (+16 more)

### Community 12 - "rest_timer_test.dart"
Cohesion: 0.05
Nodes (27): main, r, split, w, calls, cancel, deleted, deleteSet (+19 more)

### Community 18 - "State"
Cohesion: 0.23
Nodes (11): RestNotifier, StateRepository, BmiScreen, _BmiScreenState, DashboardScreen, _DashboardScreenState, _reset, SettingsScreen (+3 more)

### Community 19 - "session_repository.dart"
Cohesion: 0.07
Nodes (27): date, _db, deleteSet, endedAt, exerciseIds, exercises, finish, finishedCount (+19 more)

### Community 20 - "app_database.dart"
Cohesion: 0.15
Nodes (8): delete, openAppDatabase, openDatabase, path, resetData, _schemaV1, _schemaV2, _seed

### Community 21 - "common.dart"
Cohesion: 0.07
Nodes (27): EntryType, fromRow, id, isRest, name, position, SplitEntry, type (+19 more)

### Community 22 - "dates.dart"
Cohesion: 0.29
Nodes (6): addDays, d, dateKey, p, parseDateKey, _two

### Community 23 - "WorkoutStore"
Cohesion: 0.50
Nodes (4): _DbStore, NoStore, WorkoutStore, RecordingStore

### Community 24 - "state_repository.dart"
Cohesion: 0.12
Nodes (15): addWeight, applyCatchUp, _db, deleteWeight, graceDays, heightCm, Pointer, reset (+7 more)

### Community 25 - "plan_repository.dart"
Cohesion: 0.10
Nodes (18): addEntry, addPlanExercise, allExercises, createExercise, createSplit, _db, deleteEntry, entries (+10 more)

### Community 26 - "WorkoutController"
Cohesion: 0.29
Nodes (6): WorkoutController, build, _ExerciseCard, _SetRow, WorkoutScreen, _WorkoutScreenState

### Community 27 - "split_editor_screen.dart"
Cohesion: 0.11
Nodes (16): _addWorkout, build, createState, _cycle, _delete, _edit, _entries, initState (+8 more)

### Community 28 - "rest_notifier.dart"
Cohesion: 0.12
Nodes (12): _android, cancel, _details, _id, init, NoAlerts, _plugin, requestPermissions (+4 more)

### Community 29 - "day_detail_screen.dart"
Cohesion: 0.16
Nodes (11): DaySession, CycleService, build, date, DayDetailScreen, _duration, isRest, _kg (+3 more)

### Community 30 - "StatelessWidget"
Cohesion: 0.22
Nodes (8): GymApp, _Dot, _MainButton, _StreakRow, _Period, Stepper48, _RestPanel, _Stepper

### Community 31 - "streak_calculator.dart"
Cohesion: 0.25
Nodes (6): best, computeStreak, covered, current, first, Streak

### Community 32 - "Project structure (lib/ layout)"
Cohesion: 0.67
Nodes (3): core/time/clock.dart (injectable now), Project structure (lib/ layout), Repositories (plan / session / state)

### Community 33 - "onboarding_view.dart"
Cohesion: 0.22
Nodes (4): build, n, onDone, _templates

### Community 34 - "graphify Knowledge Graph (graphify-out/)"
Cohesion: 0.40
Nodes (3): GRAPH_REPORT.md, graphify Knowledge Graph (graphify-out/), graphify-out/wiki/index.md navigation

### Community 35 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): build, _calendar, _go, _create, _open

### Community 36 - "stats.dart"
Cohesion: 0.10
Nodes (18): avgPerDay, avgPerWorkout, bmi, bmiCategory, days, daysBetween, inRange, m (+10 more)

### Community 37 - "exercises_screen.dart"
Cohesion: 0.15
Nodes (14): PlanRepository, _all, build, createExercise, createState, _edit, ExercisesScreen, _ExercisesScreenState (+6 more)

### Community 38 - "stats_screen.dart"
Cohesion: 0.17
Nodes (9): PeriodStats, _all, createState, _dur, _kg, s, StatsScreen, _StatsScreenState (+1 more)

### Community 39 - "bmi_screen.dart"
Cohesion: 0.15
Nodes (11): _ask, build, _card, _color, createState, _Data, initState, _load (+3 more)

### Community 40 - "app.dart"
Cohesion: 0.17
Nodes (7): build, clock, cycle, notifier, openWorkout, plan, state

### Community 41 - "settings_screen.dart"
Cohesion: 0.18
Nodes (8): build, createState, initState, _push, _rest, _s, _save, _state

### Community 42 - "Clock"
Cohesion: 0.28
Nodes (7): advance, Clock, FakeClock, _now, SystemClock, _logWeight, build

### Community 43 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (5): _player, _show, showRestOver, sound, vibrate

## Knowledge Gaps
- **414 isolated node(s):** `clock`, `cycle`, `plan`, `state`, `notifier` (+409 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 508 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Clock` connect `Clock` to `workout_controller.dart`, `cycle_service.dart`, `bmi_screen.dart`, `app.dart`, `rest_timer_controller.dart`, `settings_screen.dart`, `dashboard_screen.dart`, `stats_screen.dart`, `State`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `clock`, `cycle`, `plan` to the rest of the system?**
  _414 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._
- **Why does `Project structure (lib/ layout)` connect `Project structure (lib/ layout)` to `SQLite Data Model`, `workout_controller.dart`, `cycle_service.dart`, `rest_timer_controller.dart`, `app_database.dart`, `rest_notifier.dart`, `streak_calculator.dart`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Should `SQLite Data Model` be split into smaller, more focused modules?**
  _Cohesion score 0.06312098188194039 - nodes in this community are weakly interconnected._
- **Why does `PlanRepository` connect `exercises_screen.dart` to `workout_editor_screen.dart`, `cycle_service.dart`, `app.dart`, `State`, `plan_repository.dart`, `split_editor_screen.dart`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Should `pubspec.yaml` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._