import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'role_select_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final UserRole role;
  final bool isFirstLogin;

  const ResetPasswordScreen({
    super.key,
    required this.role,
    required this.isFirstLogin,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Forgot password flow: step 0 = enter email, step 1 = enter OTP, step 2 = new password
  // First login flow: step 0 = enter new password directly
  int _step = 0;

  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  late AnimationController _entryController;
  late AnimationController _stepController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  Color get _roleColor {
    switch (widget.role) {
      case UserRole.student:    return const Color(0xFF1A1F71);
      case UserRole.landlord:   return const Color(0xFF006B4F);
      case UserRole.university: return const Color(0xFF7B2FF7);
      case UserRole.admin:      return const Color(0xFFB45309);
    }
  }

  Color get _roleAccent {
    switch (widget.role) {
      case UserRole.student:    return const Color(0xFF4F5FD4);
      case UserRole.landlord:   return const Color(0xFF00A876);
      case UserRole.university: return const Color(0xFF9B5FF7);
      case UserRole.admin:      return const Color(0xFFD97706);
    }
  }

  double get _passwordStrength {
    final p = _newPasswordController.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 8) score += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) score += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) score += 0.25;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score += 0.25;
    return score;
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return Colors.red;
    if (_passwordStrength <= 0.5) return Colors.orange;
    if (_passwordStrength <= 0.75) return Colors.yellow.shade700;
    return const Color(0xFF00C48C);
  }

  String get _strengthLabel {
    if (_newPasswordController.text.isEmpty) return '';
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong ✓';
  }

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
    _newPasswordController.addListener(() => setState(() {}));

    // If first login, skip directly to new-password step
    if (widget.isFirstLogin) _step = 0;
  }

  @override
  void dispose() {
    _entryController.dispose();
    _stepController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _animateStep() {
    _stepController.reset();
    _stepController.forward();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 1;
    });
    _animateStep();
    _startResendTimer();
  }

  void _startResendTimer() async {
    setState(() => _resendCountdown = 60);
    while (_resendCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 2;
    });
    _animateStep();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        isFirstLogin: widget.isFirstLogin,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
          if (widget.isFirstLogin) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFirstLogin
        ? 'Set New Password'
        : _step == 0
            ? 'Forgot Password'
            : _step == 1
                ? 'Verify Code'
                : 'New Password';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Column(
          children: [
            // Header
            _buildHeader(title),

            // Progress bar (forgot password flow only)
            if (!widget.isFirstLogin)
              _buildProgressBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStep(),
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

  Widget _buildHeader(String title) {
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
                  Row(
                    children: [
                      const Text('🔐', style: TextStyle(fontSize: 34)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'UniStay Account Security',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12),
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

  Widget _buildProgressBar() {
    final steps = ['Email', 'Verify', 'Reset'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: List.generate(3, (i) {
          final isDone = i < _step;
          final isActive = i == _step;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF00C48C)
                            : isActive
                                ? _roleColor
                                : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              ),
                      ),
                    ),
                    if (i < 2) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          color: isDone
                              ? const Color(0xFF00C48C)
                              : Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDone
                        ? const Color(0xFF00C48C)
                        : isActive
                            ? _roleColor
                            : Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (widget.isFirstLogin) return _buildNewPasswordStep();

    switch (_step) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPasswordStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Enter Email ────────────────────────────────────────────────────

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBox(
          icon: Icons.mail_outline,
          color: _roleColor,
          message:
              'Enter your registered email address. We\'ll send you a 6-digit verification code.',
        ),
        const SizedBox(height: 28),
        const Text('Email Address',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF0D1147))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDeco(
            label: 'Registered Email',
            hint: 'e.g. student@university.ac.ug',
            icon: Icons.email_outlined,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: 'Send Verification Code',
          color: _roleColor,
          accent: _roleAccent,
          isLoading: _isLoading,
          icon: Icons.send_outlined,
          onTap: _sendOtp,
        ),
      ],
    );
  }

  // ── Step 1: Enter OTP ──────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBox(
          icon: Icons.sms_outlined,
          color: _roleColor,
          message:
              'A 6-digit code was sent to ${_emailController.text.trim()}. Enter it below.',
        ),
        const SizedBox(height: 28),
        const Text('Verification Code',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF0D1147))),
        const SizedBox(height: 16),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextFormField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _roleColor,
                ),
                onChanged: (v) {
                  if (v.length == 1 && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  counterText: '',
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
                    borderSide:
                        BorderSide(color: _roleColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            _resendCountdown > 0
                ? Text(
                    'Resend in ${_resendCountdown}s',
                    style: TextStyle(
                      color: _roleColor.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      setState(() => _isResending = true);
                      await Future.delayed(const Duration(milliseconds: 1000));
                      if (mounted) {
                        setState(() => _isResending = false);
                        _startResendTimer();
                      }
                    },
                    child: _isResending
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _roleColor),
                          )
                        : Text(
                            'Resend',
                            style: TextStyle(
                              color: _roleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                  ),
          ],
        ),

        const SizedBox(height: 32),

        _PrimaryButton(
          label: 'Verify Code',
          color: _roleColor,
          accent: _roleAccent,
          isLoading: _isLoading,
          icon: Icons.verified_outlined,
          onTap: _verifyOtp,
        ),
      ],
    );
  }

  // ── Step 2 / First Login: New Password ─────────────────────────────────────

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isFirstLogin)
          _InfoBox(
            icon: Icons.security_outlined,
            color: _roleColor,
            message:
                'Welcome! For security, you must set a new personal password before continuing.',
          ),
        if (widget.isFirstLogin) const SizedBox(height: 20),

        const Text('New Password',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF0D1147))),
        const SizedBox(height: 8),

        // New password
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            return null;
          },
          decoration: _inputDeco(
            label: 'New Password',
            hint: 'At least 8 characters',
            icon: Icons.lock_outline,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureNew = !_obscureNew),
              child: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
        ),

        // Strength bar
        if (_newPasswordController.text.isNotEmpty) ...[
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
              Text(_strengthLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: _strengthColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          _buildPasswordHints(),
        ],

        const SizedBox(height: 14),

        // Confirm password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _newPasswordController.text)
              return 'Passwords do not match';
            return null;
          },
          decoration: _inputDeco(
            label: 'Confirm Password',
            hint: 'Re-enter new password',
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

        const SizedBox(height: 32),

        _PrimaryButton(
          label: widget.isFirstLogin ? 'Set Password & Continue' : 'Reset Password',
          color: _roleColor,
          accent: _roleAccent,
          isLoading: _isLoading,
          icon: Icons.lock_reset_outlined,
          onTap: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildPasswordHints() {
    final p = _newPasswordController.text;
    final hints = [
      {'label': '8+ chars', 'met': p.length >= 8},
      {'label': 'Uppercase', 'met': p.contains(RegExp(r'[A-Z]'))},
      {'label': 'Number', 'met': p.contains(RegExp(r'[0-9]'))},
      {'label': 'Special char', 'met': p.contains(RegExp(r'[!@#\$%^&*]'))},
    ];
    return Wrap(
      spacing: 10,
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
            Text(h['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: met
                      ? const Color(0xFF00C48C)
                      : Colors.grey.shade400,
                )),
          ],
        );
      }).toList(),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _roleColor, size: 20),
        suffixIcon: suffix,
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
          borderSide: BorderSide(color: _roleColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      );
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBox(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13, color: color, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color accent;
  final bool isLoading;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.accent,
    required this.isLoading,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, accent]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final bool isFirstLogin;
  final VoidCallback onDone;

  const _SuccessDialog({required this.isFirstLogin, required this.onDone});

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
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFF00C48C), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              isFirstLogin ? 'Password Set! 🎉' : 'Password Reset! ✅',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1147)),
            ),
            const SizedBox(height: 8),
            Text(
              isFirstLogin
                  ? 'Your new password has been set.\nYou can now use it to sign in.'
                  : 'Your password has been successfully updated.\nSign in with your new password.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F71), Color(0xFF4F5FD4)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Back to Login',
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
}