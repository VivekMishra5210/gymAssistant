# Gym Assistant — Build Spec

> **For Claude Code:** This is the source of truth for the app. Build it **phase by phase** (see §13). Finish one phase, run it on the phone, then move on. Don't add features outside this spec unless asked. When a rule here is ambiguous, ask before guessing.

Personal Android app that runs a workout and **enforces consistent rest between sets**. Fully offline. No backend, no login, no internet.

- **Framework:** Flutter (Dart)
- **Database:** SQLite via `sqflite`
- **Target device:** Redmi Note 13 5G (Android, HyperOS/MIUI)
- **Units:** kg

---

## 0. How to use this file

1. Install Flutter (§1) and set up the phone (§2).
2. Create the project: `flutter create gym_assistant` and open the folder in VS Code.
3. Put this file at the project root as `SPEC.md`.
4. Create `CLAUDE.md` at the root with:
   ```
   Read SPEC.md before doing anything. Build one phase at a time from §13.
   After each phase: run `flutter analyze` and `flutter test`, fix all issues, then stop and tell me what to test on the phone.
   ```
5. Prompt Claude Code like: *"Build Phase 1 from SPEC.md."*

---

## 1. Install Flutter on Windows

Official guide (check here if any step differs): https://docs.flutter.dev/get-started/install/windows/mobile

1. **Install Git for Windows**. Flutter needs it. Check with `git --version`.
2. **Install VS Code** + the **Flutter** extension (it installs the Dart extension too).
3. **Get the Flutter SDK.** Either:
   - **Easy way:** VS Code → `Ctrl+Shift+P` → **Flutter: New Project** → it offers to **Download SDK**. Pick a folder like `C:\src\flutter` (**no spaces, not in Program Files**). Let it add Flutter to PATH.
   - **Manual way:** download the SDK zip from the official page, extract it to `C:\src\flutter`, and add `C:\src\flutter\bin` to your user **PATH** environment variable.
4. **Install Android Studio** (you probably have it already). Use it only to install the SDK pieces: **More Actions → SDK Manager**:
   - SDK Platforms: latest Android API
   - SDK Tools: **Android SDK Build-Tools**, **Android SDK Command-line Tools (latest)**, **Android SDK Platform-Tools**
5. Open a **new** terminal and run:
   ```
   flutter --version
   flutter doctor
   flutter doctor --android-licenses     (accept all with y)
   ```
   `flutter doctor` should show ✓ for Flutter, Android toolchain and VS Code. You can ignore Chrome/Visual Studio (Windows desktop) warnings; we're not building for those.

## 2. Phone setup (Redmi Note 13 5G)

1. **Settings → About phone → tap "OS version" 7 times** → developer mode on.
2. **Settings → Additional settings → Developer options**:
   - **USB debugging**: ON
   - **Install via USB**: ON (Xiaomi may require signing in to a Mi account)
   - **USB debugging (Security settings)**: ON
3. Connect with USB → allow the "Allow USB debugging?" prompt on the phone.
4. `flutter devices` should list the phone. `flutter run` installs and launches the app.
5. **After the app is installed** (important for the rest timer):
   - App info → **Battery saver → No restrictions**
   - App info → **Autostart → ON**
   - Allow **Notifications** when the app asks.

---

## 3. What the app does

You train on a **split**: a repeating cycle of days that you define. Each day is either a **Workout** day (a list of exercises) or a **Rest** day. Every user's split can be different:

| User | Cycle |
|---|---|
| 6 on / 1 off | Push · Pull · Legs · Push · Pull · Legs · Rest |
| 5 on / 2 off | Chest · Back · Legs · Shoulders · Arms · Rest · Rest |
| 4 on / 3 off | Upper · Lower · Rest · Upper · Lower · Rest · Rest |

The app always knows **what's next in your cycle**, not what weekday it is. During a workout, it logs every set (weight + reps) and **runs the rest timer automatically** when you tick a set.

### v1 screens
1. **Dashboard:** Today card, streak, calendar
2. **Active Workout:** exercises, set logging, rest timer
3. **Rest-finished popup**
4. **Day Detail:** what you did on a past day
5. **Settings:** split editor, exercises, sets, rest times, streak grace

### Not in v1
BMI calculator, browsable exercise library, charts, PRs, cloud sync, multiple users. (The data model supports adding charts/PRs later.)

---

## 4. Locked decisions

| Topic | Decision |
|---|---|
| Framework | Flutter |
| Split length | Flexible: 1–14 entries, each **Workout** or **Rest**, any order. Must contain ≥1 Workout. |
| Cycle advance | Driven by finished sessions and elapsed rest days, **never by weekday** (§6). |
| Logging | **Weight and reps are mandatory** for every set. Bodyweight exercise → weight 0 allowed. |
| Pre-fill | Each set row is pre-filled with the weight/reps from the **last time this exercise + set number was done**. Tap ✓ to accept. |
| Rest between sets | That exercise's `rest_seconds`. |
| Rest after last set of an exercise | The **next** exercise's `rest_seconds`. |
| After last set of last exercise | No rest; session completes. |
| Duration | From **Start Workout** tap to completion or End Workout. |
| End early | Red **End Workout** button → reason (required) → second confirm → saved as `ended_early`. Split advances. Counts for streak. |
| Streak | Planned rest days never break it. Unplanned misses: survives **1** missed day, breaks at **2** in a row (grace configurable, default 1). |
| Alerts | In-app popup + vibration + sound. Plus a **local** (on-device, offline) notification in case the phone is locked or another app is open. No SMS, no server. |
| History vs plan | History copies names. Editing the plan never rewrites past records. |

---

## 5. Screens & UX

### 5.1 First launch (onboarding)
- No split yet → "Create your split" screen.
- Option A: **Start from template** (6 on/1 off, 5 on/2 off, 4 on/3 off). Creates the entries with placeholder names and no exercises. The user then fills them in.
- Option B: **Start empty.**
- Leads into the Split Editor (§5.5). The cycle pointer starts at entry #1.

### 5.2 Dashboard
Top to bottom:

**Today card**, one of these states:
| State | Shows | Actions |
|---|---|---|
| Workout due | "Day 3 · Back + Biceps", exercise count, total sets, est. time, list of exercises with `sets × rest` | **Start Workout** |
| Workout in progress (app was closed mid-session) | "In progress · 2/4 exercises" | **Resume** |
| Done today | "✓ Done · 1h 12m" + "Next: Legs" | **Start next anyway** (small, secondary) |
| Rest day | "Rest day 😴" + "Next: Legs" | **Train anyway** (skips the remaining rest entries → next workout) |

**Streak row:** 🔥 Current streak · 🏆 Best streak · total workouts.

**Calendar** (month view):
- Workout day: filled dot (green = completed, orange = ended early)
- Planned rest day: hollow/grey dot
- Today: outlined
- Tap a day with data → Day Detail (§5.4)

### 5.3 Active Workout
- Header: workout name, **elapsed time** (live), red **End Workout** button.
- One card per exercise, in order. The current exercise is expanded, the others collapsed with progress ("2/4 sets").
- Set rows:
  ```
  Set 1   [ 60.0 kg  − + ]  [ 10 reps  − + ]   ✓
  Set 2   [ 60.0 kg  − + ]  [ 10 reps  − + ]   ○
  ```
  - Weight step ±2.5 kg, reps step ±1. Tapping the number opens a numeric keyboard.
  - Pre-filled from last time (§4). If there's no history: empty, and ✓ stays disabled until both fields are filled.
  - Tap ✓ → saves the set → starts rest → the next set row becomes active.
  - Long-press a completed set → edit or undo it (undo doesn't restart the timer).
- **Rest timer panel** (sticky at the bottom while resting):
  - Big countdown `1:45`, a progress ring, "Next: Set 3 · Lat Pulldown" or "Next: Barbell Curl".
  - Buttons: **−15s**, **+15s**, **Skip rest**.
  - While resting, set rows can still be edited, but the next ✓ doesn't need to wait for the timer. If ticked early, the timer restarts for the new set.
- Last set of the last exercise ticked → session **completed** → summary sheet (duration, sets done, total volume = Σ weight × reps) → back to Dashboard.
- Keep the screen awake during a workout (`wakelock_plus`), toggleable in Settings.

### 5.4 Rest-finished popup
- Full-screen modal dialog: "Rest over 💪" + "Set 3 of Lat Pulldown" or "Next exercise: Barbell Curl (4 sets)".
- Vibrate on repeat (0.8 s on / 0.4 s off) until **Got it** is tapped. Plus a short sound if Sound is on (§5.7, added in Phase 5).
- One button: **Got it** → dismiss → back to the workout screen.
- If the app was in the background when rest ended, the **local notification** fires instead. Tapping it opens the Active Workout screen, and the popup shows on resume.

### 5.5 End Workout flow
1. Tap **End Workout**.
2. If all sets are done → just finish normally.
3. Otherwise a dialog: "You have N sets left. Why are you ending?" Quick-pick chips: *Short on time · Tired / low energy · Pain / injury · Gym crowded · Other* (+ optional text).
4. Second dialog: "End workout now? This can't be undone." → red **End Workout** / **Keep going**.
5. Save as `ended_early` with the reason. The split advances (§6).

### 5.6 Day Detail
- Date, workout name, status (Completed / Ended early + reason), start–end, duration.
- Each exercise with its sets: `60 kg × 10`, and the time each set was done.
- Total volume.
- Planned rest day → "Rest day".

### 5.7 Settings
- **Split Editor**
  - Ordered list of entries. Add Workout / Add Rest. Drag to reorder. Rename. Delete (block deleting the last Workout entry).
  - Shows which entry is "next up". Action: **Set next up** (manually move the pointer).
  - Tap a Workout entry → **Workout Editor**: list of exercises (drag to reorder), each with `sets` (1–10) and `rest_seconds` (15–600, step 15, shown as mm:ss). Add an exercise by picking an existing one or creating a new one (name, optional muscle group).
- **Exercises:** manage names/muscle groups. Renaming doesn't change history.
- **Streak grace days:** 0–3 (default 1).
- **Keep screen on during workout:** on/off (default on).
- **Sound on rest end:** on/off (default on). **Vibration:** on/off (default on).
- **Default rest for new exercises:** default 90 s.

Editing the plan mid-session doesn't affect the session already running. It uses a snapshot taken at Start Workout.

---

## 6. Split cycle logic

State (in the `app_state` table):
- `pointer_position`: position (1-based) of the next entry in the cycle
- `pointer_since`: the date (yyyy-mm-dd, local) from which the current entry applies

**Advance** = `pointer_position = pointer_position % entry_count + 1`.

### On app open / resume (and at local midnight if the app is open)
```
today = local date
// Catch up rest days that have already passed
while entry(pointer_position).type == REST and pointer_since < today:
    insert rest_day_log(date = pointer_since)        // planned rest, for streak + calendar
    advance()
    pointer_since = pointer_since + 1 day
// If the pointer now sits on a WORKOUT entry whose pointer_since is in the past, set pointer_since = today
```
- Rest entries are consumed **one per calendar day**. Three rest entries in a row = three days of rest.
- A workout entry **never** gets skipped automatically. If you miss days, it waits for you.

### Today card state
```
if a session has status in_progress           → "In progress"
else if a finished session exists for today   → "Done today"
else if entry(pointer).type == REST           → "Rest day"
else                                          → "Workout due"
```

### When a session finishes (completed or ended_early) on date D
```
advance()
pointer_since = D + 1 day
```
So if the next entry is Rest, the rest applies to **tomorrow**, not today.

### "Train anyway" on a rest day
Advance past all consecutive Rest entries to the next Workout entry. Set `pointer_since = today`. **Don't** log rest days for the skipped entries.

### "Start next anyway" after finishing today
Starts a session for the current pointer entry (the next workout). If it's a Rest entry, do the "Train anyway" skip first.

### Editing the split
- Deleting or reordering entries: keep the pointer on the same entry if it still exists. Otherwise clamp the pointer to `min(pointer_position, entry_count)`.
- Changes never touch past sessions.

---

## 7. Rest timer logic

**Rule: store the end time, never trust a running countdown.** Android (especially HyperOS) pauses or kills background apps.

Active rest state (persisted in `app_state` so it survives the app being killed):
- `rest_ends_at`: epoch ms, null if not resting
- `rest_next_label`: e.g. "Set 3 · Lat Pulldown"

Starting rest after ticking set *s* of exercise *e*:
```
if s < e.sets:            duration = e.rest_seconds
elif e is not last:       duration = next_exercise.rest_seconds
else:                     no rest → complete session
rest_ends_at = now + duration
schedule local notification at rest_ends_at (id = 1, replace any existing one)
```
- UI: a `Timer.periodic(1s)` that only **redraws** `remaining = rest_ends_at − now`, clamped at 0.
- When `remaining` hits 0 while the app is in the foreground → cancel the scheduled notification, show the popup (§5.4), vibrate, play sound, clear `rest_ends_at`.
- On resume (`AppLifecycleState.resumed`): if `rest_ends_at` is in the past → show the popup once and clear it. If it's in the future → keep counting.
- −15s / +15s change `rest_ends_at` (min: now) and reschedule the notification. **Skip** clears the rest and cancels the notification.
- Ending or finishing the workout cancels any rest notification.

### Local notification details
- Package: `flutter_local_notifications` + `timezone` (for `zonedSchedule`).
- Android channel "Rest timer", high importance, sound + vibration.
- Android 13+: request `POST_NOTIFICATIONS` at the first Start Workout.
- Exact timing: use exact scheduling (`AndroidScheduleMode.exactAllowWhileIdle`). Android 12+ needs exact-alarm permission. Add `SCHEDULE_EXACT_ALARM` (and/or `USE_EXACT_ALARM`) to the manifest and check/request it. **If it's denied, fall back to inexact scheduling.** The in-app popup still works on resume.
- Follow the package README for the required manifest receivers. Versions change, so check the current docs.

---

## 8. Streak algorithm

Definitions (all in local dates):
- **Workout day:** a date with ≥1 session whose status is `completed` or `ended_early`.
- **Planned rest day:** a date in `rest_day_log`.
- **Covered day** = workout day ∪ planned rest day.
- **Grace** `g` = settings value (default 1).

**Current streak:**
```
streak = 0; misses = 0
d = today
if today is not covered: d = yesterday       // today isn't over yet, so don't penalise it
loop backwards over d:
    if d is a workout day:  streak += 1; misses = 0
    elif d is planned rest: misses = 0        // neutral: doesn't add, doesn't break
    else:                   misses += 1; if misses > g: break
    d = d - 1
    stop when d < first ever session date
```
- The streak counts **workout days** in the unbroken chain.
- **Best streak:** run the same chain logic forward over all history and keep the max. Compute it on load. Don't store it.
- With the default `g = 1`: skip one day → streak survives. Skip two days in a row → streak resets.

Write unit tests for these cases (§14).

---

## 9. Data model (SQLite)

All timestamps are epoch milliseconds (int). All dates are `TEXT 'yyyy-mm-dd'` in local time.

```sql
-- ===== PLAN (configuration) =====
CREATE TABLE split_entry (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  position    INTEGER NOT NULL,            -- 1..N, unique, contiguous
  type        TEXT    NOT NULL CHECK (type IN ('workout','rest')),
  name        TEXT    NOT NULL             -- e.g. 'Back + Biceps' or 'Rest'
);

CREATE TABLE exercise (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL UNIQUE,
  muscle_group  TEXT,
  is_archived   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE plan_exercise (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  split_entry_id  INTEGER NOT NULL REFERENCES split_entry(id) ON DELETE CASCADE,
  exercise_id     INTEGER NOT NULL REFERENCES exercise(id),
  position        INTEGER NOT NULL,
  sets            INTEGER NOT NULL CHECK (sets BETWEEN 1 AND 10),
  rest_seconds    INTEGER NOT NULL CHECK (rest_seconds BETWEEN 15 AND 600)
);

CREATE TABLE app_state (                   -- single row, id = 1
  id                 INTEGER PRIMARY KEY CHECK (id = 1),
  pointer_position   INTEGER NOT NULL DEFAULT 1,
  pointer_since      TEXT    NOT NULL,
  rest_ends_at       INTEGER,              -- null when not resting
  rest_next_label    TEXT,
  streak_grace_days  INTEGER NOT NULL DEFAULT 1,
  keep_screen_on     INTEGER NOT NULL DEFAULT 1,
  sound_on           INTEGER NOT NULL DEFAULT 1,
  vibration_on       INTEGER NOT NULL DEFAULT 1,
  default_rest_sec   INTEGER NOT NULL DEFAULT 90
);

-- ===== HISTORY (what actually happened) =====
CREATE TABLE workout_session (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  date              TEXT    NOT NULL,      -- local date of start
  split_entry_id    INTEGER,               -- may become dangling if entry deleted; don't FK-cascade
  split_entry_name  TEXT    NOT NULL,      -- copied
  started_at        INTEGER NOT NULL,
  ended_at          INTEGER,
  status            TEXT NOT NULL CHECK (status IN ('in_progress','completed','ended_early')),
  end_reason        TEXT
);

CREATE TABLE session_exercise (            -- snapshot of the plan at start
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id       INTEGER NOT NULL REFERENCES workout_session(id) ON DELETE CASCADE,
  exercise_id      INTEGER,
  exercise_name    TEXT    NOT NULL,       -- copied
  position         INTEGER NOT NULL,
  planned_sets     INTEGER NOT NULL,
  rest_seconds     INTEGER NOT NULL
);

CREATE TABLE set_log (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  session_exercise_id  INTEGER NOT NULL REFERENCES session_exercise(id) ON DELETE CASCADE,
  set_number           INTEGER NOT NULL,
  weight_kg            REAL    NOT NULL CHECK (weight_kg >= 0),
  reps                 INTEGER NOT NULL CHECK (reps >= 1),
  completed_at         INTEGER NOT NULL,
  UNIQUE (session_exercise_id, set_number)
);

CREATE TABLE rest_day_log (
  date  TEXT PRIMARY KEY
);

CREATE INDEX idx_session_date ON workout_session(date);
CREATE INDEX idx_setlog_lookup ON set_log(session_exercise_id, set_number);
```

**Pre-fill query** (last weight/reps for exercise X, set N):
```sql
SELECT sl.weight_kg, sl.reps
FROM set_log sl
JOIN session_exercise se ON se.id = sl.session_exercise_id
WHERE se.exercise_id = ? AND sl.set_number = ?
ORDER BY sl.completed_at DESC LIMIT 1;
```
If there's nothing for set N, fall back to that exercise's most recent set of any number.

- Turn on foreign keys: `PRAGMA foreign_keys = ON` in `onConfigure`.
- Use `version` + `onUpgrade` migrations from day one (start at version 1).
- Only one `in_progress` session can exist at a time.

---

## 10. Project structure

```
lib/
  main.dart
  app.dart                     # MaterialApp, theme, routes
  core/
    db/app_database.dart       # open, onCreate, migrations
    time/clock.dart            # injectable "now" for tests
    notifications/rest_notifier.dart
  data/
    models/                    # SplitEntry, Exercise, PlanExercise, Session, SetLog...
    repositories/
      plan_repository.dart
      session_repository.dart
      state_repository.dart
  logic/
    cycle_service.dart         # §6 (pure functions + repo calls)
    rest_timer_controller.dart # §7
    streak_calculator.dart     # §8 (pure, no DB)
    workout_controller.dart    # active session state
  ui/
    dashboard/  workout/  day_detail/  settings/  onboarding/  widgets/
test/
  streak_calculator_test.dart
  cycle_service_test.dart
  rest_timer_test.dart
```
- State management: **`provider`** with `ChangeNotifier`. Keep it simple.
- Put logic in `logic/` and make it **pure/testable**. Inject a `Clock` so tests can control time.

## 11. Packages

| Package | Purpose |
|---|---|
| `sqflite`, `path` | Database |
| `provider` | State management |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | Rest-end notification |
| `permission_handler` | Notification / exact-alarm permission |
| `wakelock_plus` | Keep screen on during a workout |
| `vibration` (or `HapticFeedback`) | Vibrate on rest end |
| `audioplayers` | Short sound on rest end (add `assets/sounds/rest_done.mp3`) |
| `table_calendar` | Calendar on the dashboard |
| `intl` | Date/duration formatting |

Use `flutter pub add <name>` so you get the current versions.

## 12. Android config

- `minSdkVersion`: 21 or whatever the packages require (check `flutter_local_notifications`).
- `AndroidManifest.xml` permissions: `POST_NOTIFICATIONS`, `VIBRATE`, `SCHEDULE_EXACT_ALARM` (and/or `USE_EXACT_ALARM`), `RECEIVE_BOOT_COMPLETED` (if the notification package needs it for scheduled notifications), `WAKE_LOCK`.
- Add the receivers that `flutter_local_notifications` requires (see its README).
- Follow the package's current setup guide for desugaring and the notification icon.
- App name: **Gym Assistant**. Dark theme by default (gym lighting); high-contrast, large tap targets (≥48 dp). The ✓ button and timer should be usable with sweaty thumbs.

---

## 13. Build phases

Each phase ends with something you can run on the phone.

### Phase 1: Workout + rest timer (hardcoded)
- Hardcode one workout in code (e.g. Lat Pulldown 4×120 s, Seated Row 4×120 s, Barbell Curl 4×90 s, Hammer Curl 4×90 s).
- Active Workout screen: set rows with weight/reps (+/−), ✓, rest panel (countdown, −15/+15/Skip), rest-over popup with vibration.
- Rest durations follow §4 exactly. Timer based on end time (§7).
- No DB yet.
- **Done when:** you can go through a whole workout at the gym, lock the phone mid-rest, unlock, and the timer is still correct.

### Phase 2: Database + flexible split
- Create the schema (§9). Seed one split from a template.
- Cycle logic (§6) with `cycle_service` + tests.
- Sessions, session_exercise snapshot, set_log saved live (every ✓ writes to the DB).
- Resume an in-progress session after the app is killed.
- Weight/reps pre-fill from history.
- End Workout flow (§5.5).
- **Done when:** after killing the app mid-workout you can resume, and the next day's Today card shows the next entry.

### Phase 3: Dashboard, calendar, streak, day detail
- Today card with all 4 states.
- Streak calculator (§8) + unit tests.
- Calendar dots + Day Detail screen.
- Rest-day catch-up on open + `rest_day_log`.

### Phase 4: Settings + onboarding
- Onboarding with templates.
- Split Editor (add/remove/reorder Workout & Rest entries, set next up).
- Workout Editor (exercises, sets, rest).
- Exercise management, toggles, grace days.

### Phase 5: Background notification + polish
- Local notification at `rest_ends_at` with exact-alarm handling + fallback.
- Notification tap → opens the workout.
- Sound, wakelock, summary sheet, volume.
- Empty states, edge cases (§14).

### Later (not v1)
Progress charts per exercise, personal records, weekly volume, CSV export/backup, an iOS build to share with friends.

---

## 14. Test checklist

**Unit tests (required):**
- Streak: consecutive days; 1 miss survives; 2 misses break; planned rest days are neutral; today with no workout doesn't break; best streak over history; grace 0 and 2.
- Cycle: advance wraps around; 3 rest entries consume 3 days; returning after 10 days away lands on a workout entry (not skipped past); finish on day D with next = Rest → rest applies to D+1; "Train anyway" skips consecutive rests without logging them; pointer clamp after deleting entries.
- Rest timer: between-sets uses current exercise rest; after last set uses next exercise rest; last set of last exercise → no rest; +15/−15 clamp; resume after the end time → popup once.

**Manual on phone:**
- Lock the phone during rest → notification arrives at the right time.
- Switch to Spotify during rest → notification arrives; open app → popup.
- Kill the app mid-workout → reopen → Resume works, sets intact.
- End Workout with sets left → asks for a reason → confirms → saved as ended early → split advances.
- Change the split mid-cycle → past Day Detail still shows the old names.
- Crossing midnight during a workout → session date = start date.

---

## 15. Additions after v1 (requested 2026-11-10)

- **Stats screen** (dashboard 📊): for this week (Mon–today), this month and all time: total gym time, workouts, avg per workout, avg per day (total ÷ calendar days, rest days included), sets, volume (Σ weight × reps). Only finished sessions count; duration = start → end.
- **BMI screen** (dashboard ⚖): height saved once (`app_state.height_cm`, 50–272 cm); weigh-ins logged to `body_weight(id, date, weight_kg 20–400, logged_at)`. BMI = kg ÷ m², latest weigh-in, WHO categories (<18.5 / <25 / <30 / ≥30). DB version 2 adds these.
- **Reset data** (Settings): choose *History only* (sessions, sets, rest days, weigh-ins) or *Everything* (also split, exercises, height, settings → onboarding). Second confirm; cancels any pending rest notification.
- **Multiple splits** (Settings → Splits): any number of named splits (e.g. College, Exams, Home), one *followed*. Tap a split → its Split Editor. Switching saves the old split's position in `split.pointer_position` and resumes the new one at its saved position from today (no rest days logged for the time away). Can't switch mid-workout or delete the followed split. Dashboard shows the followed split's name. DB version 3: `split(id, name, pointer_position)`, `split_entry.split_id`, `app_state.active_split_id`; existing days become "My split".
- **Exercise progress / PRs** (Settings → Exercises → tap one; or Stats → PRs): best set (heaviest kg, more reps breaks a tie), best estimated 1RM (Epley: kg × (1 + reps/30)), a chart of the heaviest set per session, and the last session's sets. Only finished sessions count.
- **Weight trend** (BMI screen): line chart of weigh-ins with the change since the first one; shown from 2 weigh-ins.
- **Cardio exercises**: an exercise is *Weights* or *Cardio (min)*, chosen when created. A cardio set logs minutes (stepper ±5) in `set_log.reps` with weight 0, so it adds nothing to volume. DB version 4: `exercise.timed`, `session_exercise.timed` (copied at session start).
- **Archive exercises** (Settings → Exercises ⋮): archived ones are hidden from the add-exercise picker; plans and history keep them; Unarchive restores.
- **Backup / restore** (Settings): *Export backup* snapshots the DB (`VACUUM INTO`) and saves it via Android's file picker (Drive, Downloads, …) as `gym-backup-<date>.db`. *Restore backup* picks a file, checks it's a Gym Assistant DB of version ≤ current (older ones are upgraded), replaces the DB and restarts the app. A bad file leaves the current data untouched. No extra packages: a `gym/backup` method channel in `MainActivity`.
- **v1.0.0 release**: own adaptive launcher icon (dumbbell), status-bar notification icon, dark launch screen, release APK signed with the app's own key (`android/key.properties` + `gym-release.jks`, gitignored; falls back to the debug key if missing).
