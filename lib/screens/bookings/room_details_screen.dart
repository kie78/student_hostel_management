import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hostel_list_screen.dart';
import 'booking_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final Hostel hostel;
  const RoomDetailsScreen({super.key, required this.hostel});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRoomIndex = 0;
  bool _isFavorited = false;
  int _imageIndex = 0;
  final PageController _imagePageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  // Fake review data
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Amara Nakato',
      'avatar': 'AN',
      'rating': 5,
      'date': '2 weeks ago',
      'comment': 'Absolutely love it here! The WiFi is super fast and the management is very responsive. Highly recommend to any student.',
      'roomType': 'Single Self-Contained',
    },
    {
      'name': 'David Ochieng',
      'avatar': 'DO',
      'rating': 4,
      'date': '1 month ago',
      'comment': 'Great location, very close to campus. Water supply is reliable. Would be 5 stars if they had a gym.',
      'roomType': 'Double Room',
    },
    {
      'name': 'Faith Nabirye',
      'avatar': 'FN',
      'rating': 5,
      'date': '2 months ago',
      'comment': 'Security here is top notch. I feel very safe even when coming back late from the library. The rooms are clean and spacious.',
      'roomType': 'Single Self-Contained',
    },
    {
      'name': 'Samuel Kato',
      'avatar': 'SK',
      'rating': 4,
      'date': '3 months ago',
      'comment': 'Good value for the price. Management is helpful. The common area could use better maintenance though.',
      'roomType': 'Triple Room',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 200;
      if (collapsed != _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  RoomType get _selectedRoom => widget.hostel.roomTypes[_selectedRoomIndex];

  String _formatPrice(double price) {
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  // Placeholder images per hostel
  List<String> get _hostelImages => [
    widget.hostel.imageUrl,
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
    'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=800',
    'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Image Gallery App Bar ──
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF1A1F71),
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Slider
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: _hostelImages.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          _hostelImages[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEF0F8),
                            child: const Center(
                              child: Icon(Icons.apartment, size: 64, color: Color(0xFF1A1F71)),
                            ),
                          ),
                        ),
                      ),
                      // Gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      // Image Indicators
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _hostelImages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _imageIndex == i ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _imageIndex == i
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Photo count
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_imageIndex + 1} / ${_hostelImages.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hostel Header ──
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
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
                                    if (widget.hostel.isVerified)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C48C).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, color: Color(0xFF00C48C), size: 13),
                                            SizedBox(width: 4),
                                            Text('Verified Hostel', style: TextStyle(color: Color(0xFF00C48C), fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      widget.hostel.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1F71),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 15, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.hostel.location}, ${widget.hostel.district}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.hostel.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF1A1F71),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.hostel.reviews} reviews',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Quick stats row
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.school,
                                label: widget.hostel.distanceFromCampus,
                                sublabel: 'from campus',
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.door_front_door,
                                label: '${widget.hostel.availableRooms}',
                                sublabel: 'rooms available',
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.people,
                                label: '${widget.hostel.roomTypes.length}',
                                sublabel: 'room types',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tabs ──
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1A1F71),
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        indicatorColor: const Color(0xFF1A1F71),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Rooms'),
                          Tab(text: 'Amenities'),
                          Tab(text: 'Reviews'),
                        ],
                        onTap: (i) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tab Content
                    [
                      _buildRoomsTab(),
                      _buildAmenitiesTab(),
                      _buildReviewsTab(),
                    ][_tabController.index],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // ── Sticky Bottom Bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Select a Room Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71)),
            ),
          ),

          // About section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About this Hostel',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1F71))),
                const SizedBox(height: 8),
                Text(
                  widget.hostel.description,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.6),
                ),
              ],
            ),
          ),

          // Room type cards
          ...widget.hostel.roomTypes.asMap().entries.map((entry) {
            final i = entry.key;
            final room = entry.value;
            final isSelected = _selectedRoomIndex == i;

            return GestureDetector(
              onTap: () => setState(() => _selectedRoomIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1A1F71) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF1A1F71).withOpacity(0.12)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Selection indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF1A1F71) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1A1F71) : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isSelected ? const Color(0xFF1A1F71) : Colors.black87,
                                  ),
                                ),
                              ),
                              if (!room.isAvailable)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Full', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            room.description,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _RoomInfoBadge(icon: Icons.straighten, label: room.size),
                              const SizedBox(width: 8),
                              _RoomInfoBadge(icon: Icons.people, label: '${room.maxOccupants} person'),
                              const SizedBox(width: 8),
                              if (room.hasEnsuite)
                                _RoomInfoBadge(icon: Icons.shower, label: 'Ensuite'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Features
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: room.features.map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFF2D3561))),
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _formatPrice(room.pricePerMonth),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1F71),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' /month',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (room.availableSpaces > 0)
                                Text(
                                  '${room.availableSpaces} space${room.availableSpaces > 1 ? 's' : ''} left',
                                  style: TextStyle(
                                    color: room.availableSpaces <= 2 ? Colors.orange : const Color(0xFF00C48C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
          }),
        ],
      ),
    );
  }

  Widget _buildAmenitiesTab() {
    final amenityDetails = {
      'WiFi': {'icon': Icons.wifi, 'desc': 'High-speed fiber internet'},
      'Security': {'icon': Icons.security, 'desc': '24/7 CCTV and guards'},
      'Water': {'icon': Icons.water_drop, 'desc': 'Running water all day'},
      'Kitchen': {'icon': Icons.kitchen, 'desc': 'Shared cooking facility'},
      'Laundry': {'icon': Icons.local_laundry_service, 'desc': 'Washing machines available'},
      'Gym': {'icon': Icons.fitness_center, 'desc': 'Fully equipped gym'},
      'Study Room': {'icon': Icons.menu_book, 'desc': 'Quiet study space'},
      'Parking': {'icon': Icons.local_parking, 'desc': 'Secure parking available'},
      'Swimming Pool': {'icon': Icons.pool, 'desc': 'Outdoor pool'},
      'Cafeteria': {'icon': Icons.restaurant, 'desc': 'On-site dining'},
      'Common Room': {'icon': Icons.weekend, 'desc': 'Shared lounge area'},
    };

    final hostelPolicies = [
      {'icon': Icons.access_time, 'title': 'Gate Closing Time', 'value': '11:00 PM'},
      {'icon': Icons.no_drinks, 'title': 'Alcohol Policy', 'value': 'Not allowed'},
      {'icon': Icons.pets, 'title': 'Pets', 'value': 'Not allowed'},
      {'icon': Icons.people_outline, 'title': 'Visitors', 'value': 'Allowed until 9 PM'},
      {'icon': Icons.smoke_free, 'title': 'Smoking', 'value': 'Outdoor only'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Facilities & Amenities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: widget.hostel.amenities.asMap().entries.map((entry) {
                final i = entry.key;
                final amenity = entry.value;
                final details = amenityDetails[amenity];
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          details?['icon'] as IconData? ?? Icons.check_circle_outline,
                          color: const Color(0xFF1A1F71),
                          size: 20,
                        ),
                      ),
                      title: Text(amenity, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        details?['desc'] as String? ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      trailing: const Icon(Icons.check, color: Color(0xFF00C48C), size: 18),
                    ),
                    if (i < widget.hostel.amenities.length - 1)
                      const Divider(height: 1, indent: 60),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
          const Text('Hostel Rules & Policies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: hostelPolicies.asMap().entries.map((entry) {
                final i = entry.key;
                final policy = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(policy['icon'] as IconData, color: const Color(0xFF1A1F71), size: 22),
                      title: Text(policy['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      trailing: Text(
                        policy['value'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (i < hostelPolicies.length - 1)
                      const Divider(height: 1, indent: 16),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Location map placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFEEF0F8),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 48, color: Color(0xFF1A1F71)),
                          SizedBox(height: 8),
                          Text('Map View', style: TextStyle(color: Color(0xFF1A1F71), fontWeight: FontWeight.w600)),
                          Text('Tap to open in Maps', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Text(widget.hostel.location,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1F71))),
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

  Widget _buildReviewsTab() {
    final avgRating = widget.hostel.rating;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < avgRating.floor() ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107),
                        size: 16,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.hostel.reviews} reviews',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      // Fake distribution
                      final fractions = [0.68, 0.22, 0.07, 0.02, 0.01];
                      final fraction = fractions[5 - star];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('Recent Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 12),

          ..._reviews.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1A1F71),
                      child: Text(
                        r['avatar'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            '${r['roomType']} • ${r['date']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        (r['rating'] as int),
                        (_) => const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  r['comment'] as String,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatPrice(_selectedRoom.pricePerMonth),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1F71),
                ),
              ),
              Text(
                'per month · ${_selectedRoom.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _selectedRoom.isAvailable
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(
                            hostel: widget.hostel,
                            roomType: _selectedRoom,
                          ),
                        ),
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _selectedRoom.isAvailable
                      ? const LinearGradient(
                          colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                        )
                      : null,
                  color: _selectedRoom.isAvailable ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedRoom.isAvailable
                      ? [BoxShadow(
                          color: const Color(0xFF1A1F71).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _selectedRoom.isAvailable ? 'Book This Room' : 'Not Available',
                    style: TextStyle(
                      color: _selectedRoom.isAvailable ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A1F71)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1F71))),
            Text(sublabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RoomInfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoomInfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}