import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'booking_screen.dart';

class BookingSuccessScreen extends StatefulWidget {
  final BookingData booking;
  const BookingSuccessScreen({super.key, required this.booking});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late AnimationController _pulseController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _pulse;

  final List<_ConfettiParticle> _particles = [];
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();

    // Generate confetti particles
    final rand = math.Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: rand.nextDouble(),
        delay: rand.nextDouble() * 2,
        color: [
          const Color(0xFF1A1F71),
          const Color(0xFFFFC107),
          const Color(0xFF00C48C),
          const Color(0xFFFF6B6B),
          const Color(0xFF4FC3F7),
          Colors.purple,
        ][rand.nextInt(6)],
        size: 6 + rand.nextDouble() * 8,
        rotation: rand.nextDouble() * math.pi * 2,
        speed: 0.3 + rand.nextDouble() * 0.7,
      ));
    }

    // Check animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    _checkOpacity = CurvedAnimation(parent: _checkController, curve: Curves.easeIn);

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Card slide-up
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);

    // Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Sequence
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _cardController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showDetails = true);

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return 'UGX ${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    return 'UGX ${price.toStringAsFixed(0)}';
  }

  String _paymentMethodLabel(String method) => switch (method) {
        'mtn_mobile_money' => 'MTN Mobile Money',
        'airtel_mobile_money' => 'Airtel Money',
        _ => 'Mobile Money',
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Success Icon ──
                  ScaleTransition(
                    scale: _checkScale,
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, child) => Transform.scale(
                          scale: _pulse.value,
                          child: child,
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C48C), Color(0xFF00A876)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C48C).withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Title ──
                  AnimatedOpacity(
                    opacity: _showDetails ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        const Text(
                          'Booking Confirmed! 🎉',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1F71),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your room has been successfully reserved.\nYou\'ll receive a confirmation shortly.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Booking ID Banner ──
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.booking.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking ID copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Booking ID: ${widget.booking.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, color: Colors.white54, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Booking Summary Card ──
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: _buildBookingCard(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Next Steps ──
                  AnimatedOpacity(
                    opacity: _showDetails ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: _buildNextSteps(),
                  ),

                  const SizedBox(height: 24),

                  // ── Action Buttons ──
                  AnimatedOpacity(
                    opacity: _showDetails ? 1 : 0,
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        // View Booking History
                        GestureDetector(
                          onTap: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1F71), Color(0xFF2D3561)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A1F71).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Go to Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Browse more
                        GestureDetector(
                          onTap: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1A1F71).withValues(alpha: 0.2)),
                            ),
                            child: const Center(
                              child: Text(
                                'Browse More Hostels',
                                style: TextStyle(
                                  color: Color(0xFF1A1F71),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Share
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sharing booking details...')),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_outlined, color: Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Share Booking Confirmation',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF0F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F71),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.hostelName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1F71)),
                      ),
                      Text(
                        widget.booking.roomTypeName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C48C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.booking.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Divider with dashes
          Row(
            children: List.generate(
              20,
              (i) => Expanded(
                child: Container(
                  height: 1,
                  color: i.isEven ? Colors.grey.shade200 : Colors.transparent,
                ),
              ),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: widget.booking.hostelLocation,
                ),
                _DetailRow(
                  icon: Icons.hotel,
                  label: 'Room Type',
                  value: widget.booking.roomTypeName,
                ),
                if (widget.booking.paymentMethod != null)
                  _DetailRow(
                    icon: Icons.payment,
                    label: 'Payment Method',
                    value: _paymentMethodLabel(widget.booking.paymentMethod!),
                  ),
                if (widget.booking.paymentType != null)
                  _DetailRow(
                    icon: Icons.receipt,
                    label: 'Payment Type',
                    value: _capitalize(widget.booking.paymentType!),
                  ),
              ],
            ),
          ),

          // Price footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount Paid',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _formatPrice(widget.booking.amountPaid ?? widget.booking.roomPrice),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1F71),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    final steps = [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Booking Confirmed',
        'desc': 'Your booking is confirmed and the landlord has been notified.',
        'color': const Color(0xFF4FC3F7),
      },
      {
        'icon': Icons.payments,
        'title': 'Payment Processed',
        'desc': 'Your payment via ${_paymentMethodLabel(widget.booking.paymentMethod ?? '')} has been processed successfully.',
        'color': const Color(0xFF00C48C),
      },
      {
        'icon': Icons.vpn_key,
        'title': 'Move In',
        'desc': 'Contact the hostel management on WhatsApp to arrange your move-in date.',
        'color': const Color(0xFFFFC107),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What Happens Next?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F71)),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (step['color'] as Color).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: (step['color'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Icon(step['icon'] as IconData, color: step['color'] as Color, size: 18),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(width: 2, height: 20, color: Colors.grey.shade200),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1F71)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc'] as String,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Detail Row Widget ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1A1F71).withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1F71)),
          ),
        ],
      ),
    );
  }
}

// ─── Confetti Particle ─────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double delay;
  final Color color;
  final double size;
  final double rotation;
  final double speed;

  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
    required this.rotation,
    required this.speed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final adjustedProgress = ((progress - p.delay * 0.3) * p.speed).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final x = p.x * size.width;
      final y = adjustedProgress * size.height * 1.2;
      final opacity = (1 - adjustedProgress * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * math.pi * 4 * p.speed);

      if (particles.indexOf(p) % 3 == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else if (particles.indexOf(p) % 3 == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Triangle
        final path = Path();
        path.moveTo(0, -p.size / 2);
        path.lineTo(p.size / 2, p.size / 2);
        path.lineTo(-p.size / 2, p.size / 2);
        path.close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}