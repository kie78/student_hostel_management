// landlord_dashboard_screen.dart
// On first load the dashboard fetches:
//   GET /landlord/hostels                     → populates LandlordStore.hostels
//   GET /landlord/hostels/:hostelId/bookings → populates LandlordStore.bookings
//   GET /landlord/notifications              → populates LandlordStore.notifications
// Pull-to-refresh re-fetches all three.
// No dummy / mock data anywhere.

import 'package:dio/dio.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../role_select_screen.dart';
import 'landlord_models.dart';
import 'add_hostel_screen.dart' show AddHostelScreen;
import 'landlord_bookings_screen.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  int _unreadBadgeCount = 0;
  String? _errorMessage;

  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryController,
                curve: Curves.easeOutCubic));
    _entryController.forward();
    _loadDashboard();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadDashboard() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Hostels must load first because bookings are fetched per hostel.
      final hostels = await ApiService.fetchMyHostels();
      LandlordStore.setHostels(hostels);

      final results = await Future.wait([
        ApiService.fetchMyProfile(),
        ApiService.fetchAllBookings(hostels),
        ApiService.fetchNotifications(),
      ]);

      LandlordStore.setProfile(results[0] as LandlordProfile);
      LandlordStore.setBookings(results[1] as List<LandlordBooking>);
      LandlordStore.setNotifications(
          results[2] as List<LandlordNotification>);
      _unreadBadgeCount = LandlordStore.unreadNotifications;
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg != null) return msg.toString();
      switch (e.response?.statusCode) {
        case 401: return 'Session expired. Please log in again.';
        case 403: return 'Account suspended or access denied.';
        case 500: return 'Server error. Please try again later.';
      }
    }
    return 'Could not load dashboard. Pull down to retry.';
  }

  String _formatUGX(double amount) {
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX ${amount.toStringAsFixed(0)}';
  }

  void _refresh() => _loadDashboard();

  String _metadataValue(
    Map<String, dynamic>? metadata,
    List<String> keys,
  ) {
    if (metadata == null) return '';
    for (final key in keys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  LandlordProfile _effectiveProfile(BuildContext context) {
    final stored = LandlordStore.currentLandlord;
    final auth = ClerkAuth.of(context, listen: false);
    final user = auth.user;
    final publicMetadata = user?.publicMetadata;
    final unsafeMetadata = user?.unsafeMetadata;

    String metadata(List<String> keys) {
      final publicValue = _metadataValue(publicMetadata, keys);
      if (publicValue.isNotEmpty) return publicValue;
      return _metadataValue(unsafeMetadata, keys);
    }

    final email = stored.email.isNotEmpty
        ? stored.email
        : metadata(const ['email', 'studentEmail', 'student_email']).isNotEmpty
            ? metadata(const ['email', 'studentEmail', 'student_email'])
            : (user?.emailAddresses ?? []).firstOrNull?.emailAddress ?? '';

    final fullName = stored.fullName.isNotEmpty
        ? stored.fullName
        : metadata(const [
            'fullName',
            'full_name',
            'name',
            'otherNames',
            'other_names',
          ]).isNotEmpty
            ? metadata(const [
                'fullName',
                'full_name',
                'name',
                'otherNames',
                'other_names',
              ])
            : [user?.firstName ?? '', user?.lastName ?? '']
                .where((part) => part.trim().isNotEmpty)
                .join(' ')
                .trim();

    return LandlordProfile(
      id: stored.id.isNotEmpty ? stored.id : user?.id ?? 'local-landlord',
      fullName: fullName.isNotEmpty ? fullName : 'Landlord',
      username: stored.username.isNotEmpty
          ? stored.username
          : metadata(const ['username']),
      landlordCode: stored.landlordCode.isNotEmpty
          ? stored.landlordCode
          : metadata(const ['landlordCode', 'landlord_code', 'code']),
      email: email,
      phone: stored.phone.isNotEmpty
          ? stored.phone
          : metadata(const ['phone', 'phoneNumber', 'phone_number']),
      whatsappNumber: stored.whatsappNumber.isNotEmpty
          ? stored.whatsappNumber
          : metadata(const ['whatsappNumber', 'whatsapp_number']),
      gender: stored.gender.isNotEmpty
          ? stored.gender
          : metadata(const ['gender']),
      nin: stored.nin.isNotEmpty ? stored.nin : metadata(const ['nin']),
      maritalStatus: stored.maritalStatus.isNotEmpty
          ? stored.maritalStatus
          : metadata(const ['maritalStatus', 'marital_status']),
      universityName: stored.universityName.isNotEmpty
          ? stored.universityName
          : metadata(const ['universityName', 'university_name']),
      joinedAt: stored.joinedAt,
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'L';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _openAddHostel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddHostelScreen()),
    );
    _loadDashboard();
  }

  Future<void> _doLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      final auth = ClerkAuth.of(context, listen: false);
      await AuthService.logout(auth: auth, role: 'landlord');
      LandlordStore.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: _isLoggingOut ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _doLogout();
                    },
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  : const Text('Log Out',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: _buildCurrentTab(),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _currentTab == 0
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await _openAddHostel();
                },
                backgroundColor: const Color(0xFF006B4F),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Hostel',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              )
            : null,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return LandlordBookingsScreen(onUpdate: _refresh);
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF006B4F),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 118,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: const Color(0xFF006B4F),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildAppBarBackground(),
            ),
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF006B4F))),
                  )
                : _errorMessage != null
                    ? _buildErrorBanner()
                    : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarBackground() {
    final name = LandlordStore.currentLandlord.fullName;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006B4F), Color(0xFF00A876)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_greeting()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.isNotEmpty ? name.split(' ').first : 'Landlord',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentTab = 2;
                      _unreadBadgeCount = 0;
                    }),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        if (_unreadBadgeCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadBadgeCount > 99
                                      ? '99+'
                                      : '$_unreadBadgeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.wifi_off_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadDashboard,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF006B4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final hostels = LandlordStore.hostels;
    final pendingBookings = LandlordStore.pendingBookings;

    return Column(
      children: [
        const SizedBox(height: 14),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildStatsRow(),
        ),
        const SizedBox(height: 16),

        // Pending bookings alert
        if (pendingBookings > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPendingAlert(pendingBookings),
          ),
        if (pendingBookings > 0) const SizedBox(height: 16),

        const SizedBox(height: 20),

        // My hostels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Hostels',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1147))),
              Text(
                '${hostels.length} listing${hostels.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (hostels.isEmpty)
          _buildEmptyHostels()
        else
          ...hostels.map((h) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _HostelCard(
                  hostel: h,
                  formatUGX: _formatUGX,
                  onTap: () {},
                ),
              )),

        const SizedBox(height: 24),

        // Recent notifications (as activity feed)
        if (LandlordStore.notifications.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1147))),
                GestureDetector(
                  onTap: () => setState(() => _currentTab = 2),
                  child: const Text('View all',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF006B4F),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...LandlordStore.notifications.take(3).map((n) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _NotificationMiniCard(notification: n),
              )),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final occupied = LandlordStore.totalOccupied;
    final total = LandlordStore.totalCapacity;
    final available = LandlordStore.availableRooms;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${LandlordStore.hostels.length}',
                label: 'Hostels',
                icon: Icons.apartment_rounded,
                color: const Color(0xFF006B4F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$total',
                label: 'Rooms',
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFF1A1F71),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '$occupied/$total',
                label: 'Occupied Rooms',
                icon: Icons.bed_rounded,
                color: const Color(0xFF7B2FF7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$available',
                label: 'Available Rooms',
                icon: Icons.event_available_rounded,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Pending Alert ─────────────────────────────────────────────────────────

  Widget _buildPendingAlert(int count) {
    return GestureDetector(
      onTap: () => setState(() => _currentTab = 1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pending_actions,
                  color: Color(0xFFB45309), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You have $count pending booking${count > 1 ? 's' : ''} awaiting confirmation.',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFB45309), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHostels() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF006B4F).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Text('🏠', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No hostels listed yet',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0D1147))),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Hostel" to list your first property.',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Notifications Tab ─────────────────────────────────────────────────────

  Widget _buildNotificationsTab() {
    final notifications = LandlordStore.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (LandlordStore.unreadNotifications > 0)
            TextButton(
              onPressed: () async {
                LandlordStore.markAllNotificationsRead();
                setState(() => _unreadBadgeCount = 0);
                try {
                  await ApiService.markAllNotificationsRead();
                } catch (_) {}
              },
              child: const Text('Mark all read',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF006B4F)))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: const Color(0xFF006B4F),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      return _NotificationCard(
                        notification: n,
                        onTap: () {
                          LandlordStore.markNotificationRead(n.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
    );
  }

  // ── Profile Tab ───────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    final profile = _effectiveProfile(context);
    final code =
        profile.landlordCode.isNotEmpty ? profile.landlordCode : 'Code unavailable';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006B4F).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(
                      _initials(profile.fullName),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (profile.email.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1147),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Alerts',
                    subtitle: LandlordStore.unreadNotifications > 0
                        ? '${LandlordStore.unreadNotifications} unread'
                        : 'View updates',
                    icon: Icons.notifications_rounded,
                    color: const Color(0xFF1A1F71),
                    onTap: () => setState(() => _currentTab = 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Bookings',
                    subtitle: 'Manage reservations',
                    icon: Icons.book_online_rounded,
                    color: const Color(0xFF006B4F),
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Add Hostel',
                    subtitle: 'List a new property',
                    icon: Icons.add_business_rounded,
                    color: const Color(0xFFB45309),
                    onTap: _openAddHostel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Logout',
                    subtitle: _isLoggingOut ? 'Signing out...' : 'Sign out safely',
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFB91C1C),
                    isLoading: _isLoggingOut,
                    onTap: _confirmLogout,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home', 'tab': 0},
      {'icon': Icons.book_online_rounded, 'label': 'Bookings', 'tab': 1},
      {'icon': Icons.person_rounded, 'label': 'Profile', 'tab': 3},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final tabIndex = item['tab'] as int;
              final isActive = _currentTab == tabIndex;

              return GestureDetector(
                onTap: () => setState(() => _currentTab = tabIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF006B4F).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isActive
                                ? const Color(0xFF006B4F)
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF006B4F)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _ProfileActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ProfileActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1147),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _HostelCard extends StatelessWidget {
  final LandlordHostel hostel;
  final String Function(double) formatUGX;
  final VoidCallback onTap;

  const _HostelCard(
      {required this.hostel,
      required this.formatUGX,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: hostel.imageUrls.isNotEmpty
                      ? Image.network(
                          hostel.imageUrls.first,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hostel.isActive
                          ? const Color(0xFF00C48C)
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hostel.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(hostel.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF0D1147))),
                      ),
                      if (hostel.rooms.isNotEmpty)
                        Text(
                          'from ${formatUGX(hostel.lowestPrice)}/sem',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF006B4F),
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(hostel.location,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (hostel.totalRooms > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Occupancy',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                  Text(
                                    '${hostel.occupiedRooms}/${hostel.totalRooms} rooms',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF006B4F)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      hostel.occupancyRate / 100,
                                  backgroundColor:
                                      Colors.grey.shade100,
                                  valueColor:
                                      const AlwaysStoppedAnimation<
                                              Color>(
                                          Color(0xFF006B4F)),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 140,
        color: const Color(0xFFE8F5EF),
        child: const Center(
          child: Icon(Icons.apartment,
              size: 48, color: Color(0xFF006B4F)),
        ),
      );
}

class _NotificationMiniCard extends StatelessWidget {
  final LandlordNotification notification;
  const _NotificationMiniCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFE8F5EF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF006B4F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              notification.type == 'payment'
                  ? Icons.payments_outlined
                  : notification.type == 'termination'
                      ? Icons.exit_to_app
                      : Icons.book_online_outlined,
              color: const Color(0xFF006B4F),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0D1147))),
                const SizedBox(height: 2),
                Text(notification.message,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF006B4F),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final LandlordNotification notification;
  final VoidCallback onTap;
  const _NotificationCard(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFE8F5EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : const Color(0xFF006B4F).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF006B4F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                notification.type == 'payment'
                    ? Icons.payments_outlined
                    : notification.type == 'termination'
                        ? Icons.exit_to_app
                        : Icons.book_online_outlined,
                color: const Color(0xFF006B4F),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0D1147))),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF006B4F),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

