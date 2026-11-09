# Graph Report - gymApp  (2026-11-07)

## Corpus Check
- 23 files · ~8,199 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 32 file(s) not represented in the graph (top: (none) 7, .stamp 7, .xml 7)

## Summary
- 157 nodes · 212 edges · 18 communities (11 shown, 7 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f91b7598`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- SQLite Data Model
- Workout & Rest Timer
- pubspec.yaml
- Plan: Gym Assistant
- Split Editing & Onboarding
- Graphify Workflow Rules
- Split cycle logic (pointer_position / pointer_since)
- app.dart
- clock.dart
- analysis_options.yaml
- dart_plugin_registrant.dart
- link_hooks_result.json
- widget_test.dart
- MainActivity.kt
- gym_assistant

## God Nodes (most connected - your core abstractions)
1. `SQLite Data Model` - 11 edges
2. `Split cycle logic (pointer_position / pointer_since)` - 10 edges
3. `Plan: Gym Assistant` - 9 edges
4. `Project structure (lib/ layout)` - 9 edges
5. `Streak algorithm` - 9 edges
6. `Locked Decisions` - 8 edges
7. `Rest timer logic (store end time)` - 8 edges
8. `Milestones` - 7 edges
9. `Local rest-end notification` - 7 edges
10. `dependencies` - 6 edges

## Surprising Connections (you probably didn't know these)
- `graphify Knowledge Graph (graphify-out/)` --conceptually_related_to--> `Gym Assistant App`  [INFERRED]
  CLAUDE.md → SPEC.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Session history tables snapshotting the plan** — spec_workout_session_table, spec_session_exercise_table, spec_set_log_table, spec_history_vs_plan_snapshot [EXTRACTED 1.00]
- **Rest-end alert flow (end-time timer, popup, notification fallback)** — spec_rest_timer_logic, spec_rest_timer_controller, spec_rest_finished_popup, spec_local_notification, spec_exact_alarm_fallback, spec_app_state_table [EXTRACTED 1.00]
- **Pure, Clock-injected testable logic layer** — spec_cycle_service, spec_rest_timer_controller, spec_streak_calculator, spec_clock, spec_test_checklist [INFERRED 0.85]

## Communities (18 total, 7 thin omitted)

### Community 0 - "SQLite Data Model"
Cohesion: 0.27
Nodes (11): core/db/app_database.dart, SQLite Data Model, End Workout flow (ended_early), exercise table, Locked Decisions, Phase 2: Database + flexible split, plan_exercise table, session_exercise table (plan snapshot) (+3 more)

### Community 1 - "Workout & Rest Timer"
Cohesion: 0.14
Nodes (20): Active Workout screen, Android config (permissions, dark theme), core/time/clock.dart (injectable now), logic/cycle_service.dart, flutter_local_notifications + timezone, Local rest-end notification, Packages list, Phase 1: Workout + rest timer (hardcoded) (+12 more)

### Community 2 - "pubspec.yaml"
Cohesion: 0.10
Nodes (19): dependencies, cupertino_icons, flutter, intl, provider, vibration, description, dev_dependencies (+11 more)

### Community 3 - "Plan: Gym Assistant"
Cohesion: 0.12
Nodes (15): Acceptance, Dependencies, M0: Project setup, M1: Workout + rest timer, hardcoded (SPEC Phase 1), M2: Database + flexible split (SPEC Phase 2), M3: Dashboard, calendar, streak, day detail (SPEC Phase 3), M4: Settings + onboarding (SPEC Phase 4), M5: Background notification + polish (SPEC Phase 5) (+7 more)

### Community 4 - "Split Editing & Onboarding"
Cohesion: 0.20
Nodes (12): Flutter (Dart), Install Flutter on Windows, Gym Assistant App, First launch onboarding, Phase 4: Settings + onboarding, Pointer clamp on split edit, Redmi Note 13 5G (HyperOS) target device, Split (repeating cycle of Workout/Rest days) (+4 more)

### Community 5 - "Graphify Workflow Rules"
Cohesion: 0.40
Nodes (3): GRAPH_REPORT.md, graphify Knowledge Graph (graphify-out/), graphify-out/wiki/index.md navigation

### Community 6 - "Split cycle logic (pointer_position / pointer_since)"
Cohesion: 0.16
Nodes (17): Advance (pointer % count + 1), app_state table, Best streak (computed on load), Build phases, Dashboard month calendar, Dashboard screen, Day Detail screen, Later / not v1 features (+9 more)

### Community 7 - "app.dart"
Cohesion: 0.25
Nodes (3): build, GymApp, main

### Community 8 - "clock.dart"
Cohesion: 0.38
Nodes (5): advance, Clock, FakeClock, _now, SystemClock

### Community 9 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 11 - "link_hooks_result.json"
Cohesion: 0.33
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

## Knowledge Gaps
- **9 isolated node(s):** `build`, `_now`, `advance`, `main`, `main` (+4 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 59 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Gym Assistant App` connect `Split Editing & Onboarding` to `Graphify Workflow Rules`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Streak algorithm` (e.g. with `Rest-day catch-up on open/resume` and `workout_session table`) actually correct?**
  _`Streak algorithm` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `build`, `_now`, `advance` to the rest of the system?**
  _9 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Workout & Rest Timer` be split into smaller, more focused modules?**
  _Cohesion score 0.1422924901185771 - nodes in this community are weakly interconnected._
- **Why does `SQLite Data Model` connect `SQLite Data Model` to `Split Editing & Onboarding`, `Split cycle logic (pointer_position / pointer_since)`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **Should `pubspec.yaml` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Why does `SQLite via sqflite` connect `Split Editing & Onboarding` to `SQLite Data Model`, `Workout & Rest Timer`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._