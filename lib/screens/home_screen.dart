import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/season_card.dart';
import '../services/mock_data_service.dart';
import '../models/season.dart';
import '../models/group.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final MockDataService _mockService = MockDataService();

  // Listas para las temporadas
  List<Season> _activeSeasons = [];
  List<Season> _pastSeasons = [];

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  // Cargar temporadas desde MockDataService
  void _loadSeasons() {
    setState(() {
      _activeSeasons = _mockService.getActiveSeasons();
      _pastSeasons = _mockService.getPastSeasons();
    });
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Implementar navegación a otras secciones
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header con logo y acciones
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                'REELITY',
                style: AppTextStyles.logo.copyWith(fontSize: 28),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Búsqueda próximamente'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificaciones próximamente'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                ),
              ],
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Sección: Temporadas activas
                  _buildSectionHeader(
                    'Temporadas activas',
                    'Sigue el ritmo de tus grupos',
                  ),
                  const SizedBox(height: 16),
                  _buildSeasonCarousel(_activeSeasons),

                  const SizedBox(height: 40),

                  // Sección: Temporadas pasadas
                  _buildSectionHeader(
                    'Temporadas pasadas',
                    'Revive tus mejores momentos',
                  ),
                  const SizedBox(height: 16),
                  _buildSeasonCarousel(_pastSeasons),

                  const SizedBox(height: 40),

                  // Botón para crear nueva temporada
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Crea una nueva temporada',
                            style: AppTextStyles.h4,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Invita a tus amigos y empieza un nuevo reality',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Crear temporada próximamente'),
                                  backgroundColor: AppColors.info,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Empezar ahora',
                              style: AppTextStyles.button,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarTap,
          backgroundColor: AppColors.backgroundLight,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: 'Grupos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_rounded),
              label: 'Retos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCarousel(List<Season> seasons) {
    if (seasons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No hay temporadas aquí todavía',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        itemBuilder: (context, index) {
          final season = seasons[index];
          final group = _mockService.getGroupById(season.groupId);

          return SeasonCard(
            imageUrl: season.imageUrl,
            seasonName: season.name,
            groupName: group?.name ?? 'Grupo',
            currentDay: season.currentDay,
            totalDays: season.totalDays,
            hasUploadedToday: season.hasUploadedToday,
            streakDays: season.streakDays,
            onTap: () {
              context.push('/series/${season.id}');
            },
          );
        },
      ),
    );
  }
}