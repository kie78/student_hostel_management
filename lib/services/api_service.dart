import 'api_client.dart';

/// Student-scoped API methods (bookings + payments).
/// All requests go through [ApiClient.dio], which automatically injects a
/// fresh Clerk JWT via the interceptor registered in [ApiClient.setTokenRefresher].
class StudentApiService {
  static final _dio = ApiClient.dio;

  static List<dynamic> _readListPayload(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in const ['bookings', 'items', 'results', 'rows']) {
        final value = map[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const <dynamic>[];
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  /// POST /student/bookings
  static Future<Map<String, dynamic>> createBooking(String roomId) async {
    final response = await _dio.post(
      '/student/bookings',
      data: {'room_id': roomId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// POST /student/bookings/:bookingId/terminate
  static Future<void> terminateBooking(String bookingId) async {
    await _dio.post('/student/bookings/$bookingId/terminate');
  }

  /// GET /student/bookings
  static Future<List<dynamic>> getMyBookings() async {
    final response = await _dio.get('/student/bookings');
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return _readListPayload(body['data']);
    }
    return _readListPayload(body);
  }

  /// GET /student/bookings/:bookingId
  static Future<Map<String, dynamic>> getBooking(String bookingId) async {
    final response = await _dio.get('/student/bookings/$bookingId');
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  /// POST /student/bookings/:bookingId/payments
  /// [paymentMethod] — 'mtn_mobile_money' or 'airtel_mobile_money'
  /// [paymentType]   — 'partial' (50 %) or 'full' (100 %)
  static Future<Map<String, dynamic>> makePayment({
    required String bookingId,
    required String paymentMethod,
    required String paymentType,
  }) async {
    final response = await _dio.post(
      '/student/bookings/$bookingId/payments',
      data: {
        'payment_method': paymentMethod,
        'payment_type': paymentType,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// GET /student/bookings/:bookingId/payments
  static Future<List<dynamic>> getPayments(String bookingId) async {
    final response =
        await _dio.get('/student/bookings/$bookingId/payments');
    return response.data['data'] as List<dynamic>;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// GET /student/notifications
  static Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/student/notifications');
    return response.data['data'] as List<dynamic>;
  }

  /// GET /student/me
  static Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/student/me');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// GET /student/notifications/count
  static Future<int> getNotificationCount() async {
    final response = await _dio.get('/student/notifications/count');
    return (response.data['data']['count'] as num).toInt();
  }

  /// POST /student/notifications/mark-all-read
  static Future<void> markAllNotificationsRead() async {
    await _dio.post('/student/notifications/mark-all-read');
  }
}
