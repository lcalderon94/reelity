import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/mock_data_service.dart';
import '../models/user.dart';
import '../models/season.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final MockDataService _mockService = MockDataService();

  User? _user;
  Map<String, int> _stats = {};
  List<Season> _userSeasons = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _user = _mockService.getUserById(widget.userId);

    if (_user != null) {
      _stats = _mockService.getUserStats(widget.userId);
      _userSeasons = _mockService.getSeasonsByUser(widget.userId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Suscrito a ${_user!.name}' : 'Cancelada suscripción'),
        backgroundColor: _isFollowing ? AppColors.success : AppColors.info,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final isOwnProfile = _mockService.currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Simple header con back button
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),

            // Contenido del perfil
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.border,
                        width: 3,
                      ),
                      color: AppColors.cardBackground,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        _user!.avatarUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.textTertiary,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nombre
                  Text(
                    _user!.name,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Username
                  Text(
                    _user!.username ?? '@user',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  if (_user!.bio != null && _user!.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _user!.bio!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botón Suscribirse / Editar Perfil
                  if (!isOwnProfile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: _isFollowing
                              ? AppColors.border
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          _isFollowing ? 'Suscrito' : 'Suscribirse',
                          style: AppTextStyles.button.copyWith(fontSize: 15),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Editar perfil próximamente'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Editar perfil',
                          style: AppTextStyles.button.copyWith(fontSize: 15),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('1.2K', 'Suscriptores'),
                        Container(width: 1, height: 40, color: AppColors.divider),
                        _buildStatColumn('${_userSeasons.length}', 'Series'),
                        Container(width: 1, height: 40, color: AppColors.divider),
                        _buildStatColumn('${_stats['episodes'] ?? 0}', 'Episodios'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tabs
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider, width: 2),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textTertiary,
                      labelStyle: AppTextStyles.button.copyWith(fontSize: 15),
                      unselectedLabelStyle: AppTextStyles.button.copyWith(fontSize: 15),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'SERIES'),
                        Tab(text: 'ACERCA DE'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSeriesTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesTab() {
    if (_userSeasons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Este usuario no tiene series todavía',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _userSeasons.length,
      itemBuilder: (context, index) {
        final season = _userSeasons[index];
        final episodes = _mockService.getEpisodesBySeason(season.id);

        return GestureDetector(
          onTap: () {
            context.push('/series/${season.id}');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        season.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          season.isActive ? 'EN CURSO' : 'COMPLETADA',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(top: 66),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.background,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.name,
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${season.totalDays ~/ 7} Temporadas',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Text(' · ', style: TextStyle(color: AppColors.textTertiary)),
                          Text(
                            '${episodes.length} Episodios',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Text(' · ', style: TextStyle(color: AppColors.textTertiary)),
                          Text(
                            '2024',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        season.description ?? 'Sin descripción',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection(
            'Sobre mí',
            _user!.bio ?? 'Este usuario no ha añadido una biografía todavía.',
          ),
          const SizedBox(height: 30),
          _buildAboutSection(
            'Información',
            null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Se unió', _formatDate(_user!.createdAt)),
                const SizedBox(height: 8),
                _buildInfoRow('Última actividad', 'Hace 2 horas'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Logros',
            style: AppTextStyles.h4.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAchievement('🏆 ${_stats['views']}+ Vistas'),
              _buildAchievement('🎬 Creador desde ${_user!.createdAt.year}'),
              _buildAchievement('🔥 ${_stats['episodes']}+ Episodios'),
              _buildAchievement('⭐ Top Creator'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, String? text, {Widget? child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (text != null)
          Text(
            text,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.body2.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildAchievement(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            const Color(0xFFFF006E).withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}