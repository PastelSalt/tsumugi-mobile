import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../data/workspace_store.dart';
import 'api_client.dart';
import 'live_store.dart';

/// Who is using the app.
/// - [unknown]: just launched, checking whether a saved session still works.
/// - [signedOut]: no account session. Welcome and the sign-in screens show.
/// - [signedIn]: a real account; data comes from the server.
/// - [demo]: the sample workspace. **Makes no network calls, stores nothing.** A permanent feature.
enum AuthStatus { unknown, signedOut, signedIn, demo }

class AccountUser {
  const AccountUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.preferences,
  });

  final String id;
  final String email;
  final String displayName;

  /// Server-side preferences: theme, weekStart, motion, timeZone, ...
  final Map<String, dynamic> preferences;

  factory AccountUser.fromJson(Map<String, dynamic> j) => AccountUser(
    id: j['id'] as String,
    email: j['email'] as String,
    displayName: j['displayName'] as String,
    preferences: (j['preferences'] as Map?)?.cast<String, dynamic>() ?? {},
  );
}

class AuthState {
  const AuthState(this.status, {this.user});
  final AuthStatus status;
  final AccountUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isDemo => status == AuthStatus.demo;
}

/// The device's IANA time zone ("Asia/Taipei"), or null if it cannot be read. A provider so tests can fix it.
final deviceZoneProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    try {
      final zone = (await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 3),
      )).identifier;
      return zone.isEmpty ? null : zone;
    } catch (_) {
      return null; // unknown: the server keeps its default
    }
  },
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // A 401 from any call means the session ended somewhere else (another device, password change).
    ref.read(apiClientProvider).onUnauthenticated = _sessionEnded;
    return const AuthState(AuthStatus.unknown);
  }

  ApiClient get _api => ref.read(apiClientProvider);

  void _sessionEnded() {
    if (state.status != AuthStatus.signedIn) return;
    _leaveWorkspace();
    state = const AuthState(AuthStatus.signedOut);
  }

  void _leaveWorkspace() {
    ref.read(liveProvider.notifier).clear();
    ref.read(sessionProvider.notifier).reset();
  }

  /// At launch: if a session was saved, ask the server whether it is still good and load the workspace.
  /// Offline or failing, the person lands on Welcome (the demo still works).
  Future<void> bootstrap() async {
    if (!await _api.hasSession()) {
      state = const AuthState(AuthStatus.signedOut);
      return;
    }
    try {
      final user = AccountUser.fromJson((await _api.get('/auth/session')).map);
      await _enter(user);
    } on ApiError {
      state = const AuthState(AuthStatus.signedOut);
    }
  }

  Future<void> login(String email, String password) async {
    final user = AccountUser.fromJson(
      (await _api.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      )).map,
    );
    await _enter(user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final zone = await _deviceZone();
    final user = AccountUser.fromJson(
      (await _api.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'displayName': displayName,
          'acceptTerms': true,
          'timeZone': ?zone,
        },
      )).map,
    );
    await _enter(user);
  }

  Future<void> _enter(AccountUser user) async {
    // "Today" and "overdue" depend on the account's time zone; a brand-new account has the UTC placeholder.
    var account = user;
    final zone = await _deviceZone();
    if (zone != null && user.preferences['timeZone'] == 'UTC' && zone != 'UTC') {
      try {
        account = AccountUser.fromJson(
          (await _api.patch(
            '/me',
            body: {
              'preferences': {'timeZone': zone},
            },
          )).map,
        );
      } on ApiError {
        // Keep going with the server's value.
      }
    }
    await ref.read(liveProvider.notifier).load();
    state = AuthState(AuthStatus.signedIn, user: account);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiError {
      // Signing out locally is what matters.
    }
    await _api.clearSession();
    _leaveWorkspace();
    state = const AuthState(AuthStatus.signedOut);
  }

  /// The sample workspace: bundled data, no network, nothing stored. Never touches the API.
  void enterDemo() {
    _leaveWorkspace();
    state = const AuthState(AuthStatus.demo);
  }

  /// Back to Welcome from the demo.
  void leaveDemo() => state = const AuthState(AuthStatus.signedOut);

  Future<String?> _deviceZone() => ref.read(deviceZoneProvider)();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
