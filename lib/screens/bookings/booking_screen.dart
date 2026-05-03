import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'hostel_list_screen.dart';
import 'booking_success_screen.dart';

// ─── Booking Model ─────────────────────────────────────────────────────────────

class BookingData {
  final String id;
  final String status;
  final DateTime createdAt;
  final String roomType;
  final double roomPrice;
  final String hostelName;
  final String hostelLocation;
  final String? paymentMethod;
  final String? paymentType;
  final double? amountPaid;

  const BookingData({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.roomType,
    required this.roomPrice,
    required this.hostelName,
    required this.hostelLocation,
    this.paymentMethod,
    this.paymentType,
    this.amountPaid,
  });

  String get roomTypeName => roomType
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  factory BookingData.fromApiResponse(
    Map<String, dynamic> json, {
    String fallbackRoomType = '',
    double fallbackRoomPrice = 0,
    String fallbackHostelName = '',
    String fallbackHostelLocation = '',
  }) {
    final booking = _asMap(json['booking']).isNotEmpty ? _asMap(json['booking']) : json;
    final room = _asMap(booking['room']).isNotEmpty
        ? _asMap(booking['room'])
        : _asMap(json['room']);
    final hostel = _asMap(room['hostel']).isNotEmpty
        ? _asMap(room['hostel'])
        : _asMap(booking['hostel']).isNotEmpty
            ? _asMap(booking['hostel'])
            : _asMap(json['hostel']);

    final bookingId = _readString(booking, const ['id', 'bookingId']);
    final roomTypeValue = _readString(
      room,
      const ['roomType', 'type', 'room_type'],
    );
    final hostelNameValue = _readString(
      hostel,
      const ['hostelName', 'name', 'hostel_name'],
    );
    final hostelLocationValue = _readString(
      hostel,
      const ['location', 'address'],
    );

    return BookingData(
      id: bookingId.isNotEmpty ? bookingId : 'local-booking',
      status: _readString(booking, const ['status']).isNotEmpty
          ? _readString(booking, const ['status'])
          : 'active',
      createdAt: DateTime.tryParse(
            _readString(booking, const ['createdAt', 'created_at']),
          ) ??
          DateTime.now(),
      roomType: roomTypeValue.isNotEmpty ? roomTypeValue : fallbackRoomType,
      roomPrice: double.tryParse(room['price'].toString()) ?? fallbackRoomPrice,
      hostelName:
          hostelNameValue.isNotEmpty ? hostelNameValue : fallbackHostelName,
      hostelLocation: hostelLocationValue.isNotEmpty
          ? hostelLocationValue
          : fallbackHostelLocation,
    );
  }

  BookingData withPayment({
    required String paymentMethod,
    required String paymentType,
    required double amountPaid,
  }) =>
      BookingData(
        id: id,
        status: status,
        createdAt: createdAt,
        roomType: roomType,
        roomPrice: roomPrice,
        hostelName: hostelName,
        hostelLocation: hostelLocation,
        paymentMethod: paymentMethod,
        paymentType: paymentType,
        amountPaid: amountPaid,
      );
}

// ─── Global Bookings Store ─────────────────────────────────────────────────────

class BookingStore {
  static BookingData? lastBooking;
}

// ─── Booking Screen ────────────────────────────────────────────────────────────

class BookingScreen extends StatefulWidget {
  final Hostel hostel;
  final RoomType roomType;

  const BookingScreen({
    super.key,
    required this.hostel,
    required this.roomType,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  // 0 = confirm booking, 1 = payment
  int _step = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Created in step 0, used in step 1
  BookingData? _createdBooking;

  // Payment choices
  String _paymentMethod = 'mtn_mobile_money';
  String _paymentType = 'full';

  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatPrice(double price) {
    if (price >= 1000000) return 'UGX ${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  double get _paymentAmount =>
      _paymentType == 'partial'
          ? widget.roomType.price / 2
          : widget.roomType.price;

  String _friendlyError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg != null) return msg.toString();
      switch (e.response?.statusCode) {
        case 401:
          return 'Session expired. Please log in again.';
        case 403:
          return 'Access denied or account suspended.';
        case 409:
          return 'You already have an active booking for this room.';
        case 500:
          return 'Server error. Please try again later.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  // ── API Actions ────────────────────────────────────────────────────────────

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await StudentApiService.createBooking(widget.roomType.id);
      final booking = BookingData.fromApiResponse(
        data,
        fallbackRoomType: widget.roomType.roomType,
        fallbackRoomPrice: widget.roomType.price,
        fallbackHostelName: widget.hostel.name,
        fallbackHostelLocation: widget.hostel.location,
      );
      BookingStore.lastBooking = booking;
      setState(() {
        _createdBooking = booking;
        _step = 1;
        _isLoading = false;
      });
      _entryController.forward(from: 0);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _makePayment() async {
    if (_createdBooking == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await StudentApiService.makePayment(
        bookingId: _createdBooking!.id,
        paymentMethod: _paymentMethod,
        paymentType: _paymentType,
      );
      final amountPaid =
          double.tryParse(data['amount'].toString()) ?? _paymentAmount;
      final finalBooking = _createdBooking!.withPayment(
        paymentMethod: _paymentMethod,
        paymentType: _paymentType,
        amountPaid: amountPaid,
      );
      BookingStore.lastBooking = finalBooking;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(booking: finalBooking)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (_step == 1) {
              setState(() => _step = 0);
              _entryController.forward(from: 0);
            } else {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back, color: Color(0xFF1A1F71)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 0 ? 'Confirm Booking' : 'Make Payment',
              style: const TextStyle(
                  color: Color(0xFF1A1F71),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              'Step ${_step + 1} of 2',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 2,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF1A1F71)),
            minHeight: 4,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SlideTransition(
        position: _entrySlide,
        child: FadeTransition(
          opacity: _entryFade,
          child: _step == 0 ? _buildConfirmStep() : _buildPaymentStep(),
        ),
      ),
    );
  }

  // ── Step 1: Confirm Booking ────────────────────────────────────────────────

  Widget _buildConfirmStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomCard(),
                const SizedBox(height: 20),
                const Text(
                  'Booking Summary',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F71)),
                ),
                const SizedBox(height: 12),
                _buildSummaryCard([
                  _SummaryEntry('Hostel', widget.hostel.name),
                  _SummaryEntry('Room Type', widget.roomType.name),
                  _SummaryEntry('Location', widget.hostel.location),
                  _SummaryEntry('WhatsApp', widget.hostel.whatsappNumber),
                  _SummaryEntry('Price per Semester',
                      _formatPrice(widget.roomType.price)),
                  _SummaryEntry(
                      'Availability',
                      '${widget.roomType.availableSpaces} space'
                          '${widget.roomType.availableSpaces != 1 ? 's' : ''} left'),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF00C48C).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF00C48C), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A confirmation email will be sent to you and '
                          'the landlord will be notified once you confirm.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(_errorMessage!),
                ],
              ],
            ),
          ),
        ),
        _buildActionBar(
            label: 'Confirm Booking', onTap: _confirmBooking),
      ],
    );
  }

  // ── Step 2: Payment ────────────────────────────────────────────────────────

  Widget _buildPaymentStep() {
    final methods = [
      _PaymentOption(
        value: 'mtn_mobile_money',
        label: 'MTN Mobile Money',
        icon: Icons.phone_android,
        color: const Color(0xFFFFCC00),
      ),
      _PaymentOption(
        value: 'airtel_mobile_money',
        label: 'Airtel Money',
        icon: Icons.phone_android,
        color: const Color(0xFFE40000),
      ),
    ];

    final types = [
      _PaymentOption(
        value: 'full',
        label: 'Full Payment',
        subtitle: _formatPrice(widget.roomType.price),
        icon: Icons.payment,
        color: const Color(0xFF1A1F71),
      ),
      _PaymentOption(
        value: 'partial',
        label: 'Partial Payment (50%)',
        subtitle: _formatPrice(widget.roomType.price / 2),
        icon: Icons.splitscreen,
        color: const Color(0xFF00C48C),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomCard(),
                const SizedBox(height: 20),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F71)),
                ),
                const SizedBox(height: 12),
                ...methods.map((m) => _buildOptionTile(
                      value: m.value,
                      label: m.label,
                      subtitle: m.subtitle,
                      icon: m.icon,
                      color: m.color,
                      selected: _paymentMethod == m.value,
                      onTap: () =>
                          setState(() => _paymentMethod = m.value),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'Payment Type',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F71)),
                ),
                const SizedBox(height: 12),
                ...types.map((t) => _buildOptionTile(
                      value: t.value,
                      label: t.label,
                      subtitle: t.subtitle,
                      icon: t.icon,
                      color: t.color,
                      selected: _paymentType == t.value,
                      onTap: () =>
                          setState(() => _paymentType = t.value),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Due',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      Text(
                        _formatPrice(_paymentAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(_errorMessage!),
                ],
              ],
            ),
          ),
        ),
        _buildActionBar(label: 'Pay Now', onTap: _makePayment),
      ],
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.hotel, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hostel.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.roomType.name,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(widget.roomType.price),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<_SummaryEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final isLast = e.key == entries.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.value.label,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600)),
                    Flexible(
                      child: Text(
                        e.value.value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F71)),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionTile({
    required String value,
    required String label,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.1)
                    : const Color(0xFFEEF0F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? color : Colors.grey.shade500,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selected ? color : Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                    color: selected ? color : Colors.grey.shade300,
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13, color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
      {required String label, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isLoading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF1A1F71), Color(0xFF2D3561)]),
            color: _isLoading ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Internal Data Classes ─────────────────────────────────────────────────────

class _SummaryEntry {
  final String label;
  final String value;
  const _SummaryEntry(this.label, this.value);
}

class _PaymentOption {
  final String value;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const _PaymentOption({
    required this.value,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
  });
}
