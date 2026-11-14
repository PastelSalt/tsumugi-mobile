# Code Map

Maintained index of the current code. Update it when files, responsibilities, routes or data flow change. Describes what exists now, not what is planned (the plan is in `docs/PLAN-FLUTTER-MOBILE.md`).

| Path | Responsibility |
| --- | --- |
| `docs/PLAN-FLUTTER-MOBILE.md` | Analysis of the website demo, decisions, screen specs and phased plan |
| `lib/main.dart` | Entry point: loads the fixtures, then runs `TsumugiApp` in a `ProviderScope` that overrides `fixturesProvider` |
| `lib/app/app.dart` | `MaterialApp.router` with the Tsumugi theme; owns the `GoRouter` |
| `lib/app/router.dart` | Full route table. Pushed pages: `/` (Welcome), `/login`, `/register`, `/forgot-password`, `/reset-password` (the `preview` query selects a designed state), `/insights`, `/account`, `/help`, `/search`, `/legal/:doc`, `/gallery`. Four `StatefulShellRoute` tabs: `/home`, `/projects` (+ `:projectId`), `/tasks`, `/library` (+ `doc/:fileId`). `buildRouter(initialLocation)`; every screen receives its query parameters |
| `lib/app/sheet_selection.dart` | `SheetSelection` mixin: a `select` query value opens that record's detail sheet on phones (nothing on wide screens, where the shell docks the panel) and is cleared when the sheet closes, unless the router has already moved on (used by Tasks, Projects, the project page and Library) |
| `lib/app/query_params.dart` | `context.queryParam(key)` and `context.setQueryParams({...})`: view, filter and selection state lives in the URL query like on the website |
| `lib/app/layout_breakpoints.dart` | `wideBreakpoint` (840 dp), `dockWidth`, `isWideLayout` |
| `lib/app/shell/wide_shell.dart` | Tablet layout: side rail (Home, Projects, Tasks, Library, Insights, Quick add, search, account) and the selected record's details docked on the right |
| `lib/app/shell/app_shell.dart` | App bar (logo, search and account buttons), bottom bar with four destinations and the centre Quick add button (opens the Quick add sheet) |
| `lib/app/placeholder_screen.dart` | Temporary screen used until each page is built |
| `lib/core/theme/tokens.dart` | `AppTokens` theme extension (colours, spacing, radii, type scale), `AppTokens.dark` palette (scaffold) and `StatusTone` pill colours from the website |
| `lib/core/theme/theme.dart` | `buildTheme()`: Fredoka text theme, flat Material 3 theme, buttons, sheets, page transitions; `buildDarkTheme()` scaffold (not used) |
| `lib/core/theme/motion.dart` | `TsumugiPageTransitionsBuilder` (short fade and slide, none when animations are disabled) and `motionDuration` |
| `lib/core/data/status.dart` | Status vocabulary (domain, label, tone, icon) and flags, from the website `status.js` |
| `lib/core/data/format.dart` | Fixed demo date (2026-11-12), `dueInfo`, `timeAgo`, `dayGroup`, `formatDate`, `formatBytes` |
| `lib/core/data/models.dart` | Immutable records (Project, Milestone, Task, Requirement, WorkFile, Change, ProjectTemplate), `WorkspaceData`, `Fixtures.fromJson` |
| `lib/core/data/selectors.dart` | All derived numbers and queries as an extension on `WorkspaceData`, plus `stableSorted`; port of the website `selectors.js` |
| `lib/core/data/workspace_store.dart` | `loadFixtures`, `fixturesProvider`, session-only additions (`sessionProvider`: addTask, addProject, reset), merged `workspaceDataProvider`, `templatesProvider` |
| `lib/core/data/kinds.dart` | File kind labels |
| `lib/core/quickadd/parse.dart` | Quick add line parser (#project, !, today/tomorrow/weekday) |
| `assets/data/fixtures.json` | Sample data exported from the website (generated, do not hand-edit) |
| `tool/export_fixtures.mjs` | One-off export of the fixtures and the website-computed parity values |
| `test/fixtures/web_parity.json` | Expected values computed by the website's own selectors and parser |
| `lib/core/docs/markdown_doc.dart` | `parseDocument`: title, metadata, notice and numbered sections of a Markdown document |
| `lib/core/docs/doc_source.dart` | `docSourceProvider`: loads the bundled Markdown from `assets/docs/` |
| `lib/core/docs/legal_meta.dart` | Legal document info, draft flag, legal links, storage inventory (empty) |
| `lib/core/state/dev_tools.dart` | Developer tools switch (off by default) |
| `lib/core/state/preview_state.dart` | Developer preview state (normal, loading, empty, error) provider |
| `lib/shared/widgets/badges.dart` | `TonePill`, `StatusBadge`, `Flag`, `DueLabel`, `SessionTag`, `TsProgressBar` |
| `lib/shared/widgets/states.dart` | `EmptyState`, `NoResults`, `ErrorState`, `LoadingState`, `StateGate` |
| `lib/shared/widgets/layout.dart` | `PageHeader`, `Section`, `StatStrip`, `ViewTabs`, `SegmentedToggle`, `Fields`, `SearchFilterBar` |
| `lib/shared/widgets/records.dart` | `RowCard`, `TaskRow`, `MilestoneGroup`, `RequirementRow`, `FileThumb`, `FileTile`, `FileRow`, `ChangeEntry`, `RelationChip`, `LensBlock` |
| `lib/shared/widgets/record_sheets.dart` | `openRecord`, `recordPanel` (the panel for a record, used by sheets and the dock), `showRecordSheet`, `showDetailSheet` (draggable sheet), `DetailPanel` and the Task / Milestone / Requirement / File / Change panels |
| `lib/shared/widgets/timeline.dart` | `TimelineList`: milestones with a span bar and a Today marker (the website's narrow-screen timeline) |
| `lib/shared/widgets/phase_stepper.dart` | `PhaseStepper`: done, current and next project phases |
| `lib/shared/widgets/diff_view.dart` | `DiffView`: added and removed lines marked with + and -, announced to screen readers |
| `lib/shared/widgets/markdown_view.dart` | `MarkdownView`: Markdown with the Tsumugi look, no raw HTML, links not followed |
| `lib/shared/widgets/doc_outline.dart` | `DocOutline`: collapsible "On this page" list that scrolls to a section |
| `lib/shared/widgets/doc_page.dart` | `DocLoader`, `NumberedSection`, `DocSections` (outline plus numbered sections) |
| `lib/shared/widgets/filters.dart` | `FilterField` (choice chips), `FilterToggle`, `showFilterSheet` |
| `lib/shared/widgets/preview_sheet.dart` | `showPreviewSheet` and `PreviewAction` (the "Preview only" bottom sheet) |
| `lib/features/home/home_screen.dart` | Home: stat strip, Today, Up next, Your projects, Recent, and the first-run checklist (`FirstRun`) |
| `lib/features/tasks/tasks_screen.dart` | Tasks: Today (with inline add), Upcoming, Calendar, All (List / Board); view, project, status, mode, month, day and select live in the URL query; `select` opens the task sheet |
| `lib/features/tasks/calendar_view.dart` | Month grid (Monday start, count and dots per day) with the selected day's agenda |
| `lib/features/quickadd/quick_add_sheet.dart` | Quick add sheet: live detected chips, adds session-only tasks, stays open for rapid entry |
| `lib/features/projects/new_project_sheet.dart` | New project from a template (session-only), then opens the project page |
| `lib/features/projects/projects_screen.dart` | Projects: card list (`ProjectCard`, pastel tint per project tone) and cross-project timeline; search; filter sheet (status, category, show archived) |
| `lib/features/project/project_screen.dart` | Project page: Overview (phase stepper, numbers, next milestone, about, recent changes), Work (milestone groups or timeline), Specs, Files (`FileGrid`), History (feed by day and comparison); not-found state |
| `lib/features/library/library_screen.dart` | Library: grid or list of files, search, filter sheet (type, project, final only); Markdown documents open the reader, other files open their sheet |
| `lib/features/library/doc_reader_screen.dart` | Document reader: Preview or Source, collapsible outline, links to requirements and tasks, not-found state |
| `lib/features/insights/insights_screen.dart` | Insights: Progress, Coverage, Overdue, overdue items, by-project cards, definitions; project filter |
| `lib/features/account/account_screen.dart` | Account: preview-only profile and preferences (Edited badge, Reset), privacy link, developer switch and Reset session data |
| `lib/features/help/help_screen.dart` | Help: renders the bundled guide with a contents list |
| `lib/features/legal/legal_screen.dart` | Legal: draft banner, cleaned details, contents list, numbered sections, storage inventory |
| `lib/features/search/search_screen.dart` | Search or jump to: actions, pages, projects and files; recent items when empty |
| `lib/features/auth/auth_widgets.dart` | `AuthShell`, `FormBanner`, `StatusPanel`, text and password fields (live requirements), demo submit sheet |
| `lib/features/auth/auth_screens.dart` | Demo login, register, forgot and reset password with their preview states; nothing typed is read |
| `lib/features/welcome/welcome_screen.dart` | Welcome: tagline, demo and log-in buttons, the six-step thread, the four kinds of making, legal links |
| `lib/features/gallery/gallery_screen.dart` | Developer widget gallery at `/gallery` |
| `lib/app/shell/account_sheet.dart` | Account menu sheet: Insights, Account, Help, legal links, Back to welcome, Leave demo; developer switch that reveals the preview-state picker and the gallery |
| `lib/shared/widgets/brand_mark.dart` | `BrandMark` ("ts" badge) and `BrandLogo` (badge plus "tsumugi" wordmark) |
| `assets/fonts/` | Fredoka Regular and Bold (TTF) and the OFL license |
| `assets/brand/` | `tsumugi-mark.svg` (reference), `launcher_icon.png`, `launcher_foreground.png` (rendered by `tool/render_launcher_icons_test.dart`) |
| `assets/docs/` | Markdown from the website: three draft legal policies (verbatim) and the individual workspace guide (desktop-only wording edited for phones; see `tool/mobile_guide_edits.mjs`) |
| `tool/mobile_guide_edits.mjs`, `tool/mobile_guide_edits2.mjs` | One-off wording edits applied to the bundled guide copy |
| `tool/woff_to_ttf.mjs` | One-off Node script converting the website's WOFF fonts to TTF |
| `tool/render_launcher_icons_test.dart` | Test-as-script that renders the launcher icon PNGs from `BrandMark` |
| `test/support/fixtures.dart` | Loads the bundled sample data for tests |
| `test/features/` | Home, Quick add, Tasks, Projects, project page, Library, reader, Insights, Account, Help, Legal, Search, Welcome and auth tests; `layout_sweep_test.dart` renders every screen at 360 x 640 dp at normal and 1.5x text size (figures, today list, first run, Quick add flow, tabs and URL, calendar, All and Board, project filter, select in URL) |
| `test/features/accessibility_test.dart` | Flutter accessibility guidelines (48 dp tap targets, labelled targets, text contrast) on 24 routes |
| `test/goldens/` | 16 golden screenshots with the real fonts and icons: key screens at 390 x 844, three screens at 200% text on 360 x 640, and the tablet layout |
| `test/privacy_test.dart`, `test/design_rules_test.dart` | No network or storage code, no manifest permissions, no text under 12 sp, no team wording |
| `test/support/fonts.dart` | Loads Fredoka and the Lucide font for golden tests |
| `test/features/phase7_test.dart` | Wide layout (rail, docked panel, portrait and landscape), reduced motion, dark scaffold, preview states on every list screen |
| `test/features/workflows_test.dart` | The guide's everyday workflows (13.1 to 13.6) driven through the UI |
| `test/` | Boot and tab tests, format tests, WCAG contrast test, shared widget and record widget tests, route tests, `parity_test.dart` (Dart results vs the website's), `store_test.dart` (session additions) |
| `android/` | Android runner; launcher label "Tsumugi"; launch screen = website canvas colour with the "ts" mark (`drawable/launch_background.xml`, `splash_mark.png`); no `INTERNET` permission in the main manifest |

## Runtime flow

```text
main.dart -> ProviderScope -> TsumugiApp (theme + GoRouter)
  -> StatefulShellRoute -> AppShell (app bar + bottom bar) -> placeholder screen per tab
```

## Not built yet

iOS runner and a working dark theme (the scaffold exists but fixed-colour widgets are not adapted). Open manual checks (device run, TalkBack) are listed in `CONTEXT.md` and the plan, section 10.
