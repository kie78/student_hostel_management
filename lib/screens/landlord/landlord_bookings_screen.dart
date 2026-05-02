// landlord_bookings_screen.dart
// Two tabs: Active (booked rooms) and Terminated (ended bookings).
// Terminate action is directly on the card for active bookings.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'landlord_models.dart';

class LandlordBookingsScreen extends StatefulWidget {
  final VoidCallback? onUpdate;
  const LandlordBookingsScreen({super.key, this.onUpdate});

  @override
  State<LandlordBookingsScreen> createState() =>
      _LandlordBookingsScreenState();
}

class _LandlordBookingsScreenState extends State<LandlordBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _terminatingBookingId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Hostels must be fetched first — their IDs are used for the
      // per-hostel bookings endpoint.
      final hostels = await ApiService.fetchMyHostels();
      LandlordStore.setHostels(hostels);
      final bookings = await ApiService.fetchAllBookings(hostels);
      LandlordStore.setBookings(bookings);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg != null) return msg.toString();
      switch (e.response?.statusCode) {
        case 401: return 'Session expired. Please log in again.';
        case 403: return 'Access denied.';
        case 500: return 'Server error. Please try again later.';
      }
    }
    return 'Could not load bookings. Pull down to retry.';
  }

  List<LandlordBooking> get _activeBookings => LandlordStore.bookings
      .where((b) => b.status == BookingStatusEnum.active)
      .toList();

  List<LandlordBooking> get _terminatedBookings => LandlordStore.bookings
      .where((b) =>
          b.status == BookingStatusEnum.cancelled ||
          b.status == BookingStatusEnum.completed)
      .toList();

  String _formatUGX(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _confirmTerminate(LandlordBooking booking) async {
    if (_terminatingBookingId == booking.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminate Booking'),
        content: Text(
          "Terminate ${booking.studentName}'s booking at ${booking.hostelName}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        setState(() => _terminatingBookingId = booking.id);
        await ApiService.terminateBooking(
          hostelId: booking.hostelId,
          bookingId: booking.id,
        );
        LandlordStore.updateBookingStatus(
            booking.id, BookingStatusEnum.completed);
        if (!mounted) return;
        setState(() {});
        widget.onUpdate?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking terminated successfully'),
          ),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _terminatingBookingId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: const Color(0xFF006B4F),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            expandedHeight: 108,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 52),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bookings',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Student bookings on your properties',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF006B4F),
                  unselectedLabelColor: Colors.grey.shade400,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  indicatorColor: const Color(0xFF006B4F),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Terminated'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF006B4F)))
            : _errorMessage != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF006B4F),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_activeBookings, isActive: true),
                        _buildList(_terminatedBookings, isActive: false),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onTap: _loadData,
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
      ),
    );
  }

  Widget _buildList(List<LandlordBooking> bookings,
      {required bool isActive}) {
    if (bookings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive
                      ? Icons.apartment_outlined
                      : Icons.do_not_disturb_alt_outlined,
                  size: 56,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  isActive
                      ? 'No active bookings'
                      : 'No terminated bookings',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _BookingHostelCard(
        booking: bookings[i],
        isActive: isActive,
        formatDate: _formatDate,
        formatUGX: _formatUGX,
        isTerminating: _terminatingBookingId == bookings[i].id,
        onTerminate: isActive ? () => _confirmTerminate(bookings[i]) : null,
      ),
    );
  }
}

// ─── Booking Hostel Card ──────────────────────────────────────────────────────

class _BookingHostelCard extends StatelessWidget {
  final LandlordBooking booking;
  final bool isActive;
  final bool isTerminating;
  final String Function(DateTime) formatDate;
  final String Function(double) formatUGX;
  final VoidCallback? onTerminate;

  const _BookingHostelCard({
    required this.booking,
    required this.isActive,
    required this.isTerminating,
    required this.formatDate,
    required this.formatUGX,
    this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    final hostel = LandlordStore.hostels
        .where((h) => h.id == booking.hostelId)
        .firstOrNull;
    final imageUrl =
        (hostel?.imageUrls.isNotEmpty == true) ? hostel!.imageUrls.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + overlay buttons ──────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              // Status badge – top left (terminated only)
              if (!isActive)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Terminated',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              // Terminate button – top right (active only)
              if (isActive && onTerminate != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: isTerminating ? null : onTerminate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isTerminating
                            ? Colors.red.withValues(alpha: 0.8)
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTerminating) ...[
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('Terminating',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ] else ...[
                            const Icon(Icons.stop_circle_outlined,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            const Text('Terminate',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Card body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.hostelName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1147)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B4F)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bed_outlined,
                              size: 12, color: Color(0xFF006B4F)),
                          const SizedBox(width: 4),
                          Text(
                            booking.roomType,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF006B4F),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatUGX(booking.monthlyAmount),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006B4F)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF1A1F71)
                          .withValues(alpha: 0.08),
                      child: Text(
                        _initials(booking.studentName),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F71)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.studentName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D1147)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Booked ${formatDate(booking.bookedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 130,
        width: double.infinity,
        color: const Color(0xFF006B4F).withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.apartment_rounded,
              size: 40, color: Color(0xFF006B4F)),
        ),
      );

  String _initials(String name) =>
      name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
}