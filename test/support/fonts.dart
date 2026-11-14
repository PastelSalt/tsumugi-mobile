import 'package:flutter/services.dart';

/// Loads the real app fonts (Fredoka and the Lucide icons) so golden screenshots show what a phone
/// shows. Without this, widget tests draw text with a placeholder font and icons as boxes.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Fredoka', [
    'assets/fonts/Fredoka-Regular.ttf',
    'assets/fonts/Fredoka-Bold.ttf',
  ]);
  await load('packages/lucide_icons_flutter/Lucide', [
    'packages/lucide_icons_flutter/assets/lucide.ttf',
  ]);
}
