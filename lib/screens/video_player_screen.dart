import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/mock_data_service.dart';
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
  final MockDataService _mockService = MockDataService();

  Episode? _episode;
  User? _videoOwner; // NUEVO: Usuario dueño del video
  List<Comment> _comments = [];
  bool _isLiked = false;
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _episode = _mockService.getEpisodeById(widget.episodeId);

    if (_episode != null) {
      // NUEVO: Obtener el usuario dueño del video
      _videoOwner = _mockService.getUserById(_episode!.userId);
      _comments = _mockService.getCommentsByEpisode(widget.episodeId);
    }

    setState(() {});
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });

    await _mockService.toggleLikeEpisode(widget.episodeId);
    _loadData();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final comment = await _mockService.addComment(
      widget.episodeId,
      _commentController.text.trim(),
    );

    if (comment != null) {
      _commentController.clear();
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario añadido'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_episode == null || _videoOwner == null) {
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video (YouTube iframe)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: _episode!.videoUrl.isNotEmpty
                  ? _buildYouTubePlayer(_episode!.videoUrl)
                  : Image.network(
                _episode!.thumbnailUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // User info (bottom left) - CORREGIDO: Mostrar el usuario dueño del video
          Positioned(
            bottom: 120,
            left: 20,
            right: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Navegar a perfil del usuario
                        context.push('/user-profile/${_videoOwner!.id}');
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 2),
                          color: AppColors.cardBackground,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _videoOwner!.avatarUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navegar a perfil del usuario
                          context.push('/user-profile/${_videoOwner!.id}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _videoOwner!.username ?? '@user',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _episode!.formattedDate,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Siguiendo!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Seguir'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _episode!.description ?? '',
                  style: AppTextStyles.body2.copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Side buttons (right side)
          Positioned(
            bottom: 120,
            right: 20,
            child: Column(
              children: [
                // Like button
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? AppColors.primary : Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text(
                      '${_episode!.likes}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Comment button
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                    ),
                    Text(
                      '${_episode!.commentsCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Share button
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Compartir próximamente'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                    ),
                    Text(
                      'Compartir',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments sheet
          if (_showComments)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCommentsSheet(),
            ),
        ],
      ),
    );
  }

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_comments.length} comentarios',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showComments = false;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                return _buildCommentItem(_comments[index]);
              },
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTextStyles.inputText,
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
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18),
                    color: Colors.white,
                    onPressed: _addComment,
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: AppColors.background,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                comment.userAvatarUrl,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.formattedTime,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '❤️ ${comment.likes}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Responder',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubePlayer(String videoId) {
    // Mostrar thumbnail con botón para abrir en YouTube
    return GestureDetector(
      onTap: () async {
        // Abrir en la app de YouTube o navegador
        final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
        // Por ahora solo mostramos un mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abre YouTube y busca: $videoId'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail de YouTube
          Image.network(
            'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              );
            },
          ),
          // Botón de play
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(20),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 64,
            ),
          ),
          // Mensaje
          Positioned(
            bottom: 100,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Toca para ver en YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}