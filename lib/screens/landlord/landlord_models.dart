// ─── Landlord Module Models + API Service ────────────────────────────────────
// All data is fetched from the live API. No dummy/mock data.

import 'package:dio/dio.dart';

import '../../services/api_client.dart' as shared_api;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum RoomTypeEnum { singleSelfContained, doubleSelfContained }

enum BookingStatusEnum { pending, confirmed, active, completed, cancelled }

enum PaymentStatusEnum { pending, partial, paid }

// ─── Room Model ───────────────────────────────────────────────────────────────

class LandlordRoom {
  final String id;
  final String hostelId;
  final RoomTypeEnum type;
  final double pricePerMonth;
  final int totalSlots;
  final int roomCount;
  int occupiedSlots;
  bool isAvailable;

  // Local-only fields (UI helpers not returned by API)
  final List<String> features;
  final String description;

  LandlordRoom({
    required this.id,
    required this.hostelId,
    required this.type,
    required this.pricePerMonth,
    required this.totalSlots,
    this.roomCount = 1,
    this.occupiedSlots = 0,
    this.isAvailable = true,
    this.features = const [],
    this.description = '',
  });

  int get availableSlots => totalSlots - occupiedSlots;
  int get totalBedSlots => roomCount * totalSlots;
  int get remainingBedSlots {
    final remaining = totalBedSlots - occupiedSlots;
    return remaining < 0 ? 0 : remaining;
  }
  int get availableRoomCount {
    if (totalSlots <= 0) return 0;
    final count = remainingBedSlots ~/ totalSlots;
    if (count < 0) return 0;
    return count > roomCount ? roomCount : count;
  }
  int get occupiedRoomCount {
    final occupied = roomCount - availableRoomCount;
    if (occupied < 0) return 0;
    return occupied > roomCount ? roomCount : occupied;
  }

  String get typeName {
    switch (type) {
      case RoomTypeEnum.singleSelfContained:
        return 'Single Self-Contained';
      case RoomTypeEnum.doubleSelfContained:
        return 'Double Self-Contained';
    }
  }

  String get typeShort {
    switch (type) {
      case RoomTypeEnum.singleSelfContained:
        return 'Single S/C';
      case RoomTypeEnum.doubleSelfContained:
        return 'Double S/C';
    }
  }

  /// Parse a room from the API response shape.
  factory LandlordRoom.fromApi(Map<String, dynamic> json, String hostelId) {
    final rawType = (json['roomType'] ?? json['room_type'] ?? '').toString();
    final type = rawType == 'double_self_contained'
        ? RoomTypeEnum.doubleSelfContained
        : RoomTypeEnum.singleSelfContained;

    final totalRooms = (json['total_rooms'] as num?)?.toInt() ??
        (json['totalRooms'] as num?)?.toInt() ??
        (json['number_of_rooms'] as num?)?.toInt() ??
        (json['numberOfRooms'] as num?)?.toInt() ??
        1;
    final capacity = (json['capacity'] as num?)?.toInt() ?? 0;
    final occupiedSlots = (json['occupied_slots'] as num?)?.toInt() ??
        (json['occupiedSlots'] as num?)?.toInt() ??
        0;
    final availableSlots = (json['available_slots'] as num?)?.toInt() ??
        (json['availableSlots'] as num?)?.toInt() ??
        ((totalRooms * capacity) - occupiedSlots);

    return LandlordRoom(
      id: json['id'] as String,
      hostelId: hostelId,
      type: type,
      pricePerMonth: double.tryParse(json['price'].toString()) ?? 0,
      totalSlots: capacity,
      roomCount: totalRooms,
      occupiedSlots: occupiedSlots,
      isAvailable: json['isAvailable'] as bool? ??
          json['is_available'] as bool? ??
          availableSlots > 0,
    );
  }

  /// Serialize for POST /landlord/hostels/:hostelId/rooms
  Map<String, dynamic> toApiCreate() => {
        'room_type': type == RoomTypeEnum.singleSelfContained
            ? 'single_self_contained'
            : 'double_self_contained',
        'price': pricePerMonth.toInt(),
        'number_of_rooms': roomCount,
        'capacity': totalSlots,
      };
}

// ─── Hostel Model ─────────────────────────────────────────────────────────────

class LandlordHostel {
  final String id;
  final String name;
  final String location;
  final String district;
  final String description;
  final String whatsappNumber;
  final List<String> imageUrls;
  final List<LandlordRoom> rooms;
  final DateTime createdAt;
  bool isActive;

  LandlordHostel({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
    required this.description,
    required this.whatsappNumber,
    required this.imageUrls,
    required this.rooms,
    required this.createdAt,
    this.isActive = true,
  });

  int get totalRooms => rooms.fold(0, (sum, r) => sum + r.roomCount);
  int get occupiedRooms => rooms.fold(0, (sum, r) => sum + r.occupiedRoomCount);
  int get availableRooms => rooms.fold(0, (sum, r) => sum + r.availableRoomCount);
  int get totalBedSlots => rooms.fold(0, (sum, r) => sum + r.totalBedSlots);
  int get occupiedBedSlots => rooms.fold(0, (sum, r) => sum + r.occupiedSlots);
  int get availableBedSlots => rooms.fold(0, (sum, r) => sum + r.remainingBedSlots);
  double get occupancyRate =>
      totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0;
  double get lowestPrice => rooms.isEmpty
      ? 0
      : rooms.map((r) => r.pricePerMonth).reduce((a, b) => a < b ? a : b);

  /// Parse from API response shape:
  /// { id, hostelName, location, description, images, whatsappNumber, rooms[] }
  factory LandlordHostel.fromApi(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final rawRooms = (json['rooms'] as List<dynamic>? ?? []);
    final rooms =
        rawRooms.map((r) => LandlordRoom.fromApi(r as Map<String, dynamic>, id)).toList();

    final rawImages = json['images'] as List<dynamic>? ?? [];
    final images = rawImages.map((e) => e.toString()).toList();

    return LandlordHostel(
      id: id,
      name: json['hostelName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      district: '',          // not returned by API
      description: json['description'] as String? ?? '',
      whatsappNumber: json['whatsappNumber'] as String? ?? '',
      imageUrls: images,
      rooms: rooms,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isActive: true,        // API does not return this flag yet
    );
  }
}

// ─── Booking Model ────────────────────────────────────────────────────────────

class LandlordBooking {
  final String id;
  final String hostelId;
  final String hostelName;
  final String roomType;
  final String studentName;
  final String studentId;
  final String studentPhone;
  final String studentEmail;
  final String university;
  final DateTime moveInDate;
  final int durationMonths;
  final double monthlyAmount;
  final double totalAmount;
  final double depositAmount;
  double amountPaid;
  BookingStatusEnum status;
  PaymentStatusEnum paymentStatus;
  final DateTime bookedAt;
  final String paymentMethod;
  bool terminationRequested;
  DateTime? terminationDate;

  LandlordBooking({
    required this.id,
    required this.hostelId,
    required this.hostelName,
    required this.roomType,
    required this.studentName,
    required this.studentId,
    required this.studentPhone,
    required this.studentEmail,
    required this.university,
    required this.moveInDate,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.totalAmount,
    required this.depositAmount,
    this.amountPaid = 0,
    this.status = BookingStatusEnum.pending,
    this.paymentStatus = PaymentStatusEnum.pending,
    required this.bookedAt,
    required this.paymentMethod,
    this.terminationRequested = false,
    this.terminationDate,
  });

  double get balanceDue => totalAmount - amountPaid;
  double get paymentProgress =>
      totalAmount > 0 ? (amountPaid / totalAmount).clamp(0.0, 1.0) : 0;

  String get statusLabel {
    switch (status) {
      case BookingStatusEnum.pending:   return 'Pending';
      case BookingStatusEnum.confirmed: return 'Confirmed';
      case BookingStatusEnum.active:    return 'Active';
      case BookingStatusEnum.completed: return 'Completed';
      case BookingStatusEnum.cancelled: return 'Cancelled';
    }
  }

  /// Parse from GET /landlord/hostels/:hostelId/bookings response shape.
  /// [hostelId] and [hostelName] come from the URL context, not the response body.
  factory LandlordBooking.fromApi(
    Map<String, dynamic> json, {
    required String hostelId,
    required String hostelName,
  }) {
    // --- status ---
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'pending';
    BookingStatusEnum status;
    switch (rawStatus) {
      case 'confirmed':  status = BookingStatusEnum.confirmed;  break;
      case 'active':     status = BookingStatusEnum.active;     break;
      case 'terminated': status = BookingStatusEnum.completed;  break;
      case 'completed':  status = BookingStatusEnum.completed;  break;
      case 'cancelled':  status = BookingStatusEnum.cancelled;  break;
      default:           status = BookingStatusEnum.pending;
    }

    // --- payment amounts from payments array ---
    final payments = json['payments'] as List<dynamic>? ?? [];
    double amountPaid = 0;
    for (final p in payments) {
      if ((p['status'] as String?) == 'success') {
        amountPaid += double.tryParse(p['amount'].toString()) ?? 0;
      }
    }

    // --- room data ---
    final room = json['room'] as Map<String, dynamic>? ?? {};
    final roomPrice =
        double.tryParse(room['price']?.toString() ?? '0') ?? 0;

    PaymentStatusEnum paymentStatus;
    if (amountPaid == 0) {
      paymentStatus = PaymentStatusEnum.pending;
    } else if (amountPaid >= roomPrice) {
      paymentStatus = PaymentStatusEnum.paid;
    } else {
      paymentStatus = PaymentStatusEnum.partial;
    }

    // --- student data ---
    final student = json['student'] as Map<String, dynamic>? ?? {};
    final studentName =
        '${student['otherNames'] ?? ''} ${student['surname'] ?? ''}'.trim();

    return LandlordBooking(
      id: json['id'] as String? ?? '',
      hostelId: hostelId,
      hostelName: hostelName,
      roomType: _formatRoomType(room['roomType']?.toString()),
      studentName: studentName.isEmpty ? 'Unknown Student' : studentName,
      studentId: student['registrationNumber'] as String? ?? '',
      studentPhone: '',
      studentEmail: student['studentEmail'] as String? ?? '',
      university: '',
      moveInDate:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      durationMonths: 1,
      monthlyAmount: roomPrice,
      totalAmount: roomPrice,
      depositAmount: 0,
      amountPaid: amountPaid,
      status: status,
      paymentStatus: paymentStatus,
      bookedAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      paymentMethod: payments.isNotEmpty
          ? _formatPaymentMethod(
              payments.last['paymentMethod']?.toString())
          : '',
      terminationRequested: rawStatus == 'terminated',
    );
  }

  static String _formatRoomType(String? raw) {
    if (raw == 'double_self_contained') return 'Double Self-Contained';
    return 'Single Self-Contained';
  }

  static String _formatPaymentMethod(String? raw) {
    if (raw == 'airtel_mobile_money') return 'Airtel Money';
    if (raw == 'mtn_mobile_money') return 'MTN Mobile Money';
    return raw ?? '';
  }
}

// ─── Notification Model ───────────────────────────────────────────────────────

class LandlordNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  bool isRead;

  LandlordNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory LandlordNotification.fromApi(Map<String, dynamic> json) {
    return LandlordNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'booking',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

// ─── Landlord Profile ─────────────────────────────────────────────────────────

class LandlordProfile {
  final String id;
  final String fullName;
  final String username;
  final String landlordCode;
  final String email;
  final String phone;
  final String whatsappNumber;
  final String gender;
  final String nin;
  final String maritalStatus;
  final String universityName;
  final DateTime joinedAt;

  const LandlordProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.landlordCode,
    required this.email,
    required this.phone,
    required this.whatsappNumber,
    required this.gender,
    required this.nin,
    required this.maritalStatus,
    required this.universityName,
    required this.joinedAt,
  });

  factory LandlordProfile.fromApi(Map<String, dynamic> json) {
    final profile =
      json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json['profile'] is Map
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : json;

    return LandlordProfile(
      id: json['id'] as String? ?? '',
      fullName: profile['fullName'] as String? ?? json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      landlordCode: profile['landlordCode'] as String? ?? json['landlordCode'] as String? ?? '',
      email: profile['email'] as String? ?? json['email'] as String? ?? '',
      phone: profile['phone'] as String? ?? json['phone'] as String? ?? '',
      whatsappNumber: profile['whatsappNumber'] as String? ?? json['whatsappNumber'] as String? ?? '',
      gender: profile['gender'] as String? ?? json['gender'] as String? ?? '',
      nin: profile['nin'] as String? ?? json['nin'] as String? ?? '',
      maritalStatus: profile['maritalStatus'] as String? ?? json['maritalStatus'] as String? ?? '',
      universityName:
        profile['university']?['universityName'] as String? ??
        json['university']?['universityName'] as String? ??
        '',
      joinedAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? profile['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  /// Fallback empty profile before the API call completes
  factory LandlordProfile.empty() => LandlordProfile(
        id: '',
        fullName: '',
        username: '',
        landlordCode: '',
        email: '',
        phone: '',
        whatsappNumber: '',
        gender: '',
        nin: '',
        maritalStatus: '',
        universityName: '',
        joinedAt: DateTime.now(),
      );
}

// ─── API Service ──────────────────────────────────────────────────────────────

/// Centralised Dio client for the Hostel Booking API.
///
/// Usage:
///   1. Call [ApiService.init] once at app startup (or after Clerk login).
///   2. Every method fetches a fresh Clerk JWT via [getToken] before the
///      request, so you never hold a stale token.
///
/// [getToken] must be provided by the caller — wire it to
/// `clerk.session.getToken()` from the Clerk Flutter SDK.

typedef TokenProvider = Future<String?> Function();

class ApiService {
  static final Dio _dio = shared_api.ApiClient.dio;

  /// Call once after Clerk login, before any API method.
  static void init(TokenProvider getToken) {
    shared_api.ApiClient.setTokenRefresher(getToken);
  }

  /// Returns auth headers with a fresh JWT.
  static Future<Options> _authOptions({bool isMultipart = false}) async {
    return Options(
      headers: {
        if (isMultipart) 'Content-Type': 'multipart/form-data',
      },
    );
  }

  // ── Landlord: Hostels ─────────────────────────────────────────────────────

  /// GET /landlord/hostels
  static Future<List<LandlordHostel>> fetchMyHostels() async {
    final opts = await _authOptions();
    final resp = await _dio.get('/landlord/hostels', options: opts);
    final data = resp.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => LandlordHostel.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /landlord/hostels/:hostelId/bookings for every hostel, in parallel.
  static Future<List<LandlordBooking>> fetchAllBookings(
      List<LandlordHostel> hostels) async {
    if (hostels.isEmpty) return [];
    final opts = await _authOptions();
    final results = await Future.wait(
      hostels.map((hostel) async {
        try {
          final resp = await _dio.get(
            '/landlord/hostels/${hostel.id}/bookings',
            options: opts,
          );
          final data = resp.data['data'] as List<dynamic>? ?? [];
          return data
              .map((e) => LandlordBooking.fromApi(
                    e as Map<String, dynamic>,
                    hostelId: hostel.id,
                    hostelName: hostel.name,
                  ))
              .toList();
        } catch (_) {
          return <LandlordBooking>[];
        }
      }),
    );
    return results.expand((list) => list).toList();
  }

  /// PATCH /landlord/hostels/:hostelId/bookings/:bookingId/terminate
  static Future<void> terminateBooking({
    required String hostelId,
    required String bookingId,
  }) async {
    final opts = await _authOptions();
    await _dio.patch(
      '/landlord/hostels/$hostelId/bookings/$bookingId/terminate',
      options: opts,
    );
  }

  /// POST /landlord/hostels  (multipart/form-data)
  /// [imagePaths] — absolute file paths on device to upload.
  static Future<LandlordHostel> createHostel({
    required String hostelName,
    required String location,
    required String description,
    required String whatsappNumber,
    List<String> imagePaths = const [],
  }) async {
    final opts = await _authOptions(isMultipart: true);

    final formData = FormData.fromMap({
      'hostel_name': hostelName,
      'location': location,
      'description': description,
      'whatsapp_number': whatsappNumber,
      for (int i = 0; i < imagePaths.length; i++)
        'images': await MultipartFile.fromFile(imagePaths[i]),
    });

    final resp = await _dio.post('/landlord/hostels',
        data: formData, options: opts);
    return LandlordHostel.fromApi(
        resp.data['data'] as Map<String, dynamic>);
  }

  // ── Landlord: Rooms ───────────────────────────────────────────────────────

  /// POST /landlord/hostels/:hostelId/rooms
  static Future<LandlordRoom> createRoom({
    required String hostelId,
    required LandlordRoom room,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.post(
      '/landlord/hostels/$hostelId/rooms',
      data: room.toApiCreate(),
      options: opts,
    );
    return LandlordRoom.fromApi(
        resp.data['data'] as Map<String, dynamic>, hostelId);
  }

  /// PATCH /landlord/hostels/:hostelId/rooms/:roomId
  static Future<LandlordRoom> updateRoom({
    required String hostelId,
    required String roomId,
    double? price,
    int? numberOfRooms,
    int? capacity,
    String? roomType,
  }) async {
    final opts = await _authOptions();
    final body = <String, dynamic>{
      if (price != null) 'price': price.toInt(),
      if (numberOfRooms != null) 'number_of_rooms': numberOfRooms,
      if (capacity != null) 'capacity': capacity,
      if (roomType != null) 'room_type': roomType,
    };
    final resp = await _dio.patch(
      '/landlord/hostels/$hostelId/rooms/$roomId',
      data: body,
      options: opts,
    );
    return LandlordRoom.fromApi(
        resp.data['data'] as Map<String, dynamic>, hostelId);
  }

  // ── Landlord: Notifications ───────────────────────────────────────────────

  /// GET /landlord/notifications
  static Future<List<LandlordNotification>> fetchNotifications() async {
    final opts = await _authOptions();
    final resp =
        await _dio.get('/landlord/notifications', options: opts);
    final data = resp.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) =>
            LandlordNotification.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /landlord/me
  static Future<LandlordProfile> fetchMyProfile() async {
    final opts = await _authOptions();
    final resp = await _dio.get('/landlord/me', options: opts);
    return LandlordProfile.fromApi(
      Map<String, dynamic>.from(resp.data['data'] as Map),
    );
  }

  /// GET /landlord/notifications/count
  static Future<int> fetchNotificationCount() async {
    final opts = await _authOptions();
    final resp =
        await _dio.get('/landlord/notifications/count', options: opts);
    return (resp.data['data']['count'] as num).toInt();
  }

  /// POST /landlord/notifications/mark-all-read
  static Future<void> markAllNotificationsRead() async {
    final opts = await _authOptions();
    await _dio.post('/landlord/notifications/mark-all-read', options: opts);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// POST /landlord/auth/reset-password
  static Future<void> resetPassword(String newPassword) async {
    final opts = await _authOptions();
    await _dio.post(
      '/landlord/auth/reset-password',
      data: {'new_password': newPassword},
      options: opts,
    );
  }

  /// POST /landlord/auth/logout
  static Future<void> logout() async {
    final opts = await _authOptions();
    await _dio.post('/landlord/auth/logout', options: opts);
  }
}

// ─── Runtime Store (live data cache) ─────────────────────────────────────────
///
/// This is a thin in-memory cache that the UI reads from.
/// Populate it by calling the ApiService methods and storing results here.
/// There is NO pre-seeded dummy data.

class LandlordStore {
  // ── Profile ──
  static LandlordProfile currentLandlord = LandlordProfile.empty();

  // ── Live data lists (populated by API calls in the dashboard) ──
  static List<LandlordHostel> _hostels = [];
  static List<LandlordBooking> _bookings = [];
  static List<LandlordNotification> _notifications = [];

  // ── Setters (called after API responses) ──
  static void setHostels(List<LandlordHostel> data) => _hostels = data;
  static void setBookings(List<LandlordBooking> data) => _bookings = data;
  static void setNotifications(List<LandlordNotification> data) =>
      _notifications = data;
  static void setProfile(LandlordProfile profile) =>
      currentLandlord = profile;

  // ── Getters ──
  static List<LandlordHostel> get hostels => List.from(_hostels);
  static List<LandlordBooking> get bookings => List.from(_bookings);
  static List<LandlordNotification> get notifications =>
      List.from(_notifications);

  static int get unreadNotifications =>
      _notifications.where((n) => !n.isRead).length;

  // ── Derived earnings / stats (computed from live data) ──
  static double get totalEarnings =>
      _bookings.fold(0, (sum, b) => sum + b.amountPaid);

  static double get thisMonthEarnings {
    final now = DateTime.now();
    return _bookings
        .where((b) =>
            b.bookedAt.month == now.month && b.bookedAt.year == now.year)
        .fold(0, (sum, b) => sum + b.amountPaid);
  }

  static double get pendingPayments =>
      _bookings.fold(0, (sum, b) => sum + b.balanceDue);

  static int get activeBookings =>
      _bookings.where((b) => b.status == BookingStatusEnum.active).length;

  static int get pendingBookings =>
      _bookings.where((b) => b.status == BookingStatusEnum.pending).length;

    static int get totalOccupied =>
      _hostels.fold(0, (sum, h) => sum + h.occupiedRooms);

  static int get totalCapacity =>
      _hostels.fold(0, (sum, h) => sum + h.totalRooms);

  static int get availableRooms {
    final available = totalCapacity - totalOccupied;
    return available < 0 ? 0 : available;
  }

  // ── Local mutations (optimistic UI updates) ──
  static void addHostel(LandlordHostel hostel) =>
      _hostels.insert(0, hostel);

  static void addRoomToHostel(String hostelId, LandlordRoom room) {
    final hostel = _hostels.firstWhere((h) => h.id == hostelId,
        orElse: () => throw StateError('Hostel $hostelId not found'));
    hostel.rooms.add(room);
  }

  static void markNotificationRead(String id) {
    final n = _notifications.firstWhere((n) => n.id == id,
        orElse: () => throw StateError('Notification $id not found'));
    n.isRead = true;
  }

  static void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
  }

  static void updateBookingStatus(String id, BookingStatusEnum status) {
    final b = _bookings.firstWhere((b) => b.id == id,
        orElse: () => throw StateError('Booking $id not found'));
    b.status = status;
  }

  static void clear() {
    _hostels = [];
    _bookings = [];
    _notifications = [];
    currentLandlord = LandlordProfile.empty();
  }
}