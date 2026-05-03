// ─── University Module Models & Store ────────────────────────────────────────

enum LandlordRegistrationStatus { pending, active, suspended }
enum DocumentType { ownershipDeed, nationalId, utilityBill, leaseAgreement }

// ─── University Landlord Model ────────────────────────────────────────────────

class UniversityLandlord {
  final String id;
  final String fullName;
  final String gender;
  final String nin; // National Identification Number
  final String maritalStatus;
  final String email;
  final String phone;
  final String whatsappNumber;
  final List<String> ownershipDocuments;
  final String universityId;
  final String landlordCode;
  final String username;
  LandlordRegistrationStatus status;
  final DateTime registeredAt;
  int hostelCount;
  int activeBookings;

  UniversityLandlord({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.nin,
    required this.maritalStatus,
    required this.email,
    this.phone = '',
    required this.whatsappNumber,
    this.ownershipDocuments = const [],
    required this.universityId,
    required this.landlordCode,
    required this.username,
    this.status = LandlordRegistrationStatus.pending,
    required this.registeredAt,
    this.hostelCount = 0,
    this.activeBookings = 0,
  });

  String get initials =>
      fullName.split(' ').map((w) => w[0].toUpperCase()).take(2).join();

  String get statusLabel {
    switch (status) {
      case LandlordRegistrationStatus.pending:   return 'Pending';
      case LandlordRegistrationStatus.active:    return 'Active';
      case LandlordRegistrationStatus.suspended: return 'Suspended';
    }
  }
}

// ─── University Student Model ─────────────────────────────────────────────────

class UniversityStudent {
  final String id;
  final String fullName;
  final String surname;
  final String otherNames;
  final String studentId;
  final String email;
  final String gender;
  final String courseYear;
  final String phone;
  final DateTime joinedAt;
  bool hasBooking;
  String? bookedHostel;

  UniversityStudent({
    required this.id,
    required this.fullName,
    required this.surname,
    required this.otherNames,
    required this.studentId,
    required this.email,
    required this.gender,
    required this.courseYear,
    required this.phone,
    required this.joinedAt,
    this.hasBooking = false,
    this.bookedHostel,
  });

  String get initials =>
      fullName.split(' ').map((w) => w[0].toUpperCase()).take(2).join();
}

// ─── University Hostel (read-only view) ───────────────────────────────────────

class UniversityHostel {
  final String id;
  final String name;
  final String location;
  final String landlordName;
  final String landlordCode;
  final double lowestPrice;
  final int totalRooms;
  final int occupiedRooms;
  final bool isVerified;
  final String imageUrl;

  const UniversityHostel({
    required this.id,
    required this.name,
    required this.location,
    required this.landlordName,
    required this.landlordCode,
    required this.lowestPrice,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.isVerified,
    required this.imageUrl,
  });

  int get availableRooms => totalRooms - occupiedRooms;
  double get occupancyRate =>
      totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0;
}

// ─── University Profile Model ─────────────────────────────────────────────────

class UniversityProfile {
  final String id;
  final String name;
  final String location;
  final String type; // Government / Private
  final String email;
  final DateTime joinedAt;

  const UniversityProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.email,
    required this.joinedAt,
  });
}

// ─── University Store ─────────────────────────────────────────────────────────
class UniversityStore {
  static UniversityProfile currentUniversity = UniversityProfile(
    id: '',
    name: '',
    location: '',
    type: '',
    email: '',
    joinedAt: DateTime.now(),
  );

  // Call this right after login succeeds
  static void setFromApiData(Map<String, dynamic> data) {
    final profile =
        data['profile'] is Map<String, dynamic>
            ? data['profile'] as Map<String, dynamic>
            : data['profile'] is Map
                ? Map<String, dynamic>.from(data['profile'] as Map)
                : data;

    currentUniversity = UniversityProfile(
      id: data['id'] ?? '',
      name: profile['universityName'] ?? data['universityName'] ?? '',
      location: profile['location'] ?? data['location'] ?? '',
      type: profile['type'] ?? data['type'] ?? '',
      email: profile['email'] ?? data['email'] ?? '',
      joinedAt:
          DateTime.tryParse((data['createdAt'] ?? profile['createdAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }

  static bool get isLoaded => currentUniversity.id.isNotEmpty;

  static List<UniversityLandlord> get landlords => [];
  static List<UniversityStudent> get students   => [];
  static List<UniversityHostel> get hostels     => [];

  static int get totalLandlords  => 0;
  static int get activeLandlords => 0;
  static int get totalStudents   => 0;
  static int get bookedStudents  => 0;
  static int get totalHostels    => 0;
  static int get totalRooms      => 0;
  static int get occupiedRooms   => 0;

  static String generateLandlordCode() => '';
  static String generateUsername(String fullName) =>
      fullName.toLowerCase().replaceAll(' ', '_');
}