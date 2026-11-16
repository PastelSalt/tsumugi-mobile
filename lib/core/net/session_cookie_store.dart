import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the one session cookie value lives between launches. Secure storage uses the Android Keystore, so the
/// token is not readable from the app's plain files. Nothing else is stored.
abstract class SessionCookieStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureCookieStore implements SessionCookieStore {
  SecureCookieStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'tsumugi_session';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null; // an unreadable store just means "not signed in"
    }
  }

  @override
  Future<void> write(String value) async {
    try {
      await _storage.write(key: _key, value: value);
    } catch (_) {
      // Without storage the session lasts until the app closes.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// For tests and for the demo (which never stores anything).
class InMemoryCookieStore implements SessionCookieStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;
}
