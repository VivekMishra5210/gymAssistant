# Graph Report - gymApp  (2026-11-10)

## Corpus Check
- 39 files · ~19,178 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: .xml 7, (none) 4, .properties 2)

## Summary
- 631 nodes · 862 edges · 33 communities (28 shown, 5 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f53b60d9`
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
- common.dart
- dates.dart
- WorkoutStore
- state_repository.dart
- plan_repository.dart
- WorkoutController
- split_editor_screen.dart
- exercises_screen.dart
- settings_screen.dart
- StatelessWidget
- streak_calculator.dart
- Project structure (lib/ layout)

## God Nodes (most connected - your core abstractions)
1. `PlanRepository` - 13 edges
2. `CycleService` - 12 edges
3. `SQLite Data Model` - 11 edges
4. `Split cycle logic (pointer_position / pointer_since)` - 10 edges
5. `Clock` - 9 edges
6. `dependencies` - 9 edges
7. `Plan: Gym Assistant` - 9 edges
8. `Streak algorithm` - 9 edges
9. `Project structure (lib/ layout)` - 9 edges
10. `StateRepository` - 8 edges

## Surprising Connections (you probably didn't know these)
- `_load` --references--> `PlanRepository`  [EXTRACTED]
  lib/ui/settings/split_editor_screen.dart → lib/data/repositories/plan_repository.dart
- `RecordingStore` --implements--> `WorkoutStore`  [EXTRACTED]
  test/rest_timer_test.dart → lib/logic/workout_controller.dart
- `createExercise` --references--> `PlanRepository`  [EXTRACTED]
  lib/ui/settings/exercises_screen.dart → lib/data/repositories/plan_repository.dart
- `_edit` --references--> `PlanRepository`  [EXTRACTED]
  lib/ui/settings/exercises_screen.dart → lib/data/repositories/plan_repository.dart
- `_load` --references--> `PlanRepository`  [EXTRACTED]
  lib/ui/settings/exercises_screen.dart → lib/data/repositories/plan_repository.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Session history tables snapshotting the plan** — spec_workout_session_table, spec_session_exercise_table, spec_set_log_table, spec_history_vs_plan_snapshot [EXTRACTED 1.00]
- **Rest-end alert flow (end-time timer, popup, notification fallback)** — spec_rest_timer_logic, lib_logic_rest_timer_controller, spec_rest_finished_popup, spec_local_notification, spec_exact_alarm_fallback, spec_app_state_table [EXTRACTED 1.00]
- **Pure, Clock-injected testable logic layer** — lib_logic_cycle_service, lib_logic_rest_timer_controller, lib_logic_streak_calculator, spec_clock, spec_test_checklist [INFERRED 0.85]

## Communities (33 total, 5 thin omitted)

### Community 0 - "workout_screen.dart"
Cohesion: 0.05
Nodes (35): _confirmEnd, createState, _ctrl, didChangeAppLifecycleState, dispose, _doneSetMenu, _editNumber, _endReasons (+27 more)

### Community 1 - "SQLite Data Model"
Cohesion: 0.06
Nodes (54): GRAPH_REPORT.md, graphify Knowledge Graph (graphify-out/), graphify-out/wiki/index.md navigation, Active Workout screen, Advance (pointer % count + 1), Android config (permissions, dark theme), app_state table, Best streak (computed on load) (+46 more)

### Community 2 - "pubspec.yaml"
Cohesion: 0.09
Nodes (22): dependencies, cupertino_icons, flutter, intl, path, provider, sqflite, table_calendar (+14 more)

### Community 3 - "Plan: Gym Assistant"
Cohesion: 0.12
Nodes (15): Acceptance, Dependencies, M0: Project setup, M1: Workout + rest timer, hardcoded (SPEC Phase 1), M2: Database + flexible split (SPEC Phase 2), M3: Dashboard, calendar, streak, day detail (SPEC Phase 3), M4: Settings + onboarding (SPEC Phase 4), M5: Background notification + polish (SPEC Phase 5) (+7 more)

### Community 4 - "workout_editor_screen.dart"
Cohesion: 0.12
Nodes (16): StateRepository, _add, build, _card, createState, _defaultSets, entry, _entryId (+8 more)

### Community 5 - "workout_controller.dart"
Cohesion: 0.04
Nodes (43): bumpReps, bumpWeight, _busy, canTick, _clock, complete, completed, deleteSet (+35 more)

### Community 6 - "cycle_service.dart"
Cohesion: 0.04
Nodes (42): advance, afterFinish, at, _c, catchUp, clampPosition, _clock, createSplit (+34 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (28): build, clock, cycle, plan, state, DaySession, CycleService, clock (+20 more)

### Community 8 - "rest_timer_controller.dart"
Cohesion: 0.08
Nodes (16): adjust, _clear, _clock, e, _endsAt, isResting, nextLabel, null (+8 more)

### Community 9 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 10 - "plan_exercise.dart"
Cohesion: 0.40
Nodes (4): name, PlanExercise, restSeconds, sets

### Community 11 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (32): advance, Clock, FakeClock, _now, SystemClock, History, _armMidnight, build (+24 more)

### Community 12 - "rest_timer_test.dart"
Cohesion: 0.06
Nodes (21): main, r, split, w, deleted, deleteSet, finish, finished (+13 more)

### Community 18 - "_WorkoutScreenState"
Cohesion: 0.27
Nodes (8): SettingsScreen, _SettingsScreenState, SplitEditorScreen, _SplitEditorScreenState, _EndReasonDialog, _EndReasonDialogState, _NumberDialog, _NumberDialogState

### Community 19 - "session_repository.dart"
Cohesion: 0.07
Nodes (26): date, _db, deleteSet, endedAt, exerciseIds, exercises, finish, finishedCount (+18 more)

### Community 20 - "app_database.dart"
Cohesion: 0.20
Nodes (5): openAppDatabase, openDatabase, path, _schemaV1, _seed

### Community 21 - "common.dart"
Cohesion: 0.07
Nodes (26): EntryType, fromRow, id, isRest, name, position, SplitEntry, type (+18 more)

### Community 22 - "dates.dart"
Cohesion: 0.29
Nodes (6): addDays, d, dateKey, p, parseDateKey, _two

### Community 23 - "WorkoutStore"
Cohesion: 0.50
Nodes (4): _DbStore, NoStore, WorkoutStore, RecordingStore

### Community 24 - "state_repository.dart"
Cohesion: 0.17
Nodes (10): applyCatchUp, _db, graceDays, Pointer, restDays, _row, saveSettings, setPointer (+2 more)

### Community 25 - "plan_repository.dart"
Cohesion: 0.10
Nodes (18): addEntry, addPlanExercise, allExercises, createExercise, createSplit, _db, deleteEntry, entries (+10 more)

### Community 26 - "WorkoutController"
Cohesion: 0.29
Nodes (6): WorkoutController, build, _ExerciseCard, _SetRow, WorkoutScreen, _WorkoutScreenState

### Community 27 - "split_editor_screen.dart"
Cohesion: 0.11
Nodes (15): _addWorkout, build, createState, _cycle, _delete, _edit, _entries, initState (+7 more)

### Community 28 - "exercises_screen.dart"
Cohesion: 0.20
Nodes (13): PlanRepository, _all, build, createExercise, createState, _edit, ExercisesScreen, _ExercisesScreenState (+5 more)

### Community 29 - "settings_screen.dart"
Cohesion: 0.15
Nodes (8): build, createState, initState, _push, _rest, _s, _save, _state

### Community 30 - "StatelessWidget"
Cohesion: 0.22
Nodes (8): GymApp, _Dot, _MainButton, _StreakRow, _SessionCard, Stepper48, _RestPanel, _Stepper

### Community 31 - "streak_calculator.dart"
Cohesion: 0.25
Nodes (6): best, computeStreak, covered, current, first, Streak

### Community 32 - "Project structure (lib/ layout)"
Cohesion: 0.50
Nodes (4): core/time/clock.dart (injectable now), Project structure (lib/ layout), Repositories (plan / session / state), core/notifications/rest_notifier.dart

## Knowledge Gaps
- **338 isolated node(s):** `clock`, `cycle`, `plan`, `state`, `build` (+333 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 421 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `PlanRepository` connect `exercises_screen.dart` to `workout_editor_screen.dart`, `cycle_service.dart`, `dashboard_screen.dart`, `_WorkoutScreenState`, `plan_repository.dart`, `split_editor_screen.dart`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `clock`, `cycle`, `plan` to the rest of the system?**
  _338 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._
- **Why does `Project structure (lib/ layout)` connect `Project structure (lib/ layout)` to `SQLite Data Model`, `workout_controller.dart`, `cycle_service.dart`, `rest_timer_controller.dart`, `app_database.dart`, `streak_calculator.dart`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Should `SQLite Data Model` be split into smaller, more focused modules?**
  _Cohesion score 0.055288461538461536 - nodes in this community are weakly interconnected._
- **Why does `Clock` connect `dashboard_screen.dart` to `rest_timer_controller.dart`, `workout_controller.dart`, `cycle_service.dart`, `dashboard_screen.dart`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Should `pubspec.yaml` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._