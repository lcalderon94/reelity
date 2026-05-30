import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/episode.dart';
import '../models/comment.dart';
import '../models/user.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String episodeId;

  const VideoPlayerScreen({
    super.key,
    required this.episodeId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Lista de episodios de la temporada
  List<Episode> _allEpisodes = [];
  int _currentIndex = 0;
  late PageController _pageController;

  // Estado del episodio actual
  User? _videoOwner;
  List<Comment> _comments = [];
  bool _isLiked = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _showComments = false;
  bool _isLoading = true;
  StreamSubscription? _commentsSubscription;

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _showPlayIcon = false;

  // Banner "Siguiente episodio" estilo Netflix
  bool _showNextBanner = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _isTransitioning = false;

  Episode? get _episode =>
      _allEpisodes.isNotEmpty ? _allEpisodes[_currentIndex] : null;

  bool get _hasNext => _currentIndex < _allEpisodes.length - 1;
  bool get _hasPrev => _currentIndex > 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _commentsSubscription?.cancel();
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── CARGA DE DATOS ───────────────────────────────────────

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar el episodio inicial
      final episode =
          await _firestoreService.getEpisodeById(widget.episodeId);
      if (episode == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Cargar todos los episodios de la misma temporada
      final allEps = await _firestoreService
          .getEpisodesBySeason(episode.seasonId);

      // 3. Encontrar el índice del episodio actual
      final index = allEps.indexWhere((e) => e.id == widget.episodeId);

      _allEpisodes = allEps;
      _currentIndex = index >= 0 ? index : 0;

      // 4. Inicializar el PageController en el índice correcto
      _pageController = PageController(initialPage: _currentIndex);

      // 5. Cargar datos sociales y video
      await _loadEpisodeData(_currentIndex);
    } catch (e) {
      debugPrint('❌ Error en carga inicial: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadEpisodeData(int index) async {
    if (index >= _allEpisodes.length) return;
    final ep = _allEpisodes[index];
    final currentUserId = _authService.currentUser?.uid;

    try {
      // Cargar en paralelo: dueño + estado social
      final results = await Future.wait([
        _firestoreService.getUser(ep.userId),
        _firestoreService.incrementViews(ep.id),
        if (currentUserId != null)
          _firestoreService.isEpisodeLiked(
            userId: currentUserId,
            episodeId: ep.id,
          )
        else
          Future.value(false),
        if (currentUserId != null && currentUserId != ep.userId)
          _firestoreService.isSubscribed(
            userId: currentUserId,
            creatorId: ep.userId,
          )
        else
          Future.value(false),
      ]);

      if (!mounted) return;
      setState(() {
        _videoOwner = results[0] as User?;
        _isLiked = results[2] as bool;
        _isFollowing = results[3] as bool;
      });

      // Stream de comentarios
      _commentsSubscription?.cancel();
      _commentsSubscription = _firestoreService
          .getCommentsByEpisode(ep.id)
          .listen((comments) {
        if (mounted) setState(() => _comments = comments);
      });

      // Inicializar video
      await _initVideo(ep.videoUrl);
    } catch (e) {
      debugPrint('❌ Error cargando episodio: $e');
    }
  }

  // ─── VIDEO ────────────────────────────────────────────────

  Future<void> _initVideo(String videoUrl) async {
    // Limpiar el controller anterior
    _videoController?.removeListener(_onVideoProgress);
    await _videoController?.dispose();
    _videoController = null;
    if (mounted) setState(() => _isVideoReady = false);

    if (!videoUrl.startsWith('http')) return;

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      controller.addListener(_onVideoProgress);
      await controller.setLooping(false);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _isVideoReady = true;
      });
    } catch (e) {
      debugPrint('❌ Error iniciando video: $e');
    }
  }

  void _onVideoProgress() {
    if (!mounted || _videoController == null) return;
    final value = _videoController!.value;
    if (!value.isInitialized || value.duration.inSeconds == 0) return;

    final remaining = value.duration - value.position;

    // Mostrar banner cuando quedan ≤3 segundos y hay siguiente episodio
    if (remaining.inSeconds <= 3 &&
        !_showNextBanner &&
        _hasNext &&
        !_isTransitioning) {
      if (mounted) {
        setState(() => _showNextBanner = true);
        _startCountdown();
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _showPlayIcon = true;
      } else {
        _videoController!.play();
        _showPlayIcon = false;
      }
    });
    if (_showPlayIcon) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showPlayIcon = false);
      });
    }
  }

  // ─── NAVEGACIÓN ENTRE EPISODIOS ───────────────────────────

  void _onPageChanged(int newIndex) {
    _cancelCountdown();
    setState(() {
      _currentIndex = newIndex;
      _showNextBanner = false;
      _isVideoReady = false;
      _comments = [];
    });
    _loadEpisodeData(newIndex);
  }

  void _goToNext() {
    if (!_hasNext) return;
    _cancelCountdown();
    _isTransitioning = true;
    _pageController
        .nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        )
        .then((_) => _isTransitioning = false);
  }

  void _goToPrev() {
    if (!_hasPrev) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ─── COUNTDOWN NETFLIX ────────────────────────────────────

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _goToNext();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    if (mounted) setState(() => _showNextBanner = false);
  }

  // ─── ACCIONES SOCIALES ────────────────────────────────────

  Future<void> _toggleLike() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || _episode == null) return;

    final wasLiked = _isLiked;
    setState(() => _isLiked = !_isLiked);
    try {
      if (wasLiked) {
        await _firestoreService.unlikeEpisode(
          userId: currentUserId,
          episodeId: _episode!.id,
        );
      } else {
        await _firestoreService.likeEpisode(
          userId: currentUserId,
          episodeId: _episode!.id,
          seasonId: _episode!.seasonId,
        );
      }
    } catch (e) {
      setState(() => _isLiked = wasLiked);
    }
  }

  Future<void> _toggleFollow() async {
    if (_episode == null || _isFollowLoading) return;
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _firestoreService.unsubscribeFromCreator(
          userId: currentUserId,
          creatorId: _episode!.userId,
        );
      } else {
        await _firestoreService.subscribeToCreator(
          userId: currentUserId,
          creatorId: _episode!.userId,
        );
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint('❌ Error suscripción: $e');
    }
    if (mounted) setState(() => _isFollowLoading = false);
  }

  final TextEditingController _commentController =
      TextEditingController();

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _episode == null) return;
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    _commentController.clear();
    try {
      final userData =
          await _firestoreService.getUser(currentUser.uid);
      await _firestoreService.addComment(
        episodeId: _episode!.id,
        userId: currentUser.uid,
        username: userData?.username ?? '@user',
        userAvatarUrl: userData?.avatarUrl ?? '',
        text: text,
      );
    } catch (e) {
      debugPrint('❌ Error comentario: $e');
    }
  }

  // ─── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _allEpisodes.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView de videos ─────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _allEpisodes.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, index) {
              if (index == _currentIndex) {
                return _buildCurrentVideo();
              }
              // Páginas adyacentes: fondo negro con thumbnail
              final ep = _allEpisodes[index];
              return Container(
                color: Colors.black,
                child: ep.thumbnailUrl.isNotEmpty
                    ? Image.network(ep.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox())
                    : const SizedBox(),
              );
            },
          ),

          // ── Gradientes ─────────────────────────────────────
          _buildGradient(Alignment.topCenter, Alignment.bottomCenter,
              top: 0, height: 140),
          _buildGradient(Alignment.bottomCenter, Alignment.topCenter,
              bottom: 0, height: 240),

          // ── Header ─────────────────────────────────────────
          Positioned(
            top: 50, left: 12, right: 12,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _episode?.title ?? '',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ep. ${(_currentIndex + 1)} de ${_allEpisodes.length}',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                // Flechas prev/next
                Row(
                  children: [
                    if (_hasPrev)
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white70, size: 24),
                        onPressed: _goToPrev,
                      ),
                    if (_hasNext)
                      IconButton(
                        icon: const Icon(Icons.skip_next,
                            color: Colors.white70, size: 24),
                        onPressed: _goToNext,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Info del creador ───────────────────────────────
          if (_videoOwner != null)
            Positioned(
              bottom: 110, left: 16, right: 90,
              child: _buildCreatorInfo(),
            ),

          // ── Botones laterales ──────────────────────────────
          Positioned(
            bottom: 100, right: 12,
            child: _buildSideButtons(),
          ),

          // ── Banner "Siguiente episodio" ────────────────────
          if (_showNextBanner && _hasNext)
            Positioned(
              bottom: 100, left: 16, right: 16,
              child: _buildNextEpisodeBanner(),
            ),

          // ── Panel de comentarios ───────────────────────────
          if (_showComments)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildCommentsSheet(),
            ),
        ],
      ),
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────

  Widget _buildCurrentVideo() {
    if (_episode == null) return const SizedBox();

    final videoUrl = _episode!.videoUrl;
    final isRealVideo = videoUrl.startsWith('http');

    if (!isRealVideo) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$videoUrl/maxresdefault.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.black),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off,
                    color: Colors.white54, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Actualiza la URL del video\nen Firestore para reproducir',
                  style: AppTextStyles.body2
                      .copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!_isVideoReady || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          AnimatedOpacity(
            opacity: _showPlayIcon ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradient(
    AlignmentGeometry begin,
    AlignmentGeometry end, {
    double? top,
    double? bottom,
    required double height,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  context.push('/user-profile/${_videoOwner!.id}'),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    _videoOwner!.avatarUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    context.push('/user-profile/${_videoOwner!.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _videoOwner!.username ?? _videoOwner!.name,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8)
                        ],
                      ),
                    ),
                    Text(
                      _episode?.formattedDate ?? '',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            if (_authService.currentUser?.uid != _episode?.userId)
              GestureDetector(
                onTap: _isFollowLoading ? null : _toggleFollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isFollowing
                        ? Colors.white24
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isFollowLoading
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isFollowing ? 'Siguiendo' : 'Seguir',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_episode?.description?.isNotEmpty == true)
          Text(
            _episode!.description!,
            style: AppTextStyles.body2.copyWith(
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 8)
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildSideButtons() {
    return Column(
      children: [
        _sideBtn(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          color: _isLiked ? AppColors.primary : Colors.white,
          label: '${(_episode?.likes ?? 0) + (_isLiked ? 1 : 0)}',
          onTap: _toggleLike,
        ),
        const SizedBox(height: 20),
        _sideBtn(
          icon: Icons.chat_bubble_outline,
          label: '${_comments.length}',
          onTap: () =>
              setState(() => _showComments = !_showComments),
        ),
        const SizedBox(height: 20),
        _sideBtn(
          icon: Icons.share,
          label: 'Compartir',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compartir próximamente'),
              backgroundColor: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sideBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4)
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner siguiente episodio estilo Netflix ──────────────

  Widget _buildNextEpisodeBanner() {
    final nextEp = _allEpisodes[_currentIndex + 1];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.skip_next,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Siguiente episodio',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _cancelCountdown,
                child: Text(
                  'Cancelar',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ep.${nextEp.episodeNumber} · ${nextEp.title}',
                  style: AppTextStyles.body1
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _goToNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_countdown s',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.play_arrow,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de countdown animada
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _countdown / 3,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel de comentarios ──────────────────────────────────

  Widget _buildCommentsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_comments.length} comentarios',
                  style: AppTextStyles.body1
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _showComments = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _comments.isEmpty
                ? Center(
                    child: Text('Sé el primero en comentar',
                        style: AppTextStyles.body2),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) =>
                        _buildCommentItem(_comments[i]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTextStyles.inputText,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    decoration: InputDecoration(
                      hintText: 'Añade un comentario...',
                      hintStyle: AppTextStyles.inputHint,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              comment.userAvatarUrl,
              width: 36, height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36, height: 36,
                color: AppColors.cardBackground,
                child: const Icon(Icons.person,
                    color: AppColors.textTertiary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: AppTextStyles.body2
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.formattedTime,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: AppTextStyles.body2),
                const SizedBox(height: 6),
                Text(
                  '❤️ ${comment.likes}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
