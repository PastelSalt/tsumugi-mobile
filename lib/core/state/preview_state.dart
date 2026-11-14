import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Developer "Preview state" (website `?preview=` and the developer bar): lets every list screen
/// be reviewed in its loading, empty and error layouts.
enum PreviewState { normal, loading, empty, error }

class PreviewStateNotifier extends Notifier<PreviewState> {
  @override
  PreviewState build() => PreviewState.normal;

  void set(PreviewState value) => state = value;
}

final previewStateProvider =
    NotifierProvider<PreviewStateNotifier, PreviewState>(
      PreviewStateNotifier.new,
    );
