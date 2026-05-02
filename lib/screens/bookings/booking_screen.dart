import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hostel_list_screen.dart';
import 'booking_success_screen.dart';

// ─── Booking Model ─────────────────────────────────────────────────────────────

class BookingData {
  final String id;
  final Hostel hostel;
  final RoomType roomType;
  final DateTime moveInDate;
  final int durationMonths;
  final String studentName;
  final String studentId;
  final String phoneNumber;
  final String email;
  final String university;
  final String courseYear;
  final String paymentMethod;
  final double totalAmount;
  final double depositAmount;
  final DateTime bookedAt;
  BookingStatus status;

  BookingData({
    required this.id,
    required this.hostel,
    required this.roomType,
    required this.moveInDate,
    required this.durationMonths,
    required this.studentName,
    required this.studentId,
    required this.phoneNumber,
    required this.email,
    required this.university,
    required this.courseYear,
    required this.paymentMethod,
    required this.totalAmount,
    required this.depositAmount,
    required this.bookedAt,
    this.status = BookingStatus.pending,
  });
}

enum BookingStatus { pending, confirmed, active, completed, cancelled }

// ─── Global Bookings Store (simple in-memory state) ───────────────────────────

class BookingStore {
  static final List<BookingData> _bookings = [];
  static List<BookingData> get bookings => List.unmodifiable(_bookings);

  static void addBooking(BookingData booking) {
    _bookings.insert(0, booking);
  }

  static void updateStatus(String id, BookingStatus status) {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) _bookings[idx].status = status;
  }
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

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late AnimationController _progressController;

  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Stay Details
  DateTime? _moveInDate;
  int _durationMonths = 3;

  // Step 2: Personal Info
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController(text: 'Makerere University');
  String _courseYear = '1st Year';

  // Step 3: Payment
  String _paymentMethod = 'Mobile Money';
  final _momoNumberController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isProcessing = false;

  final List<String> _courseYears = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate'];
  final List<String> _paymentMethods = ['Mobile Money', 'Bank Transfer', 'Cash'];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressController.value = 1 / _totalSteps;
    _moveInDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _momoNumberController.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.roomType.pricePerMonth * _durationMonths;
  double get _depositAmount => widget.roomType.pricePerMonth; // 1 month deposit
  double get _firstPayment => _depositAmount + widget.roomType.pricePerMonth; // deposit + first month

  String _formatPrice(double price) {
    if (price >= 1000000) return 'UGX ${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime get _moveOutDate {
    if (_moveInDate == null) return DateTime.now();
    return DateTime(
      _moveInDate!.year,
      _moveInDate!.month + _durationMonths,
      _moveInDate!.day,
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validate current step
      if (_currentStep == 1) {
        if (!_formKey.currentState!.validate()) return;
      }

      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / _totalSteps);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / _totalSteps);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitBooking() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Create booking
    final booking = BookingData(
      id: 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      hostel: widget.hostel,
      roomType: widget.roomType,
      moveInDate: _moveInDate!,
      durationMonths: _durationMonths,
      studentName: _nameController.text.trim(),
      studentId: _studentIdController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      university: _universityController.text.trim(),
      courseYear: _courseYear,
      paymentMethod: _paymentMethod,
      totalAmount: _totalAmount,
      depositAmount: _depositAmount,
      bookedAt: DateTime.now(),
      status: BookingStatus.confirmed,
    );

    BookingStore.addBooking(booking);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: _prevStep,
          child: const Icon(Icons.arrow_back, color: Color(0xFF1A1F71)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Booking',
              style: TextStyle(
                color: Color(0xFF1A1F71),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (_, __) => LinearProgressIndicator(
              value: _progressController.value,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1F71)),
              minHeight: 4,
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          // Step Indicators
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: List.generate(_totalSteps, (i) {
                final labels = ['Stay Details', 'Your Info', 'Payment'];
                final icons = [Icons.calendar_today, Icons.person, Icons.payment];
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF00C48C)
                                  : isActive
                                      ? const Color(0xFF1A1F71)
                                      : Colors.grey.shade200,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Icon(icons[i],
                                      color: isActive ? Colors.white : Colors.grey.shade400,
                                      size: 16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive ? const Color(0xFF1A1F71) : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (i < _totalSteps - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 18),
                            color: isDone ? const Color(0xFF00C48C) : Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Page Content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1StayDetails(),
                  _buildStep2PersonalInfo(),
                  _buildStep3Payment(),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Step 1: Stay Details ──────────────────────────────────────────────────

  Widget _buildStep1StayDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Summary Card
          _buildRoomSummaryCard(),
          const SizedBox(height: 20),

          const Text('When do you want to move in?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 12),

          // Date Picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _moveInDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1A1F71),
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _moveInDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _moveInDate != null ? const Color(0xFF1A1F71) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: Color(0xFF1A1F71), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Move-in Date',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        Text(
                          _moveInDate != null ? _formatDate(_moveInDate!) : 'Select a date',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _moveInDate != null ? const Color(0xFF1A1F71) : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text('How long do you want to stay?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 12),

          // Duration Selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '$_durationMonths month${_durationMonths > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1A1F71),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [1, 3, 6, 9, 12].map((months) {
                    final isSelected = _durationMonths == months;
                    return GestureDetector(
                      onTap: () => setState(() => _durationMonths = months),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A1F71) : const Color(0xFFEEF0F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${months}mo',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (_moveInDate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DateDisplayTile(label: 'Move In', date: _formatDate(_moveInDate!)),
                        const Icon(Icons.arrow_forward, color: Color(0xFF1A1F71), size: 20),
                        _DateDisplayTile(label: 'Move Out', date: _formatDate(_moveOutDate)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildPriceSummaryCard(),
        ],
      ),
    );
  }

  // ── Step 2: Personal Info ─────────────────────────────────────────────────

  Widget _buildStep2PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Personal Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71)),
          ),
          const SizedBox(height: 4),
          Text(
            'This information will be used for your booking confirmation.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. Amara Nakato',
            icon: Icons.person_outline,
            validator: (v) => v!.trim().isEmpty ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _studentIdController,
            label: 'Student ID Number',
            hint: 'e.g. 21/U/0123/PS',
            icon: Icons.badge_outlined,
            validator: (v) => v!.trim().isEmpty ? 'Please enter your student ID' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'e.g. 0701234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v!.trim().isEmpty) return 'Please enter your phone number';
              if (v.trim().length < 10) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'e.g. amara@students.mak.ac.ug',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v!.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _universityController,
            label: 'University / Institution',
            hint: 'e.g. Makerere University',
            icon: Icons.school_outlined,
            validator: (v) => v!.trim().isEmpty ? 'Please enter your university' : null,
          ),
          const SizedBox(height: 12),

          // Course Year Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonFormField<String>(
              value: _courseYear,
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: 'Year of Study',
                labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.school, color: Color(0xFF1A1F71), size: 20),
              ),
              style: const TextStyle(color: Color(0xFF1A1F71), fontWeight: FontWeight.w500),
              items: _courseYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (v) => setState(() => _courseYear = v!),
              dropdownColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF00C48C), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your information is encrypted and will only be shared with the hostel management.',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Payment ────────────────────────────────────────────────────────

  Widget _buildStep3Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
          const SizedBox(height: 4),
          Text(
            'Select how you\'d like to pay your deposit',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          // Payment methods
          ..._paymentMethods.map((method) {
            final isSelected = _paymentMethod == method;
            final icons = {
              'Mobile Money': Icons.phone_android,
              'Bank Transfer': Icons.account_balance,
              'Cash': Icons.payments_outlined,
            };
            final colors = {
              'Mobile Money': const Color(0xFFE91E8C),
              'Bank Transfer': const Color(0xFF1A1F71),
              'Cash': const Color(0xFF00C48C),
            };
            final subtitles = {
              'Mobile Money': 'MTN / Airtel Money',
              'Bank Transfer': 'Bank to bank transfer',
              'Cash': 'Pay in person',
            };

            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? colors[method]! : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors[method]!.withOpacity(0.1)
                            : const Color(0xFFEEF0F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icons[method]!,
                        color: isSelected ? colors[method]! : Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isSelected ? colors[method]! : Colors.black87,
                              )),
                          Text(
                            subtitles[method]!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors[method]! : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colors[method]! : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          // Mobile Money number field
          if (_paymentMethod == 'Mobile Money') ...[
            const SizedBox(height: 8),
            _buildTextField(
              controller: _momoNumberController,
              label: 'Mobile Money Number',
              hint: 'e.g. 0701234567',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],

          if (_paymentMethod == 'Bank Transfer') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
                  const SizedBox(height: 8),
                  _BankDetailRow(label: 'Bank', value: 'Stanbic Bank Uganda'),
                  _BankDetailRow(label: 'Account Name', value: 'Hostel Management Ltd'),
                  _BankDetailRow(label: 'Account No.', value: '9030012345678'),
                  _BankDetailRow(label: 'Branch', value: 'Kampala Main Branch'),
                  _BankDetailRow(label: 'Reference', value: '${_nameController.text.split(' ').first}HOSTEL'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Final Payment Summary
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _PaymentRow(label: 'Room: ${widget.roomType.name}', value: _formatPrice(widget.roomType.pricePerMonth) + '/mo'),
                _PaymentRow(label: 'Duration', value: '$_durationMonths months'),
                _PaymentRow(label: 'Refundable Deposit (1 month)', value: _formatPrice(_depositAmount)),
                const Divider(color: Colors.white24, height: 24),
                _PaymentRow(label: 'Total Stay Cost', value: _formatPrice(_totalAmount)),
                _PaymentRow(
                  label: 'Due Now (Deposit + 1st Month)',
                  value: _formatPrice(_firstPayment),
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Terms
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _acceptedTerms ? const Color(0xFF1A1F71) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _acceptedTerms ? const Color(0xFF1A1F71) : Colors.grey.shade400,
                    ),
                  ),
                  child: _acceptedTerms
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                      children: const [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: Color(0xFF1A1F71),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Hostel Booking Policy',
                          style: TextStyle(
                            color: Color(0xFF1A1F71),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '. The deposit is refundable with 30 days notice.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Builders ────────────────────────────────────────────────────────

  Widget _buildRoomSummaryCard() {
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hostel.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.roomType.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(widget.roomType.pricePerMonth) + '/month',
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

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A1F71).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Monthly Rent', value: _formatPrice(widget.roomType.pricePerMonth)),
          _SummaryRow(label: 'Duration', value: '$_durationMonths months'),
          _SummaryRow(label: 'Total', value: _formatPrice(_totalAmount)),
          const Divider(height: 20),
          _SummaryRow(
            label: 'Due Now (Deposit + 1st Month)',
            value: _formatPrice(_firstPayment),
            isBold: true,
            color: const Color(0xFF1A1F71),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A1F71), size: 20),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A1F71), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1F71)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: isLastStep ? _submitBooking : _nextStep,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1F71).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isLastStep ? 'Confirm & Book 🎉' : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
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

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? (color ?? Colors.black87) : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _PaymentRow({required this.label, required this.value, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(isHighlighted ? 1 : 0.7),
                fontSize: isHighlighted ? 14 : 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? const Color(0xFFFFD700) : Colors.white,
              fontSize: isHighlighted ? 16 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDisplayTile extends StatelessWidget {
  final String label;
  final String date;

  const _DateDisplayTile({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71))),
      ],
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1F71))),
        ],
      ),
    );
  }
}