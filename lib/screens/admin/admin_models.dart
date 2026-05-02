// ─── Admin Module Models & API Service ───────────────────────────────────────
//
// All data is fetched from the real API. No mock/dummy data.
// Base URL: https://hostel-booking-api.onrender.com/api
// Auth: Clerk JWT Bearer token
//
// Endpoints used by this module:
//   GET    /admin/users?role=...
//   GET    /admin/universities
//   GET    /admin/landlords
//   GET    /admin/students
//   PATCH  /admin/users/:userId/suspend
//   PATCH  /admin/users/:userId/unsuspend
//   DELETE /admin/users/:userId
//   POST   /admin/universities
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:dio/dio.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SystemUserRole { student, landlord, university, admin }
enum UserStatus { active, suspended, deleted }
enum UniversityType { government, private }

// ─── University Model (from /admin/universities) ──────────────────────────────

class SystemUniversity {
  final String id;
  final String universityName;
  final String location;
  final UniversityType type;
  final String email;
  final String createdAt;
  final bool isSuspended; // from nested user.isSuspended
  final String userId;    // from nested user.id

  const SystemUniversity({
    required this.id,
    required this.universityName,
    required this.location,
    required this.type,
    required this.email,
    required this.createdAt,
    required this.isSuspended,
    required this.userId,
  });

  factory SystemUniversity.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};
    return SystemUniversity(
      id: json['id'] as String? ?? '',
      universityName: json['universityName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      type: (json['type'] as String?) == 'government'
          ? UniversityType.government
          : UniversityType.private,
      email: json['email'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      isSuspended: userMap['isSuspended'] as bool? ?? false,
      userId: userMap['id'] as String? ?? '',
    );
  }

  String get typeLabel =>
      type == UniversityType.government ? 'Government' : 'Private';

  UserStatus get status =>
      isSuspended ? UserStatus.suspended : UserStatus.active;
}

// ─── System User Model (from /admin/users) ────────────────────────────────────

class SystemUser {
  final String id;         // internal UUID
  final String clerkId;
  final SystemUserRole role;
  final bool isSuspended;
  final bool firstLogin;
  final String createdAt;
  final Map<String, dynamic>? profile; // role-specific, may be null

  const SystemUser({
    required this.id,
    required this.clerkId,
    required this.role,
    required this.isSuspended,
    required this.firstLogin,
    required this.createdAt,
    this.profile,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? '';
    SystemUserRole role;
    switch (roleStr) {
      case 'student':    role = SystemUserRole.student;    break;
      case 'landlord':   role = SystemUserRole.landlord;   break;
      case 'university': role = SystemUserRole.university; break;
      default:           role = SystemUserRole.admin;
    }
    return SystemUser(
      id: json['id'] as String? ?? '',
      clerkId: json['clerkId'] as String? ?? '',
      role: role,
      isSuspended: json['isSuspended'] as bool? ?? false,
      firstLogin: json['firstLogin'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      profile: json['profile'] as Map<String, dynamic>?,
    );
  }

  UserStatus get status =>
      isSuspended ? UserStatus.suspended : UserStatus.active;

  String get roleLabel {
    switch (role) {
      case SystemUserRole.student:    return 'Student';
      case SystemUserRole.landlord:   return 'Landlord';
      case SystemUserRole.university: return 'University';
      case SystemUserRole.admin:      return 'Admin';
    }
  }

  // ── Derived display fields from profile ──

  String get name {
    if (profile == null) return clerkId;
    switch (role) {
      case SystemUserRole.student:
        final s = profile!['surname'] ?? '';
        final o = profile!['otherNames'] ?? '';
        return '$s $o'.trim();
      case SystemUserRole.landlord:
        return profile!['fullName'] ?? '';
      case SystemUserRole.university:
        return profile!['universityName'] ?? '';
      default:
        return 'Admin';
    }
  }

  String get email {
    if (profile == null) return '';
    switch (role) {
      case SystemUserRole.student:    return profile!['studentEmail'] ?? '';
      case SystemUserRole.landlord:   return profile!['email'] ?? '';
      case SystemUserRole.university: return profile!['email'] ?? '';
      default:                        return '';
    }
  }

  String? get university {
    if (profile == null) return null;
    final uni = profile!['university'];
    if (uni is Map) return uni['universityName'] as String?;
    return null;
  }

  String get initials {
    final parts = name.trim().split(' ');
    return parts
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}

// ─── Create University Request ────────────────────────────────────────────────

class CreateUniversityRequest {
  final String universityName;
  final String location;
  final String type; // "government" or "private"
  final String email;
  final String password;

  const CreateUniversityRequest({
    required this.universityName,
    required this.location,
    required this.type,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'university_name': universityName,
    'location': location,
    'type': type,
    'email': email,
    'password': password,
  };
}

// ─── API Response Wrapper ─────────────────────────────────────────────────────

class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  const ApiResult.ok(this.data, {this.message = ''})
      : success = true, error = null;

  const ApiResult.err(this.error, {this.message = ''})
      : success = false, data = null;
}

// ─── Admin API Service ────────────────────────────────────────────────────────

class AdminApiService {
  static const String _base = 'https://hostel-booking-api.onrender.com/api';

  final Dio _dio;

  /// Pass a [tokenProvider] that returns a fresh Clerk JWT.
  /// This is called immediately before every request so the token is always
  /// valid (Clerk tokens expire after 60 s).
  AdminApiService({required Future<String?> Function() tokenProvider})
      : _dio = _buildDio(tokenProvider);

  static Dio _buildDio(Future<String?> Function() tokenProvider) {
    final dio = Dio(BaseOptions(
      baseUrl: _base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Inject fresh JWT before every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (err, handler) {
          return handler.next(err);
        },
      ),
    );

    return dio;
  }

  // ── Helpers ──

  String _msg(dynamic responseData) {
    if (responseData is Map) {
      return responseData['message'] as String? ?? 'An error occurred';
    }
    return 'An error occurred';
  }

  // ── Users ──

  /// GET /admin/users?role=...
  /// [role] is optional: 'university' | 'landlord' | 'student'
  Future<ApiResult<List<SystemUser>>> getUsers({String? role}) async {
    try {
      final resp = await _dio.get(
        '/admin/users',
        queryParameters: role != null ? {'role': role} : null,
      );
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => SystemUser.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.ok(list, message: resp.data['message'] ?? '');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data),
          message: _msg(e.response?.data));
    }
  }

  /// PATCH /admin/users/:userId/suspend
  Future<ApiResult<void>> suspendUser(String userId) async {
    try {
      await _dio.patch('/admin/users/$userId/suspend');
      return const ApiResult.ok(null, message: 'User suspended successfully');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data));
    }
  }

  /// PATCH /admin/users/:userId/unsuspend
  Future<ApiResult<void>> unsuspendUser(String userId) async {
    try {
      await _dio.patch('/admin/users/$userId/unsuspend');
      return const ApiResult.ok(null, message: 'User reactivated successfully');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data));
    }
  }

  /// DELETE /admin/users/:userId
  Future<ApiResult<void>> deleteUser(String userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
      return const ApiResult.ok(null, message: 'User deleted successfully');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data));
    }
  }

  // ── Universities ──

  /// GET /admin/universities
  Future<ApiResult<List<SystemUniversity>>> getUniversities() async {
    try {
      final resp = await _dio.get('/admin/universities');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => SystemUniversity.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.ok(list, message: resp.data['message'] ?? '');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data));
    }
  }

  /// POST /admin/universities
  Future<ApiResult<SystemUniversity>> createUniversity(
      CreateUniversityRequest req) async {
    try {
      final resp = await _dio.post(
        '/admin/universities',
        data: req.toJson(),
      );
      final uni = SystemUniversity.fromJson(
          resp.data['data']['university'] as Map<String, dynamic>);
      return ApiResult.ok(uni, message: resp.data['message'] ?? '');
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data),
          message: _msg(e.response?.data));
    }
  }

  // ── Stats helpers (derived from user lists) ──

  Future<ApiResult<AdminStats>> getStats() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _dio.get('/admin/users'),
        _dio.get('/admin/universities'),
      ]);

      final allUsers = (results[0].data['data'] as List? ?? [])
          .map((e) => SystemUser.fromJson(e as Map<String, dynamic>))
          .toList();
      final unis = (results[1].data['data'] as List? ?? [])
          .map((e) => SystemUniversity.fromJson(e as Map<String, dynamic>))
          .toList();

      final students  = allUsers.where((u) => u.role == SystemUserRole.student).length;
      final landlords = allUsers.where((u) => u.role == SystemUserRole.landlord).length;
      final active    = allUsers.where((u) => !u.isSuspended).length;
      final suspended = allUsers.where((u) => u.isSuspended).length;

      return ApiResult.ok(AdminStats(
        totalUsers: allUsers.length,
        totalStudents: students,
        totalLandlords: landlords,
        totalUniversities: unis.length,
        activeUsers: active,
        suspendedUsers: suspended,
        universities: unis,
        allUsers: allUsers,
      ));
    } on DioException catch (e) {
      return ApiResult.err(_msg(e.response?.data));
    }
  }
}

// ─── Stats Bundle ─────────────────────────────────────────────────────────────

class AdminStats {
  final int totalUsers;
  final int totalStudents;
  final int totalLandlords;
  final int totalUniversities;
  final int activeUsers;
  final int suspendedUsers;
  final List<SystemUniversity> universities;
  final List<SystemUser> allUsers;

  const AdminStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalLandlords,
    required this.totalUniversities,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.universities,
    required this.allUsers,
  });

  List<SystemUser> get students =>
      allUsers.where((u) => u.role == SystemUserRole.student).toList();
  List<SystemUser> get landlords =>
      allUsers.where((u) => u.role == SystemUserRole.landlord).toList();
  List<SystemUser> get universityUsers =>
      allUsers.where((u) => u.role == SystemUserRole.university).toList();
}