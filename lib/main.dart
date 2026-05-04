import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:student_hostel_management/screens/login_screen.dart';
import 'package:student_hostel_management/screens/role_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HostelApp());
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey:
            'pk_test_c2hhcnAtZ2F6ZWxsZS0yMy5jbGVyay5hY2NvdW50cy5kZXYk', // 🔥 your real key here
      ),
      child: MaterialApp(
        title: 'UniStay – Student Hostel Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1F71)),
        ),
        home: const _AppStartupGate(),
      ),
    );
  }
}

class _AppStartupGate extends StatefulWidget {
  const _AppStartupGate();

  @override
  State<_AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<_AppStartupGate> {
  bool _isChecking = true;
  UserRole? _resolvedRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isChecking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
    }
  }

  Future<void> _checkSession() async {
    final auth = ClerkAuth.of(context, listen: false);
    final claims = auth.user?.publicMetadata;
    final role = claims?['role']?.toString();

    if (!mounted) return;

    setState(() {
      _resolvedRole = switch (role) {
        'student' => UserRole.student,
        'landlord' => UserRole.landlord,
        'university' => UserRole.university,
        _ => null,
      };
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: false);
    final hasSession = auth.user != null || auth.session != null;

    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FE),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A1F71)),
        ),
      );
    }

    if (hasSession && _resolvedRole != null) {
      return LoginScreen(role: _resolvedRole!);
    }

    return const RoleSelectScreen();
  }
}
