import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:student_hostel_management/screens/register_screen.dart';
import 'screens/register_screen.dart';

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
        publishableKey: 'pk_test_c2hhcnAtZ2F6ZWxsZS0yMy5jbGVyay5hY2NvdW50cy5kZXYk', // 🔥 your real key here
      ),
      child: MaterialApp(
        title: 'UniStay – Student Hostel Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A1F71),
          ),
        ),
        home: const RegisterScreen(),
      ),
    );
  }
}