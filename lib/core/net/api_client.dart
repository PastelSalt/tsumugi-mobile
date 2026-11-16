import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_cookie_store.dart';

// The only place the app talks to the network (docs: webapp PLAN-D-01 section 10). The demo never reaches this
// code: it runs on bundled sample data. The server sends a session cookie; this client keeps just that one cookie
// value in secure storage and sends it back, so there is no cookie-jar package and nothing else is stored.

/// Where the API lives. The Android emulator reaches the computer running the backend at 10.0.2.2.
/// Override at build time: `--dart-define=API_BASE=https://api.example.com/api/v1`.
const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3001/api/v1',
);

const _cookieName = 'tsumugi_sid';

/// One field problem from a `400 validation_failed` response.
class ApiFieldError {
  const ApiFieldError(this.path, this.message);
  final String path;
  final String message;
}

/// A failed request, in the shape the server's error envelope uses. `status` is 0 when the server could not be
/// reached at all.
class ApiError implements Exception {
  const ApiError(
    this.status,
    this.code,
    this.message, {
    this.fields = const [],
    this.details,
  });

  final int status;

  /// Stable code such as `auth.invalid_credentials`. Branch on this, never on [message].
  final String code;

  /// A sentence written for people.
  final String message;
  final List<ApiFieldError> fields;
  final Object? details;

  bool get isUnauthenticated => status == 401 && code == 'unauthenticated';
  bool get isOffline => status == 0;

  /// The message for one form field, if the server named it.
  String? fieldMessage(String path) {
    for (final f in fields) {
      if (f.path == path) return f.message;
    }
    return null;
  }

  @override
  String toString() => 'ApiError($status $code: $message)';
}

class ApiClient {
  ApiClient({Dio? dio, SessionCookieStore? cookies, String? baseUrl})
    : _cookies = cookies ?? InMemoryCookieStore(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? apiBase,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              // Every status comes back as a response; errors are turned into ApiError below.
              validateStatus: (_) => true,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.options.validateStatus = (_) => true;
    if (baseUrl != null) _dio.options.baseUrl = baseUrl;
  }

  final Dio _dio;
  final SessionCookieStore _cookies;
  String? _cookie;
  bool _loaded = false;

  /// Called when any request returns 401: the session ended somewhere else.
  void Function()? onUnauthenticated;

  Future<void> _ensureCookie() async {
    if (_loaded) return;
    _cookie = await _cookies.read();
    _loaded = true;
  }

  /// Whether a session cookie is stored (the person was signed in last time).
  Future<bool> hasSession() async {
    await _ensureCookie();
    return _cookie != null;
  }

  Future<void> clearSession() async {
    _cookie = null;
    _loaded = true;
    await _cookies.clear();
  }

  Future<ApiResponse> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);
  Future<ApiResponse> post(String path, {Object? body}) =>
      _send('POST', path, body: body);
  Future<ApiResponse> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<ApiResponse> delete(String path) => _send('DELETE', path);

  /// Multipart upload (files). `fields` are plain form fields; `file` is the bytes.
  Future<ApiResponse> upload(
    String path, {
    required Map<String, String> fields,
    required List<int> bytes,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) => _send(
    'POST',
    path,
    body: FormData.fromMap({
      ...fields,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    }),
    onSendProgress: onProgress,
  );

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    void Function(int, int)? onSendProgress,
  }) async {
    await _ensureCookie();
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        onSendProgress: onSendProgress,
        options: Options(
          method: method,
          headers: {if (_cookie != null) 'cookie': '$_cookieName=$_cookie'},
          contentType: body is FormData ? null : Headers.jsonContentType,
        ),
      );
    } on DioException catch (e) {
      throw ApiError(
        0,
        'network',
        'Can’t reach Tsumugi right now. Check your connection and try again.',
        details: e.type.name,
      );
    }
    await _rememberCookie(response.headers.map['set-cookie']);
    final status = response.statusCode ?? 0;
    if (status == 204) return const ApiResponse(null, null);
    final json = response.data;
    if (status >= 200 && status < 300) {
      return json is Map<String, dynamic>
          ? ApiResponse(json['data'], json['meta'])
          : ApiResponse(json, null);
    }
    final error = _errorFrom(status, json);
    if (error.isUnauthenticated) onUnauthenticated?.call();
    throw error;
  }

  /// Picks the session cookie out of `Set-Cookie` headers and stores it; an empty or expired one signs out.
  Future<void> _rememberCookie(List<String>? headers) async {
    if (headers == null) return;
    for (final h in headers) {
      if (!h.startsWith('$_cookieName=')) continue;
      final value = h.substring(_cookieName.length + 1).split(';').first;
      final expired =
          value.isEmpty ||
          RegExp(r'expires=[^;]*1970', caseSensitive: false).hasMatch(h);
      if (expired) {
        await clearSession();
      } else {
        _cookie = value;
        _loaded = true;
        await _cookies.write(value);
      }
    }
  }

  ApiError _errorFrom(int status, Object? json) {
    final error = json is Map<String, dynamic> ? json['error'] : null;
    if (error is Map<String, dynamic>) {
      final details = error['details'];
      return ApiError(
        status,
        (error['code'] as String?) ?? 'unknown',
        (error['message'] as String?) ?? 'Something went wrong.',
        details: details,
        fields: [
          if (details is List)
            for (final d in details)
              if (d is Map<String, dynamic>)
                ApiFieldError(
                  (d['path'] as String?) ?? '',
                  (d['message'] as String?) ?? '',
                ),
        ],
      );
    }
    return ApiError(status, 'unknown', 'Something went wrong.');
  }
}

/// A successful response: the envelope's `data`, plus `meta` for paginated lists. `data` is null for `204`.
class ApiResponse {
  const ApiResponse(this.data, this.meta);
  final Object? data;
  final Object? meta;

  /// `data` as a JSON object.
  Map<String, dynamic> get map => data! as Map<String, dynamic>;

  /// `data` as a list of JSON objects.
  List<Map<String, dynamic>> get list => [
    for (final e in (data! as List)) e as Map<String, dynamic>,
  ];
}

/// The one client, shared by the whole app. Tests override it with a fake adapter.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(cookies: SecureCookieStore()),
);
