import 'package:clerk_auth/clerk_auth.dart' as clerk_auth;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:student_hostel_management/screens/university/university_models.dart';
import 'api_client.dart';

class AuthService {
  static final _dio = ApiClient.dio;

  static Future<({bool firstLogin, String role})> login({
    required ClerkAuthState auth,
    required String email,
    required String password,
  }) async {
    await auth.attemptSignIn(
      strategy: clerk_auth.Strategy.password,
      identifier: email,
      password: password,
    );

    // Get a fresh JWT token
    final sessionToken = await auth.sessionToken();
    final token = sessionToken.jwt;
    if (token.isEmpty) throw Exception('Login failed — no session token');

    // Attach to all future API requests
    ApiClient.setToken(token);

    // Register refresher so every subsequent request gets a fresh token
    // (Clerk tokens expire after 60 s; this ensures automatic renewal)
    ApiClient.setTokenRefresher(() async {
      try {
        final st = await auth.sessionToken();
        return st.jwt;
      } catch (_) {
        return null;
      }
    });
    // Read claims your backend set in Clerk
    final claims = auth.user?.publicMetadata;
    final bool firstLogin = claims?['firstLogin'] ?? false;
    final String role = claims?['role'] ?? 'student';

    return (firstLogin: firstLogin, role: role);
  }


  static Future<({bool firstLogin, String role})> loginWithCode({
    required ClerkAuthState auth,
    required String landlordCode,
    required String password,
  }) async {
    throw UnimplementedError(
      'Landlord code sign-in is not supported by the current API. Use email and password instead.',
    );
  }

  static Future<void> logout({
    required ClerkAuthState auth,
    required String role,
  }) async {
    final endpoint = switch (role) {
      'student'    => '/student/auth/logout',
      'landlord'   => '/landlord/auth/logout',
      'university' => '/university/auth/logout',
      _            => '/student/auth/logout',
    };
    try { await _dio.post(endpoint); } catch (_) {}
    await auth.signOut();
    ApiClient.clearToken();
  }

static Future<Map<String, dynamic>> getStudentMe() async {
  final response = await _dio.get('/student/me');
  return Map<String, dynamic>.from(response.data['data'] as Map);
}

static Future<Map<String, dynamic>> getUniversityMe() async {
  final response = await _dio.get('/university/me');
  return Map<String, dynamic>.from(response.data['data'] as Map);
}

  // Fetch universities — public endpoint, no token needed
static Future<List<dynamic>> getUniversities() async {
  final response = await _dio.get('/student/universities');
  return response.data['data'];
}

// Register student
static Future<Map<String, dynamic>> registerStudent({
  required String registrationNumber,
  required String surname,
  required String otherNames,
  required String gender,
  required String studentEmail,
  required String password,
  required String universityId,
}) async {
  final response = await _dio.post(
    '/student/auth/register',
    data: {
      'registration_number': registrationNumber,
      'surname': surname,
      'other_names': otherNames,
      'gender': gender,
      'student_email': studentEmail,
      'password': password,
      'university_id': universityId,
    },
  );
  return response.data;
}
// ── University endpoints ──────────────────────────────────────

static Future<List<dynamic>> getLandlords() async {
  final response = await _dio.get('/university/landlords');
  return response.data['data'];
}

static Future<List<dynamic>> getStudents() async {
  final response = await _dio.get('/university/students');
  return response.data['data'];
}

static Future<List<dynamic>> getHostels() async {
  final response = await _dio.get('/university/hostels');
  return response.data['data'];
}

static Future<List<dynamic>> getStudentHostels() async {
  final response = await _dio.get('/student/hostels');
  return response.data['data'];
}

static Future<Map<String, dynamic>> registerLandlord({
  required String fullName,
  required String gender,
  required String nin,
  required String maritalStatus,
  required String whatsappNumber,
  required String email,
  required String password,
}) async {
  final response = await _dio.post(
    '/university/landlords',
    data: {
      'full_name': fullName,
      'gender': gender.toLowerCase(),
      'nin': nin,
      'marital_status': maritalStatus.toLowerCase(),
      'whatsapp_number': whatsappNumber,
      'email': email,
      'password': password,
      'ownership_documents': const <String>[],
    },
  );
  return response.data;
}

static Future<void> suspendLandlord(String userId) async {
  await _dio.patch('/university/landlords/$userId/suspend');
}

static Future<void> unsuspendLandlord(String userId) async {
  await _dio.patch('/university/landlords/$userId/unsuspend');
}

static Future<void> resetPasswordUniversity({
  required String newPassword,
}) async {
  await _dio.post(
    '/university/auth/reset-password',
    data: {'new_password': newPassword},
  );
}

static Future<void> logoutUniversity() async {
  await _dio.post('/university/auth/logout');
}
// Fetch current university profile from /university/me.
static Future<void> loadUniversityProfile() async {
  try {
    final me = await getUniversityMe();
    UniversityStore.setFromApiData(me);
  } catch (e) {
    debugPrint('Failed to load university profile: $e');
  }
}
}