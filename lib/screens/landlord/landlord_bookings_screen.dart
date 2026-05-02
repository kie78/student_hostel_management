// landlord_bookings_screen.dart
// Bookings are derived from the landlord's hostels (GET /landlord/hostels).
// Each hostel returns rooms; rooms contain booking/occupancy data.
// When a dedicated landlord bookings endpoint becomes available in the API,
// replace _loadData() with a single GET /landlord/bookings call.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _searchQuery = '';
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _tabs = [
    'All', 'Pending', 'Active', 'Completed', 'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Refresh hostels from API; bookings are embedded per-hostel.
      // Re-use the already-loaded LandlordStore.bookings if available.
      // If the store is empty (e.g. direct navigation), fetch fresh.
      if (LandlordStore.bookings.isEmpty) {
        final hostels = await ApiService.fetchMyHostels();
        LandlordStore.setHostels(hostels);
        // Extract bookings from occupancy data if API embeds them.
        // Currently the API returns rooms with occupiedSlots but no
        // student-level booking objects. We show what the store has.
      }
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

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<LandlordBooking> get _filteredBookings {
    var bookings = LandlordStore.bookings;

    final tab = _tabs[_tabController.index];
    if (tab != 'All') {
      final statusMap = {
        'Pending': BookingStatusEnum.pending,
        'Active': BookingStatusEnum.active,
        'Completed': BookingStatusEnum.completed,
        'Cancelled': BookingStatusEnum.cancelled,
      };
      bookings =
          bookings.where((b) => b.status == statusMap[tab]).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      bookings = bookings
          .where((b) =>
              b.studentName.toLowerCase().contains(q) ||
              b.hostelName.toLowerCase().contains(q) ||
              b.id.toLowerCase().contains(q))
          .toList();
    }

    return bookings;
  }

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

  // ── Build ─────────────────────────────────────────────────────────────────

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
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bookings',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            Text('Manage student bookings',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            _HeaderBadge(
                              label:
                                  '${LandlordStore.pendingBookings}',
                              sublabel: 'Pending',
                              color: const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 8),
                            _HeaderBadge(
                              label:
                                  '${LandlordStore.activeBookings}',
                              sublabel: 'Active',
                              color: const Color(0xFF00C48C),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF006B4F),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  indicatorColor: const Color(0xFF006B4F),
                  indicatorWeight: 3,
                  isScrollable: true,
                  tabs: _tabs.map((t) {
                    final count = t == 'All'
                        ? LandlordStore.bookings.length
                        : LandlordStore.bookings
                            .where((b) =>
                                b.statusLabel.toLowerCase() ==
                                t.toLowerCase())
                            .length;
                    return Tab(
                      child: Row(
                        children: [
                          Text(t),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006B4F)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text('$count',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF006B4F))),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText:
                      'Search by student, hostel or booking ID…',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.grey),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF006B4F), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF006B4F)))
                  : _errorMessage != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF006B4F),
                          child: _buildList(),
                        ),
            ),
          ],
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
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 14)),
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

  Widget _buildList() {
    final bookings = _filteredBookings;
    if (bookings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No bookings found',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15)),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BookingCard(
        booking: bookings[i],
        formatUGX: _formatUGX,
        formatDate: _formatDate,
        onTap: () => _showBookingDetail(bookings[i]),
      ),
    );
  }

  void _showBookingDetail(LandlordBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: booking,
        formatUGX: _formatUGX,
        formatDate: _formatDate,
        onStatusUpdate: (status) {
          LandlordStore.updateBookingStatus(booking.id, status);
          setState(() {});
          widget.onUpdate?.call();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final LandlordBooking booking;
  final String Function(double) formatUGX;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.formatUGX,
    required this.formatDate,
    required this.onTap,
  });

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatusEnum.pending:   return const Color(0xFFFF9800);
      case BookingStatusEnum.confirmed: return const Color(0xFF1A1F71);
      case BookingStatusEnum.active:    return const Color(0xFF00C48C);
      case BookingStatusEnum.completed: return Colors.grey;
      case BookingStatusEnum.cancelled: return Colors.red;
    }
  }

  Color get _paymentColor {
    switch (booking.paymentStatus) {
      case PaymentStatusEnum.pending: return const Color(0xFFFF9800);
      case PaymentStatusEnum.partial: return const Color(0xFF1A1F71);
      case PaymentStatusEnum.paid:    return const Color(0xFF00C48C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFF006B4F).withOpacity(0.1),
                  child: Text(
                    _initials(booking.studentName),
                    style: const TextStyle(
                        color: Color(0xFF006B4F),
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0D1147))),
                      Text(
                        '${booking.university} · ${booking.studentId}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(booking.statusLabel,
                          style: TextStyle(
                              color: _statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text(booking.id,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.apartment, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${booking.hostelName} · ${booking.roomType}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Booked: ${formatDate(booking.bookedAt)}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Progress',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                          Text(
                            '${(booking.paymentProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _paymentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: booking.paymentProgress,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _paymentColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paid: ${formatUGX(booking.amountPaid)}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500)),
                          Text(
                            'Total: ${formatUGX(booking.totalAmount)}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatUGX(booking.monthlyAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF006B4F))),
                    Text('/semester',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),

            if (booking.terminationRequested) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.exit_to_app,
                        size: 13, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    Text('Termination requested',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) =>
      name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
}

// ─── Booking Detail Sheet ──────────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  final LandlordBooking booking;
  final String Function(double) formatUGX;
  final String Function(DateTime) formatDate;
  final Function(BookingStatusEnum) onStatusUpdate;

  const _BookingDetailSheet({
    required this.booking,
    required this.formatUGX,
    required this.formatDate,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      const Color(0xFF006B4F).withOpacity(0.1),
                  child: Text(
                    booking.studentName
                        .split(' ')
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .take(2)
                        .join(),
                    style: const TextStyle(
                        color: Color(0xFF006B4F),
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xFF0D1147))),
                      Text(booking.university,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),

            _DetailRow2(label: 'Booking ID', value: booking.id),
            _DetailRow2(label: 'Student ID', value: booking.studentId),
            if (booking.studentPhone.isNotEmpty)
              _DetailRow2(
                  label: 'Phone',
                  value: booking.studentPhone,
                  isLink: true),
            if (booking.studentEmail.isNotEmpty)
              _DetailRow2(
                  label: 'Email',
                  value: booking.studentEmail,
                  isLink: true),
            _DetailRow2(label: 'Hostel', value: booking.hostelName),
            _DetailRow2(
                label: 'Room Type', value: booking.roomType),
            _DetailRow2(
                label: 'Booked On',
                value: formatDate(booking.bookedAt)),
            if (booking.paymentMethod.isNotEmpty)
              _DetailRow2(
                  label: 'Payment Method',
                  value: booking.paymentMethod),
            _DetailRow2(
                label: 'Price',
                value: formatUGX(booking.monthlyAmount),
                highlight: true),
            _DetailRow2(
                label: 'Amount Paid',
                value: formatUGX(booking.amountPaid),
                highlight: true),
            _DetailRow2(
                label: 'Balance Due',
                value: formatUGX(booking.balanceDue),
                highlight: booking.balanceDue > 0),

            const SizedBox(height: 20),

            if (booking.status == BookingStatusEnum.pending) ...[
              const Text('Actions',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0D1147))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Confirm',
                      color: const Color(0xFF00C48C),
                      icon: Icons.check_circle_outline,
                      onTap: () => onStatusUpdate(
                          BookingStatusEnum.confirmed),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Decline',
                      color: Colors.red,
                      icon: Icons.cancel_outlined,
                      onTap: () => onStatusUpdate(
                          BookingStatusEnum.cancelled),
                    ),
                  ),
                ],
              ),
            ],

            if (booking.status == BookingStatusEnum.confirmed) ...[
              _ActionBtn(
                label: 'Mark as Active',
                color: const Color(0xFF1A1F71),
                icon: Icons.people_outline,
                onTap: () =>
                    onStatusUpdate(BookingStatusEnum.active),
                fullWidth: true,
              ),
            ],

            if (booking.terminationRequested &&
                booking.status == BookingStatusEnum.active) ...[
              const SizedBox(height: 12),
              _ActionBtn(
                label: 'Approve Termination',
                color: Colors.orange,
                icon: Icons.exit_to_app,
                onTap: () =>
                    onStatusUpdate(BookingStatusEnum.completed),
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow2 extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isLink;

  const _DetailRow2({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            Flexible(
              child: Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: highlight
                        ? const Color(0xFF006B4F)
                        : isLink
                            ? const Color(0xFF1A1F71)
                            : const Color(0xFF0D1147),
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
              vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _HeaderBadge(
      {required this.label,
      required this.sublabel,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(sublabel,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}