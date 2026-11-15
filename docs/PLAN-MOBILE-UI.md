# Tsumugi Mobile: Mobile-Native UI Plan

> **Status:** **M1 to M8 done (2026-11-14 and 2026-11-15, with the gaps listed under each phase).** M8's usability script with other people was not run; the device checks below were done by the developer on one phone. Decision D1 was settled on 2026-11-14: **real in-session actions are allowed; the app stays a play-demo with no backend and no online services** (see section 1a).
> **Follows:** [`PLAN-FLUTTER-MOBILE.md`](PLAN-FLUTTER-MOBILE.md), the faithful port of the website demo (all phases done on 2026-11-14).
> **Purpose:** take the app from "the website, rebuilt in Flutter" to "an app that feels made for a phone".
> **Last updated:** 2026-11-14

---

## 1. Why this plan exists

The first plan had one governing rule: stay as close to the website as possible. That gave us a correct, testable port, but it also carried over habits that suit a wide screen with a mouse and are awkward in the hand:

- every page opens with a large static title, a description and a row of buttons, so the first screen of content starts below the fold;
- every record is a bordered card with two or three lines of meta chips, so lists are dense and heavy;
- almost every action ends in a "Preview only" sheet, so the most common thing a person does in a task app (finish a task) cannot be done;
- navigation is tabs-as-underlines, filter popovers turned into sheets, and a command palette turned into a page;
- there is no gesture, haptic, pull-to-refresh, collapsing bar, predictive back, or real dark mode, the things people expect from a phone app without noticing.

This plan keeps what makes Tsumugi *Tsumugi* and changes how it behaves and is laid out on a phone.

### What stays (brand and product)

| Keep | Why |
|---|---|
| Name, logo ("ts" badge and wordmark), Fredoka, the pastel palette, flat colour with ink outlines for selection | Identity |
| The vocabulary: Project, Milestone, Task, Requirement, File, Change; the status labels and tones | Consistency with the website and the data |
| The data model, sample data, fixed demo date, selectors and their parity with the website | Already verified by tests |
| "Why it exists / What it becomes" traceability on every record | The product idea |
| Individual workspace only: no team concepts | Product rule |
| No network, no persistence, no backend, no online services; everything the person does lives in memory and resets on restart | Play-demo rule (see section 1a for what actions may do inside it) |

### What may now differ from the website

Layout, navigation affordances, input methods, density, gestures, feedback, motion, how detail and editing are presented, and the dark theme. The website remains the reference for *meaning*, not for *form*.

### Non-goals

Any backend or online service (APIs, accounts, sync, analytics, crash reporting, cloud storage, push notifications), saving data on the device, iOS-specific styling, a team workspace.

---

## 1a. Play-demo boundary (decision D1, settled 2026-11-14)

Tsumugi Mobile is a **play-demo**: a person can try the app as if it were real, but nothing leaves the phone and nothing outlives the app session.

**Allowed and now planned: real in-session actions.** They change the in-memory session state, show up everywhere immediately (Home, Tasks, calendar, Insights, project pages), can be undone, and are all discarded on restart or when "Reset session data" is used:

- tasks: complete or reopen, change status, reschedule, set priority, block or unblock, edit title and notes, add and tick subtasks, delete (session items and sample items alike, within the session);
- requirements: mark met, mark verified, tick acceptance criteria, link a task;
- files and documents: mark or unmark final, edit a note in the document (in memory), rename;
- changes: mark reviewed;
- projects and milestones: create from a template (already works), edit name, status and dates, mark a milestone done, add a milestone, archive;
- Account preferences (theme, density, haptics, reduced motion, week start) apply immediately for the session.

**Still not available, shown plainly as "Not available in this demo":** adding real files or uploads, downloads, exports, sharing to other apps or people, sign-in or accounts (the demo sign-in screens stay layout-only), sync, notifications, and anything that would need a server.

**Hard rules (enforced by tests):**

1. No networking code or packages, no analytics, no crash reporters, no remote fonts or images. `test/privacy_test.dart` stays and is extended to cover any new dependency.
2. No device storage: no `shared_preferences`, files, databases or secure storage. State lives only in Riverpod providers in memory.
3. No Android permissions in the main manifest (no `INTERNET`, no notifications permission).
4. Every changed record carries or is covered by a clear session notice ("Changes last until you close the app"), shown once per session on first edit and in Account under "Demo data".
5. "Reset session data" restores the original sample data completely, including edits to sample records (the session layer must store overrides on top of the base fixtures, never mutate them).

**Consequences for the codebase:**

- `SessionNotifier` grows from "added records" to a full **overlay**: added records plus per-record overrides and deletions, merged over `fixturesProvider` in `workspaceDataProvider`. `selectors.dart` is unchanged (it reads the merged data), so website-parity tests keep passing against the pristine fixtures.
- A small **undo stack** (last 20 actions) feeds the "Undo" snackbar.
- `PreviewAction` and `showPreviewSheet` remain only for the unavailable items above, with the wording changed from "Preview only" to "Not available in this demo".
- The Help guide, the website-parity note in `CONTEXT.md` and the sample-data notes are updated when M2 lands.

---

## 2. Mobile principles

Ten principles, each as "web habit we carried over → what a phone wants instead". They drive every decision below.

| # | Principle | Web habit now in the app | Mobile-native replacement |
|---|---|---|---|
| 1 | **Content first, chrome second** | Big title + description + buttons on every page | Collapsing large title that shrinks into the app bar; description only where it helps; page actions in the bar or a bottom action |
| 2 | **Thumb zone** | Actions at the top of sheets and pages (Edit, Change status) | Primary actions in the bottom third: sticky bottom action bar in detail sheets, FAB-style add, bottom-anchored search on long lists |
| 3 | **Direct manipulation** | "Change status" button opens a sheet | Tap the status circle to complete; swipe a row to complete or defer; drag to reorder where order matters |
| 4 | **Glanceable lists** | Every row repeats project, milestone, subtasks, flags and due date | Two-line rows: title and one meaningful secondary line; the rest moves into the detail sheet; group headers carry shared context (project, day) |
| 5 | **Native input** | Typed syntax (`#garden tomorrow !`) is the only way to set project, date, priority | Typed syntax stays as a shortcut, but every field is also a tappable chip that opens a picker (date picker, project list, priority toggle) |
| 6 | **Feedback you can feel** | Silent state changes | Haptics on completion, selection and errors; undo snackbars instead of confirm dialogs; subtle motion that explains cause and effect |
| 7 | **One-hand, interruptible, resumable** | Modal dialogs, forms that lose state | Bottom sheets that keep their draft, predictive back that previews where back goes, state restored when returning |
| 8 | **Respect the system** | Own look only | Edge-to-edge with correct insets, system dark mode, dynamic text size, system back gesture, platform scroll physics, share sheet and app shortcuts where they fit |
| 9 | **Short paths for frequent tasks** | Add a task = tap +, type a line, tap Add, tap Close (4 steps) | Add a task in one gesture and one line, keep the sheet ready for the next; "done" in one tap; "what's next" visible on open |
| 10 | **Calm by default, rich on demand** | Everything visible at once | Progressive disclosure: summaries first, detail on tap or long-press, advanced filters behind one button |

---

## 3. Audit of the current app

Findings against the principles, with where they live. Severity: **H** hurts daily use, **M** noticeable, **L** polish.

### Structure and navigation

| # | Finding | Where | Sev |
|---|---|---|---|
| A1 | Every screen is a plain `ListView` under a fixed app bar; no collapsing bar, so the big page title scrolls away and the app bar shows only the logo | all `features/*/*_screen.dart`, `app_shell.dart` | H |
| A2 | App bar shows the logo on every tab; it carries no context (which tab am I on?) and wastes the most valuable pixels | `app_shell.dart` | M |
| A3 | Section switching uses underlined text tabs (web style); no swipe between Today, Upcoming, Calendar, All | `ViewTabs`, `tasks_screen.dart`, `project_screen.dart` | M |
| A4 | Search is a separate page behind an icon; no in-context search with live results, no recent searches | `search_screen.dart` | M |
| A5 | Insights is hidden in the account sheet although it is one of five destinations | `account_sheet.dart` | L |
| A6 | No predictive back or back-stack awareness beyond go_router defaults; the bottom bar does not hide on scroll | router, shell | M |

### Lists and records

| # | Finding | Where | Sev |
|---|---|---|---|
| B1 | Rows are bordered cards with up to six chips (project, milestone, subtask count, session tag, blocked, priority, due); at 360 dp a task row is three to four lines | `records.dart` `TaskRow` | H |
| B2 | Status is an icon on the left that cannot be tapped; completing a task needs row → sheet → Change status → "Preview only" | `TaskRow`, `record_sheets.dart` | H |
| B3 | No swipe actions, no long-press menu, no multi-select | all lists | H |
| B4 | Long lists are built eagerly (`ListView(children: [...])`, `Column` of all rows) instead of lazily with slivers; fine with 15 tasks, a problem with 150 | `tasks_screen.dart`, `library_screen.dart`, `projects_screen.dart` | M |
| B5 | Group headers (Overdue, Today, In progress) scroll away; no sticky headers; no counts | `tasks_screen.dart` | M |
| B6 | No pull-to-refresh, no scroll-to-top on tab re-tap | all tabs | L |

### Input and editing

| # | Finding | Where | Sev |
|---|---|---|---|
| C1 | Quick add depends on typed syntax; project, date and priority cannot be set by tapping | `quick_add_sheet.dart` | H |
| C2 | Edit task, Edit project, Add file and similar actions all open the same "Preview only" sheet, so nothing can be edited at all | `preview_sheet.dart` and callers | H |
| C3 | Filters open a tall chip sheet; the active filters are not visible on the list afterwards | `filters.dart`, list screens | M |
| C4 | Dates are shown but never picked with a date picker | Quick add, task details | M |
| C5 | Keyboard handling is basic (sheet moves up); no `textInputAction` chains, no auto-scroll of the focused field in long forms (Account, Register) | forms | L |

### Visuals and feel

| # | Finding | Where | Sev |
|---|---|---|---|
| D1 | Light theme only; most phones run dark mode for much of the day; the scaffold exists but widgets use fixed colours | `tokens.dart`, pills, banners | H |
| D2 | Heavy Fredoka bold everywhere, including row titles and numbers; hierarchy between title, body and meta is weaker than it could be | theme text styles | M |
| D3 | Every surface has a 1 px border and a 14 to 20 px radius; with many cards on screen the page looks boxed | `RowCard`, cards | M |
| D4 | No haptics, no sounds, no motion on state change (a task completing just changes an icon), no shared-element transitions from a row to its detail | all | M |
| D5 | Not edge-to-edge: system bars are the default colour; no styled status/navigation bar icons per theme | `main.dart`, theme | M |
| D6 | Empty and error states are text-only; no illustration or friendly next step beyond a button | `states.dart` | L |

### Content and flow

| # | Finding | Where | Sev |
|---|---|---|---|
| E1 | Home opens with three number tiles before any task; the question "what do I do now?" is answered third | `home_screen.dart` | M |
| E2 | Project page header (title, description, two badges, Edit button, tabs) takes about 60% of a 360 x 640 screen before content | `project_screen.dart` | H |
| E3 | The calendar is a full month grid plus an agenda; good for planning, heavy for "what is today?" | `calendar_view.dart` | L |
| E4 | Welcome is a scrolling marketing page; a phone app usually goes straight to content, with a short first-run | `welcome_screen.dart` | L |

---

## 4. Design direction

### 4.1 Layout system

- **Grid:** 4 dp base, 16 dp gutters, 8 / 12 / 16 / 24 / 32 spacing (unchanged), content max width 600 dp on large phones and tablets, centred.
- **Thumb map:** top band (0 to 20%) is for orientation only (title, back, search); the middle is content; the bottom 25% is for primary actions and navigation. Nothing that must be tapped often lives in the top band except back.
- **Edge-to-edge:** draw behind the system bars, pad content with `MediaQuery.viewPadding`, use `SystemUiOverlayStyle` per theme, gesture-navigation friendly bottom insets.
- **Density:** one density for lists (two-line rows, 56 to 64 dp), one for the dock/tablet. The unused "Comfortable/Compact" Account preference becomes real (see M6).

### 4.2 Typography (mobile hierarchy)

Keep Fredoka as the brand voice but use weight deliberately:

| Role | Style | Use |
|---|---|---|
| Display | Fredoka 700, 32 / 36, collapses to 20 | Large page title |
| Title | Fredoka 600 (or 700 where 600 is not bundled), 20 | Section and sheet titles |
| Row title | Fredoka **500**, 16 | List row titles (today bold, which reads heavy) |
| Body | Fredoka 400, 15 to 16 | Paragraphs, notes |
| Meta | Fredoka 400, 12 to 13, muted | Secondary lines |
| Number | Fredoka 700, tabular figures if available | Stats |

Action: bundle Fredoka 500 and 600 (same OFL source as today, converted with `tool/woff_to_ttf.mjs`), and define the scale once in `theme.dart`. All sizes still respect system text scale up to 200%.

### 4.2b Colour and surfaces

- Keep the palette; add **semantic roles** (`surface`, `surfaceRaised`, `onSurface`, `onSurfaceMuted`, `accent`, `accentContainer`, `outline`, `success/warning/danger` pairs) so a dark palette can be swapped in. Move every hard-coded colour (status tones, banners, diff colours, project tints) into tokens with light and dark values.
- Surfaces: lists sit on the canvas **without per-row borders**; rows are separated by whitespace and thin dividers inset to the text. Cards (borders) are reserved for things that are objects in their own right: project cards, insight cards, empty states.
- Selection still uses the ink outline (brand), but only for selected items and focused controls.

### 4.3 Components to replace or add

| Today | Replace with | Notes |
|---|---|---|
| `PageHeader` + fixed `AppBar` | `LargeTitleScaffold` (a `CustomScrollView` with `SliverAppBar.large`-style collapsing title, optional search, optional pinned tab bar) | One scaffold for every top-level screen |
| `ViewTabs` underlined tabs | Pinned `TabBar` inside the sliver, with a `TabBarView` for swipe between views | Keeps state per tab (`AutomaticKeepAliveClientMixin`) |
| `SegmentedToggle` | Material 3 `SegmentedButton` styled with brand tokens | Native feel, 48 dp |
| `RowCard` list rows | `TaskTile` / `FileTile` / `ProjectTile` list tiles: leading control, title, one secondary line, trailing meta | See 6.2 |
| `FilterField` chip sheet | Filter bar of chips **above** the list (active filters visible and removable) plus a "More filters" sheet | Also a "Clear" chip |
| `PreviewAction` buttons | Real in-session actions (D1 below) or a clear inline "Not available in the demo" tooltip for the rest | |
| Quick add sheet | `QuickAddSheet` v2 with picker chips and keyboard accessory row | See 6.3 |
| Detail bottom sheet with top buttons | Detail sheet with sticky bottom action bar and a drag handle that doubles as a collapse control | See 6.4 |
| Command palette page | `SearchAnchor`-style search: tap the bar, results fill the screen with suggestions and recents | |
| Spinner/skeleton rows | Shimmer-free skeletons that match the real row shape | Already close; align shapes |

---

## 5. Navigation and structure

1. **Bottom navigation:** keep four destinations plus a central add button, but use the Material 3 navigation bar behaviour: badges (overdue count on Tasks), label always visible, hide on scroll down and reveal on scroll up for long lists, re-tap scrolls to top.
2. **Top bar:** shows the **screen title** (collapsing), not the logo. The logo moves to Welcome, the account sheet header and the launch screen. Search icon stays; account button becomes an avatar.
3. **Insights:** becomes part of Home (an "At a glance" section that opens a full Insights page) rather than hidden in a menu. The fifth destination remains on tablets.
4. **Swipe between sibling views** (Tasks: Today / Upcoming / Calendar / All; Project: Overview / Work / Specs / Files / History) with `TabBarView`; the pinned tab bar follows.
5. **Predictive back** (Android 14+): opt in (`android:enableOnBackInvokedCallback`), use `PopScope` where a sheet or draft is open, and make go_router transitions compatible (shared-axis for push/pop, fade-through for tab switches).
6. **Deep links and state:** keep the query-parameter state model (it works well). Add restoration (`RestorationMixin`) for scroll positions and the selected tab per branch so process death returns the person to where they were.

---

## 6. Screen-by-screen redesign

### 6.1 Home: "What do I do now?"

> **Superseded in part (2026-11-15, [PLAN-UX.md](PLAN-UX.md) section 5.5):** Home now leads with one headline and figures line instead of stat chips, has no carousel and no Recent list, and tiles are two lines. The list below is the original M4 design.

- Collapsing title "Today" with the date underneath (a person-relevant title instead of "Home").
- **First block: Up now.** The top three tasks (overdue first, then due today, then in progress) as large tappable tiles with a one-tap complete control. A "See all N" link when more.
- **Second block: At a glance.** One horizontally scrolling row of compact stat chips (Due today, Overdue, In progress) that act as filters into Tasks; Insights link at the end.
- **Third block: Continue.** The most recently opened project as a wide card with its next milestone and progress; "Your projects" as a horizontal carousel.
- **Fourth block: Recent.** Compact list.
- Pull to refresh (demo: replays a subtle "up to date" feedback and re-reads sample data).
- First-run: replaces the checklist with a three-card carousel and a single primary "Start a project" button.

### 6.2 Tasks: the daily driver

**Row anatomy (new `TaskTile`):**

```
( ) Title of the task                         Today   ⋮
    Project Garden · Chapter one review   ▮ High
```

- Leading **status control** (circle): tap = complete with a satisfying check animation and a light haptic; long-press = pick status (To do / Doing / Done).
- Title (one line, wraps to two when needed), strikethrough and muted when done.
- Secondary line: project (shown only when the list mixes projects), milestone if useful. Subtask progress as a tiny ring on the right, not a text chip.
- Trailing: due label as plain text (red text and icon when overdue; no pill), priority as a small coloured bar on the left edge plus the arrow glyph (never colour alone).
- **Swipe right:** complete. **Swipe left:** reveal "Tomorrow" and "Pick date". Both undoable via snackbar.
- **Long-press:** context menu (Edit, Move to tomorrow, Block, Open project, Delete in session).
- Tap opens the detail sheet.

**List behaviour:** sliver list with **sticky group headers** showing counts ("Overdue 2"); lazy building; items animate in and out on change (`AnimatedList` or `SliverAnimatedList`); a floating "Add" stays in the bottom bar.

**Views:** Today / Upcoming / Calendar / All as swipeable tabs. Board mode on phones becomes a horizontal pager of three status columns with snap, not a wide scrolling row.

**Filters:** a horizontal filter chip row under the title (Project, Priority, Status as dropdown chips that open small menus), active filters highlighted and removable with one tap; "More" opens the sheet. Search lives in the collapsing bar (a pill that expands on tap).

**Calendar:** week strip by default (seven days, swipe by week, tap a day) with the agenda below; a toggle expands to the month grid. Day dots become count badges; overdue days get an outline. Swiping the agenda horizontally moves day by day.

### 6.3 Quick add v2

Goal: add a task in one hand, one line, two taps for extras.

- Opens focused with the keyboard up. Single line field, then a **chip row that is also the picker row**: Project, Date, Priority, (optional) Milestone. Each chip shows the detected or default value and opens the right picker: project list sheet, `showDatePicker` plus quick options (Today, Tomorrow, Next week), priority toggle.
- Typed syntax (`#garden`, `tomorrow`, `!`) still fills the chips live and is explained once on first use (a dismissible tip), then hidden.
- Primary button "Add" sits **above the keyboard** (a keyboard accessory bar) and the keyboard "done" key also adds. The sheet stays open for the next task with a confirmation line and a haptic tick; "Done" closes.
- Remembers the last used project for the session; long-press the central + for a menu: New task, New project, New note (demo previews).
- Draft survives a back press (confirm only when text exists).

### 6.4 Detail sheet (task, milestone, requirement, file, change)

- Drag handle and a visible **expand** affordance (half sheet, full sheet).
- **Sticky bottom action bar** with the primary action (Complete / Mark met / Open / Open comparison) and an overflow for the rest; edit controls inline.
- Content order: title, status control, due/priority, notes, subtasks as a checklist (tap to tick), then "Why it exists / What it becomes" as a collapsible card with chips, then history.
- Shared-element feel: the tapped row's title animates into the sheet title (Hero or `OpenContainer`-style container transform).
- On tablets the docked panel keeps the same content and actions.

### 6.5 Projects and the project page

- **Projects list:** two-column grid on wider phones, single column on narrow; cards simplified to name, status dot-and-label, progress ring and next milestone date; tint kept subtle. A "Timeline" toggle becomes a view switch in the app bar.
- **Project page:** `SliverAppBar` with a tinted flexible space showing name, status and progress ring; collapses to a compact bar; the five tabs pin beneath it. The description moves into Overview. Edit moves to an overflow menu.
- **Overview:** next milestone card first, then the phase stepper (horizontal, current phase centred), then numbers, then recent changes.
- **Work:** milestone sections with sticky headers and collapse; tasks use `TaskTile`; "Add task to this milestone" row at the bottom of each section.
- **Specs:** requirement rows show a small coverage ring (criteria met) instead of text; tapping opens the sheet with the traceability chain drawn as a vertical connected timeline (objective to requirement to tasks to files).
- **History:** a vertical timeline with day headers; diff opens full screen with a side-by-side toggle on tablets and inline unified view on phones.

### 6.6 Library and the reader

- Library: segmented filter chips by kind (All, Documents, Images, Media, Data, Links), a grid with real thumbnails where possible (image kinds draw a placeholder swatch), list mode with leading thumb. Long-press to select multiple (demo: batch "Mark final" preview). Sticky search.
- **Reader:** reading-first: collapsing title, reading progress indicator, adjustable text size (A−/A+), a floating "Outline" button opening a bottom sheet of sections instead of an inline accordion, link chips collected at the bottom. Source mode uses a monospace view with line numbers and horizontal scroll.

### 6.7 Search

Tap the search pill (in any collapsing bar or the top-bar icon) to open a full-screen search with **recent searches**, **suggestions by type** (Tasks, Projects, Files, Actions), filter chips (All, Tasks, Projects, Files), highlighted matches, and results grouped with counts. Results open in place (sheets or pages) without losing the query. Voice input affordance is out of scope.

### 6.8 Insights

Cards become **glanceable visuals**: a progress ring, a coverage ring, an overdue count with a mini list. Each card taps through to the matching filtered list. Per-project breakdown as horizontal bars. Definitions behind an info button (bottom sheet), not an always-visible section.

### 6.9 Account and settings

Native settings pattern: grouped list with leading icons, switches and value rows that open pickers; the preferences become real within the session (theme: System / Light / Dark; text size preview; density; reduce motion; haptics on/off; week start affects the calendar). A "Demo data" group holds Reset session data and the developer toggle. Edited/Reset banner is replaced by immediate apply.

### 6.10 Welcome and sign-in

- App opens straight to **Home** after the first run; Welcome becomes a three-step onboarding carousel (the six-step thread condensed to three screens) shown once per session with Skip.
- Sign-in screens keep their designed states but use native patterns: autofill hints, password visibility, `textInputAction` chains, keyboard-aware scrolling, and a sticky primary button above the keyboard.

---

## 7. Interaction layer

### 7.1 Gestures

| Gesture | Where | Result |
|---|---|---|
| Tap status circle | Task rows, subtasks | Complete / un-complete |
| Swipe right / left | Task rows | Complete / schedule |
| Long-press | Rows, central + | Context menu / add menu |
| Swipe between tabs | Tasks, Project | Change view |
| Pull down | Tab roots | Refresh feedback |
| Drag handle | Sheets | Expand, collapse, dismiss |
| Edge swipe | Anywhere | Predictive back |

All gestures have a visible, accessible equivalent (button or menu) so nothing is gesture-only.

### 7.2 Haptics (`HapticFeedback`)

Light tick on selection, medium on completing a task, success pattern when the day's last overdue task is done, error pattern on invalid input. A single `Feedback` service wraps these and honours the Account "Haptics" switch and the system setting.

### 7.3 Feedback and undo

- Replace "Preview only" interruptions with in-context feedback: snackbar with **Undo** for complete, reschedule, delete; inline "Not available in the demo" for the genuinely unbuilt (file upload, account).
- Optimistic UI: changes apply immediately to the session state.
- Empty-state celebrations: all tasks done today gets a small, calm confirmation (not confetti).

### 7.4 Motion spec

| Motion | Duration | Curve | Notes |
|---|---|---|---|
| Row complete (check draw, strike, fade to group end) | 220 ms | ease-out-cubic | Haptic at start |
| List item insert/remove | 200 ms | ease-in-out | `SliverAnimatedList` |
| Shared-element row to sheet | 300 ms | emphasized | Falls back to fade |
| Tab switch (swipe) | system | system | Physics-driven |
| Collapsing bar | scroll-linked | linear | No time-based animation |
| Sheet expand | 250 ms | emphasized decelerate | |

All motion is skipped when system animations are disabled (the infrastructure already exists in `motion.dart`); the Account "Reduce motion" switch becomes real.

### 7.5 Keyboard and forms

`textInputAction` chains, `autofillHints`, `FocusTraversalGroup`, scroll the focused field above the keyboard, sticky submit above the keyboard, `TextInputType` per field, no auto-capitalisation for emails.

---

## 8. Visual system updates

1. **Real dark mode** (D1): semantic colour tokens, dark palette for every surface, pills and diff colours; status colours re-tuned for contrast; system theme follows the device, Account can override; goldens for both themes.
2. **Elevation vs outline:** replace most borders with tonal surfaces (one step lighter or darker than the canvas) in both themes; keep outlines for selection and focus.
3. **Iconography:** keep Lucide; use filled/duotone variants only for the selected navigation item; 24 dp icons, 20 dp inline; consistent stroke weight.
4. **Illustrations:** three small flat illustrations in the brand palette (empty tasks, empty library, error) drawn with `CustomPainter` or SVG so they scale and tint for dark mode.
5. **Dynamic type:** test every screen at 100, 130, 160 and 200%; rows may grow, chips wrap, nothing truncates silently.
6. **Large screens:** keep the existing 840 dp rail and docked panel; add a two-column Home and a three-pane Projects (list, project, detail) at 1200 dp.
7. **Material You:** optional "Use device colours" switch in Account (dynamic colour for accents only, brand surfaces stay). Off by default so the brand stays recognisable.

---

## 9. Platform integration (Android first)

| Item | Plan | Frontend-only? |
|---|---|---|
| Edge-to-edge and system bar styling | `SystemChrome.setEnabledSystemUIMode(edgeToEdge)`, per-theme overlay style | Yes |
| Predictive back | Manifest flag, `PopScope`, compatible transitions | Yes |
| App shortcuts (long-press launcher icon: Add task, Today) | Static shortcuts via `quick_actions` | Yes (opens routes) |
| Share sheet | Not included (play-demo: nothing leaves the phone) | Out of scope, decision D4 |
| Home-screen widget (Today) | Native Glance widget showing sample data | Out of scope for now; listed for the future |
| Notifications / reminders | Not in scope (needs permission and a backend story) | No |
| Haptics | `HapticFeedback` (no permission needed) | Yes |
| Locale and 24 h time | Use `MaterialLocalizations` for date formats where a picker is shown | Yes |

---

## 10. Content and microcopy

- Titles name the screen or the person's intent ("Today", "Plan", "Library") rather than the data type.
- Replace "Preview only. Nothing is saved or sent anywhere." with context-specific inline messages.
- Buttons use verbs ("Add task", "Mark done", "Open comparison"). Remove "Edit project"-style buttons that do nothing; replace with real actions or hide them.
- Empty states say what the screen is for, what to do next, and offer exactly one primary action.
- Dates: "Today", "Tomorrow", weekday names within a week, otherwise "14 Nov"; always with a text alternative for screen readers.

---

## 11. Accessibility for the new patterns

- Every gesture has an accessible custom action (`Semantics.customSemanticsActions`) for complete, schedule, delete.
- Status circle exposes "Task, not done, double tap to complete".
- Collapsing bars keep the title reachable by screen reader at any scroll offset.
- Swipe actions announce their result through a polite live region and the undo snackbar is reachable.
- Targets stay at least 48 dp including the new tiles and chips; text contrast re-checked in dark mode; reduced motion removes shared-element and check animations.
- Re-run `accessibility_test.dart` and add dark-theme and 160% text variants.

---

## 12. Performance

- Convert all long lists to `SliverList.builder` / `ListView.builder` with `itemExtent` or `prototypeItem` where rows are uniform.
- Keep selectors cheap and memoised (Riverpod `select`); avoid rebuilding whole lists when one task changes (family providers per task id).
- Pre-warm shaders for the collapsing bar and sheets (profile on a mid-range device).
- Budget: first frame under 700 ms cold start on a mid-range device, 60 fps scrolling with 500 sample tasks (add a synthetic data generator for benchmarking only).

---

## 13. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| D1 | **Settled (2026-11-14): yes.** Real in-session actions are allowed. The app is a play-demo: no backend, no online services, nothing saved. See section 1a for the boundary, the allowed actions and the hard rules. | Done |
| D2 | Replace the logo in the app bar with screen titles? | Yes (keep the logo on Welcome, launch and account header). |
| D3 | Make Home the first screen (skip Welcome) after the first run? | Yes; Welcome becomes a short onboarding shown once per session. |
| D4 | Add `share_plus` and `quick_actions`? | `quick_actions` yes (no network, no permission). **Skip `share_plus`**: with the play-demo rule, sharing is listed as not available. |
| D5 | Bundle Fredoka 500 and 600? | Yes (+ about 70 KB). |
| D6 | Dark mode default: follow system? | Yes, with an override in Account. |
| D7 | Keep tablet docked panel as is? | Yes. |

---

## 14. Phased delivery

Each phase leaves the app shippable, tests green, goldens updated for both themes once M5 lands. Sizes: S about half a day, M 1 to 2 days, L 3+ days.

### M1: Foundations for a mobile-native shell (M)

- Token refactor to **semantic colours** with light and dark values; move all hard-coded colours into tokens.
- Edge-to-edge, system bar styling, predictive back opt-in, `PopScope` on sheets and drafts.
- `LargeTitleScaffold` (collapsing bar, optional pinned tabs, optional search pill) with scroll-linked collapse and restoration of scroll position.
- Bundle Fredoka 500 and 600; new type scale in `theme.dart`.
- **Done when:** one screen (Tasks) uses the scaffold; analyzer and tests green; goldens updated.
- **Status: done on 2026-11-14.** Delivered: semantic roles and a full dark palette in `AppTokens` (all literal colours moved out of widgets, enforced by a test); Fredoka 500 and 600 bundled and the mobile type scale in `theme.dart`; edge-to-edge with transparent system bars and per-theme icon colours; predictive back opted in (manifest); draft protection with `PopScope` on Quick add and New project; `LargeTitleScaffold` (collapsing 32 sp to 20 sp title, pinned view tabs, pull-to-refresh, scroll-position restoration) adopted by Tasks, whose shell bar now shows no logo. Notes: the large title is one `FlexibleSpaceBar` text scaled 1.6x (the stock `SliverAppBar.large` ignored our type scale); the Tasks subtitle was dropped as planned; the app still ships the light theme (dark is M5); `LargeTitleScaffold` is used by Tasks only, other screens adopt it in M4 and M6.

### M2: The task tile and lists (L)

- `TaskTile` with tappable status circle, simplified meta, swipe actions, long-press menu, sticky group headers, animated insert/remove; lazy slivers for Tasks, Library, Projects.
- Feedback service (haptics, snackbar with undo); the **session overlay** and undo stack described in section 1a (overrides and deletions on top of the pristine fixtures), with the in-session actions listed there starting with complete, status, reschedule, block, edit text and delete.
- **Done when:** a person can complete, reschedule and undo a task in one gesture from Today; widget tests cover each action and undo; accessibility custom actions exist.
- **Status: done on 2026-11-14.** Delivered: `TaskTile` (tappable status circle, simplified meta, swipe right to complete or reopen, swipe left to move to tomorrow, long-press menu, hairline dividers, 48 dp targets, custom accessibility actions for complete, tomorrow, block, more and delete); the session overlay with an undo stack of 20 (complete, status, reschedule, priority, block, edit text, subtasks, delete); haptics behind `AppFeedback`; an overlay `UndoToast` that shows above sheets; `TaskPanel` actions are real (Mark done or Reopen, Edit task, Change status, Mark blocked, tappable subtasks); Tasks is lazy slivers with pinned group headers and counts, plus a "Done this session" group in Today. Notes: undo never reverts more than the latest action; actions capture the session and overlay up front because a task that changes group unmounts the tile that started the action (this caused two real bugs found by the tests: Undo and Save used a disposed widget's `ref`); the session notifier looks tasks up in the fixtures and its own overlay, not in `workspaceDataProvider`, to avoid a circular provider dependency. **Not done:** animated insert/remove of tiles (tiles move group without animation; the circle and check animate), lazy slivers for Library and Projects (still box lists), the Calendar and Board views are still boxed (not lazy).

### M3: Quick add v2 and pickers (M)

- Picker chips, date picker, project picker, keyboard accessory Add button, draft preservation, long-press menu on the add button.
- **Done when:** adding a task with project, date and priority takes at most two taps beyond typing; the typed syntax still works; tests updated.
- **Status: done on 2026-11-14.** Delivered: the detail chips are now 48 dp buttons (project list sheet; date sheet with Today, Tomorrow, Next week, Pick a date with the system date picker, No date; priority toggle); a tapped chip wins over the typed line; the project carries over to the next task and to the next sheet this session; the typed-syntax hint became a one-time tip with "Got it"; Add task sits at the bottom of the sheet, which rises above the keyboard, and the keyboard's done key also adds; a light haptic on add; long-press on the + button opens New task, New project and New note (a preview). Draft protection from M1 is unchanged. Not done: the optional Milestone chip, and the long-press menu is on the phone bottom bar only (not the tablet rail).

### M4: Home, navigation and search (M)

- Home redesign (Up now, At a glance, Continue, Recent), titles instead of logo, nav bar badges and hide-on-scroll, swipeable tab views, Search v2 with recents and type chips, Insights entry from Home.
- **Done when:** Home answers "what now" in the first viewport on a 360 x 640 screen; tests and goldens updated.
- **Status: done on 2026-11-14, partly.** Delivered: Home has an "At a glance" row of tappable chips (Due today, Overdue, In progress, Insights), "Up now" with the top three tasks as `TaskTile`s and an "All tasks (N)" link, a "Continue" card (latest project, next milestone, progress), a horizontal project carousel, Up next and Recent, and pull to refresh; the Tasks tab shows an overdue badge (spoken as "Tasks, 2 overdue"); Search has type chips (All, Tasks, Projects, Files, Actions), task results, group counts and session-only recent searches. **Not done:** swipeable tab views (TabBarView), hide-on-scroll for the bottom bar, scroll-to-top on re-tapping a tab, match highlighting in search, and the Home title still sits under the logo bar (it keeps "Home" so existing screens and tests are unchanged).

### M5: Dark mode and visual polish (L)

- Real dark palette across all widgets, tonal surfaces instead of borders, illustrations for empty/error states, shared-element row to sheet transition, new motion spec, system theme follow plus Account override, dark goldens and contrast tests.
- **Done when:** every screen passes accessibility and golden tests in both themes at 100% and 160% text.
- **Status: done on 2026-11-14, partly.** Delivered: the dark theme is on, following the device by default with a System, Light or Dark choice in Account (`preferencesProvider`); text size (Small to Largest) and Reduce motion apply on top of the device settings; every route (25) passes the tap-target, label and contrast guidelines in dark at 100% and 160% text with no layout errors; four dark goldens (home, tasks, project, library). Real layout bugs found at 160% and fixed: section headers with a long action, due-date pills in rows. **Not done:** tonal surfaces instead of borders, the three illustrations, the shared-element row-to-sheet transition and the new motion spec, "use device colours", dark goldens beyond four screens.

### M6: Project, Library, reader and settings (L)

- Project page collapsing header with pinned tabs, requirement coverage rings and the vertical traceability timeline, week-strip calendar, reader upgrades (progress, text size, outline sheet), native settings page with real preferences.
- **Done when:** the project page shows content within the first 40% of a 360 x 640 screen; preferences take effect immediately.
- **Status: done on 2026-11-14, partly.** Delivered: the project page is a collapsing large-title page with a back button and the five tabs pinned (the shell's logo bar is hidden there); the reader has a reading-progress bar, A- and A+ text size for the document, an "Outline" button that opens a bottom sheet and jumps to a section, and a Source view with line numbers and sideways scrolling; Account is a settings page with theme, text size, reduce motion, week start (changes the Calendar), vibration feedback, Reset preferences and Reset session data, all applying at once (density and reminders were dropped: density would shrink touch targets and reminders need notifications). **Not done:** requirement coverage rings, the vertical traceability timeline, the week-strip calendar, the project page's tinted header, lazy Projects and Library lists.

### M7: Platform extras and performance (M)

- App shortcuts, optional share, restoration across process death, synthetic-data benchmark, profile and fix jank, tablet three-pane at 1200 dp.
- **Done when:** the benchmark meets the budgets in section 12; release APK and manifest re-checked.
- **Status: done on 2026-11-15, partly.** Delivered: launcher shortcuts Add task, Today and Search (static `shortcuts.xml` plus `tsumugi://` links, no package and no permission; `/add` opens Home with Quick add); Android 12+ system splash in light and dark; a larger launcher icon (badge 650 of 1024 px with larger "ts" letters); the Undo message stays readable in dark mode; a 500-task test shows the Tasks list builds under 40 rows and scrolls without errors; the overdue icon stays beside its text when the text wraps. **Measured on a Galaxy A05s (Android 15, release build):** cold start 517 to 677 ms (budget 700); scrolling Tasks median 11 ms per frame on a 90 Hz screen, 95th percentile 22 ms, no frame over 25 ms; memory about 115 MB PSS. **Not done:** lazy Projects and Library lists (the sample lists have about 20 rows, so there is nothing to gain; Tasks is the list that can grow), animated tile insert and remove, themed (monochrome) icon, restoration of the selected tab, the three-pane layout at 1200 dp, share (excluded by decision D4).

### M8: Validation and docs (M)

- Run the usability script (below) with real people on a real device; fix the top findings; update `CONTEXT.md`, `CODEMAP.md`, `LOG.md`, Help guide and the first plan's status; record before/after metrics.
- **Status: done on 2026-11-15, partly.** Run on a real phone (Samsung Galaxy A05s, Android 15) in dark, light and 1.5x system font: Welcome to Home, complete a task with Undo, Quick add opened through the Add task link, back button closing the sheet, Tasks scroll and cold start measured (see M7). One real defect found and fixed on the device: the Undo button's yellow text was hard to read on the toast's light background in dark mode. Release APK rebuilt: 55.9 MB (three ABIs); the only permission is the app's own AndroidX receiver permission, no `INTERNET`. **Not done:** usability sessions with real people, a TalkBack walkthrough, checking the launcher shortcuts by long-pressing the icon (the files and links are tested, the long-press itself was not), Help guide wording review, side-by-side comparison with the website.

Suggested order if time is short: M1, M2, M3 give the biggest felt improvement (the app becomes usable for real tasks); M5 (dark mode) next; M4, M6, M7 after.

---

## 15. Validation

**Metrics (before to target):**

| Measure | Today | Target |
|---|---|---|
| Steps to complete a task | Not possible (Preview only) | 1 tap or 1 swipe |
| Steps to add a task with project and date | Type syntax correctly, 4 taps | 2 taps beyond typing |
| Content visible on first screen of a project page (360 x 640) | about 40% | at least 65% |
| Overdue task found from app open | 3 steps (Home, Tasks, scroll) | 0 to 1 (visible on Home) |
| Scroll jank at 500 tasks | not measured | no frame over 16 ms on a mid-range device |

**Usability script (5 people, thumb-only, phone in one hand):** add three tasks with different projects and dates; complete one; reschedule one to tomorrow and undo; find an overdue task; open a project and find its next milestone; find a requirement's linked file; switch to dark mode. Record time, errors and comments.

**Automated:** extend goldens to dark theme and 160% text; accessibility guidelines in both themes; widget tests for each gesture and its accessible equivalent; layout sweep adds the new scaffold at 360 x 640 and 200%.

---

## 16. Risks

- **Scope creep into a different product.** Mitigation: the "what stays" table; D1 keeps the demo rule (session only).
- **Gesture discoverability.** Mitigation: every gesture has a visible alternative; a one-time hint on first use.
- **Dark mode effort is larger than it looks** (fixed colours are everywhere). Mitigation: M1 token refactor first, then M5.
- **Collapsing bars and nested scrolling with tab views** can be fiddly in Flutter. Mitigation: build `LargeTitleScaffold` once, with tests, before adopting it everywhere.
- **Drift from the website** makes parity tests less meaningful. Mitigation: keep the data and selector parity tests (they test meaning); UI tests stop asserting website layout.
- **Performance regressions** from animations and slivers. Mitigation: profile in M7, keep the reduced-motion path simple.

---

## 17. Appendix: web pattern to mobile pattern map

| Website pattern | Current mobile port | Mobile-native target |
|---|---|---|
| Left rail with five items | Bottom bar with four plus a centre button | Navigation bar with badges, hide on scroll; rail on tablets |
| Page header block | `PageHeader` | Collapsing large title |
| Underlined view tabs | `ViewTabs` | Pinned tabs with swipeable pages |
| Filter popover | Chip sheet | Filter chip row plus "More" sheet |
| Search box in top bar, command palette | Search page | In-bar search pill, full-screen search with recents |
| Row cards with chips | `RowCard` | Two-line tiles with leading control |
| Side detail panel | Bottom sheet (docked on tablet) | Sheet with sticky action bar; docked on tablet |
| Hover tooltips, keyboard shortcuts | Removed | Long-press menus, haptics |
| Dialogs (Preview only) | Bottom sheet | Inline feedback and undo; real session actions |
| Landing page | Welcome screen | Short onboarding, then Home |
| Month calendar grid | Month grid and agenda | Week strip plus agenda, month on demand |
| Light theme only | Light only | System-following light and dark |
