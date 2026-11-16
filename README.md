# Tsumugi Mobile

Flutter mobile app for **Tsumugi** ("Weaving ideas into finished work"), a creative and technical production-management platform by Moeko Works.

This began as a **frontend-only demo**, a mobile port of the website demo (now `../tsumugi-webapp/client`). The demo is **permanent**: it stays in every build and sends and stores nothing. Since 2026-11-16 the app can also **sign in to the Tsumugi server** and use real data (section "Signed-in mode" below). Actions work inside the session and reset on restart; the few that cannot (for example editing a project) open a "Preview only" sheet. The full plan, scope and phases are in [docs/PLAN-FLUTTER-MOBILE.md](docs/PLAN-FLUTTER-MOBILE.md). The follow-up plan for a more mobile-native UI (collapsing bars, gestures, real in-session actions, dark mode) is [docs/PLAN-MOBILE-UI.md](docs/PLAN-MOBILE-UI.md); M1 to M8 are done (foundations, task tile and undo, Quick add pickers, Home and Search, dark mode and settings, project page and reader, launcher shortcuts and splash, device validation). Each phase's gaps are listed in the plan. The motion pass (M9, UX plan 9.1) is mostly built; its remaining items and what was not verified by eye are listed there. The UX side (users, journeys, research and test plan, prioritised backlog) is in [docs/PLAN-UX.md](docs/PLAN-UX.md). A reference sheet for aligning the website with the mobile app (tokens, CSS, component specs, screenshots) is [docs/REFERENCE-WEB-ALIGNMENT.md](docs/REFERENCE-WEB-ALIGNMENT.md).

## Status

**The original eight phases and the mobile-native UI plan (M1 to M8) are done. It has been run on a real phone (Galaxy A05s, Android 15); what remains is listed in `CONTEXT.md`.** Every screen exists with a phone layout, a tablet layout, a light and a dark theme, and reduced-motion support, and runs on the sample data: Welcome and demo sign-in, Home, Tasks, Quick add, Projects and project pages, Library with the document reader, Insights, Account (settings), Help, Search and the draft legal pages. Many actions are real inside the session (complete, reschedule, edit, delete with Undo) and reset on restart. 271 automated tests pass (2 more run only against a live server), including accessibility guidelines in both themes, 20 golden screenshots, a layout sweep of every screen and a 500-task list test. Long-press the launcher icon for Add task, Today and Search.

## Signed-in mode (2026-11-16)

Owner decision: the demo stays offline and permanent; **signed-in use may use the network** (see `CONTEXT.md`). Welcome has three paths: *Continue as demo user* (bundled sample data, no network), *Log in* (`/sign-in`) and *Create account* (`/sign-up`). The API contract is in the website repo's [`docs/PLAN-D-01.md`](../tsumugi-webapp/docs/PLAN-D-01.md).

What works against the server: sign-in and sign-up, resuming a saved session at launch, loading the whole workspace (one snapshot), the account's time zone and "today", tasks (complete, reopen, status, reschedule, block, priority, edit, subtasks, delete, Quick add) with the existing 20-step Undo (also undone on the server), New project from a template, sign-out, and plain-words messages for failed saves. Requirements show their server key (`REQ-001`).

Still preview-only when signed in (next steps): editing a project, milestone and requirement writes, adding files and notes, the reader's Edit, History "reviewed", account preferences syncing to the server, password change, pull-to-refresh, an offline outbox.

Run it against a local server:

```bash
# website repo: npm run setup; npm run seed (optional); set HOST=0.0.0.0 in Server/.env; npm run dev --prefix Server
flutter run                                              # emulator reaches the computer at http://10.0.2.2:3001/api/v1
flutter run --dart-define=API_BASE=http://<computer-ip>:3001/api/v1   # a phone on the same Wi-Fi
flutter test test/integration --dart-define=TSUMUGI_API=http://127.0.0.1:3001/api/v1   # real-server test (creates and deletes a throwaway account)
```

Debug builds allow plain http to the local server (`android/app/src/debug/AndroidManifest.xml`); release builds do not and must use https. Release builds ask for the `INTERNET` permission and nothing else.

## Requirements

- Flutter (stable) with the Android toolchain. Android is the only platform runner so far.
- Node.js is only needed to re-run the one-off tools in `tool/` (font conversion and the fixtures export: `node tool/export_fixtures.mjs`, which needs the website's `node_modules`).

## Commands

```bash
flutter pub get
flutter run            # needs an Android device or emulator
flutter analyze
flutter test
```

Regenerate the launcher icons after changing the brand mark:

```bash
flutter test tool/render_launcher_icons_test.dart
dart run flutter_launcher_icons
```

## Verification

```bash
flutter analyze
flutter test                         # 271 tests (+2 live-server tests, skipped by default)
flutter test --update-goldens test/goldens   # only after an intentional visual change
flutter build apk --release          # was 55.9 MB (three ABIs) before signed-in mode; INTERNET permission only. Rebuild to re-measure
flutter run -d <device-id> --release # on a phone; adb is in the Android SDK platform-tools
```

Not yet done: a TalkBack pass, usability sessions with other people and a side-by-side check against the live website. The checklist is in the plan, section 10.

## Brand and design

- **Logo:** the website's "ts" badge (pink `#C73579`, rotated -8 degrees, corner radii 50% 50% 50% 8 px, white Fredoka 700 "ts") plus the lowercase "tsumugi" wordmark. Drawn by `BrandMark` / `BrandLogo` in `lib/shared/widgets/brand_mark.dart`; a reference SVG is in `assets/brand/tsumugi-mark.svg`. The website's `favicon.svg` is the Vite template logo and is not used.
- **Font:** Fredoka 400, 500, 600 and 700, bundled in `assets/fonts/` (SIL Open Font License, see `OFL-Fredoka.txt`). Converted from the website's `@fontsource/fredoka` WOFF files with `tool/woff_to_ttf.mjs` because Flutter cannot load WOFF.
- **Tokens:** colours, spacing, radii and status tones live in `lib/core/theme/tokens.dart`, extracted from the website's `base.css` and `workspace.css`.

## Structure

See [CODEMAP.md](CODEMAP.md). Change history is in [LOG.md](LOG.md).
