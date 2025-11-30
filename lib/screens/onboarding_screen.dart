import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.groups_rounded,
      title: 'Tu círculo, tu reality',
      description:
      'Crea grupos pequeños con tus amigos y vive vuestro propio reality show privado. Sin desconocidos, sin postureo.',
      color: AppColors.primary,
    ),
    OnboardingPage(
      icon: Icons.calendar_today_rounded,
      title: 'Retos diarios en video',
      description:
      'Cada día un nuevo reto. Graba clips cortos de 15-30 segundos y descubre qué están haciendo tus amigos.',
      color: Color(0xFFFF6B35),
    ),
    OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'Temporadas memorables',
      description:
      'Organiza tu vida en temporadas: "Gym Enero", "Viaje a Barcelona", "Erasmus". Crea recuerdos que duran.',
      color: Color(0xFF46D369),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // IR A REGISTRO, NO A HOME
      context.go('/register');
    }
  }

  void _skip() {
    // IR A REGISTRO, NO A HOME
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón Skip
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Saltar',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView con los slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicadores de página
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => _buildPageIndicator(index),
                ),
              ),
            ),

            // Botón siguiente/empezar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: _currentPage == _pages.length - 1
                    ? 'Empezar a usar REELITY'
                    : 'Siguiente',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono grande con gradiente
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [page.color, page.color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(80),
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 60),

          // Título
          Text(
            page.title,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Descripción
          Text(
            page.description,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primary
            : AppColors.textTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Modelo para las páginas del onboarding
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}