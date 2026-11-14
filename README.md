# Tsumugi Mobile

Flutter mobile app for **Tsumugi** ("Weaving ideas into finished work"), a creative and technical production-management platform by Moeko Works.

This is a **frontend-only demo**, a mobile port of the website demo in `../CTINASSL_Activity/client`. Nothing is saved or sent anywhere, there is no backend, and actions that would write open a "Preview only" sheet. The full plan, scope and phases are in [docs/PLAN-FLUTTER-MOBILE.md](docs/PLAN-FLUTTER-MOBILE.md).

## Status

**All eight phases of the plan are done, apart from the manual checks that need a device (see `CONTEXT.md`).** Every screen in the plan exists, with a tablet layout and reduced-motion support, and runs on the sample data: Welcome and demo sign-in, Home, Tasks, Quick add, Projects and project pages, Library with the document reader, Insights, Account, Help, Search and the draft legal pages. 126 automated tests pass, including accessibility guidelines, 16 golden screenshots and a layout sweep of every screen.

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
flutter test                         # 126 tests
flutter test --update-goldens test/goldens   # only after an intentional visual change
flutter build apk --release          # about 54 MB; no INTERNET permission
```

Not yet done: a run on a real device, a TalkBack pass and a side-by-side check against the live website. The checklist is in the plan, section 10.

## Brand and design

- **Logo:** the website's "ts" badge (pink `#C73579`, rotated -8 degrees, corner radii 50% 50% 50% 8 px, white Fredoka 700 "ts") plus the lowercase "tsumugi" wordmark. Drawn by `BrandMark` / `BrandLogo` in `lib/shared/widgets/brand_mark.dart`; a reference SVG is in `assets/brand/tsumugi-mark.svg`. The website's `favicon.svg` is the Vite template logo and is not used.
- **Font:** Fredoka 400 and 700, bundled in `assets/fonts/` (SIL Open Font License, see `OFL-Fredoka.txt`). Converted from the website's `@fontsource/fredoka` WOFF files with `tool/woff_to_ttf.mjs` because Flutter cannot load WOFF.
- **Tokens:** colours, spacing, radii and status tones live in `lib/core/theme/tokens.dart`, extracted from the website's `base.css` and `workspace.css`.

## Structure

See [CODEMAP.md](CODEMAP.md). Change history is in [LOG.md](LOG.md).
