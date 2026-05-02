import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_select_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _illustrationController;
  late AnimationController _contentController;
  late Animation<double> _illustrationFloat;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;

  int _currentPage = 0;

  final List<_OnboardSlide> _slides = [
    _OnboardSlide(
      title: 'Find Your\nPerfect Room',
      subtitle:
          'Browse verified student hostels near your university. Filter by price, distance, and room type — all in one place.',
      emoji: '🏠',
      bg1: const Color(0xFF1A1F71),
      bg2: const Color(0xFF0D1147),
      accent: const Color(0xFFFFD700),
      shapes: [
        _Shape(x: 0.7, y: 0.15, size: 120, color: Color(0x1AFFD700), isCircle: true),
        _Shape(x: -0.1, y: 0.35, size: 80, color: Color(0x1AFFFFFF), isCircle: false),
        _Shape(x: 0.6, y: 0.6, size: 60, color: Color(0x15FFD700), isCircle: false),
      ],
      features: ['Verified hostels', 'Near your campus', 'All room types'],
    ),
    _OnboardSlide(
      title: 'Book in\nMinutes',
      subtitle:
          'Reserve your room with a simple booking form. Pick your move-in date, duration, and room type without any hassle.',
      emoji: '📋',
      bg1: const Color(0xFF00856F),
      bg2: const Color(0xFF005A4B),
      accent: const Color(0xFF7FFFEA),
      shapes: [
        _Shape(x: 0.75, y: 0.1, size: 100, color: Color(0x1A7FFFEA), isCircle: false),
        _Shape(x: -0.05, y: 0.5, size: 90, color: Color(0x1AFFFFFF), isCircle: true),
        _Shape(x: 0.5, y: 0.65, size: 50, color: Color(0x157FFFEA), isCircle: true),
      ],
      features: ['Quick 3-step booking', 'Choose your dates', 'Instant confirmation'],
    ),
    _OnboardSlide(
      title: 'Pay Safely\nwith MoMo',
      subtitle:
          'Pay your deposit and rent securely using MTN or Airtel Mobile Money. Get notified instantly on every transaction.',
      emoji: '💳',
      bg1: const Color(0xFF7B2FF7),
      bg2: const Color(0xFF4A1098),
      accent: const Color(0xFFFFB3FF),
      shapes: [
        _Shape(x: 0.65, y: 0.08, size: 110, color: Color(0x1AFFB3FF), isCircle: true),
        _Shape(x: -0.08, y: 0.42, size: 75, color: Color(0x1AFFFFFF), isCircle: false),
        _Shape(x: 0.55, y: 0.62, size: 55, color: Color(0x15FFB3FF), isCircle: false),
      ],
      features: ['MTN & Airtel MoMo', 'Partial payments OK', 'Instant notifications'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _illustrationFloat = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentController, curve: Curves.easeOutCubic));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeIn);

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _contentController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
      _contentController.forward();
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RoleSelectScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [slide.bg1, slide.bg2],
            ),
          ),
          child: Stack(
            children: [
              // Background shapes
              ...slide.shapes.map((shape) => _AnimatedShape(shape: shape)),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Skip button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                        child: GestureDetector(
                          onTap: _skip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Illustration area
                    Expanded(
                      flex: 5,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemCount: _slides.length,
                        itemBuilder: (_, i) =>
                            _IllustrationPanel(slide: _slides[i],
                                floatAnim: _illustrationFloat),
                      ),
                    ),

                    // Content panel
                    Expanded(
                      flex: 4,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: _ContentPanel(
                            slide: slide,
                            currentPage: _currentPage,
                            totalPages: _slides.length,
                            onNext: _nextPage,
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

// ─── Illustration Panel ───────────────────────────────────────────────────────

class _IllustrationPanel extends StatelessWidget {
  final _OnboardSlide slide;
  final Animation<double> floatAnim;

  const _IllustrationPanel(
      {required this.slide, required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: floatAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, floatAnim.value),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main emoji illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.accent.withValues(alpha: 0.25),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  slide.emoji,
                  style: const TextStyle(fontSize: 72),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Feature pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: slide.features
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: slide.accent, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              f,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content Panel ─────────────────────────────────────────────────────────────

class _ContentPanel extends StatelessWidget {
  final _OnboardSlide slide;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;

  const _ContentPanel({
    required this.slide,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == totalPages - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            slide.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.6,
            ),
          ),

          const Spacer(),

          // Dots + Button row
          Row(
            children: [
              // Page dots
              Row(
                children: List.generate(
                  totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == currentPage
                          ? slide.accent
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Next / Get Started button
              GestureDetector(
                onTap: onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLast ? 24 : 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: slide.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          color: Color(0xFF0D1147),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0D1147),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated Background Shape ────────────────────────────────────────────────

class _AnimatedShape extends StatefulWidget {
  final _Shape shape;
  const _AnimatedShape({required this.shape});

  @override
  State<_AnimatedShape> createState() => _AnimatedShapeState();
}

class _AnimatedShapeState extends State<_AnimatedShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000 + widget.shape.hashCode % 2000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: widget.shape.x * size.width,
      top: widget.shape.y * size.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.scale(
          scale: 0.9 + 0.1 * _anim.value,
          child: Transform.rotate(
            angle: _anim.value * 0.3,
            child: Container(
              width: widget.shape.size,
              height: widget.shape.size,
              decoration: BoxDecoration(
                color: widget.shape.color,
                shape: widget.shape.isCircle
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius:
                    widget.shape.isCircle ? null : BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class _OnboardSlide {
  final String title;
  final String subtitle;
  final String emoji;
  final Color bg1;
  final Color bg2;
  final Color accent;
  final List<_Shape> shapes;
  final List<String> features;

  const _OnboardSlide({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.bg1,
    required this.bg2,
    required this.accent,
    required this.shapes,
    required this.features,
  });
}

class _Shape {
  final double x;
  final double y;
  final double size;
  final Color color;
  final bool isCircle;

  const _Shape({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}