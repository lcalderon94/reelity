import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  // Simular verificación de sesión y navegar
  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // TODO: Aquí verificarías si hay sesión guardada
    // Por ahora siempre vamos a welcome
    final bool hasSession = false; // MOCK: cambiar cuando tengamos auth real
    
    if (hasSession) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (por ahora solo texto, luego pondremos imagen)
            Text(
              'REELITY',
              style: AppTextStyles.logo,
            ),
            const SizedBox(height: 8),
            Text(
              'Your life, your reality show',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
