import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
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
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

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

    try {
      _user = await _firestoreService.getUser(widget.userId);

      if (_user != null) {
        _stats = {
          'temporadas': 0,
          'seguidores': 0,
          'siguiendo': 0,
        };
        _userSeasons = [];
      }
    } catch (e) {
      print('❌ Error cargando perfil: $e');
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

    final isOwnProfile = _authService.currentUser?.uid == widget.userId;

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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuración próximamente'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                  ),
              ],
            ),

            // Profile header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          _user!.avatarUrl ?? 'https://i.pravatar.cc/300',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.cardBackground,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      _user!.name,
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 4),

                    // Username
                    Text(
                      _user!.username ?? '@${_user!.name.toLowerCase().replaceAll(' ', '')}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bio
                    if (_user!.bio != null && _user!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _user!.bio!,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Temporadas', _stats['temporadas'] ?? 0),
                        _buildStatItem('Seguidores', _stats['seguidores'] ?? 0),
                        _buildStatItem('Siguiendo', _stats['siguiendo'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (!isOwnProfile)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleFollow,
                              icon: Icon(_isFollowing ? Icons.check : Icons.add),
                              label: Text(_isFollowing ? 'Suscrito' : 'Suscribirse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? AppColors.cardBackground
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mensajes próximamente'),
                                  backgroundColor: AppColors.info,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Icon(Icons.message_outlined),
                          ),
                        ],
                      ),
                    if (isOwnProfile)
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Editar perfil próximamente'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Contenido'),
                    Tab(text: 'Perfil'),
                  ],
                ),
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Contenido tab
                  _buildContentTab(),
                  // Perfil tab
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    if (_userSeasons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin temporadas aún',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _userSeasons.length,
      itemBuilder: (context, index) {
        final season = _userSeasons[index];
        return GestureDetector(
          onTap: () {
            context.push('/series/${season.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBackground,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    season.imageUrl ?? season.thumbnailUrl ?? 'https://via.placeholder.com/400x300',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.movie, size: 60, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season.name,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          'Día ${season.currentDay}/${season.totalDays}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, 'Email', _user!.email),
          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            _buildInfoRow(Icons.info, 'Bio', _user!.bio!),
          const SizedBox(height: 24),
          Text(
            'Estadísticas',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, 'Miembro desde',
              '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}