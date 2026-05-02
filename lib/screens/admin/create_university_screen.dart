import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateUniversityScreen
//
// Calls POST /admin/universities with:
//   { university_name, location, type, email, password }
//
// On success the API automatically sends login credentials to the university
// email. The firstLogin flag will be true — the university app prompts a
// password reset on first login.
// ─────────────────────────────────────────────────────────────────────────────

class CreateUniversityScreen extends StatefulWidget {
  final AdminApiService apiService;

  const CreateUniversityScreen({super.key, required this.apiService});

  @override
  State<CreateUniversityScreen> createState() =>
      _CreateUniversityScreenState();
}

class _CreateUniversityScreenState extends State<CreateUniversityScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  UniversityType? _selectedType;
  String? _selectedLocation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  final List<String> _ugandaLocations = [
    'Kampala', 'Wakiso', 'Mukono', 'Jinja', 'Gulu',
    'Mbarara', 'Masaka', 'Mbale', 'Lira', 'Arua',
    'Fort Portal', 'Entebbe', 'Kabale', 'Soroti',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _snack('Please select the university type');
      return;
    }
    if (_selectedLocation == null) {
      _snack('Please select the university location');
      return;
    }

    setState(() => _isLoading = true);

    final req = CreateUniversityRequest(
      universityName: _nameController.text.trim(),
      location: _selectedLocation!,
      type: _selectedType == UniversityType.government
          ? 'government'
          : 'private',
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final result = await widget.apiService.createUniversity(req);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.data != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          university: result.data!,
          onDone: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // back to dashboard
          },
        ),
      );
    } else {
      _snack(result.error ?? 'Failed to create university. Please try again.');
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: SlideTransition(
                  position: _entrySlide,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoBanner(),
                          const SizedBox(height: 24),

                          // ── University Details ──
                          _Lbl(icon: Icons.account_balance_outlined,
                              label: 'University Details'),
                          const SizedBox(height: 12),

                          _Field(
                            controller: _nameController,
                            label: 'University / Institution Name',
                            hint: 'e.g. Makerere University',
                            icon: Icons.account_balance_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'University name is required';
                              if (v.trim().length < 5)
                                return 'Name is too short';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Location dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedLocation != null
                                    ? const Color(0xFFB45309)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedLocation,
                              isExpanded: true,
                              hint: Text('Select location / district',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13)),
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFFB45309)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                prefixIcon: Icon(Icons.location_on_outlined,
                                    color: Color(0xFFB45309), size: 20),
                                labelText: 'Location / District',
                                labelStyle: TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                  color: Color(0xFF0D1147),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                              items: _ugandaLocations
                                  .map((l) => DropdownMenuItem(
                                      value: l, child: Text(l)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedLocation = v),
                              validator: (v) =>
                                  v == null ? 'Please select a location' : null,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Institution Type ──
                          _Lbl(icon: Icons.category_outlined,
                              label: 'Institution Type'),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              UniversityType.government,
                              UniversityType.private,
                            ].map((type) {
                              final isSelected = _selectedType == type;
                              final label = type == UniversityType.government
                                  ? 'Government'
                                  : 'Private';
                              final emoji = type == UniversityType.government
                                  ? '🏛️'
                                  : '🏫';
                              final desc = type == UniversityType.government
                                  ? 'Publicly funded\ninstitution'
                                  : 'Privately owned\ninstitution';

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedType = type),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: EdgeInsets.only(
                                        right:
                                            type == UniversityType.government
                                                ? 8
                                                : 0),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFEF3E2)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFB45309)
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(emoji,
                                                style: const TextStyle(
                                                    fontSize: 24)),
                                            const Spacer(),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? const Color(0xFFB45309)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFFB45309)
                                                      : Colors.grey.shade300,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(Icons.check,
                                                      color: Colors.white,
                                                      size: 12)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isSelected
                                                  ? const Color(0xFFB45309)
                                                  : const Color(0xFF0D1147),
                                            )),
                                        const SizedBox(height: 2),
                                        Text(desc,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              height: 1.4,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // ── Login Credentials ──
                          _Lbl(icon: Icons.email_outlined,
                              label: 'Login Credentials'),
                          const SizedBox(height: 6),
                          Text(
                            'These credentials will be sent to the university email after creation.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.5),
                          ),
                          const SizedBox(height: 12),

                          _Field(
                            controller: _emailController,
                            label: 'Institution Email',
                            hint: 'e.g. admin@university.ac.ug',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Email is required';
                              if (!v.contains('@'))
                                return 'Enter a valid email address';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D1147)),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 8)
                                return 'Password must be at least 8 characters';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Initial Password',
                              hintText: 'Min. 8 characters',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFFB45309), size: 20),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade300, fontSize: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFB45309), width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Colors.red),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Password hint
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade600, size: 15),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'The university will be prompted to reset this password on first login.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Email preview card
                          _buildEmailPreviewCard(),

                          const SizedBox(height: 32),

                          // Submit button
                          GestureDetector(
                            onTap: _isLoading ? null : _submit,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF92400E),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB45309)
                                        .withOpacity(0.35),
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
                                            strokeWidth: 2.5),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.send_outlined,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Create University & Send Email',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFFD97706)],
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
                  const Row(
                    children: [
                      Text('🏛️', style: TextStyle(fontSize: 34)),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Onboard University',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Admin Portal · HostelBooking',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12),
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

  Widget _buildEmailPreviewCard() {
    final name = _nameController.text.trim().isEmpty
        ? 'University Name'
        : _nameController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? 'university@email.com'
        : _emailController.text.trim();

    return AnimatedBuilder(
      animation: Listenable.merge([_nameController, _emailController]),
      builder: (_, __) {
        final displayName = _nameController.text.trim().isEmpty
            ? 'University Name'
            : _nameController.text.trim();
        final displayEmail = _emailController.text.trim().isEmpty
            ? 'university@email.com'
            : _emailController.text.trim();

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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13)),
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.email,
                          color: Color(0xFFB45309), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email Preview',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF0D1147))),
                          Text('Will be sent to: $displayEmail',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dear $displayName,',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D1147))),
                    const SizedBox(height: 8),
                    Text(
                      'Your institution has been registered on the HostelBooking platform. Below are your login credentials:',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFD97706).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _EmailRow(label: 'Email', value: displayEmail),
                          const SizedBox(height: 6),
                          _EmailRow(
                              label: 'Password',
                              value: _passwordController.text.isEmpty
                                  ? '••••••••'
                                  : '•' *
                                      _passwordController.text.length),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '⚠️ Please reset your password on first login.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3E2),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFFB45309), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'After creation, login credentials will be sent automatically to the institution email. The university must reset their password on first login.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
}

class _Lbl extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Lbl({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFFB45309)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309))),
        ],
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D1147)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFB45309), size: 20),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFB45309), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      );
}

class _EmailRow extends StatelessWidget {
  final String label;
  final String value;

  const _EmailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

// ─── Success Dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final SystemUniversity university;
  final VoidCallback onDone;

  const _SuccessDialog({required this.university, required this.onDone});

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
              const Text('University Created! 🎉',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1147))),
              const SizedBox(height: 8),
              Text(
                '"${university.universityName}" has been registered. Login credentials have been sent to:',
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
                  color: const Color(0xFFFEF3E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 15, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(university.email,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ The university must reset their password on first login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onDone,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF92400E), Color(0xFFD97706)]),
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