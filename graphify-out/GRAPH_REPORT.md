# Graph Report - gymApp  (2026-11-09)

## Corpus Check
- 33 files · ~16,188 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: .xml 7, (none) 4, .properties 2)

## Summary
- 511 nodes · 666 edges · 27 communities (22 shown, 5 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `eb78980e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- workout_screen.dart
- SQLite Data Model
- pubspec.yaml
- Plan: Gym Assistant
- Split Editing & Onboarding
- workout_controller.dart
- cycle_service.dart
- dashboard_screen.dart
- rest_timer_controller.dart
- analysis_options.yaml
- plan_exercise.dart
- dashboard_screen.dart
- rest_timer_test.dart
- MainActivity.kt
- gym_assistant
- _WorkoutScreenState
- session_repository.dart
- app_database.dart
- split_entry.dart
- dates.dart
- WorkoutStore
- state_repository.dart
- plan_repository.dart
- WorkoutController

## God Nodes (most connected - your core abstractions)
1. `SQLite Data Model` - 11 edges
2. `Split cycle logic (pointer_position / pointer_since)` - 10 edges
3. `Clock` - 9 edges
4. `dependencies` - 9 edges
5. `Plan: Gym Assistant` - 9 edges
6. `Streak algorithm` - 9 edges
7. `Project structure (lib/ layout)` - 9 edges
8. `Locked Decisions` - 8 edges
9. `Rest timer logic (store end time)` - 8 edges
10. `CycleService` - 7 edges

## Surprising Connections (you probably didn't know these)
- `RecordingStore` --implements--> `WorkoutStore`  [EXTRACTED]
  test/rest_timer_test.dart → lib/logic/workout_controller.dart
- `_DashboardScreenState` --references--> `Clock`  [EXTRACTED]
  lib/ui/dashboard/dashboard_screen.dart → lib/core/time/clock.dart
- `_DashboardScreenState` --references--> `CycleService`  [EXTRACTED]
  lib/ui/dashboard/dashboard_screen.dart → lib/logic/cycle_service.dart
- `build` --references--> `CycleService`  [EXTRACTED]
  lib/ui/day_detail/day_detail_screen.dart → lib/logic/cycle_service.dart
- `build` --references--> `WorkoutController`  [EXTRACTED]
  lib/ui/workout/workout_screen.dart → lib/logic/workout_controller.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Session history tables snapshotting the plan** — spec_workout_session_table, spec_session_exercise_table, spec_set_log_table, spec_history_vs_plan_snapshot [EXTRACTED 1.00]
- **Rest-end alert flow (end-time timer, popup, notification fallback)** — spec_rest_timer_logic, lib_logic_rest_timer_controller, spec_rest_finished_popup, spec_local_notification, spec_exact_alarm_fallback, spec_app_state_table [EXTRACTED 1.00]
- **Pure, Clock-injected testable logic layer** — lib_logic_cycle_service, lib_logic_rest_timer_controller, lib_logic_streak_calculator, spec_clock, spec_test_checklist [INFERRED 0.85]

## Communities (27 total, 5 thin omitted)

### Community 0 - "workout_screen.dart"
Cohesion: 0.05
Nodes (35): _confirmEnd, createState, _ctrl, didChangeAppLifecycleState, dispose, _doneSetMenu, _editNumber, _endReasons (+27 more)

### Community 1 - "SQLite Data Model"
Cohesion: 0.06
Nodes (50): best, computeStreak, covered, current, first, Streak, Active Workout screen, Advance (pointer % count + 1) (+42 more)

### Community 2 - "pubspec.yaml"
Cohesion: 0.09
Nodes (22): dependencies, cupertino_icons, flutter, intl, path, provider, sqflite, table_calendar (+14 more)

### Community 3 - "Plan: Gym Assistant"
Cohesion: 0.12
Nodes (15): Acceptance, Dependencies, M0: Project setup, M1: Workout + rest timer, hardcoded (SPEC Phase 1), M2: Database + flexible split (SPEC Phase 2), M3: Dashboard, calendar, streak, day detail (SPEC Phase 3), M4: Settings + onboarding (SPEC Phase 4), M5: Background notification + polish (SPEC Phase 5) (+7 more)

### Community 4 - "Split Editing & Onboarding"
Cohesion: 0.17
Nodes (10): GRAPH_REPORT.md, graphify Knowledge Graph (graphify-out/), graphify-out/wiki/index.md navigation, Flutter (Dart), Install Flutter on Windows, Gym Assistant App, Redmi Note 13 5G (HyperOS) target device, Split (repeating cycle of Workout/Rest days) (+2 more)

### Community 5 - "workout_controller.dart"
Cohesion: 0.04
Nodes (42): bumpReps, bumpWeight, _busy, canTick, _clock, complete, completed, deleteSet (+34 more)

### Community 6 - "cycle_service.dart"
Cohesion: 0.05
Nodes (39): advance, afterFinish, _c, catchUp, clampPosition, _clock, current, day (+31 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.07
Nodes (18): build, clock, cycle, DaySession, CycleService, clock, cycle, db (+10 more)

### Community 8 - "rest_timer_controller.dart"
Cohesion: 0.07
Nodes (21): advance, Clock, FakeClock, _now, SystemClock, adjust, _clear, _clock (+13 more)

### Community 9 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 10 - "plan_exercise.dart"
Cohesion: 0.40
Nodes (4): name, PlanExercise, restSeconds, sets

### Community 11 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (31): GymApp, History, _armMidnight, build, _calendar, _clock, color, createState (+23 more)

### Community 12 - "rest_timer_test.dart"
Cohesion: 0.06
Nodes (21): main, r, split, w, deleted, deleteSet, finish, finished (+13 more)

### Community 18 - "_WorkoutScreenState"
Cohesion: 0.25
Nodes (8): DashboardScreen, _DashboardScreenState, _EndReasonDialog, _EndReasonDialogState, _NumberDialog, _NumberDialogState, WorkoutScreen, _WorkoutScreenState

### Community 19 - "session_repository.dart"
Cohesion: 0.07
Nodes (26): date, _db, deleteSet, endedAt, exerciseIds, exercises, finish, finishedCount (+18 more)

### Community 20 - "app_database.dart"
Cohesion: 0.15
Nodes (9): exerciseIds, insert, openAppDatabase, openDatabase, path, _schemaV1, _seed, _seedExercises (+1 more)

### Community 21 - "split_entry.dart"
Cohesion: 0.20
Nodes (8): EntryType, fromRow, id, isRest, name, position, SplitEntry, type

### Community 22 - "dates.dart"
Cohesion: 0.29
Nodes (6): addDays, d, dateKey, p, parseDateKey, _two

### Community 23 - "WorkoutStore"
Cohesion: 0.50
Nodes (4): _DbStore, NoStore, WorkoutStore, RecordingStore

### Community 24 - "state_repository.dart"
Cohesion: 0.18
Nodes (9): applyCatchUp, _db, graceDays, Pointer, restDays, _row, setPointer, setRest (+1 more)

### Community 25 - "plan_repository.dart"
Cohesion: 0.22
Nodes (5): _db, entries, exercises, PlannedExercise, PlanRepository

### Community 26 - "WorkoutController"
Cohesion: 0.50
Nodes (4): WorkoutController, build, _ExerciseCard, _SetRow

## Knowledge Gaps
- **255 isolated node(s):** `clock`, `cycle`, `build`, `_schemaV1`, `path` (+250 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 333 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Project structure (lib/ layout)` connect `cycle_service.dart` to `rest_timer_controller.dart`, `SQLite Data Model`, `app_database.dart`, `workout_controller.dart`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **What connects `clock`, `cycle`, `build` to the rest of the system?**
  _255 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._
- **Why does `Clock` connect `rest_timer_controller.dart` to `workout_controller.dart`, `cycle_service.dart`, `dashboard_screen.dart`, `dashboard_screen.dart`, `_WorkoutScreenState`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Should `SQLite Data Model` be split into smaller, more focused modules?**
  _Cohesion score 0.061016949152542375 - nodes in this community are weakly interconnected._
- **Why does `Rest timer logic (store end time)` connect `SQLite Data Model` to `rest_timer_controller.dart`, `Split Editing & Onboarding`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Should `pubspec.yaml` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._