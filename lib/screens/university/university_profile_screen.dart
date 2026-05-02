import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'university_models.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';

class UniversityProfileScreen extends StatefulWidget {
  final VoidCallback? onUpdate;
  const UniversityProfileScreen({super.key, this.onUpdate});

  @override
  State<UniversityProfileScreen> createState() =>
      _UniversityProfileScreenState();
}

class _UniversityProfileScreenState extends State<UniversityProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  int _activeSection = 0; // 0=overview, 1=students, 2=landlords, 3=hostels

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content:
            const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
  Navigator.pop(context); // close dialog
  try {
    await AuthService.logoutUniversity();
  } catch (_) {}
  if (context.mounted) {
    Navigator.popUntil(context, (r) => r.isFirst);
  }
},
           child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uni = UniversityStore.currentUniversity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: CustomScrollView(
            slivers: [
              // ── Sliver App Bar ──
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                floating: false,
                elevation: 0,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF7B2FF7),
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.white, size: 15),
                          SizedBox(width: 5),
                          Text('Sign Out',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -40, top: -40,
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20, bottom: 20,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // University avatar
                                Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🏛️',
                                          style:
                                              TextStyle(fontSize: 34),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            uni.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _HeaderChip(
                                                label: uni.type,
                                                icon: Icons
                                                    .account_balance_outlined,
                                              ),
                                              const SizedBox(width: 8),
                                              _HeaderChip(
                                                label: uni.location,
                                                icon: Icons
                                                    .location_on_outlined,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Quick stats row
                                Row(
                                  children: [
                                    _QuickStat(
                                      value:
                                          '${UniversityStore.totalLandlords}',
                                      label: 'Landlords',
                                    ),
                                    _VertDivider(),
                                    _QuickStat(
                                      value:
                                          '${UniversityStore.totalStudents}',
                                      label: 'Students',
                                    ),
                                    _VertDivider(),
                                    _QuickStat(
                                      value:
                                          '${UniversityStore.totalHostels}',
                                      label: 'Hostels',
                                    ),
                                    _VertDivider(),
                                    _QuickStat(
                                      value:
                                          '${UniversityStore.totalRooms}',
                                      label: 'Rooms',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Section Tabs ──
                    _buildSectionTabs(),

                    // ── Active Section Content ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildActiveSection(),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Tabs ───────────────────────────────────────────────────────────

  Widget _buildSectionTabs() {
    final tabs = [
      {'label': 'Overview',  'icon': Icons.dashboard_outlined},
      {'label': 'Students',  'icon': Icons.school_outlined},
      {'label': 'Landlords', 'icon': Icons.apartment_outlined},
      {'label': 'Hostels',   'icon': Icons.holiday_village_outlined},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final tab = entry.value;
            final isActive = _activeSection == i;
            return GestureDetector(
              onTap: () => setState(() => _activeSection = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7B2FF7)
                      : const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF7B2FF7)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 14,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF7B2FF7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF7B2FF7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeSection) {
      case 0: return _buildOverviewSection();
      case 1: return _buildStudentsSection();
      case 2: return _buildLandlordsSection();
      case 3: return _buildHostelsSection();
      default: return _buildOverviewSection();
    }
  }

  // ── Overview Section ───────────────────────────────────────────────────────

  Widget _buildOverviewSection() {
    final uni = UniversityStore.currentUniversity;
    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── University Info Card ──
        _sectionPad(
          child: _InfoCard(
            title: 'University Information',
            icon: Icons.info_outline,
            color: const Color(0xFF7B2FF7),
            rows: [
              _InfoRow('Institution Name', uni.name),
              _InfoRow('Type', uni.type),
              _InfoRow('Location', uni.location),
              _InfoRow('Email', uni.email),
              _InfoRow('Member Since', _formatDate(uni.joinedAt)),
              _InfoRow('Platform Status', 'Active ✓'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Housing Stats ──
        _sectionPad(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Housing Statistics',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _GradientStat(
                      value: '${UniversityStore.totalRooms}',
                      label: 'Total Rooms',
                      color: const Color(0xFFFFD700),
                    ),
                    _GradientStat(
                      value: '${UniversityStore.occupiedRooms}',
                      label: 'Occupied',
                      color: const Color(0xFF00C48C),
                    ),
                    _GradientStat(
                      value:
                          '${UniversityStore.totalRooms - UniversityStore.occupiedRooms}',
                      label: 'Available',
                      color: const Color(0xFF7DF9FF),
                    ),
                    _GradientStat(
                      value: UniversityStore.totalRooms > 0
                          ? '${(UniversityStore.occupiedRooms / UniversityStore.totalRooms * 100).toStringAsFixed(0)}%'
                          : '0%',
                      label: 'Occupancy',
                      color: const Color(0xFFFFB3FF),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: UniversityStore.totalRooms > 0
                        ? UniversityStore.occupiedRooms /
                            UniversityStore.totalRooms
                        : 0,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C48C)),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${UniversityStore.occupiedRooms} of ${UniversityStore.totalRooms} rooms occupied across ${UniversityStore.totalHostels} hostels',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Student Housing Rate ──
        _sectionPad(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_outlined,
                        color: Color(0xFF1A1F71), size: 16),
                    SizedBox(width: 6),
                    Text('Student Housing Rate',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0D1147))),
                  ],
                ),
                const SizedBox(height: 14),
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
                              Text('Housed Students',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                              Text(
                                '${UniversityStore.bookedStudents} / ${UniversityStore.totalStudents}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF00C48C)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: UniversityStore.totalStudents > 0
                                  ? UniversityStore.bookedStudents /
                                      UniversityStore.totalStudents
                                  : 0,
                              backgroundColor: Colors.grey.shade100,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF00C48C)),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          UniversityStore.totalStudents > 0
                              ? '${(UniversityStore.bookedStudents / UniversityStore.totalStudents * 100).toStringAsFixed(0)}%'
                              : '0%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: Color(0xFF00C48C),
                          ),
                        ),
                        Text('housed',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Account Settings ──
        _sectionPad(
          child: _SettingsGroup(
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.email_outlined,
                label: 'Institution Email',
                value: uni.email,
                color: const Color(0xFF7B2FF7),
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.lock_reset_outlined,
                label: 'Change Password',
                color: const Color(0xFF1A1F71),
                onTap: () => _showChangePasswordSheet(),
              ),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                color: const Color(0xFF006B4F),
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.help_outline,
                label: 'Help & Support',
                color: const Color(0xFF0891B2),
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: Colors.red,
                isDestructive: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Students Section ───────────────────────────────────────────────────────

  Widget _buildStudentsSection() {
    final students = UniversityStore.students;
    return Column(
      key: const ValueKey('students'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Summary chips
        _sectionPad(
          child: Row(
            children: [
              _SummaryChip(
                label: '${UniversityStore.totalStudents}',
                sub: 'Total',
                color: const Color(0xFF1A1F71),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label: '${UniversityStore.bookedStudents}',
                sub: 'Housed',
                color: const Color(0xFF00C48C),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label:
                    '${UniversityStore.totalStudents - UniversityStore.bookedStudents}',
                sub: 'Unhoused',
                color: Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Students list
        ...students.map(
          (s) => _sectionPad(
            bottom: 8,
            child: _StudentProfileCard(student: s),
          ),
        ),
      ],
    );
  }

  // ── Landlords Section ──────────────────────────────────────────────────────

  Widget _buildLandlordsSection() {
    final landlords = UniversityStore.landlords;
    return Column(
      key: const ValueKey('landlords'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        _sectionPad(
          child: Row(
            children: [
              _SummaryChip(
                label: '${UniversityStore.totalLandlords}',
                sub: 'Total',
                color: const Color(0xFF7B2FF7),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label: '${UniversityStore.activeLandlords}',
                sub: 'Active',
                color: const Color(0xFF00C48C),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label:
                    '${UniversityStore.totalLandlords - UniversityStore.activeLandlords}',
                sub: 'Suspended',
                color: Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        ...landlords.map(
          (l) => _sectionPad(
            bottom: 8,
            child: _LandlordProfileCard(landlord: l),
          ),
        ),
      ],
    );
  }

  // ── Hostels Section ────────────────────────────────────────────────────────

  Widget _buildHostelsSection() {
    final hostels = UniversityStore.hostels;
    return Column(
      key: const ValueKey('hostels'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        _sectionPad(
          child: Row(
            children: [
              _SummaryChip(
                label: '${UniversityStore.totalHostels}',
                sub: 'Hostels',
                color: const Color(0xFF006B4F),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label: '${UniversityStore.totalRooms}',
                sub: 'Total Rooms',
                color: const Color(0xFF1A1F71),
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label: '${UniversityStore.totalRooms - UniversityStore.occupiedRooms}',
                sub: 'Available',
                color: const Color(0xFF00C48C),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        ...hostels.map(
          (h) => _sectionPad(
            bottom: 10,
            child: _HostelProfileCard(hostel: h),
          ),
        ),
      ],
    );
  }

  // ── Change Password Sheet ──────────────────────────────────────────────────

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 34,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Change Password',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _SheetField(
                controller: currentCtrl,
                label: 'Current Password',
                obscure: obscureCurrent,
                onToggle: () =>
                    setSheetState(() => obscureCurrent = !obscureCurrent),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: newCtrl,
                label: 'New Password',
                obscure: obscureNew,
                onToggle: () =>
                    setSheetState(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: confirmCtrl,
                label: 'Confirm New Password',
                obscure: obscureConfirm,
                onToggle: () =>
                    setSheetState(() => obscureConfirm = !obscureConfirm),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () async {
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Passwords do not match')),
                          );
                          return;
                        }
                        setSheetState(() => isLoading = true);
                        try {
                          await AuthService.resetPasswordUniversity(
                            newPassword: newCtrl.text,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully!'),
                                backgroundColor: Color(0xFF00C48C),
                              ),
                            );
                          }
                        } on DioException catch (e) {
                          final message = e.response?.data['message'] ?? 'Failed to update password';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message), backgroundColor: Colors.red),
                          );
                        } finally {
                          if (mounted) setSheetState(() => isLoading = false);
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Update Password',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionPad({required Widget child, double bottom = 0}) =>
      Padding(
        padding:
            EdgeInsets.fromLTRB(16, 0, 16, bottom),
        child: child,
      );
}

// ─── Card Widgets ─────────────────────────────────────────────────────────────

class _StudentProfileCard extends StatelessWidget {
  final UniversityStudent student;
  const _StudentProfileCard({required this.student});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  const Color(0xFF1A1F71).withOpacity(0.1),
              child: Text(student.initials,
                  style: const TextStyle(
                      color: Color(0xFF1A1F71),
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0D1147))),
                  Text(
                    '${student.studentId} · ${student.courseYear} · ${student.gender}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(student.email,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: student.hasBooking
                        ? const Color(0xFF00C48C).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.hasBooking ? 'Housed ✓' : 'Unhoused',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: student.hasBooking
                          ? const Color(0xFF00C48C)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (student.hasBooking && student.bookedHostel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      student.bookedHostel!,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF006B4F)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _LandlordProfileCard extends StatelessWidget {
  final UniversityLandlord landlord;
  const _LandlordProfileCard({required this.landlord});

  Color get _statusColor {
    switch (landlord.status) {
      case LandlordRegistrationStatus.pending:   return const Color(0xFFFF9800);
      case LandlordRegistrationStatus.active:    return const Color(0xFF00C48C);
      case LandlordRegistrationStatus.suspended: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      const Color(0xFF7B2FF7).withOpacity(0.1),
                  child: Text(landlord.initials,
                      style: const TextStyle(
                          color: Color(0xFF7B2FF7),
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(landlord.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0D1147))),
                      Text(landlord.email,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(landlord.statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniChip(label: landlord.landlordCode,
                    icon: Icons.vpn_key_outlined),
                const SizedBox(width: 8),
                _MiniChip(label: '${landlord.hostelCount} hostels',
                    icon: Icons.apartment_outlined),
                const SizedBox(width: 8),
                _MiniChip(label: landlord.gender,
                    icon: Icons.person_outline),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge_outlined,
                    size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('NIN: ${landlord.nin}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(width: 10),
                Icon(Icons.folder_outlined,
                    size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                    '${landlord.ownershipDocuments.length} doc(s) on file',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      );
}

class _HostelProfileCard extends StatelessWidget {
  final UniversityHostel hostel;
  const _HostelProfileCard({required this.hostel});

  @override
  Widget build(BuildContext context) => Container(
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
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.network(
                    hostel.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: const Color(0xFFF3EEFF),
                      child: const Center(
                        child: Icon(Icons.apartment,
                            size: 40, color: Color(0xFF7B2FF7)),
                      ),
                    ),
                  ),
                ),
                if (hostel.isVerified)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C48C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: Colors.white, size: 11),
                          SizedBox(width: 3),
                          Text('Verified',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
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
                    children: [
                      Expanded(
                        child: Text(hostel.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D1147))),
                      ),
                      Text(
                        'UGX ${(hostel.lowestPrice / 1000).toStringAsFixed(0)}K/mo',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF006B4F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(hostel.location,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                      const Spacer(),
                      const Icon(Icons.person_outline,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(hostel.landlordName,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                                Text('Occupancy',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                                Text(
                                  '${hostel.occupiedRooms}/${hostel.totalRooms}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7B2FF7)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: hostel.occupancyRate / 100,
                                backgroundColor: Colors.grey.shade100,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF7B2FF7)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
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

// ─── Shared Small Widgets ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: color)),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(r.label,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500)),
                      ),
                      Expanded(
                        child: Text(
                          r.value,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1147)),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}

class _InfoRow {
  final String label, value;
  const _InfoRow(this.label, this.value);
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon,
                                  color: item.color, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: item.isDestructive
                                      ? Colors.red
                                      : const Color(0xFF0D1147),
                                ),
                              ),
                            ),
                            if (item.value != null)
                              Text(item.value!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400),
                                  overflow: TextOverflow.ellipsis),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right,
                                color: Colors.grey.shade300, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(
                          height: 1,
                          indent: 54,
                          color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    required this.color,
    this.isDestructive = false,
    required this.onTap,
  });
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeaderChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 11),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _QuickStat extends StatelessWidget {
  final String value, label;
  const _QuickStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10)),
          ],
        ),
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        color: Colors.white.withOpacity(0.2),
      );
}

class _GradientStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _GradientStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label, sub;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: color)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: const Color(0xFF7B2FF7)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7B2FF7),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline,
              color: Color(0xFF7B2FF7), size: 20),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
                color: Color(0xFF7B2FF7), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );
}