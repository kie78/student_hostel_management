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
  int _imageIndex = 0;
  final PageController _imagePageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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

  // Use actual hostel images from the API (Cloudinary URLs)
  List<String> get _hostelImages =>
      widget.hostel.images.isNotEmpty ? widget.hostel.images : [''];

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
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
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
                                    : Colors.white.withValues(alpha: 0.5),
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
                            color: Colors.black.withValues(alpha: 0.6),
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
                                          widget.hostel.location,
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                        ],
                        onTap: (i) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tab Content
                    _buildRoomsTab(),

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
                          ? const Color(0xFF1A1F71).withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.04),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _RoomInfoBadge(icon: Icons.people, label: '${room.maxOccupants} person'),
                              const SizedBox(width: 8),
                              if (room.hasEnsuite)
                                _RoomInfoBadge(icon: Icons.shower, label: 'Ensuite'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _formatPrice(room.pricePerSemester),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1F71),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' /sem',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                _formatPrice(_selectedRoom.pricePerSemester),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1F71),
                ),
              ),
              Text(
                'per semester · ${_selectedRoom.name}',
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
                          color: const Color(0xFF1A1F71).withValues(alpha: 0.4),
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