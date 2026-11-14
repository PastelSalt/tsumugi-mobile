# Tsumugi Mobile: Flutter Frontend Plan

> **Status:** Phases 0 to 8 complete on 2026-11-14 for everything that can be automated; the manual checks that need a device (section 10) are still open. Decisions on the open questions are in section 12.
> **Source being ported:** `CTINASSL_Activity/client` (Vite + React demo website, "individual workspace", PLAN-A-04 Revision 3).
> **Target:** `tsumugi-mobile` (Flutter, currently the untouched `flutter create` counter app, Android platform folder only).
> **Last updated:** 2026-11-14

---

## 1. Goal and scope

Build a Flutter mobile app that reproduces the **frontend-only demo** of Tsumugi: same screens, same sample data, same visual language, same "Preview only" behaviour for anything that would write. It is a faithful mobile port of the demo, not a new product.

### In scope

- Welcome and demo-mode sign-in screens (nothing typed is read or sent).
- The individual workspace: **Home, Projects (list + timeline), Project page (Overview / Work / Specs / Files / History), Tasks (Today / Upcoming / Calendar / All), Library with document reader, Insights, Account, Help**.
- Quick add (with the `#project`, day word, `!` line parser), project templates, first-run checklist, and search / jump (the mobile version of the command palette).
- The three draft legal pages, rendered from the same Markdown.
- Session-only additions (tasks and projects added with Quick add or a template live in memory and vanish on restart, always labelled "Session only").
- Light theme matching the web demo; accessibility and reduced-motion support.

### Out of scope (same as the demo)

- Backend, real authentication, API calls, database, persistence, file upload or download, analytics, notifications, recurring tasks.
- Team workspace (people, assignees, roles, access). The individual workspace never shows team concepts.
- iOS, web and desktop runners (the scaffold only has `android/`). Dart code is kept platform-neutral, so adding runners later is a `flutter create --platforms=ios .` away.
- Dark theme (the web demo has none). Reserved as a later enhancement; tokens are structured so it can be added.

### Fixed rules carried over from the web project ([`CONTEXT.md`](../../CTINASSL_Activity/CONTEXT.md))

1. Frontend only. Write actions open a **Preview only** dialog (a bottom sheet on mobile).
2. Visual language: **Fredoka**, warm paper canvas, flat colour (no gradients), ink outlines on selected elements, pastel accents, Lucide-style icons, **12 px minimum text**, touch targets at least 24 px (we use 48 px on mobile), restrained motion that respects reduced-motion.
3. Status is always **icon + text**, never colour alone.
4. Every derived number (counts, progress, overdue, coverage) comes from one selectors module so screens can never disagree.
5. The demo date is **fixed at 2026-11-12** so overdue/relative dates are deterministic.

---

## 2. Analysis of `CTINASSL_Activity`

### 2.1 What the project is

Tsumugi ("Weaving ideas into finished work") is a planned creative and technical production-management platform by Moeko Works. The repository is a **static demo**: React 19 + Vite, JavaScript/JSX, GSAP (motion), Lenis (landing scroll), Lucide icons, Fredoka font, and a tiny history-API router. `Server/` contains only a placeholder `package.json`. The long-term target architecture (MERN, MUI, TanStack Query) is specified in `PROJECT-SPECS.md` but is not built.

The product idea that must survive the port: **traceability**. Objective → Requirement → Milestone → Task → File → Change, with "Why it exists / What it becomes" shown on every record.

### 2.2 Repository map (relevant parts)

| Path | What it holds | Port relevance |
|---|---|---|
| `client/src/pages/landing/` | Long-scroll marketing page (GSAP/Lenis) | Reduced to a short welcome screen (§6.1) |
| `client/src/pages/auth/` | Login, register, forgot/reset password; demo mode with `?preview=` states | Port login/register/recovery as demo screens |
| `client/src/pages/legal/` + `docs/*.md` | Privacy, Terms, Cookie policy rendered from Markdown | Copy Markdown into assets, render natively |
| `client/src/pages/workspace/` | **The product demo** (shell, pages, components, quick add, data) | Core of the port |
| `client/src/pages/workspace/data/` | `fixtures.js`, `store.js`, `selectors.js`, `status.js`, `kinds.js`, `format.js`, `templates.js` | Ported 1:1 to Dart (§5) |
| `client/src/styles/` | Design tokens and layouts (`base.css`, `workspace.css`, `workspace-pages.css`) | Source for the Flutter theme (§4) |
| `docs/individual-workspace-guide.md` | Full user guide, rendered at `/help` | Bundled as the Help screen content |
| `docs/plan/frontend/PLAN-A-01…04L` | Per-page plans with "what was built / not built" | Reference when specifying screens |
| `CONTEXT.md`, `CODEMAP.md`, `LOG.md`, `INSTRUCTIONS.md` | Handoff, file index, action log, doc rules | Mirrored for the mobile repo (§11) |

### 2.3 Route inventory → mobile screen mapping

| Web route | Purpose | Mobile screen |
|---|---|---|
| `/` | Landing | `WelcomeScreen` (short) |
| `/login`, `/register` | Demo auth (state previews via `?preview=`) | `LoginScreen`, `RegisterScreen` |
| `/forgot-password`, `/reset-password` | Recovery layouts | `ForgotPasswordScreen`, `ResetPasswordScreen` |
| `/privacy-policy`, `/terms-of-service`, `/cookie-and-local-storage-policy` | Draft legal | `LegalScreen(doc)` |
| `/home` | What needs attention today | `HomeScreen` (tab 1) |
| `/projects` (`?view=list\|timeline`) | Project cards and cross-project timeline | `ProjectsScreen` (tab 2) |
| `/projects/:id` (`?view=overview\|work\|specs\|files\|history`) | Project hub | `ProjectScreen` with 5 tabs |
| `/tasks` (`?view=today\|upcoming\|calendar\|all`) | Task horizons | `TasksScreen` (tab 3) |
| `/library` (`?doc=`) | Files and documents, Markdown reader | `LibraryScreen` (tab 4), `DocReaderScreen` |
| `/insights` | Three honest numbers | `InsightsScreen` (from account menu) |
| `/account` | Profile and preferences (preview only) | `AccountScreen` |
| `/help` | Rendered user guide | `HelpScreen` |
| Old paths (`/dashboard`, `/milestones`, …) | Redirects | Not needed on mobile |
| Unknown project id | "Project not found" state | Same empty state inside `ProjectScreen` |

### 2.4 Data model (from `fixtures.js`)

All records have string IDs and explicit relationships; nothing derived is stored.

| Entity | Key fields | Demo count |
|---|---|---|
| **Project** | `id, name, category (Software/Creative/Research/Multimedia/Other), kind, status (Planning/Active/On hold/Done), tone (pink/blue/lilac/yellow/green), tags, description, objective, start, end, updatedAt, lastOpenedAt, phases[], phaseIndex, archived?, archivedAt?, session?` | 6 (1 archived) |
| **Milestone** | `id, projectId, title, description, start, due, phase, done?, blocked?, afterId` | 9 |
| **Task** | `id, projectId, milestoneId?, title, notes, status (To do/Doing/Done), priority (normal/high), due?, blocked, subtasks[{text,done}], requirementIds[], fileIds[], changeIds[], session?` | 15 |
| **Requirement** | `id (REQ-001…), projectId, title, type (Functional/Non-functional), status (Open/Met), verified, milestoneId, description, acceptance[{text,met}]` | 9 |
| **File** (assets and documents merged) | `id, projectId, name, kind (document/image/media/data/link), ext, bytes, tags, updatedAt, description, requirementIds, taskIds, milestoneId, isFinal?, progress?, host?` and, for Markdown documents: `body, status (Draft/Final), version` | 18 (7 have a Markdown body) |
| **Change** (was "revision") | `id, projectId, at, summary, recordType, recordId, reviewed, requirementIds, taskIds, fromVersion?, toVersion?, diff?[{mark '=','+','-', text}]` | 9 |

The workspace object is `{ id: 'ws-me', type: 'individual', owner: 'Demo user' }`.

### 2.5 Derived rules (from `selectors.js`) that must be reproduced exactly

- `isOpen(task)` = status ≠ Done. `isOverdue(task)` = open and `due < today`. `dueSoon(task, days=7)`.
- `milestoneState`: Done if `done`; Overdue if `due < today`; Doing if `start <= today`; else Upcoming.
- `milestoneProgress(id)`, `projectProgress(id)` → `{done, total, pct}`; `projectHealth` = "At risk" if any task overdue else "On track".
- `todayList(project)` → `{overdue, today, doing, doneToday}` (doing = status Doing with no due date or due after today).
- `upNext(days, project)` → open tasks plus open milestones due strictly after today within the window, sorted by due.
- `figures()` → `{dueToday, overdue, doing}` (powers the top-bar chips and Home stat strip).
- `recentProjects(n)`, `recents(n)` (projects, files, changes merged by recency).
- `requirementLinks(req)` → linked tasks, files, changes, milestone, and **gaps** (`task` gap if no tasks; `file` gap if no final file). `coverage()` → `{total, complete, withGaps}` where complete = Met **and** verified.
- `overdueRecords()` → overdue tasks plus overdue milestones.
- `recordHref(type, id)` / `recordTitle(type, id)` → deep links between records (becomes typed navigation on mobile).

Format helpers (`format.js`): `dueInfo` (label + tone: overdue / today / soon / later / done / none), `timeAgo`, `dayGroup` (Today / Yesterday / "12 Nov"), `formatDate` ("12 Nov", en-GB), `formatBytes`, `plural`.

### 2.5.1 Status vocabulary (from `status.js`)

| Domain | Labels → tone |
|---|---|
| project | Planning → progress, Active → success, On hold → warning, Done → neutral, Archived → neutral |
| work | To do → info, Doing → progress, Done → success |
| derived (milestone) | Upcoming → info, Doing → progress, Overdue → danger, Done → success |
| requirement | Open → info, Met → success |
| document | Draft → warning, Final → success |
| health | On track → success, At risk → warning |
| flags | Blocked (danger), Verified, Reviewed, Final (success), High priority (warning) |

Tones map to the six pill colours already defined in `workspace.css` (§4.2).

### 2.6 Behaviours worth noting

- **Session store** (`store.js`): `addTask`, `addProject(project, milestones, tasks)`, `resetSession`, a version counter for re-render. Session records carry `session: true` and show a "Session only" tag.
- **Quick add parser** (`quickadd/parse.js`): from one line, `#project` (fuzzy match on id or name), `!` / `!high`, and a due word (`today`, `tomorrow`, `mon`…`sun` → next occurrence, never today) are extracted; the remainder is the title.
- **Templates** (`templates.js`): Software, Creative, Research, Multimedia, Blank, each with phases, one starter milestone and starter tasks.
- **Preview states** (`?preview=loading|empty|error`, developer bar): the `StateGate` component renders loading / empty / error / first-run variants. Kept as a hidden developer feature.
- **Calendar**: Monday-start month grid, full weeks, per-day pills (milestone flag, overdue, done, high priority), selected day agenda underneath.
- **Timeline**: milestones on a date axis with a Today marker; on narrow screens the web already falls back to a vertical list (the mobile design starts from that fallback).
- **Task views**: Today (grouped Overdue / Today / In progress, with inline add), Upcoming (grouped by day, tasks and milestones), Calendar, All (List with a collapsed Done fold, or Board by status).
- **Project phases**: stepper showing done / current / next.
- **Known gaps in the web demo** (not required for parity, listed for awareness): requirement Coverage matrix, compare "unsupported" state, "Not enough data" on Insights, Account tabs, `workspaceId`/`canAccess()`.

---

## 3. Mobile adaptation decisions

| Web pattern | Mobile equivalent | Reason |
|---|---|---|
| Left rail with 5 destinations | **Bottom navigation: Home, Projects, [+], Tasks, Library** (centre Quick add button) | The web's own mobile bar already uses this layout (`mobileBar` in `nav.js`) |
| Insights as 5th destination | Reached from the **account menu** (avatar in the app bar) | Matches the web mobile bar, keeps 4 tabs + FAB |
| Top bar: search + date + due/overdue chips + account menu | App bar with search icon, avatar menu; due/overdue chips live on Home's stat strip | Space |
| Command palette (`Ctrl/Cmd+K`, `Q`) | Full-screen **Search / Jump** screen opened from the app bar; Quick add is the centre FAB | No keyboard shortcuts on phones |
| `SplitLayout` + `DetailPanel` side panel | **Detail bottom sheet** (draggable, expandable to full screen) for tasks, milestones, requirements, files, changes | Side panel does not fit |
| Filter popover | **Filter bottom sheet** with a count badge on the filter button | Same |
| `ViewTabs` (underlined tabs) | `TabBar` (scrollable for the 5 project tabs) | Native idiom |
| Query-string state (`?view=&select=`) | go_router **path + query parameters** (deep-linkable, restores selection) | Keeps the same mental model and enables tests |
| `PreviewDialog` | `PreviewSheet` bottom sheet: "Preview only. Nothing is saved." | Same behaviour |
| `<details>` milestone groups / "Done" fold | `ExpansionTile` | Native |
| Hover/`title` tooltips | Long-press tooltips and semantic labels | Touch |
| GSAP scroll scenes, pointer parallax, Lenis | Dropped. Small implicit animations only (route fades, progress bar fill, sheet) and disabled when reduced motion is on | Restrained motion rule |
| `prefers-reduced-motion` | `MediaQuery.disableAnimations` plus the Account "Reduce motion" setting | Same rule |
| `localStorage` | None (demo stores nothing). Only in-memory session state | Demo rule |
| Developer tools bar | Hidden in Account → Developer (toggle), plus a Preview-state picker (Normal / Loading / Empty / Error) | Same QA tool |

Tablet/landscape: use `NavigationRail` + two-pane (list + detail) at ≥ 840 dp width. This is a Phase 7 stretch goal; phone portrait is the primary target.

---

## 4. Design system

### 4.1 Typography

- **Fredoka** (web uses 400 and 700). Bundle the font files as assets so the app works offline and never fetches at runtime (consistent with "nothing sent anywhere"). Fonts are available under the SIL OFL; ship the license file in `assets/fonts/`.
- Scale (matches `workspace.css`): meta 12, body 14, title 20, display 28. Bump body to 15–16 on mobile if testing shows 14 is too small; never below 12.
- Honour the system text scale (`MediaQuery.textScaler`); layouts must not clip at 200%.

### 4.2 Colour tokens (extracted from `base.css` and `workspace.css`)

| Token | Value | Use |
|---|---|---|
| `paper` | `#FFFDFD` | Cards, surfaces |
| `canvas` | `#F8F6FB` | App background |
| `ink` | `#2F2938` | Text, outlines on selected elements |
| `muted` | `#655F70` | Secondary text |
| `pink` | `#C73579` | Primary accent |
| `pinkSoft` | `#FFE8F5` | Pink tint |
| `blueSoft` | `#E5F4FF` | Blue tint |
| `lilac` | `#EAD9F8` | Lilac tint |
| `green` | `#5C8A6B` | Green accent |
| `greenSoft` | `#E8EFE9` | Green tint |
| `butter` | `#F8D95A` | Yellow accent |
| `line` / `lineStrong` | `#E9E3ED` / `#D8D0E0` | Dividers, borders |

Status pill pairs (background / foreground): neutral `#F1EEF5 / #4A4455`, info `#E5F4FF / #1D5F80`, progress `#ECE6FB / #5A45A8`, warning `#FFF2CF / #7A5600`, danger `#FFE8F5 / #A3205C`, success `#E8EFE9 / #2F6A42`.

Project card tones (`pink | blue | lilac | yellow | green`) map to the pastel tints above; the source CSS has no `.tone-*` definitions in the files inspected, so confirm the exact tint against the running web demo during Phase 1 and record it in the theme.

File-kind thumbnails: image → blueSoft, document → `#FFF2CF`, media → lilac, data → greenSoft, link → pinkSoft.

Radii: sm 8, md 14, lg 20 (cards), landing uses 28. Spacing: 4 / 8 / 12 / 16 / 24 / 32, page gutter 16.

Contrast: every foreground/background pair above must be checked to WCAG AA (4.5:1 body text) in a unit test, since the palette is pastel.

### 4.3 Theme implementation

- `AppTokens` (a `ThemeExtension`) holds the colours, status tones, radii and spacing. `ThemeData` is built from it (`useMaterial3: true`, Fredoka `fontFamily`, flat surfaces, no elevation or gradients, 2 px ink outline for selected state).
- Icons: use a Lucide set for Flutter (e.g. `lucide_icons_flutter`) to match the web's Lucide icons one-to-one (House, FolderKanban, ListChecks, Library, BarChart3, Plus, Circle, Loader, CircleCheckBig, OctagonX, ShieldCheck, Star, Calendar, Pause, Play, Compass, Archive, etc.). Fallback to Material icons only if a glyph is missing.

### 4.4 Shared widget library (`lib/shared/widgets/`)

Ported from the web components (`badges.jsx`, `layout.jsx`, `records.jsx`, `states.jsx`):

`StatusBadge(domain, status)`, `Flag(name)`, `DueLabel(due, done)`, `ProgressBar(value, max, label)`, `RelationChip(type, id)`, `PageHeader`, `Section`, `StatStrip`, `ViewTabs`, `SearchFilterBar` + `FilterSheet` + `FilterField`, `SegmentedToggle`, `DetailSheet`, `Fields` (definition list), `LensBlock` ("Why it exists / What it becomes"), `TaskRow`, `MilestoneGroup`, `RequirementRow`, `FileTile`, `FileThumb`, `ChangeEntry` (feed item with dot), `DiffView`, `EmptyState`, `NoResults`, `StateGate` (loading / empty / error / first-run), `PreviewAction` + `PreviewSheet`, `SessionTag`, `PhaseStepper`, `CalendarMonth`, `TimelineList` / `TimelineBars`, `MarkdownView`.

---

## 5. Technical approach

### 5.1 Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (Dart 3), Material 3 | Scaffold already generated (`sdk: ^3.13.7`; check it matches the installed SDK before adding dependencies) |
| State | **flutter_riverpod** | Fits the "store + selectors" shape; `Provider`s for selectors, `Notifier` for the session store |
| Navigation | **go_router** with `StatefulShellRoute` | Bottom-nav tabs keep their own stacks; deep links and query params like the web |
| Markdown | A maintained Markdown renderer (`flutter_markdown_plus` or equivalent) | Used by the doc reader, Help and legal screens. Raw HTML must stay disabled to match the web parser |
| Dates | `intl` (en-GB formats) | `formatDate` = "12 Nov" |
| Icons | Lucide for Flutter | See §4.3 |
| Fonts | Bundled Fredoka | See §4.1 |
| Testing | `flutter_test`, goldens for key screens | See §9 |

Versions are pinned when Phase 0 runs `flutter pub add`; do not hand-write version numbers into the plan. No networking packages are added: the app has no network code at all, which keeps "nothing is sent anywhere" verifiable (also: do not request the `INTERNET` permission in the release manifest).

### 5.2 Architecture

Feature-first folders, with all data and rules in one pure-Dart layer (no Flutter imports) so it is unit-testable and mirrors the web's `data/` folder.

```text
lib/
  main.dart                       # ProviderScope + App
  app/
    app.dart                      # MaterialApp.router, theme, text scale
    router.dart                   # go_router config, shell routes, redirects
    shell/                        # bottom nav, centre FAB, app bar, account menu
  core/
    theme/                        # tokens.dart, theme.dart, status_tones.dart
    data/
      models/                     # project, milestone, task, requirement, file, change, enums
      fixtures/                   # fixtures.dart (or loader for assets/data/fixtures.json)
      store.dart                  # session store (Notifier): addTask, addProject, resetSession
      selectors.dart              # all derived numbers and queries
      status.dart                 # status vocabulary
      kinds.dart                  # file kind labels
      format.dart                 # demo clock, dueInfo, timeAgo, dayGroup, formatDate, formatBytes
      templates.dart              # project templates
    quickadd/parse.dart           # #project / ! / due-word parser
  shared/widgets/                 # §4.4
  features/
    welcome/                      # WelcomeScreen
    auth/                         # login, register, forgot, reset (demo mode)
    home/
    projects/                     # list, timeline, new-project sheet
    project/                      # overview, work, specs, files, history, diff
    tasks/                        # today, upcoming, calendar, all (list/board), inline add
    library/                      # grid/list, doc reader
    insights/
    account/
    help/                         # renders guide Markdown
    legal/                        # renders policy Markdown
    search/                       # search / jump screen
    quickadd/                     # quick add sheet
assets/
  fonts/                          # Fredoka 400/700 + OFL license
  docs/                           # privacy-policy.md, terms-of-service.md, cookie-and-local-storage-policy.md, individual-workspace-guide.md
  data/fixtures.json              # generated once from fixtures.js (see 5.3)
test/
  core/                           # selectors, parse, format, store
  features/                       # widget tests per screen
  goldens/
docs/
  PLAN-FLUTTER-MOBILE.md          # this file
```

### 5.3 Porting the data without transcription errors

`fixtures.js` is plain ES-module data. Rather than retyping ~60 records, write a throwaway Node script (kept in `tool/export_fixtures.mjs`, not part of the app) that imports `CTINASSL_Activity/client/src/pages/workspace/data/fixtures.js` and writes `assets/data/fixtures.json`. The app loads this JSON once at startup into immutable Dart models (hand-written `fromJson`, or `json_serializable` if code generation is acceptable). Commit the JSON; the app never depends on the web repo at build time. Likewise copy the four Markdown docs into `assets/docs/`.

Add a unit test that asserts the entity counts from §2.4 (6 / 9 / 15 / 9 / 18 / 9) so a bad export is caught immediately.

### 5.4 Clock

All "today" logic reads an injectable `Clock` provider defaulting to **2026-11-12** (`DEMO_TODAY`, `DEMO_NOW = 2026-11-12T12:00:00`). Tests can override it. A later "use real date" preference is possible but is not part of parity.

### 5.5 State shape

- `workspaceDataProvider`: merged `base fixtures + session additions` (equivalent to `data()` in `store.js`), recomputed when the session store changes.
- Selector providers (`todayListProvider(projectId)`, `upNextProvider`, `figuresProvider`, `projectProgressProvider(id)`, `coverageProvider(projectId)`, …) are thin wrappers over pure functions in `selectors.dart`.
- UI-only state (selected filter values, tab index, calendar month/day, layout toggles) lives in route query parameters where the web used the URL (`view`, `status`, `project`, `mode`, `month`, `day`, `select`) and in local widget state otherwise (search text).

---

## 6. Screen specifications

Navigation: `StatefulShellRoute` with four branches (Home, Projects, Tasks, Library). The centre button opens Quick add (not a route). Insights, Account, Help, Legal and Search are pushed routes reached from the app bar / account menu.

Route table:

```text
/                         WelcomeScreen
/login  /register  /forgot-password  /reset-password
/legal/:doc               privacy-policy | terms-of-service | cookie-and-local-storage-policy
/home
/projects                 ?view=list|timeline  &status= &category= &archived=1 &select=
/projects/:projectId      ?view=overview|work|specs|files|history  &select= &mode= &rev=
/tasks                    ?view=today|upcoming|calendar|all  &project= &status= &mode=list|board &month= &day= &select=
/library                  ?kind= &project= &final=1 &mode=grid|list &select=      /library/doc/:fileId
/insights                 ?project=
/account
/help
/search
```

### 6.1 Welcome, auth and legal

- **Welcome:** brand mark ("ts"), tagline "Weaving ideas into finished work.", the one-line pitch, a short pager of the six-step thread (Objective → Requirement → Milestone → Task → Revision/Change → Deliverable/Final file) taken from the landing page, buttons *Continue as demo user* (primary) and *Log in*. Legal links in the footer. No scroll-jacking.
- **Login / Register:** fields with labels, show/hide password, the "Demo only, don't enter a real password; this page never receives it" hint, links to forgot password and register, and *Continue as demo user*. Submit goes straight to `/home`. The nine preview states (default, field errors, invalid credentials, locked, unavailable; email used, pending verification, success) are reachable from the developer preview-state picker, as on the web. **Inputs are never read, stored or sent.**
- **Forgot / Reset password:** layout-only screens with their result states.
- **Legal:** `MarkdownView` of the bundled doc, a visible **Draft** banner (the web sets `LEGAL_STATUS = 'draft'`), contents list with anchors, and the cookie/local-storage inventory (note: the mobile app stores nothing, so update the inventory text accordingly when porting).

### 6.2 Home

Source: `HomePage.jsx`, PLAN-A-04A.

- Stat strip: **Due today**, **Overdue** (hint "Needs a look" when > 0), **In progress** (from `figures()`).
- **Today** section: overdue + today + doing tasks (max 6), "All tasks →" link; empty state "Nothing due today".
- **Up next:** next 5 items due within 7 days (tasks and milestones, labelled).
- **Your projects:** 4 most recently opened, with status badge and progress bar; "New project" link.
- **Recent:** 5 most recent items across projects, files and changes with `timeAgo`.
- **First run** (no projects or preview state = empty): "Welcome. Nothing here yet." with the three-step checklist (Create a project, Add a task, Open the Library).
- App bar: brand, search icon, avatar menu.

### 6.3 Projects

Source: `ProjectsPage.jsx`, PLAN-A-04B.

- Two views via segmented control: **Projects** (card list) and **Timeline**.
- Project card: tone tint, category eyebrow, name, description, status badge, "At risk" flag for Active projects with overdue tasks, progress bar, "Next: {milestone}, {date}" line, "Session only" tag.
- Search + filter sheet: Status, Category, "Show archived".
- Timeline: cross-project milestone list (vertical, grouped by project) with a Today marker; optional horizontal scrolling bars with the Today line as an enhancement. Tapping a milestone opens its detail sheet.
- "New project" opens the **template picker** sheet (Software, Creative, Research, Multimedia, Blank) → name field → creates a session-only project with phases, starter milestone and starter tasks via `addProject`.
- Empty state: "No projects yet" with a New project button.

### 6.4 Project page

Source: `ProjectPage.jsx`, PLAN-A-04C to 04I.

Header: name, description, status badge, health badge (Active only), *Edit project* (Preview only), crumbs/back button, "Created for this session only" note for session projects. Scrollable tab bar with counts: **Overview, Work, Specs, Files, History**.

- **Overview:** `PhaseStepper`; stat strip (Tasks done x/y, Requirements complete x/y, Files n); **Next milestone** row; **About** (objective, dates, category, tags); **Recent changes** (3) with "All history" link.
- **Work:** Groups / Timeline toggle. Groups = one expandable milestone group per milestone (state badge, Blocked flag, due label, progress, "after {milestone}") containing task rows, plus a "No milestone" group. Timeline = milestones for this project. Tap a task or milestone → detail sheet.
- **Specs:** requirement rows (id code, title, criteria count, linked tasks/files, "No work yet" gap, status + Verified flag). Detail sheet shows description, acceptance criteria checklist, lens block, gap list. *(Coverage matrix is not built in the web demo and stays out of scope.)*
- **Files:** tile grid of the project's files; detail sheet as in Library.
- **History:** feed grouped by day (dot + card, summary, record, version arrow, time ago, Reviewed flag). Detail sheet with fields and lens; "Open comparison" opens `DiffView` (before/after lines with `+`/`-` markers, semantic labels "Added:"/"Removed:" for screen readers).
- Unknown id → "Project not found" empty state with Back to Projects.

### 6.5 Tasks

Source: `TasksPage.jsx`, `CalendarView.jsx`, PLAN-A-04E.

- Four views (scrollable tab bar): **Today, Upcoming, Calendar, All**. Page toolbar: search, filter sheet (Project; Status only in All), and for All a **List / Board** segmented toggle.
- **Today:** inline add field ("Add a task for today and press Enter", "Session only" hint), then groups *Overdue*, *Today*, *In progress*; empty state "All clear for today".
- **Upcoming:** next 30 days grouped by day, tasks and milestones; empty state "Nothing coming up".
- **Calendar:** Monday-start month grid, header with prev / Today / next, per-day count and up to 3 pills (milestone flag icon, overdue, done, high-priority arrow, "+n more"), day selection shows an **agenda** below; semantic label per day ("12 Nov, today, 2 items"). On phones, replace pill text with small coloured dots plus the agenda to avoid truncation, but keep non-colour cues (icons).
- **All:** open tasks sorted overdue-first then by due date, collapsed *Done (n)* fold; Board mode = three status columns (horizontal pager on phones).
- Task row: status icon, title (with hidden status text for screen readers), project / milestone / subtask count, Blocked and High priority flags, due label. Tap → **TaskSheet** (status/flags, notes, due, milestone, subtasks checklist, lens block, actions "Edit task", "Change status", "Mark blocked" all Preview only).
- `?select=` opens the sheet on load so links between records work.

### 6.5.1 Quick add

Centre FAB opens a bottom sheet with one text field ("Write the task, e.g. Proof chapter one #garden tomorrow !"), live **detected chips** (project, date or "No date", "High priority"), hint text, and **Add task** (disabled when the title is empty). Adding calls `addTask`, shows a status message "Added “{title}” to {project} for this session.", clears the field, and keeps the sheet open for rapid entry. Parser behaviour must match §2.6 and is covered by unit tests ported from the examples in the guide.

### 6.6 Library

Source: `LibraryPage.jsx`, PLAN-A-04G/I.

- Toolbar: search (name + tags), filter sheet (Type, Project, "Final files only"), **Grid / List** toggle. App bar action *Add file* (Preview only).
- Grid tiles / list rows with `FileThumb` (kind-coloured, extension label), project name, size or host, Draft/Final badge for documents, Final-file flag, upload progress bar for in-progress sample (`a-upload`, 62 %).
- Tap: Markdown documents (those with `body`) open the **DocReaderScreen** (rendered Markdown, status/version, linked requirements and tasks); other files open the file detail sheet: preview area (illustration for png/jpg/pdf/md, "unsupported preview" explanation for other types, links, and uploading files), description, fields, tags, lens block, "Download" and "Mark as final file" (Preview only), and the note that only metadata is shown.

### 6.7 Insights

Source: `InsightsPage.jsx`, PLAN-A-04J.

Project filter, then three cards: **Progress** (% with bar and "x of y tasks done"), **Coverage** (complete/total, "n requirements with gaps"), **Overdue** (count). Overdue items list, **By project** table (rendered as cards on narrow screens: status, health, tasks-done bar), and "How these are counted" definitions. Empty state "No data yet".

### 6.8 Account, Help, Search

- **Account:** one scrollable page of cards: Profile (name, email), Preferences (week starts on, density, due-today reminders), Appearance (motion: follow device / reduce), Privacy (links to the policy), Developer (show developer tools, reset session data with count). The form is **preview-only**: edits stay on screen, an "Edited" badge and Reset appear, nothing is saved. (The *week starts on* and *density* options are inert in the web demo; keep them inert and labelled preview.) **Superseded (M5, M6):** preferences are now real and apply at once; density and reminders were removed; see `docs/PLAN-MOBILE-UI.md`.
- **Help:** renders `individual-workspace-guide.md` with a contents list. Update wording that refers to keyboard shortcuts and the desktop rail so it reads correctly on mobile (see Open question 4).
- **Search / Jump:** text field with grouped results (Actions: Quick add, New project; Go to: Home, Projects, Tasks, Library, Insights, Account, Calendar, Help; Projects; Library files). Empty query shows Recent + Actions + Go to. Matches the palette logic in `CommandPalette.jsx`, capped at 12 results.
- **Account menu** (from the avatar): who/what ("Demo workspace, Individual · sample data, nothing is saved"), Insights, Account and preferences, Help, Developer tools toggle, Legal links, Back to welcome, Leave demo.

### 6.9 Shared states

`StateGate` supports `loading` (skeleton rows), `empty`, `error` (retry), and `firstRun` for every list screen, controlled by the developer **Preview state** picker (Normal / Loading / Empty / Error). All empty states have a title, a one-line body and, where sensible, an action.

---

## 7. Accessibility and quality bar

- Semantics: every icon-only button has a label; status is announced as text ("Task title (Doing)"); calendar days have full labels; diff lines announce Added/Removed; progress bars expose `value`/`max`.
- Touch targets ≥ 48 × 48 dp; minimum text 12 sp; supports system text scaling to 200 % without clipping or overflow.
- Never rely on colour alone: icon + text for statuses and calendar pills.
- Reduced motion: honour `disableAnimations` and the Account setting; default animations are short (≤ 200 ms) and decorative only.
- Back behaviour: Android system back closes sheets first, then pops routes; tab roots exit the app.
- Contrast test for the full pill/tone matrix (AA).
- TalkBack pass is an explicit exit criterion in Phase 8 (the web demo's own screen-reader pass is still outstanding, so do not assume parity is already audited).

---

## 8. Phased delivery

Each phase ends with the app runnable, `flutter analyze` clean and `flutter test` green. Estimates are rough single-developer sizes (S ≈ ½ day, M ≈ 1–2 days, L ≈ 3+ days).

### Phase 0: Foundations (S–M)

- Reconcile the SDK constraint, run `flutter pub add` for riverpod, go_router, intl, markdown renderer, Lucide icons; delete the counter app and default test.
- Bundle Fredoka and the four Markdown docs; set up `assets/` in `pubspec.yaml`.
- Create the folder skeleton (§5.2), `analysis_options.yaml` additions, app id and display name ("Tsumugi").
- Remove/avoid the `INTERNET` permission in release builds; app icon and splash placeholder using the "ts" mark.
- **Done when:** a blank themed app boots to a placeholder Home with the bottom bar.

### Phase 1: Design system (M)

- Tokens, `ThemeData`, status tones, Fredoka text theme, spacing and radii.
- Core widgets: `StatusBadge`, `Flag`, `DueLabel`, `ProgressBar`, `EmptyState`, `StateGate`, `PageHeader`, `Section`, `StatStrip`, `ViewTabs`, `SegmentedToggle`, `SessionTag`, `PreviewSheet`.
- A hidden **widget gallery** route (developer only) to review every widget in every state.
- **Done when:** gallery matches the web demo's look side by side at 390 dp wide; contrast test passes.

### Phase 2: Data and logic layer (M–L)

- `export_fixtures.mjs` → `assets/data/fixtures.json`; Dart models; loader; fixture count test.
- Port `format.dart`, `status.dart`, `kinds.dart`, `templates.dart`, `selectors.dart`, `store.dart`, `parse.dart` with the injectable clock.
- Unit tests ported from behaviour: overdue/today/doing grouping, `upNext` window, milestone states, progress and health, requirement links/gaps, coverage, `dueInfo` labels, `timeAgo`, `dayGroup`, quick-add parse cases (`#garden`, `!`, `tomorrow`, weekday never = today), session add/reset.
- **Done when:** selector outputs for the fixture set match the web demo (record expected values from the running web app: Home figures, project progress per project, coverage).

### Phase 3: Shell, navigation and shared record widgets (M)

- `StatefulShellRoute` with four tabs and the centre FAB; app bar (search icon, avatar menu); route table with query params; `DetailSheet`; `SearchFilterBar` + `FilterSheet`.
- Record widgets: `TaskRow`, `MilestoneGroup`, `RequirementRow`, `FileTile`/`FileThumb`, `ChangeEntry`, `LensBlock`, `RelationChip` (typed navigation replacing `recordHref`), `Fields`.
- **Done when:** tapping a relation chip anywhere navigates to the right place and opens the right sheet.

### Phase 4: Primary screens (L)

- Home (incl. first run), Tasks (Today, Upcoming, All list/board, Calendar, inline add, task sheet), Quick add sheet.
- **Done when:** a user can open the app, review today, add a task via Quick add and see it with the "Session only" tag across Home, Today and the calendar.

### Phase 5: Projects and project page (L)

- Projects list + timeline + filters + New project template sheet; project page with all five tabs, milestone sheet, requirement sheet, history feed, diff view, "not found" state.
- **Done when:** all six demo projects (including archived via the filter) render every tab without overflow, and a template-created project appears everywhere.

### Phase 6: Library, Insights, Account, Help, Search, Legal, Auth (M–L)

- Library grid/list, file sheet, Markdown doc reader; Insights; Account (preview-only form); Help; Search/Jump; Legal screens; Welcome, Login, Register, Forgot, Reset with preview states; account menu.
- **Done when:** every route in §6 is reachable and no screen is a stub.

### Phase 7: Polish and tablet layout (M)

- Developer preview states on every screen; skeleton loading; empty/error copy review; subtle route/sheet transitions with reduced-motion handling; adaptive two-pane layout at ≥ 840 dp; app icon, splash, launcher name; dark-mode token scaffold (disabled).
- **Done when:** UX walkthrough of the guide's "Everyday workflows" (§13 of `individual-workspace-guide.md`) succeeds end to end.

### Phase 8: Verification and docs (M)

- Widget tests per screen (loading/empty/normal states and key interactions), golden tests for Home, Tasks Today, Calendar, Project Overview, Library, Insights at 390 × 844 and a large-text variant.
- Manual passes: TalkBack, 200 % text scale, small phone (360 × 640), large phone, tablet; reduced motion; Android back behaviour; release build size and manifest permissions check.
- Write `README.md`, `CODEMAP.md`, `LOG.md`, `CONTEXT.md` for the mobile repo (§11).
- **Done when:** the checklist in §10 is fully ticked.

Suggested order if time is short: Phases 0 → 1 → 2 → 3 → 4 give a demo-able vertical slice (Home + Tasks + Quick add); Phases 5 and 6 complete parity.

---

## 9. Test strategy

| Layer | What | Tooling |
|---|---|---|
| Unit | `selectors`, `format`, `parse`, `store`, templates, fixture counts, contrast matrix | `flutter_test`, Clock override |
| Widget | Each screen in Normal / Empty / Loading / Error; filter sheets; Quick add flow; calendar day selection; tab switching; relation chip navigation | `flutter_test`, `ProviderScope` overrides, router test harness |
| Golden | Key screens at 390 × 844, plus 200 % text scale | `matchesGoldenFile` (single reference device/font to avoid platform drift) |
| Manual | TalkBack, back button, tiny/large screens, tablet two-pane, offline start | Checklist in §10 |
| Parity | Compare computed numbers and visible strings against the running web demo for the same fixtures | Recorded expected values in test files |

---

## 10. Definition of done

Status on 2026-11-14. Ticked items are verified by automated tests or builds; open items need a person with a device.

- [x] Every route in section 6 exists and matches its web counterpart in content and behaviour (preview-only actions open the Preview sheet). *Routes: `router.dart`; behaviour: feature tests and `workflows_test.dart`.*
- [x] Fixture counts and all derived numbers match the web demo (Home figures, progress, coverage, overdue). *`parity_test.dart` compares against values computed by the website's own code.*
- [x] No network code, no persistence, no `INTERNET` permission in release; session additions disappear on restart and are always labelled. *`privacy_test.dart`; release APK permissions checked with `aapt`.*
- [x] No team concepts anywhere (people, assignees, roles, access). *`design_rules_test.dart`.*
- [x] Fredoka, flat colour, ink-outlined selection, at least 12 sp text, at least 48 dp targets; status never by colour alone. *Rules test, accessibility guideline test on 24 routes. The calendar's day dots are colour-only, but each day's agenda writes status out in words.*
- [x] `flutter analyze` and `flutter test` pass; goldens committed. *126 tests, 16 goldens at the end of Phase 8; now 195 tests and 20 goldens after M1 to M6.*
- [ ] TalkBack, 200 % text and reduced-motion passes recorded in `LOG.md`. *200 % text is covered by goldens and the layout sweep; reduced motion by unit tests. A TalkBack pass and reduced motion on a device are still to do.*
- [x] Mobile `README.md`, `CODEMAP.md`, `LOG.md`, `CONTEXT.md` created and current.

Open manual checks: run on a real device or emulator, TalkBack walkthrough of Home, Tasks, a project and the Library reader, Android back behaviour, reduced motion on a device, a large phone and a small phone, and a side-by-side look at Welcome, the auth screens and the project card tints against the live website.

---

## 11. Documentation rules for the mobile repo

The web repo's `INSTRUCTIONS.md` rules apply here too: keep `LOG.md` (chronological action log), `CODEMAP.md` (current structure and data flow, not plans), and `README.md` accurate in the same change as the code. Replace the placeholder `README.md` (still the Flutter template text) during Phase 0. Add a `CONTEXT.md` handoff in Phase 8.

---

## 12. Risks and open questions

**Risks**

- **Port drift.** Mitigated by generating `fixtures.json` from the source, unit-testing counts and derived values, and recording expected numbers from the running web demo.
- **Calendar and timeline density on a phone.** Mitigated by dots + agenda and the vertical timeline list; bars are an enhancement.
- **Pastel contrast.** Several pill/tint pairs are light; the AA contrast test in Phase 1 is a gate.
- **Package churn.** Markdown and Lucide packages vary in maintenance; confirm current status at `pub add` time and be ready to swap (the Markdown view and icon set are each wrapped behind one widget/constants file).
- **SDK constraint.** `pubspec.yaml` says `sdk: ^3.13.7`; verify it matches the installed Dart/Flutter before Phase 0 so `pub get` does not fail.
- **Legal docs are drafts.** Ship them with the Draft banner; do not present them as final.

**Decisions (resolved 2026-11-14; rule: stay as close to the website as possible)**

1. **Fonts and brand:** bundle Fredoka 400 and 700 (SIL OFL, taken from the web project's `@fontsource/fredoka` files and converted from WOFF to TTF because Flutter cannot load WOFF). **The logo is the website's "ts" brand mark plus the lowercase "tsumugi" wordmark**, rebuilt from `base.css` (`.brand`, `.brand__mark`): a 31 px pink (`#C73579`) badge with corner radii 50% 50% 50% 8 px, rotated -8 degrees, white Fredoka 700 "ts" at 12 px with -0.08em tracking, next to "tsumugi" in Fredoka 700, 18 px, -0.04em tracking, ink colour. The web `favicon.svg` is the unchanged Vite template logo, not Tsumugi's, so it is **not** used. The mark is drawn by a `BrandMark` widget (scales cleanly, always uses the bundled font), with `assets/brand/tsumugi-mark.svg` as a reference file and the Android launcher icon generated from the same mark.
2. **Platforms:** Android only (matches the scaffold). Dart code stays platform-neutral so iOS can be added later.
3. **Package id / name:** keep `com.moekoworks.tsumugi_mobile`; launcher label becomes "Tsumugi".
4. **Help content:** keep the guide verbatim from the web, with only light edits where wording is desktop-specific (keyboard shortcuts, left rail), so it reads correctly on a phone.
5. **Demo date:** keep the fixed 12 Nov 2026 (same as the website). A "use today's date" toggle is deferred.
6. **Tablet two-pane:** phone first. The two-pane layout stays a Phase 7 stretch goal.
7. **Web open questions** (RESEARCH.md section 8) still stand but do not affect this frontend-only port.

---

## 13. Reference: source files to consult per feature

| Feature | Web source |
|---|---|
| Data, fixtures, selectors | `client/src/pages/workspace/data/{fixtures,store,selectors,status,kinds,format,templates}.js` |
| Shell / navigation | `WorkspaceShell.jsx`, `nav.js`, `WorkspaceProvider.jsx` |
| Pages | `pages/{HomePage,ProjectsPage,ProjectPage,TasksPage,LibraryPage,InsightsPage,AccountPage,HelpPage}.jsx` |
| Components | `components/{badges,layout,records,states,Timeline,CalendarView,DocReader}.jsx` |
| Quick add, palette, templates | `quickadd/{QuickAdd,CommandPalette,NewProjectDialog,Modal}.jsx`, `parse.js` |
| Auth | `pages/auth/{AuthPage,RecoveryPage,AuthShell}.jsx`, `components/forms/*` |
| Landing copy | `pages/landing/LandingPage.jsx` |
| Styles and tokens | `styles/{base,workspace,workspace-pages,forms,auth}.css` |
| Per-page plans | `docs/plan/frontend/PLAN-A-04A…L.md` |
| User guide | `docs/individual-workspace-guide.md` |
