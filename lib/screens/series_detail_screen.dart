import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/season.dart';
import '../models/group.dart';
import '../models/episode.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seasonId;

  const SeriesDetailScreen({
    super.key,
    required this.seasonId,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  Season? _season;
  Group? _group;
  List<Episode> _episodes = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _isSaved = false;
  bool _isSaveLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _season = await _firestoreService.getSeasonById(widget.seasonId);

      if (_season != null) {
        final results = await Future.wait([
          _firestoreService.getGroupById(_season!.groupId),
          _firestoreService.getEpisodesBySeason(widget.seasonId),
        ]);
        _group = results[0] as Group?;
        _episodes = results[1] as List<Episode>;

        // Comprobar suscripción y si la serie está guardada
        final currentUserId = _authService.currentUser?.uid;
        if (currentUserId != null && _group != null) {
          final checks = await Future.wait([
            _firestoreService.isSubscribed(
              userId: currentUserId,
              creatorId: _group!.ownerId,
            ),
            _firestoreService.isSeasonSaved(
              userId: currentUserId,
              seasonId: widget.seasonId,
            ),
          ]);
          _isFollowing = checks[0];
          _isSaved = checks[1];
        }
      }
    } catch (e) {
      print('❌ Error cargando datos: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_group == null || _isFollowLoading) return;
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _firestoreService.unsubscribeFromCreator(
          userId: currentUserId,
          creatorId: _group!.ownerId,
        );
      } else {
        await _firestoreService.subscribeToCreator(
          userId: currentUserId,
          creatorId: _group!.ownerId,
        );
      }
      setState(() => _isFollowing = !_isFollowing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing ? '¡Suscrito a ${_group!.name}!' : 'Suscripción cancelada',
            ),
            backgroundColor: _isFollowing ? AppColors.success : AppColors.info,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al cambiar suscripción: $e');
    }
    if (mounted) setState(() => _isFollowLoading = false);
  }

  Future<void> _toggleSave() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || _isSaveLoading) return;

    setState(() => _isSaveLoading = true);
    try {
      if (_isSaved) {
        await _firestoreService.unsaveSeason(
          userId: currentUserId,
          seasonId: widget.seasonId,
        );
      } else {
        await _firestoreService.saveSeason(
          userId: currentUserId,
          seasonId: widget.seasonId,
        );
      }
      setState(() => _isSaved = !_isSaved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? 'Serie guardada en tu perfil' : 'Serie eliminada de guardados',
            ),
            backgroundColor: _isSaved ? AppColors.success : AppColors.info,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaveLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _season == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image con play overlay
          SliverAppBar(
            expandedHeight: 420,
            pinned: false,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen
                  Image.network(
                    _season!.imageUrl ?? 'https://via.placeholder.com/800x600',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.cardBackground,
                        child: const Icon(
                          Icons.movie,
                          size: 100,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_episodes.isNotEmpty) {
                          context.push('/video-player/${_episodes.first.id}');
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 40,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _season!.name,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 12),

                  // Meta info
                  Row(
                    children: [
                      Text(
                        '95% Match',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '2024',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_season!.totalDays} días',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_episodes.isNotEmpty) {
                              context.push('/video-player/${_episodes.first.id}');
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Reproducir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaveLoading ? null : _toggleSave,
                          icon: _isSaveLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                          label: Text(_isSaved ? 'Guardada' : 'Guardar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _isSaved ? AppColors.primary : Colors.white,
                            side: BorderSide(
                              color: _isSaved
                                  ? AppColors.primary
                                  : Colors.white54,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Creator info
                  if (_group != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.textTertiary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_group != null && _group!.ownerId.isNotEmpty) {
                                context.push('/user-profile/${_group!.ownerId}');
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: AppColors.cardBackground,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  _group!.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: AppColors.textTertiary,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _group!.name,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_episodes.length} episodios',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isFollowLoading ? null : _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? AppColors.cardBackground
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isFollowLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isFollowing ? 'Suscrito ✓' : 'Suscribirse'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    _season!.description ?? 'Sin descripción',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Episodes section
                  Text(
                    'Episodios',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),

                  // Episodes list
                  ...(_episodes.map((episode) => _buildEpisodeCard(episode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    return GestureDetector(
      onTap: () {
        context.push('/video-player/${episode.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  width: 130,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.cardBackground,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      episode.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.play_circle_outline,
                          size: 40,
                          color: AppColors.textTertiary,
                        );
                      },
                    ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      episode.formattedDuration,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Play overlay
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 20,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Episode info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${episode.episodeNumber}. ${episode.title}',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        episode.formattedDate,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    episode.description ?? '',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.4,
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
  }
}