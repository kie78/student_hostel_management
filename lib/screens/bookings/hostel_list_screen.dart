import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';
import 'room_details_screen.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class Room {
  final String id;
  final String roomType;
  final double price;
  final int capacity;
  final int occupiedSlots;
  final bool isAvailable;

  const Room({
    required this.id,
    required this.roomType,
    required this.price,
    required this.capacity,
    required this.occupiedSlots,
    required this.isAvailable,
  });

  int get availableSpaces => capacity - occupiedSlots;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      roomType: json['roomType'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      capacity: json['capacity'] ?? 0,
      occupiedSlots: json['occupiedSlots'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
    );
  }
}

typedef RoomType = Room;

extension RoomCompat on Room {
  String get name => roomType
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  double get pricePerSemester => price;
  int get totalSlots => capacity;
  String get description => 'Comfortable $name with secure student-friendly setup.';
  String get size => 'Standard';
  int get maxOccupants => capacity;
  bool get hasEnsuite => roomType.toLowerCase().contains('self');
  List<String> get features => const [
        'WiFi',
        'Wardrobe',
        'Study desk',
        '24/7 water',
      ];
}

class Hostel {
  final String id;
  final String name;
  final String location;
  final String description;
  final List<String> images;
  final String whatsappNumber;
  final List<Room> rooms;

  const Hostel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.images,
    required this.whatsappNumber,
    required this.rooms,
  });

  int get availableRooms => rooms.where((r) => r.isAvailable).length;
  double get minPrice => rooms.isEmpty
      ? 0
      : rooms.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  factory Hostel.fromJson(Map<String, dynamic> json) {
    final rawRooms = json['rooms'] as List? ?? [];
    final rawImages = json['images'] as List? ?? [];
    return Hostel(
      id: json['id'] ?? '',
      name: json['hostelName'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      images: rawImages.map((e) => e.toString()).toList(),
      whatsappNumber: json['whatsappNumber'] ?? '',
      rooms: rawRooms.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}

extension HostelCompat on Hostel {
  List<Room> get roomTypes => rooms;
  String get imageUrl => images.isNotEmpty ? images.first : '';
  bool get isVerified => true;
  String get district => '';
  double get rating => 4.5;
  int get reviews => 0;
  String get distanceFromCampus => 'Near campus';
  List<String> get amenities => const [
        'WiFi',
        'Water',
        'Power',
        'Security',
      ];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HostelListScreen extends StatefulWidget {
  const HostelListScreen({super.key});

  @override
  State<HostelListScreen> createState() => _HostelListScreenState();
}

class _HostelListScreenState extends State<HostelListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Hostel> _hostels = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Default';
  double _maxPrice = 1000000;
  bool _showFilters = false;
  bool _availableOnly = false;

  final List<String> _filters = ['All', 'Available', 'Self-Contained', 'Double'];
  final List<String> _sortOptions = ['Default', 'Price (Low)', 'Price (High)'];

  List<Hostel> get _filteredHostels {
    List<Hostel> result = List.from(_hostels);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((h) =>
              h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.location.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_selectedFilter) {
      case 'Available':
        result = result.where((h) => h.availableRooms > 0).toList();
        break;
      case 'Self-Contained':
        result = result
            .where((h) => h.rooms.any((r) =>
                r.roomType.toLowerCase().contains('self_contained') ||
                r.roomType.toLowerCase().contains('self-contained')))
            .toList();
        break;
        case 'Double':
        result = result
            .where((h) => h.rooms.any((r) =>
                r.roomType.toLowerCase().contains('double') ||
                r.roomType.toLowerCase().contains('shared')))
            .toList();
        break;
    }

    result = result.where((h) => h.minPrice <= _maxPrice).toList();

    if (_availableOnly) {
      result = result.where((h) => h.availableRooms > 0).toList();
    }

    switch (_sortBy) {
      case 'Price (Low)':
        result.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case 'Price (High)':
        result.sort((a, b) => b.minPrice.compareTo(a.minPrice));
        break;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadHostels();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHostels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await AuthService.getStudentHostels();
      setState(() {
        _hostels = data
        .map((h) => Hostel.fromJson(h as Map<String, dynamic>))
        .toList();
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data['message'] ?? 'Failed to load hostels';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return 'UGX ${(price / 1000000).toStringAsFixed(2)}M';
    }
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  String _formatRoomType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final hostels = _filteredHostels;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: RefreshIndicator(
        onRefresh: _loadHostels,
        color: const Color(0xFF1A1F71),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1A1F71),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: const Text(
                'Student Home 🏠',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _loadHostels,
                  icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                ),
              ],
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(Icons.search,
                                  color: Color(0xFF1A1F71), size: 22),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                decoration: const InputDecoration(
                                  hintText: 'Search by name or location...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showFilters = !_showFilters),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1F71),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _showFilters
                                      ? Icons.tune
                                      : Icons.tune_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showFilters) ...[
                        const SizedBox(height: 12),
                        _buildFilterPanel(),
                      ],
                    ],
                  ),
                ),
              ),

            // ── Filter Chips ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = _selectedFilter == _filters[i];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = _filters[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1A1F71)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1A1F71)
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF1A1F71)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ]
                                : [],
                          ),
                          child: Text(
                            _filters[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Results Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : '${hostels.length} hostel${hostels.length == 1 ? '' : 's'} found',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3561),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Row(
                        children: [
                          const Icon(Icons.sort,
                              size: 16, color: Color(0xFF1A1F71)),
                          const SizedBox(width: 4),
                          Text(
                            _sortBy,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1F71),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ──
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A1F71),
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _loadHostels,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F71),
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
                ),
              )
            else if (hostels.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No hostels found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Try adjusting your filters',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: _HostelCard(
                        hostel: hostels[index],
                        formatPrice: _formatPrice,
                        formatRoomType: _formatRoomType,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailsScreen(
                                hostel: hostels[index]),
                          ),
                        ),
                      ),
                    ),
                    childCount: hostels.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Max Price / Semester',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UGX 50K',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(
                'UGX ${(_maxPrice / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F71)),
              ),
              Text('UGX 1M',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1A1F71),
              thumbColor: const Color(0xFF1A1F71),
              inactiveTrackColor: Colors.grey.shade200,
              overlayColor: const Color(0xFF1A1F71).withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _maxPrice,
              min: 50000,
              max: 1000000,
              divisions: 19,
              onChanged: (v) => setState(() => _maxPrice = v),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Rooms Only',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Switch(
                value: _availableOnly,
                onChanged: (v) => setState(() => _availableOnly = v),
                activeColor: const Color(0xFF1A1F71),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._sortOptions.map((opt) => ListTile(
                  title: Text(opt),
                  trailing: _sortBy == opt
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF1A1F71))
                      : null,
                  onTap: () {
                    setState(() => _sortBy = opt);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Hostel Card ──────────────────────────────────────────────────────────────

class _HostelCard extends StatelessWidget {
  final Hostel hostel;
  final String Function(double) formatPrice;
  final String Function(String) formatRoomType;
  final VoidCallback onTap;

  const _HostelCard({
    required this.hostel,
    required this.formatPrice,
    required this.formatRoomType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: hostel.images.isNotEmpty
                      ? Image.network(
                          hostel.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                // Available Rooms Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hostel.availableRooms > 0
                          ? const Color(0xFF1A1F71)
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hostel.availableRooms > 0
                          ? '${hostel.availableRooms} rooms left'
                          : 'Full',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (hostel.images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${hostel.images.length} photos',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostel.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1F71),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    hostel.location,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hostel.availableRooms > 0
                              ? const Color(0xFFE8F5EF)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hostel.availableRooms > 0
                              ? '${hostel.rooms.length} room types'
                              : 'Fully Booked',
                          style: TextStyle(
                            color: hostel.availableRooms > 0
                                ? const Color(0xFF006B4F)
                                : Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Description snippet
                  Text(
                    hostel.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.5),
                  ),

                  const SizedBox(height: 12),

                  // Room type chips
                  if (hostel.rooms.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hostel.rooms
                          .take(3)
                          .map((r) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: r.isAvailable
                                      ? const Color(0xFFEEF0F8)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  formatRoomType(r.roomType),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: r.isAvailable
                                          ? const Color(0xFF2D3561)
                                          : Colors.grey.shade400),
                                ),
                              ))
                          .toList(),
                    ),

                  const SizedBox(height: 14),

                  // Price + CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('from',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                          Text(
                            formatPrice(hostel.minPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1F71),
                            ),
                          ),
                          Text('/semester',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'View Rooms',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 180,
        color: const Color(0xFFEEF0F8),
        child: const Center(
          child: Icon(Icons.apartment, size: 48, color: Color(0xFF1A1F71)),
        ),
      );
}