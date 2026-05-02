// landlord_dashboard_screen.dart
// On first load the dashboard fetches:
//   GET /landlord/hostels      → populates LandlordStore.hostels
//   GET /landlord/notifications → populates LandlordStore.notifications
// Pull-to-refresh re-fetches both.
// No dummy / mock data anywhere.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'landlord_models.dart';
import 'add_hostel_screen.dart' hide LandlordStore;
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
      // Parallel fetch: hostels + notifications
      final results = await Future.wait([
        ApiService.fetchMyHostels(),
        ApiService.fetchNotifications(),
      ]);

      LandlordStore.setHostels(results[0] as List<LandlordHostel>);
      LandlordStore.setNotifications(
          results[1] as List<LandlordNotification>);
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
    if (amount >= 1000000)
      return 'UGX ${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000)
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    return 'UGX ${amount.toStringAsFixed(0)}';
  }

  void _refresh() => _loadDashboard();

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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddHostelScreen()),
                  );
                  // Refresh after returning from add hostel
                  _loadDashboard();
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
            expandedHeight: 200,
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
            child: Transform.translate(
              offset: const Offset(0, -20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarBackground() {
    final name = LandlordStore.currentLandlord.fullName;
    final code = LandlordStore.currentLandlord.landlordCode;

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
                color: Colors.white.withOpacity(0.06),
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
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            name.isNotEmpty
                                ? name.split(' ').first
                                : 'Landlord',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Notifications bell
                          GestureDetector(
                            onTap: () =>
                                setState(() => _currentTab = 2),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22),
                                ),
                                if (LandlordStore
                                        .unreadNotifications >
                                    0)
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
                                          '${LandlordStore.unreadNotifications}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          GestureDetector(
                            onTap: () =>
                                setState(() => _currentTab = 3),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withOpacity(0.2),
                              child: Text(
                                name.isNotEmpty
                                    ? name
                                        .split(' ')
                                        .map((w) => w.isNotEmpty
                                            ? w[0]
                                            : '')
                                        .take(2)
                                        .join()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (code.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vpn_key_outlined,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 6),
                          Text(code,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
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
        // Earnings card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildEarningsCard(),
        ),
        const SizedBox(height: 16),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildStatsRow(),
        ),
        const SizedBox(height: 20),

        // Pending bookings alert
        if (pendingBookings > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPendingAlert(pendingBookings),
          ),
        if (pendingBookings > 0) const SizedBox(height: 16),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildQuickActions(),
        ),
        const SizedBox(height: 24),

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

  // ── Earnings Card ─────────────────────────────────────────────────────────

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1147), Color(0xFF1A1F71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1147).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Earnings',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF00C48C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Color(0xFF00C48C), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${LandlordStore.hostels.length} hostel${LandlordStore.hostels.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Color(0xFF00C48C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatUGX(LandlordStore.totalEarnings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EarningsTile(
                  label: 'This Month',
                  value:
                      _formatUGX(LandlordStore.thisMonthEarnings),
                  icon: Icons.calendar_today,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EarningsTile(
                  label: 'Pending',
                  value:
                      _formatUGX(LandlordStore.pendingPayments),
                  icon: Icons.hourglass_empty,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final occupied = LandlordStore.totalOccupied;
    final total = LandlordStore.totalCapacity;
    final rate = total > 0
        ? (occupied / total * 100).toStringAsFixed(0)
        : '0';

    return Row(
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
            value: '${LandlordStore.activeBookings}',
            label: 'Active',
            icon: Icons.people_rounded,
            color: const Color(0xFF1A1F71),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$occupied/$total',
            label: 'Occupied',
            icon: Icons.bed_rounded,
            color: const Color(0xFF7B2FF7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$rate%',
            label: 'Occupancy',
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFFB45309),
          ),
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
              color: const Color(0xFFFFD700).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
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

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.apartment_rounded,
        'label': 'Add\nHostel',
        'color': const Color(0xFF006B4F),
        'onTap': () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddHostelScreen()));
          _loadDashboard();
        },
      },
      {
        'icon': Icons.book_online_rounded,
        'label': 'View\nBookings',
        'color': const Color(0xFF1A1F71),
        'onTap': () => setState(() => _currentTab = 1),
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'color': const Color(0xFF7B2FF7),
        'onTap': () => setState(() => _currentTab = 2),
      },
      {
        'icon': Icons.person_outline_rounded,
        'label': 'My\nProfile',
        'color': const Color(0xFFB45309),
        'onTap': () => setState(() => _currentTab = 3),
      },
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              margin: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (a['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a['icon'] as IconData,
                        color: a['color'] as Color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a['label'] as String,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1147),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
            color: const Color(0xFF006B4F).withOpacity(0.15)),
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
              onPressed: () {
                LandlordStore.markAllNotificationsRead();
                setState(() {});
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
    final profile = LandlordStore.currentLandlord;

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
        child: profile.id.isEmpty
            ? const Center(
                child: Text(
                'Profile not loaded yet.',
                style: TextStyle(color: Colors.grey),
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFF006B4F)
                              .withOpacity(0.1),
                          child: Text(
                            profile.fullName
                                .split(' ')
                                .map((w) =>
                                    w.isNotEmpty ? w[0] : '')
                                .take(2)
                                .join(),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF006B4F)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(profile.fullName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1147))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006B4F)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(profile.landlordCode,
                              style: const TextStyle(
                                  color: Color(0xFF006B4F),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ProfileRow(
                      label: 'Email', value: profile.email),
                  _ProfileRow(
                      label: 'Phone', value: profile.phone),
                  _ProfileRow(
                      label: 'WhatsApp',
                      value: profile.whatsappNumber),
                  _ProfileRow(
                      label: 'Gender', value: profile.gender),
                  _ProfileRow(
                      label: 'NIN', value: profile.nin),
                  _ProfileRow(
                      label: 'Marital Status',
                      value: profile.maritalStatus),
                  _ProfileRow(
                      label: 'University',
                      value: profile.universityName),
                  _ProfileRow(
                      label: 'Member Since',
                      value: _formatDate(profile.joinedAt)),
                ],
              ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.book_online_rounded, 'label': 'Bookings'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
              final i = entry.key;
              final item = entry.value;
              final isActive = _currentTab == i;

              return GestureDetector(
                onTap: () => setState(() => _currentTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF006B4F).withOpacity(0.1)
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
                          if (i == 2 &&
                              LandlordStore.unreadNotifications > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B6B),
                                  shape: BoxShape.circle,
                                ),
                              ),
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

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _EarningsTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _EarningsTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade500)),
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
                color: Colors.black.withOpacity(0.05),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF006B4F).withOpacity(0.1),
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
                : const Color(0xFF006B4F).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF006B4F).withOpacity(0.1),
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

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            ),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '—',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1147)),
              ),
            ),
          ],
        ),
      );
}