import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              Text(
                'REELITY',
                style: AppTextStyles.logo.copyWith(fontSize: 48),
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Tu vida convertida en',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'un reality show',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Descripción
              Text(
                'Crea temporadas con tus amigos, comparte retos diarios en video y vive vuestra propia serie privada.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Ilustración placeholder (por ahora un container con gradiente)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.video_library_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(),
              
              // Botones
              CustomButton(
                text: 'Empezar ahora',
                onPressed: () {
                  context.push('/onboarding');
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomButton(
                text: 'Ya tengo cuenta',
                onPressed: () {
                  context.push('/login');
                },
                isOutlined: true,
              ),
              
              const SizedBox(height: 24),
              
              // Footer text
              Text(
                'Al continuar, aceptas nuestros Términos y Política de Privacidad',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
