import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'utils/colors.dart';
import 'utils/text_styles.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/series_detail_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/user_profile_screen.dart';
import 'widgets/main_scaffold.dart';
import 'services/mock_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar MockDataService con datos fake
  await MockDataService().init();

  // Configurar la barra de estado (status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ReelityApp());
}

class ReelityApp extends StatelessWidget {
  const ReelityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'REELITY',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  // Configuración del tema dark estilo Netflix
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Colores principales
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.cardBackground,
        background: AppColors.background,
        error: AppColors.error,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        titleTextStyle: AppTextStyles.h4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTextStyles.inputHint,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
    );
  }
}

// Configuración de rutas con GoRouter
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainScaffold(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/series/:seasonId',
      name: 'series-detail',
      builder: (context, state) {
        final seasonId = state.pathParameters['seasonId']!;
        return SeriesDetailScreen(seasonId: seasonId);
      },
    ),
    GoRoute(
      path: '/video-player/:episodeId',
      name: 'video-player',
      builder: (context, state) {
        final episodeId = state.pathParameters['episodeId']!;
        return VideoPlayerScreen(episodeId: episodeId);
      },
    ),
    // NUEVA RUTA: Perfil de usuario
    GoRoute(
      path: '/user-profile/:userId',
      name: 'user-profile',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserProfileScreen(userId: userId);
      },
    ),
  ],
);