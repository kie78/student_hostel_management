import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

enum UserRole { student, landlord, university, admin }

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with TickerProviderStateMixin {
  UserRole? _selectedRole;
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late List<AnimationController> _cardControllers;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _pulse;

  final List<_RoleCard> _roles = [
    _RoleCard(
      role: UserRole.student,
      label: 'Student',
      description: 'Browse hostels, book rooms\nand make payments',
      emoji: '🎓',
      color: const Color(0xFF1A1F71),
      lightColor: const Color(0xFFEEF0F8),
      accentColor: const Color(0xFF4F5FD4),
      icon: Icons.school_rounded,
    ),
    _RoleCard(
      role: UserRole.landlord,
      label: 'Landlord',
      description: 'List your hostel, manage\nrooms and bookings',
      emoji: '🏢',
      color: const Color(0xFF006B4F),
      lightColor: const Color(0xFFE8F5EF),
      accentColor: const Color(0xFF00A876),
      icon: Icons.apartment_rounded,
    ),
    _RoleCard(
      role: UserRole.university,
      label: 'University',
      description: 'Manage students, landlords\nand hostel listings',
      emoji: '🏛️',
      color: const Color(0xFF7B2FF7),
      lightColor: const Color(0xFFF3EEFF),
      accentColor: const Color(0xFF9B5FF7),
      icon: Icons.account_balance_rounded,
    ),
    _RoleCard(
      role: UserRole.admin,
      label: 'Admin',
      description: 'Full system access and\nuser management',
      emoji: '⚙️',
      color: const Color(0xFFB45309),
      lightColor: const Color(0xFFFEF3E2),
      accentColor: const Color(0xFFD97706),
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardControllers = List.generate(
      _roles.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _entryController.forward();
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 100), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() => _selectedRole = role);
    HapticFeedback.lightImpact();
  }

  void _proceed() {
    if (_selectedRole == null) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            LoginScreen(role: _selectedRole!),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo mark
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1F71),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Uni',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1F71),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Stay',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Welcome Back 👋',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D1147),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Who are you signing in as today?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Role Cards ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: _roles.length,
                    itemBuilder: (_, i) {
                      final card = _roles[i];
                      final isSelected = _selectedRole == card.role;

                      return AnimatedBuilder(
                        animation: _cardControllers[i],
                        builder: (_, child) => FadeTransition(
                          opacity: _cardControllers[i],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _cardControllers[i],
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        ),
                        child: _RoleCardWidget(
                          card: card,
                          isSelected: isSelected,
                          pulseAnim: _pulse,
                          onTap: () => _selectRole(card.role),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Continue Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  children: [
                    // Selected role indicator
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedRole != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _roles
                                          .firstWhere((r) =>
                                              r.role == _selectedRole)
                                          .color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continuing as ${_roles.firstWhere((r) => r.role == _selectedRole).label}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty'), height: 0),
                    ),

                    // Button
                    GestureDetector(
                      onTap: _selectedRole != null ? _proceed : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          gradient: _selectedRole != null
                              ? LinearGradient(
                                  colors: [
                                    _roles
                                        .firstWhere(
                                            (r) => r.role == _selectedRole)
                                        .color,
                                    _roles
                                        .firstWhere(
                                            (r) => r.role == _selectedRole)
                                        .accentColor,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: _selectedRole == null
                              ? Colors.grey.shade200
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedRole != null
                              ? [
                                  BoxShadow(
                                    color: _roles
                                        .firstWhere(
                                            (r) => r.role == _selectedRole)
                                        .color
                                        .withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedRole != null
                                    ? 'Continue'
                                    : 'Select a role to continue',
                                style: TextStyle(
                                  color: _selectedRole != null
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedRole != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCardWidget extends StatelessWidget {
  final _RoleCard card;
  final bool isSelected;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _RoleCardWidget({
    required this.card,
    required this.isSelected,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: isSelected ? pulseAnim.value : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? card.color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? card.color : Colors.grey.shade100,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? card.color.withOpacity(0.30)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 24 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.20)
                        : card.lightColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      card.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                const Spacer(),

                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF0D1147),
                    letterSpacing: -0.3,
                  ),
                  child: Text(card.label),
                ),

                const SizedBox(height: 4),

                // Description
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isSelected
                        ? Colors.white.withOpacity(0.75)
                        : Colors.grey.shade500,
                    height: 1.5,
                  ),
                  child: Text(card.description),
                ),

                const SizedBox(height: 12),

                // Selected indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 3,
                  width: isSelected ? 32 : 16,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.7)
                        : card.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _RoleCard {
  final UserRole role;
  final String label;
  final String description;
  final String emoji;
  final Color color;
  final Color lightColor;
  final Color accentColor;
  final IconData icon;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.description,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.accentColor,
    required this.icon,
  });
}