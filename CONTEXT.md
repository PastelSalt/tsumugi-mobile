# Tsumugi Mobile: Continuation Context

> Portable handoff for continuing work on another device or with another agent.
>
> **Last updated:** 2026-11-14

## How to resume

The app is a complete frontend-only Flutter port of the website demo in `../CTINASSL_Activity/client` (the Tsumugi "individual workspace"). Read this file, then [`CODEMAP.md`](CODEMAP.md) for the file index and the newest entries of [`LOG.md`](LOG.md) for what changed last. The plan, decisions and the website analysis are in [`docs/PLAN-FLUTTER-MOBILE.md`](docs/PLAN-FLUTTER-MOBILE.md). A second plan, [`docs/PLAN-MOBILE-UI.md`](docs/PLAN-MOBILE-UI.md), proposes moving the UI away from web-style layout toward mobile-native patterns; M1 to M6 are done (see the status line under each phase for what was left out); M7 and M8 are not started. Nothing is committed unless the owner asks.

Rules that apply to all work (carried over from the website):

- **Play-demo (decision 2026-11-14, applies to all future work):** the app never gets a backend or any online service, never saves anything on the device and requests no permissions. Everything the person does lives in memory and resets on restart. The follow-up UI plan will make most write actions *real inside the session* (complete a task, reschedule, edit, mark met and so on); see `docs/PLAN-MOBILE-UI.md` section 1a. Today, before that work lands:
- Frontend only: no authentication, API, database, persistence, uploads or analytics. Write actions open a **Preview only** sheet. Quick add and templates add **session-only** records (in memory, labelled "Session only", gone on restart).
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
- Dark theme exists only as a scaffold (`AppTokens.dark`, `buildDarkTheme`); the app ships light only.

## Verification status (2026-11-14)

Done and automated: `flutter analyze` clean; 126 tests (parity with the website's own results, store, every screen's behaviour, the guide's everyday workflows, layout sweep of every screen at 360 x 640 dp at 1x and 1.5x text, tablet portrait and landscape, accessibility guidelines on 24 routes, preview states, 16 golden screenshots including 200% text, privacy and design-rule checks). A release APK builds (54.4 MB, three ABIs) and its manifest has no `INTERNET` permission.

**Not done (needs a person with a device):** running on a real phone or emulator, a TalkBack walkthrough, checking Android back behaviour, reduced motion on a device, and a side-by-side visual check against the live website (project card tints for yellow and green are my reading of the palette). See the checklist in the plan, section 10.

## Known gaps and next steps

- Requirement coverage matrix, compare "unsupported" state, "Not enough data" on Insights and Account view tabs are not built (the website has not built them either).
- Account preferences (week start, density, motion, reminders) are inert previews, as on the website.
- Goldens were generated on Windows; expect small differences on other operating systems.
- iOS runner, working dark theme, real authentication, persistence, file storage, backend API, team workspace and notifications are future work (backend plans belong in the website repo's `docs/plan/backend/`).
