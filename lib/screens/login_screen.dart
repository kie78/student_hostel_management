// ignore_for_file: unused_element
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_hostel_management/screens/bookings/student_dashboard_screen.dart';
import 'role_select_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'university/university_dashboard_screen.dart';
import 'landlord/landlord_dashboard_screen.dart';
import 'landlord/landlord_models.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';


class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
late ClerkAuthState _clerkAuth;
bool _checkedExistingSession = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _clerkAuth = ClerkAuth.of(context, listen: false);
  if (!_checkedExistingSession) {
    _checkedExistingSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeExistingSessionIfNeeded();
    });
  }
}
  final _formKey = GlobalKey<FormState>();

  // Common
  final _passwordController = TextEditingController();

  // Student / Landlord / University
  final _emailController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFirstLogin = false; // for Landlord & University

  late AnimationController _entryController;
  late AnimationController _shakeController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _shake;

  // Role theme
  Color get _roleColor {
    switch (widget.role) {
      case UserRole.student:     return const Color(0xFF1A1F71);
      case UserRole.landlord:    return const Color(0xFF006B4F);
      case UserRole.university:  return const Color(0xFF7B2FF7);
    }
  }

  Color get _roleAccent {
    switch (widget.role) {
      case UserRole.student:     return const Color(0xFF4F5FD4);
      case UserRole.landlord:    return const Color(0xFF00A876);
      case UserRole.university:  return const Color(0xFF9B5FF7);
    }
  }

  String get _roleLabel {
    switch (widget.role) {
      case UserRole.student:     return 'Student';
      case UserRole.landlord:    return 'Landlord';
      case UserRole.university:  return 'University';
    }
  }

  String get _roleEmoji {
    switch (widget.role) {
      case UserRole.student:     return '🎓';
      case UserRole.landlord:    return '🏢';
      case UserRole.university:  return '🏛️';
    }
  }

  String get _loginHint {
    switch (widget.role) {
      case UserRole.student:
        return 'Sign in with your student email and password.';
      case UserRole.landlord:
        return 'Sign in with the landlord email and password provided by your university.';
      case UserRole.university:
        return 'Sign in with the credentials sent to your institution email.';
    }
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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _roleKey(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'student';
      case UserRole.landlord:
        return 'landlord';
      case UserRole.university:
        return 'university';
    }
  }

  Future<void> _configureAuthenticatedSession() async {
    final sessionToken = await _clerkAuth.sessionToken();
    ApiClient.setToken(sessionToken.jwt);
    ApiClient.setTokenRefresher(() async {
      try {
        final refreshed = await _clerkAuth.sessionToken();
        return refreshed.jwt;
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _completeLoginFlow({
    required bool firstLogin,
    String? role,
  }) async {
    final resolvedRole = role ?? _roleKey(widget.role);

    await _configureAuthenticatedSession();

    if (resolvedRole == 'university') {
      await AuthService.loadUniversityProfile();
    }

    if (resolvedRole == 'landlord' || resolvedRole == 'university') {
      ApiService.init(() async {
        try {
          final sessionToken = await _clerkAuth.sessionToken();
          return sessionToken.jwt;
        } catch (_) {
          return null;
        }
      });
    }

    if (!mounted) return;

    if (firstLogin &&
        (resolvedRole == 'landlord' || resolvedRole == 'university')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            role: resolvedRole == 'landlord'
                ? UserRole.landlord
                : UserRole.university,
            isFirstLogin: true,
          ),
        ),
      );
      return;
    }

    switch (resolvedRole) {
      case 'student':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          (route) => false,
        );
        break;
      case 'landlord':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandlordDashboardScreen()),
          (route) => false,
        );
        break;
      case 'university':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UniversityDashboardScreen()),
          (route) => false,
        );
        break;
      default:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          (route) => false,
        );
        break;
    }
  }

  Future<void> _resumeExistingSessionIfNeeded() async {
    final claims = _clerkAuth.user?.publicMetadata;
    if (_clerkAuth.user == null && _clerkAuth.session == null) {
      return;
    }

    final resolvedRole = claims?['role']?.toString() ?? _roleKey(widget.role);
    final firstLogin = claims?['firstLogin'] == true;
    await _completeLoginFlow(firstLogin: firstLogin, role: resolvedRole);
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) {
    _shakeController.forward(from: 0);
    return;
  }

  setState(() => _isLoading = true);
  HapticFeedback.mediumImpact();

  try {
    final result = await AuthService.login(
      auth: _clerkAuth,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    await _completeLoginFlow(
      firstLogin: result.firstLogin,
      role: result.role,
    );

  } on DioException catch (e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data['message'] ?? 'Something went wrong';
    if (statusCode == 403) {
      _showError('Your account has been suspended. Contact support.');
    } else {
      _showError(message);
    }
    _shakeController.forward(from: 0);
  } catch (e) {
    final raw = e.toString();
    final cleaned = raw
        .replaceAll(' (ERROR RECEIVED FROM SERVER)', '')
        .replaceAll('\n', ' ')
        .trim();
    if (cleaned.toLowerCase().contains('already signed in')) {
      final claims = _clerkAuth.user?.publicMetadata;
      await _completeLoginFlow(
        firstLogin: claims?['firstLogin'] == true,
        role: claims?['role']?.toString(),
      );
      return;
    }
    _showError(cleaned.isNotEmpty ? cleaned : 'Login failed. Please try again.');
    _shakeController.forward(from: 0);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

void _showError(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

void _goToRoleSelection() {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _goToRoleSelection();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SlideTransition(
                    position: _entrySlide,
                    child: FadeTransition(
                      opacity: _entryFade,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            _buildHintBanner(),
                            const SizedBox(height: 28),
                            _buildFields(),
                            const SizedBox(height: 24),
                            if (widget.role != UserRole.landlord)
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResetPasswordScreen(
                                        role: widget.role,
                                        isFirstLogin: false,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _roleColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.role == UserRole.landlord ||
                                widget.role == UserRole.university) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isFirstLogin,
                                    activeColor: _roleColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _isFirstLogin = v!),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _isFirstLogin = !_isFirstLogin,
                                      ),
                                      child: Text(
                                        'This is my first time signing in (reset password)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 32),
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                  _shakeController.isAnimating
                                      ? 8 *
                                          (0.5 - (_shake.value - 0.5).abs()) *
                                          2 *
                                          (_shake.value < 0.5 ? 1 : -1)
                                      : 0,
                                  0,
                                ),
                                child: child,
                              ),
                              child: GestureDetector(
                                onTap: _isLoading ? null : _submit,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 17),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_roleColor, _roleAccent],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _roleColor.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
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
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (widget.role == UserRole.student) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        color: _roleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.role != UserRole.student) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _roleColor.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _roleColor.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: _roleColor, size: 15),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          widget.role == UserRole.landlord
                                              ? 'Credentials are provided by your university.'
                                              : widget.role == UserRole.university
                                                  ? 'Credentials are provided by the General Admin.'
                                                  : 'Access restricted to system administrators.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _roleColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Curved Header ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_roleColor, _roleAccent],
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
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: 10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _goToRoleSelection,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emoji + Title
                  Row(
                    children: [
                      Text(_roleEmoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_roleLabel Login',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'UniStay Platform',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.65),
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

  // ── Hint Banner ───────────────────────────────────────────────────────────

  Widget _buildHintBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roleColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: _roleColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loginHint,
              style: TextStyle(
                fontSize: 13,
                color: _roleColor,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role-Specific Fields ──────────────────────────────────────────────────

  Widget _buildFields() {
    switch (widget.role) {
      case UserRole.student:
        return _buildStudentFields();
      case UserRole.landlord:
        return _buildLandlordFields();
      case UserRole.university:
        return _buildUniversityFields();
    }
  }

  // Student: email + password
  Widget _buildStudentFields() {
    return Column(
      children: [
        _InputField(
          controller: _emailController,
          label: 'Student Email',
          hint: 'e.g. student@university.ac.ug',
          icon: Icons.email_outlined,
          roleColor: _roleColor,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _PasswordField(
          controller: _passwordController,
          roleColor: _roleColor,
          obscure: _obscurePassword,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ],
    );
  }

  // Landlord: email + password
  Widget _buildLandlordFields() {
    return Column(
      children: [
        _InputField(
          controller: _emailController,
          label: 'Landlord Email',
          hint: 'e.g. landlord@example.com',
          icon: Icons.email_outlined,
          roleColor: _roleColor,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),

        const SizedBox(height: 14),

        _PasswordField(
          controller: _passwordController,
          roleColor: _roleColor,
          obscure: _obscurePassword,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ],
    );
  }

  // University: email + password
  Widget _buildUniversityFields() {
    return Column(
      children: [
        _InputField(
          controller: _emailController,
          label: 'Institution Email',
          hint: 'e.g. admin@university.ac.ug',
          icon: Icons.email_outlined,
          roleColor: _roleColor,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _PasswordField(
          controller: _passwordController,
          roleColor: _roleColor,
          obscure: _obscurePassword,
          label: 'Temporary Password',
          hint: 'Enter the password from your email',
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ],
    );
  }

}

// ─── Reusable Input Field ──────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color roleColor;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.roleColor,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0D1147)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
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
          borderSide: BorderSide(color: roleColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

// ─── Password Field ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final Color roleColor;
  final bool obscure;
  final VoidCallback onToggle;
  final String label;
  final String hint;

  const _PasswordField({
    required this.controller,
    required this.roleColor,
    required this.obscure,
    required this.onToggle,
    this.label = 'Password',
    this.hint = 'Enter your password',
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0D1147)),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: roleColor, size: 20),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
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
          borderSide: BorderSide(color: roleColor, width: 1.5),
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
