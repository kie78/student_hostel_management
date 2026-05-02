import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_hostel_management/screens/university/university_models.dart';
import 'university_profile_screen.dart';
import 'register_landlord_screen.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';

class UniversityDashboardScreen extends StatefulWidget {
  const UniversityDashboardScreen({super.key});

  @override
  State<UniversityDashboardScreen> createState() =>
      _UniversityDashboardScreenState();
}

class _UniversityDashboardScreenState extends State<UniversityDashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  List<Map<String, dynamic>> _landlords = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _hostels = [];
  bool _isLoading = true;

  int get _totalLandlords => _landlords.length;
  int get _totalStudents => _students.length;
  int get _totalHostels => _hostels.length;
  int get _totalRooms =>
      _hostels.fold(0, (sum, h) => sum + (h['rooms'] as List? ?? []).length);
  int get _occupiedRooms => _hostels.fold(
      0,
      (sum, h) =>
          sum +
          (h['rooms'] as List? ?? [])
              .where((r) => r['isAvailable'] == false)
              .length);

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
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AuthService.getLandlords(),
        AuthService.getStudents(),
        AuthService.getHostels(),
      ]);
      setState(() {
        _landlords = List<Map<String, dynamic>>.from(results[0]);
        _students = List<Map<String, dynamic>>.from(results[1]);
        _hostels = List<Map<String, dynamic>>.from(results[2]);
      });
    } on DioException catch (e) {
      debugPrint('Failed to load data: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _refresh() => _loadData();

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
        floatingActionButton: _currentTab == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterLandlordScreen(),
                    ),
                  );
                  setState(() {});
                },
                backgroundColor: const Color(0xFF7B2FF7),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'Add Landlord',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
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
        return _buildLandlordsTab();
      case 2:
        return _buildStudentsTab();
      case 3:
        return UniversityProfileScreen(onUpdate: _refresh);
      default:
        return _buildHomeTab();
    }
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          floating: false,
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF7B2FF7),
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
                    bottom: 30,
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
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: 220,
                                    child: Text(
                                      UniversityStore.currentUniversity.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _currentTab = 3),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  child: const Text(
                                    'MU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _HeaderBadge(
                                label: UniversityStore
                                    .currentUniversity.type,
                                icon: Icons.account_balance_outlined,
                              ),
                              const SizedBox(width: 8),
                              _HeaderBadge(
                                label: UniversityStore
                                    .currentUniversity.location,
                                icon: Icons.location_on_outlined,
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

        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats Grid ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsGrid(),
                ),

                const SizedBox(height: 16),

                // ── Occupancy Card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildOccupancyCard(),
                ),

                const SizedBox(height: 20),

                // ── Quick Actions ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickActions(),
                ),

                const SizedBox(height: 24),

                // ── Recent Hostels ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hostels Near Campus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1147),
                        ),
                      ),
                      Text(
                        '$_totalHostels listed',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ..._hostels.map((h) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _HostelMiniCard(hostel: h),
                      )),

                const SizedBox(height: 24),

                // ── Recent Landlords ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Landlords',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1147),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _currentTab = 1),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B2FF7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                ..._landlords.take(3).map((l) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _LandlordMiniCard(landlord: l),
                    )),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          value: '$_totalLandlords',
          label: 'Landlords',
          sub: 'registered',
          icon: Icons.apartment_rounded,
          color: const Color(0xFF7B2FF7),
        ),
        _StatCard(
          value: '$_totalStudents',
          label: 'Students',
          sub: 'registered',
          icon: Icons.school_rounded,
          color: const Color(0xFF1A1F71),
        ),
        _StatCard(
          value: '$_totalHostels',
          label: 'Hostels',
          sub: 'in system',
          icon: Icons.holiday_village_rounded,
          color: const Color(0xFF006B4F),
        ),
        _StatCard(
          value: '$_totalRooms',
          label: 'Total Rooms',
          sub: '$_occupiedRooms occupied',
          icon: Icons.bed_rounded,
          color: const Color(0xFF0891B2),
        ),
      ],
    );
  }

  Widget _buildOccupancyCard() {
    final rate = _totalRooms > 0 ? (_occupiedRooms / _totalRooms) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F71), Color(0xFF2D3A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1F71).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Campus Housing Overview',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          _OverviewBar(
            label: 'Room Occupancy',
            value: rate,
            filled: _occupiedRooms,
            total: _totalRooms,
            unit: 'rooms',
            color: const Color(0xFF00C48C),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.person_add_rounded,
        'label': 'Register\nLandlord',
        'color': const Color(0xFF7B2FF7),
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterLandlordScreen()),
          );
          setState(() {});
        },
      },
      {
        'icon': Icons.apartment_rounded,
        'label': 'View\nHostels',
        'color': const Color(0xFF006B4F),
        'onTap': () => setState(() => _currentTab = 0),
      },
      {
        'icon': Icons.school_rounded,
        'label': 'View\nStudents',
        'color': const Color(0xFF1A1F71),
        'onTap': () => setState(() => _currentTab = 2),
      },
      {
        'icon': Icons.person_rounded,
        'label': 'Profile',
        'color': const Color(0xFF0891B2),
        'onTap': () => setState(() => _currentTab = 3),
      },
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              margin: EdgeInsets.only(
                  right: actions.indexOf(a) < actions.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ── Landlords Tab ─────────────────────────────────────────────────────────
  Widget _buildLandlordsTab() {
    return _LandlordsTabContent(onUpdate: _refresh, landlords: _landlords);
  }

  // ── Students Tab ──────────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return _StudentsTabContent(onUpdate: _refresh, students: _students);
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.apartment_rounded, 'label': 'Landlords'},
      {'icon': Icons.school_rounded, 'label': 'Students'},
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF7B2FF7).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: isActive
                              ? const Color(0xFF7B2FF7)
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
                                ? const Color(0xFF7B2FF7)
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─── Landlords Tab Content ─────────────────────────────────────────────────────
class _LandlordsTabContent extends StatefulWidget {
  final VoidCallback onUpdate;
  final List<Map<String, dynamic>> landlords;
  const _LandlordsTabContent({
    required this.onUpdate,
    required this.landlords,
  });
  @override
  State<_LandlordsTabContent> createState() => _LandlordsTabContentState();
}

class _LandlordsTabContentState extends State<_LandlordsTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final List<String> _tabs = ['All', 'Active', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = widget.landlords;
    if (_search.isNotEmpty) {
      list = list
          .where((l) =>
              (l['fullName'] ?? '')
                  .toLowerCase()
                  .contains(_search.toLowerCase()) ||
              (l['landlordCode'] ?? '')
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF7B2FF7),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Landlords',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${widget.landlords.length} registered',
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
                  labelColor: const Color(0xFF7B2FF7),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  indicatorColor: const Color(0xFF7B2FF7),
                  indicatorWeight: 3,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _SearchBar(
              controller: _searchCtrl,
              hint: 'Search by name or landlord code...',
              color: const Color(0xFF7B2FF7),
              onChanged: (v) => setState(() => _search = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
            ),
            Expanded(
              child: Builder(builder: (_) {
                final items = _filtered;
                if (items.isEmpty) {
                  return const _EmptyState(
                      icon: Icons.apartment_outlined,
                      message: 'No landlords found');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _LandlordApiCard(
                    landlord: items[i],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Students Tab Content ──────────────────────────────────────────────────────
class _StudentsTabContent extends StatefulWidget {
  final VoidCallback onUpdate;
  final List<Map<String, dynamic>> students;
  const _StudentsTabContent({
    required this.onUpdate,
    required this.students,
  });
  @override
  State<_StudentsTabContent> createState() => _StudentsTabContentState();
}

class _StudentsTabContentState extends State<_StudentsTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final List<String> _tabs = ['All', 'Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = widget.students;

    final tab = _tabs[_tabController.index];
    if (tab == 'Male') {
      list = list
          .where((s) => (s['gender'] ?? '').toLowerCase() == 'male')
          .toList();
    } else if (tab == 'Female') {
      list = list
          .where((s) => (s['gender'] ?? '').toLowerCase() == 'female')
          .toList();
    }

    if (_search.isNotEmpty) {
      list = list
          .where((s) =>
              ('${s['surname']} ${s['otherNames']}')
                  .toLowerCase()
                  .contains(_search.toLowerCase()) ||
              (s['registrationNumber'] ?? '')
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1A1F71),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF0D1147), Color(0xFF2D3A8C)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Students',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${widget.students.length} registered',
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
                  labelColor: const Color(0xFF1A1F71),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  indicatorColor: const Color(0xFF1A1F71),
                  indicatorWeight: 3,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _SearchBar(
              controller: _searchCtrl,
              hint: 'Search by name or reg number...',
              color: const Color(0xFF1A1F71),
              onChanged: (v) => setState(() => _search = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
            ),
            Expanded(
              child: Builder(builder: (_) {
                final items = _filtered;
                if (items.isEmpty) {
                  return const _EmptyState(
                      icon: Icons.school_outlined,
                      message: 'No students found');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _StudentApiCard(student: items[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── API-powered Landlord Card ─────────────────────────────────────────────────
class _LandlordApiCard extends StatelessWidget {
  final Map<String, dynamic> landlord;
  const _LandlordApiCard({required this.landlord});

  @override
  Widget build(BuildContext context) {
    final fullName = landlord['fullName'] ?? '';
    final initials = fullName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7B2FF7).withOpacity(0.1),
                child: Text(initials,
                    style: const TextStyle(
                        color: Color(0xFF7B2FF7),
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0D1147))),
                    Text(landlord['email'] ?? '',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active',
                    style: TextStyle(
                        color: Color(0xFF00C48C),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                  label: 'Code',
                  value: landlord['landlordCode'] ?? '—',
                  color: const Color(0xFF7B2FF7)),
              _MiniStat(
                  label: 'Gender',
                  value: landlord['gender'] ?? '—',
                  color: const Color(0xFF0891B2)),
              _MiniStat(
                  label: 'WhatsApp',
                  value: landlord['whatsappNumber'] ?? '—',
                  color: const Color(0xFF006B4F)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── API-powered Student Card ──────────────────────────────────────────────────
class _StudentApiCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentApiCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${student['surname'] ?? ''} ${student['otherNames'] ?? ''}'.trim();
    final initials = fullName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            backgroundColor: const Color(0xFF1A1F71).withOpacity(0.1),
            child: Text(initials,
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
                Text(fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0D1147))),
                Text(
                  '${student['registrationNumber'] ?? ''} · ${student['gender'] ?? ''}',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(student['studentEmail'] ?? '',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hostel Mini Card ──────────────────────────────────────────────────────────
class _HostelMiniCard extends StatelessWidget {
  final Map<String, dynamic> hostel;
  const _HostelMiniCard({required this.hostel});

  @override
  Widget build(BuildContext context) {
    final rooms = hostel['rooms'] as List? ?? [];
    final totalRooms = rooms.length;
    final occupiedRooms =
        rooms.where((r) => r['isAvailable'] == false).length;
    final images = hostel['images'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: images.isNotEmpty
                ? Image.network(
                    images.first.toString(),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFEEF0F8),
                      child: const Icon(Icons.apartment,
                          color: Color(0xFF7B2FF7), size: 28),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFEEF0F8),
                    child: const Icon(Icons.apartment,
                        color: Color(0xFF7B2FF7), size: 28),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hostel['hostelName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0D1147))),
                Text(hostel['location'] ?? '',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(
                  '$occupiedRooms/$totalRooms rooms',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: totalRooms > 0 ? occupiedRooms / totalRooms : 0,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7B2FF7)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Landlord Mini Card ────────────────────────────────────────────────────────
class _LandlordMiniCard extends StatelessWidget {
  final Map<String, dynamic> landlord;
  const _LandlordMiniCard({required this.landlord});

  @override
  Widget build(BuildContext context) {
    final fullName = landlord['fullName'] ?? '';
    final initials = fullName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            radius: 20,
            backgroundColor: const Color(0xFF7B2FF7).withOpacity(0.1),
            child: Text(initials,
                style: const TextStyle(
                    color: Color(0xFF7B2FF7),
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0D1147))),
                Text(landlord['landlordCode'] ?? '',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00C48C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Active',
                style: TextStyle(
                    color: Color(0xFF00C48C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.color,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon:
                const Icon(Icons.search, size: 18, color: Colors.grey),
            suffixIcon: controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey))
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
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String value, label, sub;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.sub,
      required this.icon,
      required this.color});
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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Color(0xFF0D1147))),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 9, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12, color: color),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style:
                    TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
      );
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeaderBadge({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _OverviewBar extends StatelessWidget {
  final String label, unit;
  final double value;
  final int filled, total;
  final Color color;

  const _OverviewBar({
    required this.label,
    required this.value,
    required this.filled,
    required this.total,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '$filled / $total $unit (${(value * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      );
}