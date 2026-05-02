import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 2;

  // Controllers — Step 1: Personal Info
  final _surnameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _regNumberController = TextEditingController();
  String? _selectedGender;
  String? _selectedUniversity;
  String? _selectedUniversityId;

  List<dynamic> _universities = [];
  bool _isFetchingUniversities = false;

  // Controllers — Step 2: Account Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  // Animation
  late AnimationController _entryController;
  late AnimationController _stepController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;

  bool _isLoading = false;

  // Password strength
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 8) score += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) score += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) score += 0.25;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score += 0.25;
    return score;
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return Colors.red;
    if (_passwordStrength <= 0.5) return Colors.orange;
    if (_passwordStrength <= 0.75) return Colors.yellow.shade700;
    return const Color(0xFF00C48C);
  }

  String get _strengthLabel {
    if (_passwordController.text.isEmpty) return '';
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

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
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stepFade =
        CurvedAnimation(parent: _stepController, curve: Curves.easeIn);
    _stepSlide =
        Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _stepController, curve: Curves.easeOutCubic));

    _entryController.forward();
    _stepController.forward();

    _passwordController.addListener(() => setState(() {}));
    _fetchUniversities();
  }

  Future<void> _fetchUniversities() async {
    setState(() => _isFetchingUniversities = true);
    try {
      final data = await AuthService.getUniversities();
      if (mounted) {
        setState(() => _universities = data);
      }
    } catch (e) {
      _showError('Failed to load universities. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isFetchingUniversities = false);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _stepController.dispose();
    _scrollController.dispose();
    _surnameController.dispose();
    _otherNamesController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate step 1
    if (_currentStep == 0) {
      if (_surnameController.text.trim().isEmpty ||
          _otherNamesController.text.trim().isEmpty ||
          _regNumberController.text.trim().isEmpty ||
          _selectedGender == null ||
          _selectedUniversityId == null) {
        _showError('Please fill in all fields before continuing.');
        return;
      }
    }

    setState(() => _currentStep = 1);
    _stepController.reset();
    _stepController.forward();
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _stepController.reset();
    _stepController.forward();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError('Please accept the Terms & Conditions to register.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await AuthService.registerStudent(
        registrationNumber: _regNumberController.text.trim(),
        surname: _surnameController.text.trim(),
        otherNames: _otherNamesController.text.trim(),
        gender: _selectedGender!,
        studentEmail: _emailController.text.trim(),
        password: _passwordController.text,
        universityId: _selectedUniversityId!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          name: _surnameController.text.trim(),
          email: _emailController.text.trim(),
          onDone: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Return to login
          },
        ),
      );
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Registration failed.');
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Column(
          children: [
            // ── Header ──
            _buildHeader(),

            // ── Step indicator ──
            _buildStepIndicator(),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: SlideTransition(
                  position: _entrySlide,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Form(
                      key: _formKey,
                      child: SlideTransition(
                        position: _stepSlide,
                        child: FadeTransition(
                          opacity: _stepFade,
                          child: _currentStep == 0
                              ? _buildStep1()
                              : _buildStep2(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Nav ──
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1F71), Color(0xFF4F5FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -10,
              child: Container(
                width: 150,
                height: 150,
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
                    onTap: () => Navigator.pop(context),
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
                  const Row(
                    children: [
                      Text('🎓', style: TextStyle(fontSize: 36)),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Registration',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Create your UniStay account',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
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

  // ── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = ['Personal Info', 'Account Setup'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      width: 34,
                      height: 34,
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
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFF1A1F71)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                if (i < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin:
                          const EdgeInsets.only(bottom: 16, left: 6, right: 6),
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

  // ── Step 1: Personal Info ─────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Personal Details', icon: Icons.person_outline),
        const SizedBox(height: 16),

        // Surname
        _FormField(
          controller: _surnameController,
          label: 'Surname',
          hint: 'e.g. Nakato',
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Surname is required' : null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
        ),

        const SizedBox(height: 14),

        // Other Names
        _FormField(
          controller: _otherNamesController,
          label: 'Other Names',
          hint: 'e.g. Amara Joyce',
          icon: Icons.badge_outlined,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Other names are required' : null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
        ),

        const SizedBox(height: 14),

        // Registration Number
        _FormField(
          controller: _regNumberController,
          label: 'Registration Number',
          hint: 'e.g. 21/U/0123/PS',
          icon: Icons.numbers_outlined,
          validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Registration number is required'
                  : null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9/\-]')),
          ],
        ),

        const SizedBox(height: 14),

        // Gender
        _SectionLabel(label: 'Gender', icon: Icons.wc_outlined),
        const SizedBox(height: 10),
        Row(
          children: ['Male', 'Female'].map((g) {
            final isSelected = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1F71)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A1F71)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1A1F71).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        g == 'Male' ? '👨' : '👩',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        g,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // University
        _SectionLabel(
            label: 'University / Institution', icon: Icons.school_outlined),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedUniversityId != null
                  ? const Color(0xFF1A1F71)
                  : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedUniversityId,
            isExpanded: true,
            hint: Text(
              _isFetchingUniversities ? 'Loading universities...' : 'Select your university',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            icon: _isFetchingUniversities
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A1F71)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF1A1F71), size: 20),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF0D1147),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: _universities.map((u) {
              return DropdownMenuItem<String>(
                value: u['id'].toString(),
                child: Text(u['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedUniversityId = v;
                _selectedUniversity = _universities.firstWhere((u) => u['id'].toString() == v)['name'];
              });
            },
            validator: (v) => v == null ? 'Please select your university' : null,
          ),
        ),
        
      

        const SizedBox(height: 8),

        // University note
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Only universities registered on UniStay are shown.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: Account Setup ─────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview card
        _buildProfilePreview(),

        const SizedBox(height: 24),

        _SectionLabel(label: 'Account Credentials', icon: Icons.lock_outline),
        const SizedBox(height: 16),

        // Student Email
        _FormField(
          controller: _emailController,
          label: 'Student Email',
          hint: 'e.g. nakato@students.mak.ac.ug',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),

        const SizedBox(height: 14),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D1147)),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            return null;
          },
          decoration: _inputDeco(
            label: 'Password',
            hint: 'At least 8 characters',
            icon: Icons.lock_outline,
            suffix: GestureDetector(
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
        ),

        // Password strength bar
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_strengthColor),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _strengthLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: _strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildPasswordHints(),
        ],

        const SizedBox(height: 14),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D1147)),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
          decoration: _inputDeco(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline,
            suffix: GestureDetector(
              onTap: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

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
                  color: _acceptedTerms
                      ? const Color(0xFF1A1F71)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _acceptedTerms
                        ? const Color(0xFF1A1F71)
                        : Colors.grey.shade300,
                    width: 1.5,
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
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5),
                    children: const [
                      TextSpan(text: 'I agree to UniStay\'s '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: Color(0xFF1A1F71),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF1A1F71),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Profile Preview Card ──────────────────────────────────────────────────

  Widget _buildProfilePreview() {
    final fullName =
        '${_surnameController.text.trim()} ${_otherNamesController.text.trim()}'
            .trim();
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F71), Color(0xFF4F5FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Your Name' : fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _regNumberController.text.isEmpty
                      ? 'Reg. Number'
                      : _regNumberController.text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedUniversity ?? 'University not selected',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_selectedGender != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedGender == 'Male' ? '👨 Male' : '👩 Female',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ── Password Hints ────────────────────────────────────────────────────────

  Widget _buildPasswordHints() {
    final p = _passwordController.text;
    final hints = [
      {'label': '8+ characters', 'met': p.length >= 8},
      {'label': 'Uppercase letter', 'met': p.contains(RegExp(r'[A-Z]'))},
      {'label': 'Number', 'met': p.contains(RegExp(r'[0-9]'))},
      {
        'label': 'Special character',
        'met': p.contains(RegExp(r'[!@#\$%^&*]'))
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: hints.map((h) {
        final met = h['met'] as bool;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 13,
              color: met ? const Color(0xFF00C48C) : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              h['label'] as String,
              style: TextStyle(
                fontSize: 11,
                color: met ? const Color(0xFF00C48C) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      }).toList(),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F71),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Next / Register
          Expanded(
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : _currentStep == 0
                      ? _nextStep
                      : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F71), Color(0xFF4F5FD4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1F71).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentStep == 0
                              ? 'Continue →'
                              : 'Create Account 🎉',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1A1F71), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}

// ─── Form Field Helper ─────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0D1147)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: const Color(0xFF1A1F71), size: 20),
        filled: true,
        fillColor: Colors.white,
        labelStyle:
            TextStyle(color: Colors.grey.shade500, fontSize: 13),
        hintStyle:
            TextStyle(color: Colors.grey.shade300, fontSize: 13),
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
              const BorderSide(color: Color(0xFF1A1F71), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1A1F71)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F71),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Success Dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.name,
    required this.email,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF00C48C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Account Created! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D1147),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome to UniStay, $name!\nPlease sign in with:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 16, color: Color(0xFF1A1F71)),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1A1F71),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F71), Color(0xFF4F5FD4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Go to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}