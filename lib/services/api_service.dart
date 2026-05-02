import 'api_client.dart';

/// Student-scoped API methods (bookings + payments).
/// All requests go through [ApiClient.dio], which automatically injects a
/// fresh Clerk JWT via the interceptor registered in [ApiClient.setTokenRefresher].
class StudentApiService {
  static final _dio = ApiClient.dio;

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
    return response.data['data'] as List<dynamic>;
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
}
