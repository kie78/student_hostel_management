import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://hostel-booking-api.onrender.com/api',
      contentType: 'application/json',
    ),
  );

  static void setToken(String token) {
    if (token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}