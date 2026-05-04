// ignore_for_file: unused_element
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_hostel_management/screens/bookings/student_dashboard_screen.dart';
import 'role_select_screen.dart';
import 'register_screen.dart';
import 'university/university_dashboard_screen.dart';
import 'landlord/landlord_dashboard_screen.dart';
import 'landlord/landlord_models.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/app_error.dart';
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
        return 'Sign in with your landlord email and password.';
      case UserRole.university:
        return 'Sign in with your institution email and password.';
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
    var resolvedFirstLogin = firstLogin;

    await _configureAuthenticatedSession();

    if (resolvedRole == 'landlord' || resolvedRole == 'university') {
      ApiService.init(() async {
        try {
          final sessionToken = await _clerkAuth.sessionToken();
          return sessionToken.jwt;
        } catch (_) {
          return null;
        }
      });

      if (resolvedRole == 'landlord') {
        final me = await AuthService.getLandlordMe();
        resolvedFirstLogin = _readBoolFlag(me['firstLogin']) ?? resolvedFirstLogin;
      } else {
        final me = await AuthService.getUniversityMe();
        resolvedFirstLogin = _readBoolFlag(me['firstLogin']) ?? resolvedFirstLogin;
        AuthService.loadUniversityProfile();
      }
    }

    if (!mounted) return;

    if (resolvedFirstLogin &&
        (resolvedRole == 'landlord' || resolvedRole == 'university')) {
      final updated = await _showFirstLoginResetModal(
        resolvedRole == 'landlord' ? UserRole.landlord : UserRole.university,
      );
      if (updated != true || !mounted) {
        return;
      }
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

  bool? _readBoolFlag(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) {
    _shakeController.forward(from: 0);
    return;
  }

  setState(() => _isLoading = true);
  HapticFeedback.mediumImpact();

  try {
    final identifier = _emailController.text.trim();
    final result = widget.role == UserRole.landlord && !identifier.contains('@')
        ? await AuthService.loginWithCode(
            auth: _clerkAuth,
            landlordCode: identifier,
            password: _passwordController.text,
          )
        : await AuthService.login(
            auth: _clerkAuth,
            identifier: identifier,
            password: _passwordController.text,
          );
    await _completeLoginFlow(
      firstLogin: result.firstLogin,
      role: result.role,
    );

  } on DioException catch (e) {
    final statusCode = e.response?.statusCode;
    final message = AppError.message(e);
    if (statusCode == 403) {
      _showError('Your account has been suspended. Contact support.');
    } else {
      _showError(message);
    }
    _shakeController.forward(from: 0);
  } catch (e) {
    final cleaned = AppError.message(e, fallback: 'Login failed. Please try again.');
    final attemptedCodeLogin =
        widget.role == UserRole.landlord &&
        !_emailController.text.trim().contains('@');
    if (cleaned == 'You are already signed in.') {
      final claims = _clerkAuth.user?.publicMetadata;
      await _completeLoginFlow(
        firstLogin: claims?['firstLogin'] == true,
        role: claims?['role']?.toString(),
      );
      return;
    }
    if (attemptedCodeLogin &&
        cleaned ==
            'The sign-in details are invalid. Please check them and try again.') {
      _showError(
        'Landlord code sign-in is not enabled in the current auth configuration. Use the landlord email for now, or enable username/code sign-in in Clerk and the backend.',
      );
      _shakeController.forward(from: 0);
      return;
    }
    _showError(cleaned);
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

Future<bool?> _showFirstLoginResetModal(UserRole role) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FirstLoginResetDialog(
      role: role,
      roleColor: _roleColor,
      roleAccent: _roleAccent,
      onSubmit: (newPassword) async {
        if (role == UserRole.landlord) {
          await ApiService.resetPassword(newPassword);
        } else {
          await AuthService.resetPasswordUniversity(newPassword: newPassword);
        }
      },
    ),
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
          label: 'Password',
          hint: 'Enter the password provided by your university',
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
          label: 'Password',
          hint: 'Enter your password',
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ],
    );
  }

}

class _FirstLoginResetDialog extends StatefulWidget {
  final UserRole role;
  final Color roleColor;
  final Color roleAccent;
  final Future<void> Function(String newPassword) onSubmit;

  const _FirstLoginResetDialog({
    required this.role,
    required this.roleColor,
    required this.roleAccent,
    required this.onSubmit,
  });

  @override
  State<_FirstLoginResetDialog> createState() => _FirstLoginResetDialogState();
}

class _FirstLoginResetDialogState extends State<_FirstLoginResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_newPasswordController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final message = AppError.message(
        e,
        fallback: 'Failed to reset password.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to reset password.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (widget.role) {
      UserRole.student => 'student',
      UserRole.landlord => 'landlord',
      UserRole.university => 'university',
    };

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [widget.roleColor, widget.roleAccent],
                    ),
                  ),
                  child: const Icon(Icons.lock_reset, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set Your New Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1147),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is your first $roleLabel login. You must choose a personal password before continuing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _PasswordField(
                  controller: _newPasswordController,
                  roleColor: widget.roleColor,
                  obscure: _obscureNew,
                  label: 'New Password',
                  hint: 'At least 8 characters',
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D1147),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your new password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: widget.roleColor,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
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
                          BorderSide(color: widget.roleColor, width: 1.5),
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
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.roleColor, widget.roleAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Set Password & Continue',
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
          ),
        ),
      ),
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
