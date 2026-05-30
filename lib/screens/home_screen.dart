import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/season_card.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../models/season.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Redirigir si no hay sesión activa
    if (_authService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Image.asset('assets/images/logo.png', height: 36,
            errorBuilder: (_, __, ___) => Text('REELITY',
                style: AppTextStyles.logo.copyWith(fontSize: 22))),
        elevation: 0,
      ),
      body: StreamBuilder<List<Season>>(
        stream: _firestoreService.getActiveSeasons(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo cargar el feed',
                    style: AppTextStyles.body1,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary));
          }

          final seasons = snapshot.data ?? [];

          if (seasons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_outlined,
                      color: AppColors.textTertiary, size: 72),
                  const SizedBox(height: 20),
                  Text('Tu feed está vacío', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Explora y suscríbete a creadores para ver su contenido aquí',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: AppColors.primary,
            backgroundColor: AppColors.cardBackground,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('Tu feed', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ...seasons.map((season) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FutureBuilder<String>(
                      future: _firestoreService
                          .getGroupName(season.groupId),
                      builder: (context, groupSnapshot) {
                        return SeasonCard(
                          seasonName: season.name,
                          groupName:
                              groupSnapshot.data ?? '',
                          currentDay: season.currentDay,
                          totalDays: season.totalDays,
                          streakDays: season.streakDays,
                          thumbnailUrl: season.thumbnailUrl ?? '',
                          imageUrl: season.imageUrl,
                          onTap: () =>
                              context.push('/series/${season.id}'),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
