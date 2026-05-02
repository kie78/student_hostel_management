import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../role_select_screen.dart';
import 'hostel_list_screen.dart';
import 'booking_screen.dart';

// ─── Student Shell ─────────────────────────────────────────────────────────────

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentTab = 0;
  int _unreadNotifications = 0;

  void _onTabChange(int i) => setState(() => _currentTab = i);

  void _setUnread(int count) {
    if (count != _unreadNotifications) setState(() => _unreadNotifications = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _buildCurrentTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return const HostelListScreen();
      case 1:
        return const _StudentBookingsTab();
      case 2:
        return _StudentNotificationsTab(onUnreadCount: _setUnread);
      case 3:
        return _StudentProfileTab(onTabChange: _onTabChange);
      default:
        return const HostelListScreen();
    }
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_rounded,
        'label': 'Home',
        'tab': 0,
      },
      {
        'icon': Icons.book_online_rounded,
        'label': 'Bookings',
        'tab': 1,
      },
      {
        'icon': Icons.person_rounded,
        'label': 'Profile',
        'tab': 3,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A1F71).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isActive
                                ? const Color(0xFF1A1F71)
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF1A1F71)
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
}

// ─── My Bookings Tab ───────────────────────────────────────────────────────────

class _StudentBookingsTab extends StatefulWidget {
  const _StudentBookingsTab();

  @override
  State<_StudentBookingsTab> createState() => _StudentBookingsTabState();
}

class _StudentBookingsTabState extends State<_StudentBookingsTab> {
  List<BookingData> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final raw = await StudentApiService.getMyBookings();
      setState(() {
        _bookings = raw
            .map((b) =>
                BookingData.fromApiResponse(b as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load bookings.';
      });
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Pull to retry.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return 'UGX ${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F71),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1F71)))
          : _errorMessage != null
              ? _buildError()
              : _bookings.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      color: const Color(0xFF1A1F71),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _bookings[i],
                          formatDate: _formatDate,
                          formatPrice: _formatPrice,
                          onTerminate: _bookings[i].status == 'active'
                              ? () => _confirmTerminate(_bookings[i])
                              : null,
                        ),
                      ),
                    ),
    );
  }

  Future<void> _confirmTerminate(BookingData booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminate Booking'),
        content: Text(
            'Are you sure you want to terminate your booking at ${booking.hostelName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Terminate')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await StudentApiService.terminateBooking(booking.id);
        _loadBookings();
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Failed to terminate booking.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1F71),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_online_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No bookings yet',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1147))),
            const SizedBox(height: 6),
            Text(
              'Browse hostels on the Home tab and book a room.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingData booking;
  final String Function(DateTime) formatDate;
  final String Function(double) formatPrice;
  final VoidCallback? onTerminate;

  const _BookingCard({
    required this.booking,
    required this.formatDate,
    required this.formatPrice,
    this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = booking.status == 'active';
    final statusColor = isActive ? const Color(0xFF006B4F) : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.hostelName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1147)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Terminated',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(booking.hostelLocation,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.bed_outlined,
                    label: booking.roomTypeName),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.attach_money,
                    label: formatPrice(booking.roomPrice)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booked ${formatDate(booking.createdAt)}',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.grey.shade400),
                ),
                if (onTerminate != null)
                  GestureDetector(
                    onTap: onTerminate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Terminate',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF1A1F71)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1F71),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Notifications Tab ─────────────────────────────────────────────────────────

class _StudentNotificationsTab extends StatefulWidget {
  final void Function(int) onUnreadCount;
  const _StudentNotificationsTab({required this.onUnreadCount});

  @override
  State<_StudentNotificationsTab> createState() =>
      _StudentNotificationsTabState();
}

class _StudentNotificationsTabState extends State<_StudentNotificationsTab> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final raw = await StudentApiService.getNotifications();
      final list = raw.cast<Map<String, dynamic>>();
      setState(() => _notifications = list);
      widget.onUnreadCount(list.where((n) => n['isRead'] == false).length);
    } catch (_) {
      // silently fail — notifications are non-critical
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment': return Icons.payment_rounded;
      case 'booking': return Icons.book_online_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'payment': return const Color(0xFF006B4F);
      case 'booking': return const Color(0xFF1A1F71);
      default: return const Color(0xFF7B2FF7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F71),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1F71)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFF1A1F71),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final type = n['type'] as String? ?? 'general';
                      final isRead = n['isRead'] as bool? ?? true;
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isRead ? Colors.white : const Color(0xFFEEF0F8),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: _typeColor(type)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_typeIcon(type),
                                    color: _typeColor(type), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] as String? ?? '',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              color: const Color(0xFF0D1147),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(
                                              n['createdAt'] as String? ?? ''),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['body'] as String? ?? '',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.grey.shade600,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8, top: 4),
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Color(0xFF1A1F71),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Profile Tab ───────────────────────────────────────────────────────────────

class _StudentProfileTab extends StatelessWidget {
  final void Function(int) onTabChange;
  const _StudentProfileTab({required this.onTabChange});

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

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: false);
    final user = auth.user;
    final publicMetadata = user?.publicMetadata;
    final unsafeMetadata = user?.unsafeMetadata;
    final submittedSurname = _metadataValue(
      publicMetadata,
      const ['surname', 'lastName', 'last_name'],
    ).isNotEmpty
        ? _metadataValue(
            publicMetadata,
            const ['surname', 'lastName', 'last_name'],
          )
        : _metadataValue(
            unsafeMetadata,
            const ['surname', 'lastName', 'last_name'],
          );
    final submittedOtherNames = _metadataValue(
      publicMetadata,
      const ['otherNames', 'other_names', 'firstName', 'first_name'],
    ).isNotEmpty
        ? _metadataValue(
            publicMetadata,
            const ['otherNames', 'other_names', 'firstName', 'first_name'],
          )
        : _metadataValue(
            unsafeMetadata,
            const ['otherNames', 'other_names', 'firstName', 'first_name'],
          );
    final submittedEmail = _metadataValue(
      publicMetadata,
      const ['studentEmail', 'student_email', 'email'],
    ).isNotEmpty
        ? _metadataValue(
            publicMetadata,
            const ['studentEmail', 'student_email', 'email'],
          )
        : _metadataValue(
            unsafeMetadata,
            const ['studentEmail', 'student_email', 'email'],
          );
    final fallbackEmail =
        (user?.emailAddresses ?? []).firstOrNull?.emailAddress ?? '';
    final fallbackFirstName = user?.firstName ?? '';
    final fallbackLastName = user?.lastName ?? '';
    final fullName = [submittedSurname, submittedOtherNames]
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim()
            .isNotEmpty
        ? [submittedSurname, submittedOtherNames]
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim()
        : [fallbackFirstName, fallbackLastName]
            .where((s) => s.isNotEmpty)
            .join(' ');
    final email = submittedEmail.isNotEmpty ? submittedEmail : fallbackEmail;
    final initials = fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F71),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor:
                        const Color(0xFF1A1F71).withValues(alpha: 0.1),
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1F71)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Student',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1147)),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF1A1F71).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Student',
                        style: TextStyle(
                            color: Color(0xFF1A1F71),
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Info rows
            if (fullName.isNotEmpty)
              _ProfileRow(label: 'Full Name', value: fullName),

            const SizedBox(height: 24),

            // Quick actions
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1147))),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.home_rounded,
              label: 'Browse Hostels',
              color: const Color(0xFF1A1F71),
              onTap: () => onTabChange(0),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.book_online_rounded,
              label: 'My Bookings',
              color: const Color(0xFF006B4F),
              onTap: () => onTabChange(1),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              color: const Color(0xFFB45309),
              onTap: () => onTabChange(2),
            ),
            const SizedBox(height: 24),

            // Logout
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Log Out',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Log Out')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final auth = ClerkAuth.of(context, listen: false);
      await AuthService.logout(auth: auth, role: 'student');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
          (route) => false,
        );
      }
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0D1147),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1147))),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
