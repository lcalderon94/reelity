import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/user.dart';
import '../models/season.dart';
import '../models/episode.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  /// true cuando se muestra como tab del BottomNav (sin botón de atrás)
  final bool isEmbedded;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.isEmbedded = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Season> _userSeasons = [];
  List<Season> _savedSeasons = [];
  List<Episode> _likedEpisodes = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  late TabController _tabController;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = _authService.currentUser?.uid == widget.userId;
    // Perfil propio: 3 tabs (Mis Series, Guardadas, Me gusta)
    // Perfil ajeno: 1 tab (Sus Series)
    _tabController = TabController(
      length: _isOwnProfile ? 3 : 1,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = _authService.currentUser?.uid;

      // Carga base: siempre
      final baseResults = await Future.wait([
        _firestoreService.getUser(widget.userId),
        _firestoreService.getSeriesByCreator(widget.userId),
        _firestoreService.getFollowersCount(widget.userId),
        _firestoreService.getSubscribedCount(widget.userId),
      ]);

      _user = baseResults[0] as User?;
      _userSeasons = baseResults[1] as List<Season>;
      _followersCount = baseResults[2] as int;
      _followingCount = baseResults[3] as int;

      if (currentUserId != null) {
        if (currentUserId != widget.userId) {
          // Perfil ajeno: comprobar suscripción
          _isFollowing = await _firestoreService.isSubscribed(
            userId: currentUserId,
            creatorId: widget.userId,
          );
        } else {
          // Perfil propio: cargar guardados y likes
          final ownResults = await Future.wait([
            _firestoreService.getSavedSeasons(widget.userId),
            _firestoreService.getLikedEpisodes(widget.userId),
          ]);
          _savedSeasons = ownResults[0] as List<Season>;
          _likedEpisodes = ownResults[1] as List<Episode>;
        }
      }
    } catch (e) {
      print('❌ Error cargando perfil: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_user == null || _isFollowLoading) return;
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _firestoreService.unsubscribeFromCreator(
          userId: currentUserId,
          creatorId: widget.userId,
        );
      } else {
        await _firestoreService.subscribeToCreator(
          userId: currentUserId,
          creatorId: widget.userId,
        );
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing
                ? 'Suscrito a ${_user!.name}'
                : 'Suscripción cancelada'),
            backgroundColor:
                _isFollowing ? AppColors.success : AppColors.info,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error cambiando suscripción: $e');
    }
    if (mounted) setState(() => _isFollowLoading = false);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isOwnProfile =
        _authService.currentUser?.uid == widget.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: widget.isEmbedded
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
              actions: [
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Cerrar sesión',
                    onPressed: _logout,
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
                            color: AppColors.primary, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          _user!.avatarUrl ??
                              'https://i.pravatar.cc/300',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.cardBackground,
                            child: const Icon(Icons.person,
                                size: 50,
                                color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(_user!.name, style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      _user!.username ??
                          '@${_user!.name.toLowerCase().replaceAll(' ', '')}',
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 12),

                    if (_user!.bio != null && _user!.bio!.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _user!.bio!,
                          style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(
                            'Temporadas', _userSeasons.length),
                        _buildStat('Seguidores', _followersCount),
                        _buildStat('Siguiendo', _followingCount),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (!isOwnProfile)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isFollowLoading
                                  ? null
                                  : _toggleFollow,
                              icon: _isFollowLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Icon(_isFollowing
                                      ? Icons.check
                                      : Icons.add),
                              label: Text(_isFollowing
                                  ? 'Suscrito'
                                  : 'Suscribirse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? AppColors.cardBackground
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Mensajes próximamente'),
                                  backgroundColor: AppColors.info,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white30),
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child:
                                const Icon(Icons.message_outlined),
                          ),
                        ],
                      ),
                    if (isOwnProfile)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/edit-profile');
                          _loadData();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Sticky tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicatorColor: AppColors.primary,
                  tabs: _isOwnProfile
                      ? const [
                          Tab(text: 'Mis Series'),
                          Tab(text: 'Guardadas'),
                          Tab(text: 'Me gusta'),
                        ]
                      : const [
                          Tab(text: 'Series'),
                        ],
                ),
              ),
            ),

            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: _isOwnProfile
                    ? [
                        _buildSeriesTab(_userSeasons),
                        _buildSavedSeriesTab(),
                        _buildLikedEpisodesTab(),
                      ]
                    : [
                        _buildSeriesTab(_userSeasons),
                      ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildSeriesTab(List<Season> seasons) {
    if (seasons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Sin series aún',
                style: AppTextStyles.body1
                    .copyWith(color: AppColors.textTertiary)),
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
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        final img = season.imageUrl ?? season.thumbnailUrl;
        return GestureDetector(
          onTap: () => context.push('/series/${season.id}'),
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
                      top: Radius.circular(12)),
                  child: img != null
                      ? Image.network(
                          img,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season.name,
                          style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          'Día ${season.currentDay}/${season.totalDays}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary),
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

  Widget _buildSavedSeriesTab() {
    if (_savedSeasons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Sin series guardadas',
                style: AppTextStyles.body1
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text('Guarda series desde su pantalla de detalle',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return _buildSeriesTab(_savedSeasons);
  }

  Widget _buildLikedEpisodesTab() {
    if (_likedEpisodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Sin episodios con like',
                style: AppTextStyles.body1
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text('Da ❤️ a episodios para verlos aquí',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedEpisodes.length,
      itemBuilder: (context, index) {
        final episode = _likedEpisodes[index];
        return GestureDetector(
          onTap: () => context.push('/video-player/${episode.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10)),
                  child: Image.network(
                    episode.thumbnailUrl,
                    width: 110,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 70,
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.play_circle_outline,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ep. ${episode.episodeNumber} · ${episode.title}',
                          style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('${episode.likes}',
                                style: AppTextStyles.caption),
                            const SizedBox(width: 12),
                            Text(episode.formattedDate,
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.play_arrow,
                      color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          _infoRow(Icons.email, 'Email', _user!.email),
          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            _infoRow(Icons.info_outline, 'Bio', _user!.bio!),
          _infoRow(
            Icons.calendar_today,
            'Miembro desde',
            '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
          ),
          if (_user!.creatorTags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Tags de contenido', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.creatorTags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.5)),
                        ),
                        child: Text(tag,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 160,
      color: Colors.grey.shade900,
      child: const Icon(Icons.movie, size: 48, color: Colors.grey),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
