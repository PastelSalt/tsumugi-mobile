# Log

Chronological record of actions in this repository.

## 2026-11-14

- Analysed `../CTINASSL_Activity` and wrote `docs/PLAN-FLUTTER-MOBILE.md`.
- Recorded the open-question decisions in the plan (section 12): bundle Fredoka, use the website "ts" mark plus wordmark as the logo (the website `favicon.svg` is the Vite template logo, so it is not used), Android only, app id unchanged with label "Tsumugi", Help copy kept close to the web, fixed demo date, phone first.
- **Phase 0 (foundations):**
  - Added dependencies: `flutter_riverpod`, `go_router`, `intl`, `flutter_markdown_plus`, `lucide_icons_flutter`; dev: `flutter_launcher_icons`. Removed `cupertino_icons`.
  - Converted the website's Fredoka 400/700 WOFF files to TTF with `tool/woff_to_ttf.mjs` into `assets/fonts/`, plus the OFL license. Copied the three legal drafts and the workspace guide into `assets/docs/`.
  - Added `lib/core/theme/` (tokens, theme), `lib/shared/widgets/brand_mark.dart`, `lib/app/` (app, router, shell, placeholder screen); replaced the counter app in `lib/main.dart`.
  - Rendered `assets/brand/launcher_icon.png` and `launcher_foreground.png` from `BrandMark` and generated the Android launcher icons with `flutter_launcher_icons`. Added `assets/brand/tsumugi-mark.svg` as a reference.
  - Set the Android launcher label to "Tsumugi".
  - Replaced the template `README.md`; added `CODEMAP.md` and this log.
  - Fixed during setup: bottom bar stretched to full height (fixed height now set); theme text overrides had dropped the font family (family now applied last).
  - Validation: `flutter analyze` clean; `flutter test` 2 tests pass. A rendered screenshot of Home showed the logo, Fredoka text, bar and button laid out correctly (icon glyphs show as boxes only because tests do not load the Lucide font).
  - `flutter build apk --debug` succeeds (first attempt hit a transient Gradle file-copy error, the retry passed).
  - Not verified: running on a device or emulator (none connected; only Windows and browsers were listed).

- **Phase 1 (design system):** added status vocabulary, demo-date formatting, preview-state provider, shared widgets (badges, states, layout, preview sheet), a developer widget gallery at `/gallery` (opened from the account button), and an early account sheet with the preview-state picker. Tests added: palette contrast (all status pills, ink, muted, white on pink and pink on paper meet WCAG AA 4.5:1), date formatting, shared widgets, gallery build. `flutter analyze` clean; all tests pass. Gallery screenshot checked against the website look; icon glyphs appear as boxes only in test renders.
- Not yet done from Phase 1: side-by-side check against the running website, and a run on a device.

- **Phase 2 (data and logic layer):** `tool/export_fixtures.mjs` bundles the website's own selectors with its bundler and writes `assets/data/fixtures.json` plus `test/fixtures/web_parity.json` (expected values computed by the website code: figures, today list, up next, recents, progress, health, counts, milestone state, coverage, requirement gaps, overdue, record links, quick add parse cases). Added models, selectors (stable sorting, since Dart's sort is not stable), session store with Riverpod, Quick add parser, kinds; `main()` now loads the fixtures asynchronously. `flutter analyze` clean; the parity tests (Dart matches the website for every value) and store tests pass.
- Note: the fixed demo date means Home shows 1 due today, 2 overdue, 6 in progress, same as the website.

- **Phase 3 (shell, navigation, record widgets):** added record widgets (TaskRow, MilestoneGroup, RequirementRow, FileTile/FileRow/FileThumb, ChangeEntry, RelationChip, LensBlock), a draggable detail sheet with Task / Milestone / Requirement / File / Change panels (Preview-only actions), a filter sheet (choice chips and toggles), query-parameter helpers, the full route table with placeholder pages, account menu entries (Insights, Account, Help, legal links, developer tools) and the search button. Relation chips open the linked record (a project opens its page, anything else opens its sheet over the current screen). The gallery now has a Records section drawn from the sample data. Tests: row content, sheet and chip navigation, milestone group, file tile, filter sheet, project route with unknown id, account menu push and back, query-parameter set and clear. `flutter analyze` clean; 39 tests pass.
- Known: the Requirement id uses a monospace family that is not bundled (falls back to the system monospace). A screenshot test of the open task sheet was not completed; the sheet is covered by widget tests instead. Not run on a device.

- **Phase 4 (Home, Tasks, Quick add):** added `HomeScreen` (figures, Today, Up next, Your projects, Recent, first-run checklist), `TasksScreen` (Today with inline add, Upcoming, Calendar, All with List and Board, search, filter sheet, selection in the URL), `CalendarView`, the Quick add sheet (centre button) and the New project template sheet; the router now uses the real Home and Tasks screens. Home shows 1 due today, 2 overdue, 6 in progress, as the website does. Tests: 48 pass (Home figures and rows, first run, Quick add flow, Today inline add, tabs and URL, Upcoming, Calendar month and day, All and Board, project filter, select opens and clears). `flutter analyze` clean. Rendered screenshots of Home and the Calendar look right.
- Deliberate difference from the website: Upcoming groups items by their real day ("Tomorrow", "20 Nov"). The website's `dayGroup` returns "Today" for every future date there, which looks like a bug, so it was not copied.
- Not done: running on a device; the Tasks search box is local state (not in the URL); the Quick add sheet falls back to the first active project when no `#project` is given (same as the website).

- **Phase 5 (Projects and project page):** added `ProjectsScreen` (cards, timeline, search, filters, New project), `ProjectScreen` (Overview, Work with groups or timeline, Specs, Files, History with comparison, not-found state), `TimelineList`, `PhaseStepper`, `DiffView`, and the `SheetSelection` mixin (Tasks now uses it too). The old project placeholder was removed. Tests: 59 pass, including a sweep that renders every project on every tab (and the Work timeline) at 360 x 640 dp without layout errors. `flutter analyze` clean. Screenshots of the list and a project page checked.
- Bug found and fixed by the tests: the New project sheet's Cancel / Create buttons overflowed at 360 dp (now a Wrap).
- Notes: project card tints for yellow and green are my reading of the palette (the website CSS had no `.tone-*` rules in the files inspected); Work-tab milestone details open from an info button on each group (tapping the group expands or collapses it); History comparison is only shown for changes that have a diff, as on the website.
- Not done: running on a device; a side-by-side check of the tints against the running website.

- **Phase 6 (Library, Insights, Account, Help, Search, Legal, Welcome, auth):** added `LibraryScreen` and `DocReaderScreen`, `InsightsScreen`, `AccountScreen` (preview only), `HelpScreen`, `LegalScreen`, `SearchScreen`, `WelcomeScreen` and the demo login, register, forgot and reset password screens with their preview states (`?preview=`). The app now opens on Welcome (`TsumugiApp(initialLocation)`, tests open `/home`). New shared pieces: Markdown parsing and rendering (`markdown_doc`, `MarkdownView`), doc outline and numbered sections, developer-tools switch (the account menu shows the preview-state picker and gallery only when it is on, as the website hides its developer bar).
- Guide wording: the bundled `individual-workspace-guide.md` was edited for phones (keyboard shortcuts, left rail, address bar, hover, reload wording) with `tool/mobile_guide_edits.mjs` and `mobile_guide_edits2.mjs`; the three legal documents are verbatim. A test fails if desktop-only wording such as "Ctrl+K" returns.
- Tests: 84 pass, including `layout_sweep_test.dart`, which renders every screen at 360 x 640 dp at normal and 1.5x text size. It found and fixed real overflows: the Library file thumbnail, the bottom bar at large text, the calendar day cells and header, the auth rows and header, the segmented toggle and the Welcome pager (now content-height). The logo wordmark no longer scales with text size. Several `ListTile`s sat inside decorated boxes that hid their ink; fixed with Material wrappers. `flutter analyze` clean.
- Notes: Welcome is a short mobile version of the website landing page (no scroll animations; the sample thread keeps the website words "Revision" and "Deliverable"; the "Assigned to Mika" team detail was dropped because the individual workspace has no assignees). Password rules on the demo forms are the website ones (12 characters, upper and lower case, a number or symbol). The Account preferences are inert, as on the website. Links inside Markdown are shown but not followed.
- Not done: running on a device; side-by-side check of Welcome and the auth screens against the website.

- **Phase 7 (polish and tablet layout):**
  - Tablet layout from 840 dp: a side rail with the five destinations, Quick add, search and the account menu, and the selected record docked on the right (`?select=` on Tasks, Projects, a project, Library) instead of in a sheet; phones keep the bottom bar and sheets at the same URLs. Tested in portrait and landscape.
  - Motion: short fade-and-slide page transitions and the bottom-bar pill animation, both skipped when the device disables animations.
  - Dark theme scaffold (`AppTokens.dark`, `buildDarkTheme`, contrast-tested) kept off, as fixed-colour widgets (status pills, banners) are not adapted yet. Android launch screen now shows the canvas colour and the "ts" mark.
  - Preview states (loading, empty, error) verified on every list screen with no layout errors; empty states checked for a title and a way forward. The guide's everyday workflows 13.1 to 13.6 are driven through the UI in `workflows_test.dart`.
  - Real bugs the new tests found and fixed: (1) pushing a project or document route from a page outside the tabs (Search, Insights, the New project sheet) crashed with duplicate page keys, so those links now use `go`; (2) "Open comparison" was undone when the closing sheet cleared its selection (the sheet future completes at pop time, before the router applies the navigation; the clear is now deferred and checks the router's own location); (3) `setQueryParams` used a page state that can be one frame stale, and now reads the router's current location.
  - Tests: 103 pass. `flutter analyze` clean. The tablet screenshot (rail, list, docked task) checked.
  - Not done: running on a device; a TalkBack pass (Phase 8).

- **Phase 8 (verification and docs):**
  - Accessibility: `accessibility_test.dart` checks Flutter's tap-target (48 dp), labelled-target and text-contrast guidelines on 24 routes. It found and fixed: the filter button had an unlabelled inner control; segmented toggle and filter chips had no spoken label and were 40 to 42 dp tall (now 48); the milestone info button was 40 dp; the calendar day cells were 46.9 dp wide on a 360 dp phone (the grid now uses the page gutters); a 9 sp "+" in the calendar was replaced by an icon.
  - Large text: goldens at 200% on 360 x 640 showed the bottom bar labels breaking mid-word and the inline add hint truncated; navigation labels now stop scaling at 130% and the hint is shorter (the "Session only" note moved below the field).
  - 16 golden screenshots committed (`test/goldens/`), rendered with the real Fredoka and Lucide fonts.
  - `privacy_test.dart` (no network or storage code or packages, main manifest has no permissions) and `design_rules_test.dart` (no text under 12 sp, no team wording).
  - Release build: `flutter build apk --release` succeeds, 54.4 MB (three ABIs, fonts and icons tree-shaken). `aapt` shows the only permission is the app's own AndroidX receiver permission; there is no `INTERNET` permission.
  - Totals: `flutter analyze` clean, 126 tests pass. Created `CONTEXT.md`; the plan's definition-of-done checklist now records what is verified.
  - **Not done (needs a device or a person):** running on a phone or emulator (none is connected), a TalkBack pass, Android back behaviour, reduced motion on a device, and a side-by-side visual check against the live website.

- Wrote `docs/PLAN-MOBILE-UI.md`: an audit of the current UI against mobile principles, a design direction, a screen-by-screen redesign, an interaction layer, eight phases (M1 to M8), validation metrics and seven open decisions. Linked from `README.md` and `CONTEXT.md`. No code changed.

- Recorded decision D1 in `docs/PLAN-MOBILE-UI.md` (new section 1a) and `CONTEXT.md`: real in-session actions are allowed, the app stays a play-demo with no backend or online services, nothing saved on the device and no permissions. Share (`share_plus`) is out. No code changed.

- **M1 of the mobile UI plan (foundations):**
  - Tokens: semantic roles on `AppTokens`, a complete dark palette (including status tones and text colours), and every literal colour removed from widgets (`Color(0x...)` and `Colors.white/black` are now banned outside `tokens.dart` and the logo by a test). Pills read their colours from the theme.
  - Type: bundled Fredoka 500 and 600; scale is display 32/700, title 20/600, row title 16/500, body 15, meta 13 (min 12).
  - System: edge-to-edge with transparent bars and theme-matched icons; `enableOnBackInvokedCallback` for predictive back; app `restorationScopeId`; `PopScope` with a discard confirmation on Quick add and New project.
  - `LargeTitleScaffold` (collapsing title, pinned tabs, pull to refresh, scroll restoration) now drives Tasks; the shell hides its logo bar on that tab and the subtitle was dropped. Tests that looked for the old subtitle now look for the view tabs.
  - Found while checking the screenshot: `SliverAppBar.large` showed the expanded title at 20 sp because it ignored our type scale, so the title is drawn with `FlexibleSpaceBar` scaled 1.6x instead.
  - Tests: 143 pass (17 new in `m1_test.dart`); goldens regenerated because the type scale changed every screen. `flutter analyze` clean.
  - Not done: other screens still use the old header; dark mode is not switched on; nothing run on a device.

- **M2 of the mobile UI plan (task tile and lists):**
  - `TaskTile` replaces `TaskRow` everywhere: tappable status circle (empty, half for Doing, green check for Done), swipe right to complete or reopen, swipe left to move to tomorrow, long-press action sheet (status, tomorrow, pick a date, remove the date, priority, block, edit, details, delete), hairline dividers, and custom accessibility actions on every tile.
  - Session overlay now supports real actions with a 20-step undo stack; an overlay `UndoToast` (visible above sheets) offers Undo after each action. Haptics go through `AppFeedback` (switchable, no permission needed).
  - The task detail sheet acts for real: Mark done or Reopen, Edit task (title and notes), Change status, Mark blocked, and tappable subtasks.
  - Tasks is now lazy slivers with pinned group headers (label and count) and a "Done this session" group in Today; Upcoming and All use the same groups. Calendar and Board stay boxed.
  - Real bugs found by the new tests and fixed: (1) a circular provider dependency (the session notifier read `workspaceDataProvider`, which watches the session); (2) Undo and the editor's Save read the `ref` of a tile that had already moved to another group and unmounted, so `TaskActions` now captures the session, haptics, overlay and root navigator when it is created; (3) the tile overflowed at 1.5x text (trailing column is bounded and wraps).
  - Tests: 157 pass (14 new in `m2_test.dart`); goldens regenerated (stale `test/goldens/failures` files removed). `flutter analyze` clean.
  - Not done: animated insert and remove of tiles, lazy Library and Projects lists, and a check on a device (none connected).

- **M3 of the mobile UI plan (Quick add v2):**
  - `lib/features/quickadd/quick_add_sheet.dart` rewritten: project, date and priority chips are tappable 48 dp pickers (project list; Today, Tomorrow, Next week, system date picker, No date; priority toggle). Typed `#project`, day words and `!` still fill the chips; a tapped chip wins.
  - The last project is remembered for the session (`lastProjectProvider`) and carries over to the next task. The syntax hint is a one-time dismissible tip (`quickAddTipDismissedProvider`). A light haptic confirms each add.
  - Long-press on the bottom bar's + opens New task, New project and New note (note is a preview) (`showCreateMenu`).
  - Tests: 164 pass (7 new in `m3_test.dart`); `flutter analyze` clean; goldens unchanged.
  - Not done: the optional Milestone chip; long-press menu on the tablet rail; nothing run on a device.

- **M4 (Home, navigation, search):**
  - Home: tappable "At a glance" chips, "Up now" (top three tasks, "All tasks (N)"), "Continue" card, horizontal project carousel, pull to refresh. Overdue badge on the Tasks tab (`AppShell` is now a `ConsumerWidget`). Search: type chips, task results, group counts, recent searches (`recentSearchesProvider`, session only).
  - Not done: swipeable tab views, hide-on-scroll bottom bar, tab re-tap scroll-to-top, match highlighting, Home title in place of the logo.

- **M5 (dark mode and polish):**
  - `preferencesProvider` (`lib/core/settings/preferences.dart`): theme mode (System, Light, Dark), text size, reduce motion, week start. `TsumugiApp` is now a `ConsumerStatefulWidget`: `darkTheme: buildDarkTheme()`, `themeMode`, a text-scale multiplier and a motion override applied in the app builder.
  - Dark passes the tap-target, label and contrast guidelines on 25 routes at 100% and 160% text. Layout bugs found at 160%: section headers with a long action (the action is now flexible and right-aligned) and due-date pills in rows (wrapped in `Flexible`; not inside a `Wrap`, where `Flexible` is invalid, which a test caught).
  - Not done: tonal surfaces, illustrations, shared-element transition, device colours.

- **M6 (project page, reader, settings):**
  - Project page uses `LargeTitleScaffold` (new `leading` back button; the shell hides its logo bar on `/projects/<id>`), tabs pinned.
  - Reader: reading-progress bar, A- and A+, "Outline" button and sheet, Source with line numbers. The inline "On this page" accordion was removed from the reader (Help and Legal still use it).
  - Account: real settings (theme, text size, reduce motion, week start, vibration, reset). Calendar honours Sunday week start. Density and reminders removed.
  - Not done: coverage rings, traceability timeline, week strip, tinted project header, lazy Projects and Library.
  - Tests: 195 pass (11 new in `m4_test.dart`, 8 in `m5_test.dart`, 8 in `m6_test.dart`); goldens regenerated and four dark goldens added; `flutter analyze` clean. Nothing run on a device.

- **Repository and docs housekeeping (2026-11-14):** the work was committed as `05da883` and published to a new private GitHub repo, `PastelSalt/tsumugi-mobile` (app at the root, branch `main`, made with `git subtree split`). A first push to a `MoekoWorks` repo was a mistake and that repo was deleted. `CONTEXT.md` now records the git layout, what is real versus preview, the pitfalls found in M2 to M6, and a hand-off brief for M7 and M8; README, CODEMAP and the test count (195) were brought up to date.

- **M7 and M8 (platform extras, performance, device validation), 2026-11-15:**
  - Launcher icon: the badge now fills about 65% of the adaptive icon canvas (was 43%) and `BrandMark` has a `textScale` so the "ts" letters are larger in the icon (1.9x); the legacy icon fills 84%.
  - Launcher shortcuts Add task, Today and Search (`xml/shortcuts.xml`, `tsumugi://` intent filter, `/add` route that opens Home with Quick add). No package and no permission. Android 12+ splash in light and dark (`values-v31`, `values-night-v31`).
  - Run on a real phone (Galaxy A05s, Android 15), release build: cold start 517 to 677 ms; Tasks scroll median 11 ms per frame (90 Hz), p95 22 ms, no frame over 25 ms; about 115 MB PSS; no Flutter errors in the log. Checked dark, light and 1.5x system font, back button closing a sheet, and the Add task link.
  - Defects found on the device and fixed: the Undo button was yellow on a light toast in dark mode (now dark text); the overdue warning icon drifted away from its text when the text wrapped (now inline).
  - Tests: 208 pass (13 new in `m7_test.dart`); goldens regenerated; analyzer clean. Release APK 55.9 MB, no `INTERNET` permission.
  - Not done: usability sessions, TalkBack, long-pressing the launcher icon, lazy Projects and Library, animated tile insert and remove, monochrome icon. The USB connection dropped several times; see `CONTEXT.md` for the workaround.

- **UX plan items done (2026-11-15), from `docs/PLAN-UX.md` v3:**
  - **U14 Undo toast:** 10 s instead of 5; with TalkBack or other accessibility navigation it stays until Undo or a new Dismiss button (Flutter's own SnackBar with an action no longer auto-dismisses either).
  - **U13 control borders:** new `controlBorder` token (3.9:1 light, 4.1:1 dark on cards) for fields, outlined buttons, unselected chips, glance chips and the empty status circle; `ColorScheme.outline` now uses it. Dividers keep the quiet line colours.
  - **U15 sweeps:** 320 dp light and dark at 130% text, and 200% dark. Found and fixed: Calendar day numbers overflowed at 200% (text now capped at 130% inside the fixed-height cell) and the `PreviewAction` button overflowed (label now flexible). Documented exception: seven Calendar columns are 45.7 dp wide at 320 dp.
  - **U2 tabs:** the tab row fades at the edge that has more tabs.
  - **U3 hint:** one dismissible tip on Today about swipe and press-and-hold; Account has Show tips again (also restores the Quick add tip).
  - **U4 copy:** each Preview-only action says what the full product would do and what works in the demo; the sheet scrolls; the bundled guide now covers swipe, Undo, Quick add chips, shortcuts and the real settings.
  - Tests: 222 pass (14 new in `ux_test.dart`); goldens regenerated (borders and the tip changed them); analyzer clean.
  - **Not done, needs people:** U1 usability sessions and U16 TalkBack walkthrough; the items gated on round 1 (U5 to U12).

- **Visual hierarchy and density (U18), 2026-11-15:** owner feedback that the first screens show too much at once with nothing to guide the eye. Home is now a date, one headline sentence and one line of figures, then Up now (3 tiles), Continue, Up next (quiet rows) and a "See insights" link; the figure boxes, project carousel and Recent list were removed. `TaskTile` is two lines (title and due; project, High, subtask count, Blocked), only overdue is coloured, milestone and progress ring moved to the sheet. Today shows one box ("Add a task"); search and filters stay on the other views; the helper line under it was dropped. Tests: 223 pass (1 new, 9 updated); goldens regenerated; checked on the phone. Details and reasoning in `docs/PLAN-UX.md` 5.5.

- **Top bar consistency, 2026-11-15:** Tasks no longer hides the logo bar. `LargeTitleScaffold` has an `embedded` mode (no bar of its own, title as a heading, pinned tabs and pull to refresh kept) used by Tasks; the shell shows the logo bar on every tab. The project page keeps its own collapsing bar (detail page). Test in `m1_test.dart` checks the bar on Home, Projects, Tasks and Library.

- **Visual hierarchy, other screens (U18b), 2026-11-15:** Projects (small New project action, neutral cards without descriptions), project page (progress statement first, About last, quiet Edit project), Library (list by default, compact rows), Insights (title once, scrolling project chips), Account (settings first, profile after, no duplicate title). `PreviewAction` gained a `quiet` text-button style. Tests: 223 pass (about 12 expectations updated for the new text); goldens regenerated; checked on the phone.

- **Pushed to GitHub (2026-11-15):** `main` on `PastelSalt/tsumugi-mobile` now includes the UX plan items, the visual hierarchy work and the logo bar fix.
- **Motion plan written (2026-11-15), no code:** owner reported there are no animations even with Reduce motion off. Checked: the phone's animation scales are 1.0 and battery saver is off; the code has six animated spots and tab switches, list changes, numbers and entrances are instant; `PLAN-MOBILE-UI.md` 7.4 had promised more and it was never built. Added to `docs/PLAN-UX.md`: section 3.9 (research on motion), 5.6 (finding), 9.1 (14 moments, reduced motion as "swap, do not remove", approach, performance rules, tests, backlog U19 to U30), assumptions A20 to A23, risks and sources; added M9 to `docs/PLAN-MOBILE-UI.md`.

- **Motion pass built (2026-11-15), from `docs/PLAN-UX.md` 9.1:**
  - Tokens and rule (`lib/core/theme/motion.dart`): durations 80 to 400 ms; `fadeDuration` makes reduced motion a 100 ms fade instead of nothing; `motionDuration` stays instant for small state changes.
  - Tabs: `FadeThroughBranches` replaces the indexed stack (fade in and a 6 dp rise, all tabs kept alive). Pages: shared-axis slide and fade, set in the theme.
  - Tasks: a tile shows its check, fades and collapses (320 ms), then the change is made; a tile that lands in a new group fades in (`SessionState.touchedId` and `touchedAt`). Reduced: immediate.
  - Numbers and sections: progress bars fill and move to new values; Home headline and figures fade-swap; `Entrance` fades and raises Home sections and project cards once per launch.
  - Small things: Undo message fades out (`UndoToast.hide` takes `immediate`), the Tasks tip collapses, Quick add chips change colour, Calendar grid cross-fades.
  - Found on the way: wrapping a chip in a `ShapeDecoration` added 2 dp per side and pushed Quick add's Close button off a 640 dp screen (a test caught it); the chip now keeps the plain Material layout and animates its colours.
  - On the A05s: tab switches median 11.1 ms, p95 22.3 ms, 6 of 123 intervals over 25 ms. Not seen by eye (screenshots too slow); needs a screen recording.
  - Not built: row-to-sheet shared element, swipe cue, skeleton shimmer (would stop screens settling in tests), press scale, Tasks and Library entrances, sliding tab underline.
  - Tests: 242 pass (19 new); goldens regenerated; analyzer clean.
