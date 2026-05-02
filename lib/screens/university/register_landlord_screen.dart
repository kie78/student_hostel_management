import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'university_models.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';

class RegisterLandlordScreen extends StatefulWidget {
  const RegisterLandlordScreen({super.key});

  @override
  State<RegisterLandlordScreen> createState() =>
      _RegisterLandlordScreenState();
}

class _RegisterLandlordScreenState extends State<RegisterLandlordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Step control
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1 — Personal Info
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  String? _selectedMaritalStatus;

  // Step 2 — Identification
  final _ninController = TextEditingController();
  final List<String> _documents = [];
  final List<String> _documentLabels = [
    'Ownership Deed / Title',
    'National ID (NIN card)',
    'Utility Bill',
    'Lease Agreement',
  ];

  // Step 3 — Preview
  bool _isLoading = false;

  late AnimationController _stepController;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  // Generated credentials
  late String _landlordCode;
  late String _username;
  late String _tempPassword;

  @override
  void initState() {
    super.initState();
    _landlordCode = UniversityStore.generateLandlordCode();
    _tempPassword = _generateTempPassword();

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stepFade =
        CurvedAnimation(parent: _stepController, curve: Curves.easeIn);
    _stepSlide =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _stepController, curve: Curves.easeOutCubic));
    _stepController.forward();

    _fullNameController.addListener(() => setState(() {
          _username = UniversityStore.generateUsername(
              _fullNameController.text.trim());
        }));
  }

  @override
  void dispose() {
    _stepController.dispose();
    _scrollController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  String _generateTempPassword() {
    const name = 'Landlord';
    final year = DateTime.now().year;
    return '${name}${year}!@Unistay';
  }

  void _animateStep() {
    _stepController.reset();
    _stepController.forward();
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  bool _validateStep1() {
    if (_fullNameController.text.trim().isEmpty) {
      _snack('Full name is required');
      return false;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _snack('Valid email is required');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      _snack('Valid phone number is required');
      return false;
    }
    if (_selectedGender == null) {
      _snack('Please select gender');
      return false;
    }
    if (_selectedMaritalStatus == null) {
      _snack('Please select marital status');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_ninController.text.trim().length < 14) {
      _snack('Enter a valid NIN (14 characters)');
      return false;
    }
    if (_documents.isEmpty) {
      _snack('Please attach at least one ownership document');
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _animateStep();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animateStep();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.registerLandlord(
        fullName: _fullNameController.text.trim(),
        gender: _selectedGender!,
        nin: _ninController.text.trim().toUpperCase(),
        maritalStatus: _selectedMaritalStatus!,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _generateTempPassword(),
        documentLabels: _documents,
      );

      if (!mounted) return;

      final landlordData = response['data']['landlord'];

      final landlord = UniversityLandlord(
        id: landlordData['id'],
        fullName: landlordData['fullName'],
        gender: _selectedGender!,
        nin: _ninController.text.trim().toUpperCase(),
        maritalStatus: _selectedMaritalStatus!,
        email: landlordData['email'],
        phone: _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        ownershipDocuments: _documents,
        universityId: '',
        landlordCode: landlordData['landlordCode'],
        username: landlordData['fullName']
            .toString()
            .toLowerCase()
            .replaceAll(' ', '_'),
        registeredAt: DateTime.now(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          landlord: landlord,
          tempPassword: _tempPassword,
          onDone: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // go back to dashboard
          },
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? 'Registration failed';
      if (statusCode == 409) {
        _snack('A landlord with this email already exists.');
      } else if (statusCode == 422) {
        final errors = e.response?.data['errors'] as Map?;
        final firstError = errors?.values.first;
        _snack(firstError is List ? firstError.first : message);
      } else {
        _snack(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  void _toggleDocument(String label) {
    setState(() {
      _documents.contains(label)
          ? _documents.remove(label)
          : _documents.add(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: SlideTransition(
                  position: _stepSlide,
                  child: FadeTransition(
                    opacity: _stepFade,
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Personal Details', 'Identification', 'Preview & Submit'];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('👤', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[_currentStep],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text('Register New Landlord',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12)),
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
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal', 'ID & Docs', 'Preview'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF00C48C)
                            : isActive
                                ? const Color(0xFF7B2FF7)
                                : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 15)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade400)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF7B2FF7)
                              : Colors.grey.shade400,
                        )),
                  ],
                ),
                if (i < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(
                          bottom: 16, left: 6, right: 6),
                      color: isDone
                          ? const Color(0xFF00C48C)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Personal Details ──────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lbl(icon: Icons.person_outline, label: 'Personal Information'),
        const SizedBox(height: 14),
        _Fld(
          controller: _fullNameController,
          label: 'Full Name',
          hint: 'e.g. Robert Ssemakula',
          icon: Icons.person_outline,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
          ],
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Full name is required' : null,
        ),
        const SizedBox(height: 14),
        _Fld(
          controller: _emailController,
          label: 'Email Address',
          hint: 'e.g. landlord@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _Fld(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'e.g. 0701234567',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone is required';
            if (v.length < 10) return 'Enter a valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _Fld(
          controller: _whatsappController,
          label: 'WhatsApp Number (optional)',
          hint: 'e.g. 256701234567 (with country code)',
          icon: Icons.chat_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              'Leave blank to use phone number as WhatsApp.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Lbl(icon: Icons.wc_outlined, label: 'Gender'),
        const SizedBox(height: 12),
        Row(
          children: _genders.map((g) {
            final selected = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF7B2FF7) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7B2FF7)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g == 'Male' ? '👨' : '👩',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(g,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _Lbl(
            icon: Icons.favorite_border_outlined, label: 'Marital Status'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
          children: _maritalStatuses.map((s) {
            final selected = _selectedMaritalStatus == s;
            return GestureDetector(
              onTap: () => setState(() => _selectedMaritalStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF7B2FF7) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF7B2FF7)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Center(
                  child: Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color:
                          selected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Identification & Documents ────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lbl(
            icon: Icons.badge_outlined,
            label: 'National Identification'),
        const SizedBox(height: 14),
        TextFormField(
          controller: _ninController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 14,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            UpperCaseTextFormatter(),
          ],
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF0D1147)),
          decoration: InputDecoration(
            labelText: 'National ID Number (NIN)',
            hintText: 'e.g. CM9200105734DH',
            prefixIcon: const Icon(Icons.badge_outlined,
                color: Color(0xFF7B2FF7), size: 20),
            filled: true,
            fillColor: Colors.white,
            labelStyle:
                TextStyle(color: Colors.grey.shade500, fontSize: 13),
            hintStyle: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 13,
                letterSpacing: 0),
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
              borderSide:
                  const BorderSide(color: Color(0xFF7B2FF7), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              'The NIN is found on the national ID card (14 characters).',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Lbl(icon: Icons.folder_outlined, label: 'Ownership Documents'),
        const SizedBox(height: 6),
        Text(
          'Select all documents the landlord is providing. Actual files will be uploaded when backend is connected.',
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: _documentLabels.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isChecked = _documents.contains(label);
              final icons = [
                Icons.description_outlined,
                Icons.badge_outlined,
                Icons.receipt_outlined,
                Icons.handshake_outlined,
              ];

              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _toggleDocument(label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? const Color(0xFF7B2FF7).withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icons[i],
                                color: isChecked
                                    ? const Color(0xFF7B2FF7)
                                    : Colors.grey.shade400,
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isChecked
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isChecked
                                      ? const Color(0xFF0D1147)
                                      : Colors.grey.shade600,
                                )),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked
                                  ? const Color(0xFF7B2FF7)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isChecked
                                    ? const Color(0xFF7B2FF7)
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 13)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < _documentLabels.length - 1)
                    Divider(
                        height: 1,
                        indent: 16,
                        color: Colors.grey.shade100),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _documents.isEmpty
                ? Colors.red.shade50
                : const Color(0xFFE8F5EF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _documents.isEmpty
                  ? Colors.red.shade200
                  : const Color(0xFF00C48C).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _documents.isEmpty
                    ? Icons.warning_amber_outlined
                    : Icons.check_circle_outline,
                color: _documents.isEmpty
                    ? Colors.red.shade600
                    : const Color(0xFF00C48C),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _documents.isEmpty
                      ? 'No documents selected — at least one required'
                      : '${_documents.length} document(s) selected: ${_documents.join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _documents.isEmpty
                        ? Colors.red.shade700
                        : const Color(0xFF006B4F),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF7B2FF7).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_file_outlined,
                  color: Color(0xFF7B2FF7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Physical document upload will be available once the backend is connected. For now, select which documents the landlord has presented.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Preview & Submit ──────────────────────────────────────────────

  Widget _buildStep3() {
    _username = UniversityStore.generateUsername(
        _fullNameController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lbl(
            icon: Icons.preview_outlined,
            label: 'Review Before Submitting'),
        const SizedBox(height: 16),
        _PreviewCard(
          title: 'Personal Information',
          icon: Icons.person_outline,
          color: const Color(0xFF7B2FF7),
          rows: [
            _Row2('Full Name', _fullNameController.text.trim()),
            _Row2('Email', _emailController.text.trim()),
            _Row2('Phone', _phoneController.text.trim()),
            if (_whatsappController.text.trim().isNotEmpty)
              _Row2('WhatsApp', _whatsappController.text.trim()),
            _Row2('Gender', _selectedGender ?? '—'),
            _Row2('Marital Status', _selectedMaritalStatus ?? '—'),
          ],
        ),
        const SizedBox(height: 12),
        _PreviewCard(
          title: 'Identification',
          icon: Icons.badge_outlined,
          color: const Color(0xFF1A1F71),
          rows: [
            _Row2('NIN', _ninController.text.trim().toUpperCase()),
            _Row2('Documents', _documents.join(', ')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
              const Row(
                children: [
                  Icon(Icons.vpn_key_outlined,
                      color: Colors.white70, size: 15),
                  SizedBox(width: 6),
                  Text('Login Credentials (sent via email)',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              _CredRow(label: 'Landlord Code', value: _landlordCode),
              _CredRow(label: 'Username', value: _username),
              _CredRow(label: 'Temp Password', value: _tempPassword),
              const SizedBox(height: 8),
              Text(
                '⚠️ Landlord must reset this password on first login.',
                style: TextStyle(fontSize: 11, color: Colors.yellow.shade200),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEmailPreview(),
      ],
    );
  }

  Widget _buildEmailPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              border:
                  Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.email,
                      color: Color(0xFF7B2FF7), size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email Preview (via Resend)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF0D1147))),
                      Text(
                          'To: ${_emailController.text.trim().isEmpty ? 'landlord@email.com' : _emailController.text.trim()}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Dear ${_fullNameController.text.trim().isEmpty ? 'Landlord' : _fullNameController.text.trim().split(' ').first},',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1147))),
                const SizedBox(height: 8),
                Text(
                  'You have been registered as a landlord on UniStay by ${UniversityStore.currentUniversity.name}. Below are your login credentials:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF7B2FF7).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _EmailInfoRow(
                          label: 'Landlord Code', value: _landlordCode),
                      const SizedBox(height: 4),
                      _EmailInfoRow(label: 'Username', value: _username),
                      const SizedBox(height: 4),
                      _EmailInfoRow(
                          label: 'Password', value: _tempPassword),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '⚠️ Please reset your password immediately after your first login.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B2FF7))),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : isLast
                      ? _submit
                      : _nextStep,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF7B2FF7).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          isLast ? 'Register & Send Email 📧' : 'Continue →',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _Lbl extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Lbl({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: const Color(0xFF7B2FF7)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B2FF7))),
      ]);
}

class _Fld extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Fld({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D1147)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              Icon(icon, color: const Color(0xFF7B2FF7), size: 20),
          filled: true,
          fillColor: Colors.white,
          labelStyle:
              TextStyle(color: Colors.grey.shade500, fontSize: 13),
          hintStyle:
              TextStyle(color: Colors.grey.shade300, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF7B2FF7), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      );
}

class _Row2 {
  final String label, value;
  const _Row2(this.label, this.value);
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Row2> rows;

  const _PreviewCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(r.label,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                      ),
                      Expanded(
                        child: Text(
                          r.value.isEmpty ? '—' : r.value,
                          style: const TextStyle(
                              fontSize: 12,
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

class _CredRow extends StatelessWidget {
  final String label, value;
  const _CredRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
            ),
            Flexible(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _EmailInfoRow extends StatelessWidget {
  final String label, value;
  const _EmailInfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: ',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B2FF7)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _SuccessDialog extends StatelessWidget {
  final UniversityLandlord landlord;
  final String tempPassword;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.landlord,
    required this.tempPassword,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: Color(0xFF00C48C), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Landlord Registered! 🎉',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1147))),
              const SizedBox(height: 8),
              Text(
                '${landlord.fullName} has been registered.\nLogin credentials sent to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _EmailInfoRow(
                        label: 'Email', value: landlord.email),
                    const SizedBox(height: 4),
                    _EmailInfoRow(
                        label: 'Code', value: landlord.landlordCode),
                    const SizedBox(height: 4),
                    _EmailInfoRow(
                        label: 'Password', value: tempPassword),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Landlord must reset password on first login.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onDone,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF9B5FF7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Back to Dashboard',
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
      );
}