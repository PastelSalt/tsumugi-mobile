# Tsumugi Mobile

Flutter mobile app for **Tsumugi** ("Weaving ideas into finished work"), a creative and technical production-management platform by Moeko Works.

This is a **frontend-only demo**, a mobile port of the website demo in `../CTINASSL_Activity/client`. Nothing is saved or sent anywhere and there is no backend. Actions work inside the session and reset on restart; the few that cannot (for example editing a project) open a "Preview only" sheet. The full plan, scope and phases are in [docs/PLAN-FLUTTER-MOBILE.md](docs/PLAN-FLUTTER-MOBILE.md). The follow-up plan for a more mobile-native UI (collapsing bars, gestures, real in-session actions, dark mode) is [docs/PLAN-MOBILE-UI.md](docs/PLAN-MOBILE-UI.md); M1 to M8 are done (foundations, task tile and undo, Quick add pickers, Home and Search, dark mode and settings, project page and reader, launcher shortcuts and splash, device validation). Each phase's gaps are listed in the plan.

## Status

**The original eight phases and the mobile-native UI plan (M1 to M8) are done. It has been run on a real phone (Galaxy A05s, Android 15); what remains is listed in `CONTEXT.md`.** Every screen exists with a phone layout, a tablet layout, a light and a dark theme, and reduced-motion support, and runs on the sample data: Welcome and demo sign-in, Home, Tasks, Quick add, Projects and project pages, Library with the document reader, Insights, Account (settings), Help, Search and the draft legal pages. Many actions are real inside the session (complete, reschedule, edit, delete with Undo) and reset on restart. 208 automated tests pass, including accessibility guidelines in both themes, 20 golden screenshots, a layout sweep of every screen and a 500-task list test. Long-press the launcher icon for Add task, Today and Search.

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
flutter test                         # 208 tests
flutter test --update-goldens test/goldens   # only after an intentional visual change
flutter build apk --release          # 55.9 MB (three ABIs); no INTERNET permission
flutter run -d <device-id> --release # on a phone; adb is in the Android SDK platform-tools
```

Not yet done: a TalkBack pass, usability sessions with other people and a side-by-side check against the live website. The checklist is in the plan, section 10.

## Brand and design

- **Logo:** the website's "ts" badge (pink `#C73579`, rotated -8 degrees, corner radii 50% 50% 50% 8 px, white Fredoka 700 "ts") plus the lowercase "tsumugi" wordmark. Drawn by `BrandMark` / `BrandLogo` in `lib/shared/widgets/brand_mark.dart`; a reference SVG is in `assets/brand/tsumugi-mark.svg`. The website's `favicon.svg` is the Vite template logo and is not used.
- **Font:** Fredoka 400, 500, 600 and 700, bundled in `assets/fonts/` (SIL Open Font License, see `OFL-Fredoka.txt`). Converted from the website's `@fontsource/fredoka` WOFF files with `tool/woff_to_ttf.mjs` because Flutter cannot load WOFF.
- **Tokens:** colours, spacing, radii and status tones live in `lib/core/theme/tokens.dart`, extracted from the website's `base.css` and `workspace.css`.

## Structure

See [CODEMAP.md](CODEMAP.md). Change history is in [LOG.md](LOG.md).
