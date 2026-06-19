import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('first_time') ?? true;

      if (isFirstTime) {
        await prefs.setBool('first_time', false);
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        return;
      }

      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // Permitir entrada como invitado directamente o ir a Login
        // Para cumplir con Apple, el usuario debe poder entrar sin login forzado inmediatamente.
        // Iremos al Home, y el Home manejará el estado de invitado.
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8A00),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.radar, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'CurbRadar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
