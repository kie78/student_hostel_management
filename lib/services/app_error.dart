import 'package:dio/dio.dart';

class AppError {
  static String message(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      final apiMessage = _messageFromData(data);
      if (apiMessage != null && apiMessage.isNotEmpty) {
        return apiMessage;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The request timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Check your network and try again.';
        case DioExceptionType.badCertificate:
          return 'A secure connection could not be established.';
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        case DioExceptionType.badResponse:
          switch (error.response?.statusCode) {
            case 400:
              return 'The request could not be processed.';
            case 401:
              return 'Your session has expired. Please sign in again.';
            case 403:
              return 'You do not have access to perform this action.';
            case 404:
              return 'The requested resource could not be found.';
            case 409:
              return 'This action conflicts with existing data.';
            case 422:
              return 'Some information is invalid. Please review and try again.';
            case 500:
            case 502:
            case 503:
              return 'The server is unavailable right now. Please try again later.';
          }
        case DioExceptionType.unknown:
          break;
      }
    }

    final text = error.toString().trim();
    if (text.isEmpty) return fallback;
    if (text.toLowerCase().contains('already signed in')) {
      return 'You are already signed in.';
    }
    if (text.toLowerCase().contains('invalid strategy')) {
      return 'This sign-in method is not available right now.';
    }
    if (text.toLowerCase().contains('identifier is invalid')) {
      return 'The sign-in details are invalid. Please check them and try again.';
    }
    if (text.toLowerCase().contains('session token')) {
      return 'Could not establish a valid session. Please try signing in again.';
    }

    return fallback;
  }

  static String? _messageFromData(dynamic data) {
    if (data is Map) {
      final direct = data['message'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    }

    return null;
  }
}