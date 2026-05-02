import 'package:dio/dio.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  static TokenProvider? _tokenRefresher;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://hostel-booking-api.onrender.com/api',
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenRefresher != null) {
            try {
              final token = await _tokenRefresher!();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {
              // Token refresh failed — let the request proceed; server will 401
            }
          }
          handler.next(options);
        },
      ),
    );

  /// Register a function that returns a fresh JWT before every request.
  /// Wire this to Clerk's getToken() immediately after login.
  static void setTokenRefresher(TokenProvider refresher) {
    _tokenRefresher = refresher;
  }

  /// Inject a one-time token directly (used right after login before the
  /// refresher is established, so the very first request carries a token).
  static void setToken(String token) {
    if (token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static void clearToken() {
    _tokenRefresher = null;
    dio.options.headers.remove('Authorization');
  }
}