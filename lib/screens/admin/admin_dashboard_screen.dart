import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_models.dart';
import 'create_university_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminDashboardScreen
//
// Requires [apiService] — an initialised AdminApiService created by passing
// a Clerk token provider, e.g.:
//
//   final clerk = Clerk.instance; // or however your app exposes it
//   AdminApiService(tokenProvider: () => clerk.session?.getToken())
//
// All data is fetched from the real API on mount and on pull-to-refresh.
// No mock / hard-coded data.
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  final AdminApiService apiService;

  const AdminDashboardScreen({super.key, required this.apiService});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;

  late AnimationController _entryController;
  late Animation<double> _entryFade;

  // ── Loaded state ──
  AdminStats? _stats;
  bool _loadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entryController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    final result = await widget.apiService.getStats();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _stats = result.data;
        _loadingStats = false;
      });
    } else {
      setState(() {
        _statsError = result.error ?? 'Failed to load data';
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: FadeTransition(
          opacity: _entryFade,
          child: _buildCurrentTab(),
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _currentTab == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateUniversityScreen(
                          apiService: widget.apiService),
                    ),
                  );
                  _loadStats(); // reload after possible new university
                },
                backgroundColor: const Color(0xFFB45309),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add University',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
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
        return _buildUniversitiesTab();
      case 2:
        return _buildUsersTab();
      default:
        return _buildHomeTab();
    }
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: const Color(0xFFB45309),
      onRefresh: _loadStats,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFB45309),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF92400E), Color(0xFFD97706)],
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
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good ${_greeting()},',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13),
                                    ),
                                    const Text(
                                      'System Admin ⚙️',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      Color(0x33FFFFFF),
                                  child: Text(
                                    'SA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
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
                                  Icon(Icons.admin_panel_settings,
                                      color: Colors.white70, size: 13),
                                  SizedBox(width: 6),
                                  Text(
                                    'info@hostelbooking.com',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: _loadingStats
                  ? const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFB45309))),
                    )
                  : _statsError != null
                      ? _buildErrorState(_statsError!, onRetry: _loadStats)
                      : _buildHomContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomContent() {
    final stats = _stats!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSystemStats(stats),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRevenueCard(stats),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildQuickActions(),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildUserBreakdown(stats),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSystemStats(AdminStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatCard2(
          value: '${stats.totalUniversities}',
          label: 'Universities',
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF7B2FF7),
          sub: 'registered',
        ),
        _StatCard2(
          value: '${stats.totalStudents}',
          label: 'Students',
          icon: Icons.school_rounded,
          color: const Color(0xFF1A1F71),
          sub: 'registered',
        ),
        _StatCard2(
          value: '${stats.totalLandlords}',
          label: 'Landlords',
          icon: Icons.apartment_rounded,
          color: const Color(0xFF006B4F),
          sub: 'on platform',
        ),
        _StatCard2(
          value: '${stats.totalUsers}',
          label: 'Total Users',
          icon: Icons.people_rounded,
          color: const Color(0xFF0891B2),
          sub: 'all roles',
        ),
      ],
    );
  }

  Widget _buildRevenueCard(AdminStats stats) {
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
          const Text('Platform Overview',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${stats.totalUsers} Users',
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
                child: _RevTile(
                  label: 'Universities',
                  value: '${stats.totalUniversities}',
                  icon: Icons.account_balance,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RevTile(
                  label: 'Active',
                  value: '${stats.activeUsers}',
                  icon: Icons.people,
                  color: const Color(0xFF00C48C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RevTile(
                  label: 'Suspended',
                  value: '${stats.suspendedUsers}',
                  icon: Icons.block,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.account_balance,
        'label': 'Add\nUniversity',
        'color': const Color(0xFF7B2FF7),
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateUniversityScreen(apiService: widget.apiService),
            ),
          );
          _loadStats();
        },
      },
      {
        'icon': Icons.people_rounded,
        'label': 'All\nUsers',
        'color': const Color(0xFF1A1F71),
        'onTap': () => setState(() => _currentTab = 2),
      },
      {
        'icon': Icons.school_rounded,
        'label': 'Universities',
        'color': const Color(0xFF006B4F),
        'onTap': () => setState(() => _currentTab = 1),
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Sign\nOut',
        'color': const Color(0xFFB45309),
        'onTap': _confirmLogout,
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

  Widget _buildUserBreakdown(AdminStats stats) {
    final roles = [
      {
        'label': 'Students',
        'count': stats.totalStudents,
        'color': const Color(0xFF1A1F71),
        'icon': Icons.school,
      },
      {
        'label': 'Landlords',
        'count': stats.totalLandlords,
        'color': const Color(0xFF006B4F),
        'icon': Icons.apartment,
      },
      {
        'label': 'Universities',
        'count': stats.totalUniversities,
        'color': const Color(0xFF7B2FF7),
        'icon': Icons.account_balance,
      },
    ];

    final total = stats.totalUsers;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('User Breakdown',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0D1147))),
              Text('$total total',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          ...roles.map((r) {
            final pct = total > 0 ? ((r['count'] as int) / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(r['icon'] as IconData,
                          color: r['color'] as Color, size: 16),
                      const SizedBox(width: 8),
                      Text(r['label'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                      const Spacer(),
                      Text('${r['count']}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: r['color'] as Color)),
                      Text(' (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          r['color'] as Color),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Universities Tab ──────────────────────────────────────────────────────

  Widget _buildUniversitiesTab() {
    return _UniversitiesTabContent(
      apiService: widget.apiService,
      onNeedRefresh: _loadStats,
    );
  }

  // ── Users Tab ─────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    return _UsersTabContent(apiService: widget.apiService);
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.account_balance_rounded, 'label': 'Universities'},
      {'icon': Icons.people_rounded, 'label': 'Users'},
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFB45309).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: isActive
                              ? const Color(0xFFB45309)
                              : Colors.grey.shade400,
                          size: 22),
                      const SizedBox(height: 3),
                      Text(item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isActive
                                ? const Color(0xFFB45309)
                                : Colors.grey.shade400,
                          )),
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

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: also call Clerk SDK sign-out to clear local session
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {required VoidCallback onRetry}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─── Universities Tab Content ─────────────────────────────────────────────────

class _UniversitiesTabContent extends StatefulWidget {
  final AdminApiService apiService;
  final VoidCallback onNeedRefresh;

  const _UniversitiesTabContent(
      {required this.apiService, required this.onNeedRefresh});

  @override
  State<_UniversitiesTabContent> createState() =>
      _UniversitiesTabContentState();
}

class _UniversitiesTabContentState extends State<_UniversitiesTabContent> {
  List<SystemUniversity> _universities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.apiService.getUniversities();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _universities = result.data ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.error;
        _loading = false;
      });
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
            expandedHeight: 120,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFB45309),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF92400E), Color(0xFFD97706)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Universities',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            Text(
                                '${_universities.length} registered institutions',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        if (!_loading && _error == null)
                          Row(
                            children: [
                              _TypeBadge(
                                label:
                                    '${_universities.where((u) => u.type == UniversityType.government).length}',
                                sub: 'Govt.',
                                color: const Color(0xFF1A1F71),
                              ),
                              const SizedBox(width: 8),
                              _TypeBadge(
                                label:
                                    '${_universities.where((u) => u.type == UniversityType.private).length}',
                                sub: 'Private',
                                color: const Color(0xFF7B2FF7),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              expandedTitleScale: 1,
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB45309)))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    color: const Color(0xFFB45309),
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: _universities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _UniversityCard(
                        university: _universities[i],
                        onAction: (action) =>
                            _handleAction(_universities[i], action),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _handleAction(SystemUniversity uni, String action) {
    if (action == 'suspend') {
      _confirmAction(
        title: 'Suspend University',
        message:
            'Suspend "${uni.universityName}"? Students and landlords linked to this university will be affected.',
        confirmLabel: 'Suspend',
        color: Colors.orange,
        onConfirm: () async {
          final result =
              await widget.apiService.suspendUser(uni.userId);
          if (!mounted) return;
          if (result.success) {
            _load();
            widget.onNeedRefresh();
          } else {
            _showError(result.error ?? 'Failed to suspend');
          }
        },
      );
    } else if (action == 'activate') {
      _confirmAction(
        title: 'Activate University',
        message: 'Reactivate "${uni.universityName}"?',
        confirmLabel: 'Activate',
        color: const Color(0xFF00C48C),
        onConfirm: () async {
          final result =
              await widget.apiService.unsuspendUser(uni.userId);
          if (!mounted) return;
          if (result.success) {
            _load();
            widget.onNeedRefresh();
          } else {
            _showError(result.error ?? 'Failed to activate');
          }
        },
      );
    }
  }

  void _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─── Users Tab Content ────────────────────────────────────────────────────────

class _UsersTabContent extends StatefulWidget {
  final AdminApiService apiService;

  const _UsersTabContent({required this.apiService});

  @override
  State<_UsersTabContent> createState() => _UsersTabContentState();
}

class _UsersTabContentState extends State<_UsersTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final _searchCtrl = TextEditingController();

  final List<String> _tabs = ['All', 'Students', 'Landlords', 'Universities'];

  // per-tab caches keyed by tab index
  final Map<int, List<SystemUser>> _cache = {};
  final Map<int, bool> _loading = {};
  final Map<int, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        _loadTab(_tabController.index);
      }
    });
    _loadTab(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _roleForTab(int index) {
    switch (index) {
      case 1: return 'student';
      case 2: return 'landlord';
      case 3: return 'university';
      default: return null;
    }
  }

  Future<void> _loadTab(int index) async {
    if (_loading[index] == true) return;
    setState(() {
      _loading[index] = true;
      _errors[index] = null;
    });
    final result =
        await widget.apiService.getUsers(role: _roleForTab(index));
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _cache[index] = result.data ?? [];
        _loading[index] = false;
      });
    } else {
      setState(() {
        _errors[index] = result.error;
        _loading[index] = false;
      });
    }
  }

  List<SystemUser> get _filteredUsers {
    final raw = (_cache[_tabController.index] ?? [])
        .where((u) => u.role != SystemUserRole.admin)
        .toList();
    if (_search.isEmpty) return raw;
    final q = _search.toLowerCase();
    return raw
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFB45309),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF92400E), Color(0xFFD97706)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('User Management',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${(_cache[0] ?? []).where((u) => !u.isSuspended).length} active · '
                          '${(_cache[0] ?? []).where((u) => u.isSuspended).length} suspended',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              expandedTitleScale: 1,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFB45309),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  indicatorColor: const Color(0xFFB45309),
                  indicatorWeight: 3,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Colors.grey),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
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
                        color: Color(0xFFB45309), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: Builder(builder: (_) {
                final idx = _tabController.index;
                if (_loading[idx] == true) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFB45309)));
                }
                if (_errors[idx] != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(_errors[idx]!,
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _loadTab(idx),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB45309),
                              foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final users = _filteredUsers;
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No users found',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: const Color(0xFFB45309),
                  onRefresh: () => _loadTab(idx),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserCard(
                      user: users[i],
                      onSuspend: () => _handleSuspend(users[i]),
                      onActivate: () => _handleActivate(users[i]),
                      onDelete: () => _confirmDelete(users[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSuspend(SystemUser user) async {
    final result = await widget.apiService.suspendUser(user.id);
    if (!mounted) return;
    if (result.success) {
      _loadTab(_tabController.index);
      _loadTab(0); // refresh "All" counts too
    } else {
      _snack(result.error ?? 'Failed to suspend user');
    }
  }

  Future<void> _handleActivate(SystemUser user) async {
    final result = await widget.apiService.unsuspendUser(user.id);
    if (!mounted) return;
    if (result.success) {
      _loadTab(_tabController.index);
      _loadTab(0);
    } else {
      _snack(result.error ?? 'Failed to activate user');
    }
  }

  void _confirmDelete(SystemUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Permanently delete "${user.name}"? This cannot be undone.\n\n'
            'If this is a university account, all associated landlords, students, hostels, bookings and payments will also be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await widget.apiService.deleteUser(user.id);
              if (!mounted) return;
              if (result.success) {
                _loadTab(_tabController.index);
                _loadTab(0);
              } else {
                _snack(result.error ?? 'Failed to delete user');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final SystemUser user;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onSuspend,
    required this.onActivate,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (user.role) {
      case SystemUserRole.student:    return const Color(0xFF1A1F71);
      case SystemUserRole.landlord:   return const Color(0xFF006B4F);
      case SystemUserRole.university: return const Color(0xFF7B2FF7);
      case SystemUserRole.admin:      return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.isSuspended;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuspended ? const Color(0xFFFFF7F7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuspended ? Colors.red.shade100 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _roleColor.withOpacity(0.1),
            child: Text(user.initials,
                style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0D1147))),
                    ),
                    if (isSuspended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Suspended',
                            style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                Text(user.email,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(user.roleLabel,
                          style: TextStyle(
                              color: _roleColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (user.university != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(user.university!,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Colors.grey.shade400, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'suspend') onSuspend();
              if (val == 'activate') onActivate();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (!isSuspended)
                const PopupMenuItem(
                  value: 'suspend',
                  child: Row(children: [
                    Icon(Icons.block, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text('Suspend'),
                  ]),
                ),
              if (isSuspended)
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF00C48C), size: 16),
                    SizedBox(width: 8),
                    Text('Activate'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final SystemUniversity university;
  final Function(String) onAction;

  const _UniversityCard(
      {required this.university, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isSuspended = university.isSuspended;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuspended ? const Color(0xFFFFF7F7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isSuspended ? Colors.red.shade100 : Colors.grey.shade100),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FF7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance,
                    color: Color(0xFF7B2FF7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(university.universityName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0D1147))),
                    Text(university.email,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: university.type == UniversityType.government
                          ? const Color(0xFF1A1F71).withOpacity(0.1)
                          : const Color(0xFF7B2FF7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(university.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: university.type == UniversityType.government
                              ? const Color(0xFF1A1F71)
                              : const Color(0xFF7B2FF7),
                        )),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Colors.grey.shade400, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      if (!isSuspended)
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Row(children: [
                            Icon(Icons.block,
                                color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Suspend'),
                          ]),
                        ),
                      if (isSuspended)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF00C48C), size: 16),
                            SizedBox(width: 8),
                            Text('Activate'),
                          ]),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(university.location,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const Spacer(),
              Text(
                'Since ${university.createdAt.substring(0, 10)}',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
          if (isSuspended) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 13, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Text('University suspended',
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
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;

  const _StatCard2({
    required this.value,
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF0D1147))),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RevTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RevTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;

  const _TypeBadge(
      {required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            Text(sub,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}