import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Markdown documents bundled from the website (`assets/docs/<name>.md`): the three draft legal
/// policies and the individual workspace guide. Loaded once per name.
final docSourceProvider = FutureProvider.family<String, String>(
  (ref, name) => rootBundle.loadString('assets/docs/$name.md'),
);
