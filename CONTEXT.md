# Tsumugi Mobile: Continuation Context

> Portable handoff for continuing work on another device or with another agent.
>
> **Last updated:** 2026-11-14

## How to resume

The app is a complete frontend-only Flutter port of the website demo in `../CTINASSL_Activity/client` (the Tsumugi "individual workspace"). Read this file, then [`CODEMAP.md`](CODEMAP.md) for the file index and the newest entries of [`LOG.md`](LOG.md) for what changed last. The plan, decisions and the website analysis are in [`docs/PLAN-FLUTTER-MOBILE.md`](docs/PLAN-FLUTTER-MOBILE.md). A second plan, [`docs/PLAN-MOBILE-UI.md`](docs/PLAN-MOBILE-UI.md), proposes moving the UI away from web-style layout toward mobile-native patterns; M1 to M8 are done (see the status line under each phase for what was left out). Nothing is committed or pushed unless the owner asks.

Rules that apply to all work (carried over from the website):

- **Play-demo (decision 2026-11-14, applies to all future work):** the app never gets a backend or any online service, never saves anything on the device and requests no permissions. Everything the person does lives in memory and resets on restart. Many actions are now *real inside the session* (see below and `docs/PLAN-MOBILE-UI.md` section 1a).
- Frontend only: no authentication, API, database, persistence, uploads or analytics. **Real in the session (M2 to M6):** complete, reopen, change status, reschedule, block, edit title and notes, tick subtasks and delete a task (with Undo, 20 steps); Quick add and templates add records (labelled "Session only"); theme, text size, reduce motion, week start and vibration preferences apply at once. **Still a "Preview only" sheet:** editing a project, the reader's Edit button, milestone and requirement writes, New note, sign-in and similar. Everything resets on restart.
- The individual workspace never shows team concepts (people, assignees, roles, access). A team workspace would be a separate, future workspace type.
- Look: Fredoka, warm paper canvas, flat colour (no gradients), ink outlines for selected elements, pastel accents, Lucide icons, text of at least 12 sp, targets of at least 48 dp, status always icon plus text. Motion is restrained and is skipped when the device disables animations.
- The demo date is fixed at **12 Nov 2026** so overdue and relative dates match the sample data.
- Keep `LOG.md`, `CODEMAP.md` and `README.md` current with every change.
- After code changes run `flutter analyze` and `flutter test`. Regenerate goldens only for an intentional visual change: `flutter test --update-goldens test/goldens`.

## Product and repository

- Product: **Tsumugi**, a creative and technical production-management platform by Moeko Works. Package `tsumugi_mobile`, Android id `com.moekoworks.tsumugi_mobile`, launcher label "Tsumugi". Android is the only platform runner so far.
- Stack: Flutter (Dart 3), Material 3, Riverpod (state), go_router (navigation, `StatefulShellRoute`), `flutter_markdown_plus`, `lucide_icons_flutter`, bundled Fredoka.
- Commands: `flutter pub get`, `flutter run` (needs an Android device or emulator), `flutter analyze`, `flutter test`, `flutter build apk --release`.

## Where things are

- Data and rules: `lib/core/data/` (models, selectors, session store, formatting, status vocabulary). Sample data is `assets/data/fixtures.json`, **generated** from the website by `node tool/export_fixtures.mjs` (needs the website's `node_modules`); never hand-edit it. The same script writes `test/fixtures/web_parity.json`, the values the website's own code computes, which `test/core/parity_test.dart` checks the Dart port against.
- Screens: `lib/features/<screen>/`. Shared widgets: `lib/shared/widgets/`. Theme and tokens: `lib/core/theme/`.
- Navigation: `lib/app/router.dart` (full route table), `lib/app/shell/` (phone bottom bar, tablet rail), `lib/app/sheet_selection.dart` and `lib/app/query_params.dart` (view, filter and selection live in the URL query, like the website).
- Bundled documents: `assets/docs/` (three legal drafts verbatim; the Help guide has desktop-only wording edited for phones by `tool/mobile_guide_edits*.mjs`).
- Brand: the website's "ts" badge plus "tsumugi" wordmark, drawn by `BrandMark` / `BrandLogo`; launcher icons and the Android launch mark are rendered by `tool/render_launcher_icons_test.dart`. The website's `favicon.svg` is the unchanged Vite logo and is not used.

## Decisions on record

- Bundle Fredoka (SIL OFL) converted from the website's WOFF files; Android only; app id unchanged; Help copy kept close to the web; fixed demo date; phone first, tablet two-pane from 840 dp.
- Upcoming groups tasks by their real day. The website's grouping labels every future date "Today", which looks like a bug, so it was not copied.
- On shell routes (`/projects/...`, `/library/doc/...`) use `go`, not `push`, from pages outside the tabs: pushing them from Search, Insights or a sheet crashes with duplicate page keys.
- Dark theme is **on** (M5): it follows the device by default; Account has System, Light and Dark (`lib/core/settings/preferences.dart`, applied in `lib/app/app.dart`). Widgets must use tokens only; a test bans literal colours outside `tokens.dart` and the logo.
- `TaskActions` (`lib/shared/widgets/task_actions.dart`) captures the session, haptics, overlay and root navigator when created. A task that changes status moves group and unmounts the tile that started the action, so nothing may use that tile's `context` or `ref` afterwards (this caused two real bugs). The session notifier looks tasks up in the fixtures and its own overlay, never in `workspaceDataProvider` (circular dependency).
- Inside a `Wrap`, never use `Flexible` (invalid parent data); in a `Row` next to long text, wrap due-date pills in `Flexible`.
- Tests that tap items must scroll first: lists are lazy slivers and horizontal chip rows scroll sideways (`scrollUntilVisible`, `ensureVisible`).
- Git: this folder is a subfolder of a parent repository (`../`, branch `master`, no remote tracking). The GitHub repo is **https://github.com/PastelSalt/tsumugi-mobile** (private, default branch `main`, the app at its root). It was created from `git subtree split --prefix=tsumugi-mobile`. `origin` in the parent repo points to it, but pushing the parent's `master` there would put the app under a `tsumugi-mobile/` folder; clone the new repo or move this folder into its own repo before pushing again. The old `MoekoWorks` repo was deleted.

## Verification status (2026-11-14)

Done and automated: `flutter analyze` clean; **223 tests** pass (parity with the website's own results, store, every screen's behaviour, the guide's everyday workflows, layout sweep at 360 x 640 dp at 1x and 1.5x text, tablet portrait and landscape, accessibility guidelines on 24 routes in light and 25 routes in dark at 100% and 160% text, preview states, 20 golden screenshots including 4 dark and 3 at 200% text, privacy and design-rule checks, and the new `m1` to `m6` test files). The release APK (55.9 MB, three ABIs) was rebuilt after M7 and installed on a real phone; its manifest has no `INTERNET` permission.

**Not done (needs a person):** a TalkBack walkthrough, usability sessions, reduced motion on the device, and a side-by-side visual check against the live website (project card tints for yellow and green are my reading of the palette). See the checklist in the plan, section 10.

## What is left (after M8)

- **Motion (owner feedback, 2026-11-15):** the app has almost no animation (six small ones; tab switches, list changes, numbers and entrances are instant), although the plan promised more. The phone's own animation settings are normal, so this is the app. The plan is `docs/PLAN-UX.md` section 5.6 (what is missing) and 9.1 (14 moments, reduced-motion rules, approach, tests, backlog U19 to U30), and `docs/PLAN-MOBILE-UI.md` M9. Nothing is built yet. Start with U19, U21, U23 and a prototype of the task-complete exit (U22).

- **UX plan:** [`docs/PLAN-UX.md`](docs/PLAN-UX.md) (draft v3, 2026-11-15, plus U18 visual hierarchy on all main screens; the "may do now" items U2, U3, U4, U13, U14, U15, U17 are done) has an assumptions register (A1 to A19, none verified), a standards and research review with sources, a check of the build against those standards (the three failures found, Undo toast timing, border contrast and 320 dp reflow, were fixed; what remains needs people: sessions and a TalkBack walkthrough), the revised test plan (3 to 4 people per group, two rounds, TalkBack walkthrough), a backlog (U1 to U17; U14, U2, U13, U15, U3, U4, U17 can be done before any sessions) and decisions X1 to X7. Nothing in it has been run with real people yet.

- **Needs a person:** a TalkBack walkthrough; usability sessions with other people (plan section 15); long-pressing the launcher icon to see the three shortcuts (files and links are tested, the long-press was not); a side-by-side look at the website.
- **Left out on purpose or not yet built** (status lines in `docs/PLAN-MOBILE-UI.md`): swipeable tab views, hide-on-scroll bottom bar, tab re-tap scroll-to-top, search match highlighting, tonal surfaces, empty and error illustrations, shared-element row-to-sheet transition, requirement coverage rings, traceability timeline, week-strip calendar, tinted project header, animated tile insert and remove, lazy Projects and Library lists (the lists are about 20 rows), themed monochrome icon, restoration of the selected tab, three-pane layout at 1200 dp, Milestone chip in Quick add, long-press create menu on the tablet rail.
- **Device notes:** tested on a Samsung Galaxy A05s (Android 15, serial seen as `R7AWA09VDPP`). `adb` is not on the PATH; it is at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. The USB link dropped several times during installs; `adb kill-server` then `adb start-server`, or replugging, brings it back, and `adb install -r -t build/app/outputs/flutter-apk/app-release.apk` works when `flutter run` fails. Flutter draws on a SurfaceView, so `dumpsys gfxinfo` shows 0 frames; measure with `dumpsys SurfaceFlinger --latency "<SurfaceView layer name>"` instead.
- Workflow reminders: update `LOG.md`, `CODEMAP.md`, `README.md` and this file after each phase; run `flutter analyze` and `flutter test`; regenerate goldens only for intentional visual changes; regenerate the launcher icons with `flutter test tool/render_launcher_icons_test.dart` then `dart run flutter_launcher_icons`.

## Known gaps

- Requirement coverage matrix, compare "unsupported" state, "Not enough data" on Insights and Account view tabs are not built (the website has not built them either).
- Account preferences are real now (theme, text size, reduce motion, week start, vibration). Density and reminders were removed on purpose (density would shrink touch targets; reminders need notifications, which the play-demo forbids).
- Goldens were generated on Windows; expect small differences on other operating systems.
- iOS runner, real authentication, persistence, file storage, backend API, team workspace and notifications are future work (backend plans belong in the website repo's `docs/plan/backend/`).
