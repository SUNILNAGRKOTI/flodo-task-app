# Flodo Task App

A clean, performant task management app built with Flutter.
Designed with attention to typography, smooth transitions,
and a polished mobile experience.

---

## Track
Track B — The Mobile Specialist

## Stretch Goal
Persistent Drag-and-Drop Reordering

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter & Dart | UI framework |
| Hive | Local database |
| Flutter Riverpod | State management |
| SharedPreferences | Draft persistence |
| Google Fonts (Inter) | Typography |
| Go Router | Navigation |

---

## Setup Instructions

1. Clone the repository
   git clone https://github.com/SUNILNAGRKOTI/flodo-task-app.git

2. Navigate into the project
   cd flodo-task-app

3. Install dependencies
   flutter pub get

4. Run the app
   flutter run

No backend setup needed.
No API keys required.
Works fully offline on Android.

---

## Features

**Core**
- Create, Read, Update and Delete tasks
- Title, Description, Due Date and Status fields
- Blocked By dependency between tasks
- Blocked cards show greyed out with lock icon
- Automatically unblocks when blocker is marked Done

**UX Details**
- Draft auto-saves on every keystroke
- Draft restores when user reopens creation screen
- 2-second simulated save delay with loading state
- Save button disabled during loading (no double tap)

**Search and Filter**
- Search tasks by title with 300ms debounce
- Filter by status: All, To-Do, In Progress, Done
- Search and filter work simultaneously

**Stretch Goal**
- Drag and drop to reorder tasks
- Custom order saved to Hive database
- Order persists after app restart
- Drag handle visible on each card

---

## Architecture Decisions

**Hive over Isar**
I initially chose Isar for its type-safe querying
and real-time stream support. During Android build,
I encountered a Gradle namespace conflict with
isar_flutter_libs-3.1.0+1. After reading the build
logs and understanding the root cause, I switched
to Hive which has better Android compatibility and
simpler integration without sacrificing any of
the required functionality.

**Riverpod over Provider**
Riverpod offers compile-time safety and does not
depend on BuildContext for accessing providers.
This keeps business logic cleanly separated from
the UI layer and makes the codebase easier to
maintain and scale.

**ReorderableListView switching to ListView**
ReorderableListView requires stable keys and a
consistent item count. When search or filter is
active, items change dynamically which causes
assertion errors. I solved this by switching to
a regular ListView during active search or filter,
and using ReorderableListView only on the full
unfiltered list. Drag reordering priority only
makes sense on the complete task list anyway.

---

## AI Usage

I used Cursor AI and Claude AI during development
as productivity tools.

**Where I used AI**
- Generating initial boilerplate and folder structure
- Getting a starting point for Riverpod provider setup
- Speeding up repetitive UI widget code

**Where AI was wrong and I fixed it**
- AI suggested Isar for the database. This caused
  a Gradle build failure on Android. I read the
  error logs myself, identified the namespace
  conflict, and made the independent decision to
  switch to Hive. AI had not suggested this fix.
- AI generated the list screen using StatefulWidget
  which caused widget disposal crashes when
  switching filters. I diagnosed the issue and
  directed the fix to use ConsumerStatefulWidget
  with Riverpod state instead.

All architectural decisions, bug diagnosis and
final implementation logic were my own.

---

## Repository
https://github.com/SUNILNAGRKOTI/flodo-task-app
