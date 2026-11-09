# Graph Report - gymApp  (2026-11-09)

## Corpus Check
- 22 files · ~10,321 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: .xml 7, (none) 4, .properties 2)

## Summary
- 286 nodes · 378 edges · 19 communities (14 shown, 5 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5b91ff90`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- workout_screen.dart
- Workout & Rest Timer
- pubspec.yaml
- Plan: Gym Assistant
- Split Editing & Onboarding
- workout_controller.dart
- SQLite Data Model
- Clock
- rest_timer_controller.dart
- analysis_options.yaml
- plan_exercise.dart
- WorkoutController
- rest_timer_test.dart
- MainActivity.kt
- gym_assistant
- _WorkoutScreenState

## God Nodes (most connected - your core abstractions)
1. `SQLite Data Model` - 11 edges
2. `Split cycle logic (pointer_position / pointer_since)` - 10 edges
3. `Plan: Gym Assistant` - 9 edges
4. `Clock` - 9 edges
5. `Project structure (lib/ layout)` - 9 edges
6. `Streak algorithm` - 9 edges
7. `Rest timer logic (store end time)` - 8 edges
8. `Locked Decisions` - 8 edges
9. `Milestones` - 7 edges
10. `WorkoutController` - 7 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `WorkoutController`  [EXTRACTED]
  lib/ui/workout/workout_screen.dart → lib/logic/workout_controller.dart
- `_WorkoutScreenState` --references--> `WorkoutController`  [EXTRACTED]
  lib/ui/workout/workout_screen.dart → lib/logic/workout_controller.dart
- `graphify Knowledge Graph (graphify-out/)` --conceptually_related_to--> `Gym Assistant App`  [INFERRED]
  CLAUDE.md → SPEC.md
- `_ExerciseCard` --references--> `WorkoutController`  [EXTRACTED]
  lib/ui/workout/workout_screen.dart → lib/logic/workout_controller.dart
- `_SetRow` --references--> `WorkoutController`  [EXTRACTED]
  lib/ui/workout/workout_screen.dart → lib/logic/workout_controller.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Session history tables snapshotting the plan** — spec_workout_session_table, spec_session_exercise_table, spec_set_log_table, spec_history_vs_plan_snapshot [EXTRACTED 1.00]
- **Rest-end alert flow (end-time timer, popup, notification fallback)** — spec_rest_timer_logic, lib_logic_rest_timer_controller, spec_rest_finished_popup, spec_local_notification, spec_exact_alarm_fallback, spec_app_state_table [EXTRACTED 1.00]
- **Pure, Clock-injected testable logic layer** — spec_cycle_service, lib_logic_rest_timer_controller, spec_streak_calculator, spec_clock, spec_test_checklist [INFERRED 0.85]

## Communities (19 total, 5 thin omitted)

### Community 0 - "workout_screen.dart"
Cohesion: 0.05
Nodes (31): _confirmEnd, createState, _ctrl, didChangeAppLifecycleState, dispose, _doneSetMenu, _editNumber, ex (+23 more)

### Community 1 - "Workout & Rest Timer"
Cohesion: 0.13
Nodes (21): Active Workout screen, Android config (permissions, dark theme), Build phases, SQLite Data Model, End Workout flow (ended_early), exercise table, flutter_local_notifications + timezone, Later / not v1 features (+13 more)

### Community 2 - "pubspec.yaml"
Cohesion: 0.10
Nodes (19): dependencies, cupertino_icons, flutter, intl, provider, vibration, description, dev_dependencies (+11 more)

### Community 3 - "Plan: Gym Assistant"
Cohesion: 0.12
Nodes (15): Acceptance, Dependencies, M0: Project setup, M1: Workout + rest timer, hardcoded (SPEC Phase 1), M2: Database + flexible split (SPEC Phase 2), M3: Dashboard, calendar, streak, day detail (SPEC Phase 3), M4: Settings + onboarding (SPEC Phase 4), M5: Background notification + polish (SPEC Phase 5) (+7 more)

### Community 4 - "Split Editing & Onboarding"
Cohesion: 0.13
Nodes (15): GRAPH_REPORT.md, graphify Knowledge Graph (graphify-out/), graphify-out/wiki/index.md navigation, Flutter (Dart), Install Flutter on Windows, Gym Assistant App, First launch onboarding, Phase 4: Settings + onboarding (+7 more)

### Community 5 - "workout_controller.dart"
Cohesion: 0.05
Nodes (33): bumpReps, bumpWeight, canTick, _clock, completed, done, doneCount, elapsed (+25 more)

### Community 6 - "SQLite Data Model"
Cohesion: 0.12
Nodes (25): Advance (pointer % count + 1), core/db/app_database.dart, app_state table, Best streak (computed on load), Dashboard month calendar, core/time/clock.dart (injectable now), logic/cycle_service.dart, Dashboard screen (+17 more)

### Community 7 - "Clock"
Cohesion: 0.09
Nodes (12): build, clock, advance, Clock, FakeClock, _now, SystemClock, main (+4 more)

### Community 8 - "rest_timer_controller.dart"
Cohesion: 0.08
Nodes (15): adjust, _clear, _clock, e, _endsAt, isResting, nextLabel, null (+7 more)

### Community 9 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 10 - "plan_exercise.dart"
Cohesion: 0.40
Nodes (4): name, PlanExercise, restSeconds, sets

### Community 11 - "WorkoutController"
Cohesion: 0.29
Nodes (7): GymApp, WorkoutController, build, _ExerciseCard, _RestPanel, _SetRow, _Stepper

### Community 12 - "rest_timer_test.dart"
Cohesion: 0.20
Nodes (3): main, plan, main

### Community 18 - "_WorkoutScreenState"
Cohesion: 0.33
Nodes (4): _NumberDialog, _NumberDialogState, WorkoutScreen, _WorkoutScreenState

## Knowledge Gaps
- **95 isolated node(s):** `clock`, `build`, `name`, `sets`, `restSeconds` (+90 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 160 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WorkoutController` connect `WorkoutController` to `rest_timer_controller.dart`, `workout_screen.dart`, `_WorkoutScreenState`, `workout_controller.dart`?**
  _High betweenness centrality (0.174) - this node is a cross-community bridge._
- **What connects `clock`, `build`, `name` to the rest of the system?**
  _95 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05128205128205128 - nodes in this community are weakly interconnected._
- **Why does `Project structure (lib/ layout)` connect `SQLite Data Model` to `rest_timer_controller.dart`, `Workout & Rest Timer`, `workout_controller.dart`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **Should `Workout & Rest Timer` be split into smaller, more focused modules?**
  _Cohesion score 0.1339031339031339 - nodes in this community are weakly interconnected._
- **Why does `Clock` connect `Clock` to `rest_timer_controller.dart`, `workout_controller.dart`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Should `pubspec.yaml` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._