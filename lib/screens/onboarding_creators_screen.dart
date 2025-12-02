import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/user.dart' as models;

class OnboardingCreatorsScreen extends StatefulWidget {
  final List<String> selectedTags;

  const OnboardingCreatorsScreen({
    super.key,
    required this.selectedTags,
  });

  @override
  State<OnboardingCreatorsScreen> createState() => _OnboardingCreatorsScreenState();
}

class _OnboardingCreatorsScreenState extends State<OnboardingCreatorsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  final Set<String> _followedCreators = {};
  List<models.User> _recommendedCreators = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendedCreators();
  }

  Future<void> _loadRecommendedCreators() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 QUERY REAL A FIRESTORE
      final creators = await _firestoreService.getCreatorsByTags(widget.selectedTags);

      setState(() {
        _recommendedCreators = creators;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando creadores: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando creadores: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleFollow(String creatorId) {
    setState(() {
      if (_followedCreators.contains(creatorId)) {
        _followedCreators.remove(creatorId);
      } else {
        _followedCreators.add(creatorId);
      }
    });
  }

  Future<void> _continue() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 🔥 GUARDAR INTERESES EN FIRESTORE
      await _firestoreService.updateUserInterests(
        currentUser.uid,
        widget.selectedTags,
      );

      // 🔥 CREAR SUSCRIPCIONES EN FIRESTORE
      for (final creatorId in _followedCreators) {
        await _firestoreService.subscribeToCreator(
          userId: currentUser.uid,
          creatorId: creatorId,
        );
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      print('❌ Error guardando suscripciones: $e');

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _skip() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    // Guardar tags aunque no siga a nadie
    try {
      await _firestoreService.updateUserInterests(
        currentUser.uid,
        widget.selectedTags,
      );
    } catch (e) {
      print('❌ Error guardando intereses: $e');
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _skip,
            child: Text(
              'Saltar',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _recommendedCreators.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_search,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No encontramos creadores',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prueba con otros intereses',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      'Creadores para ti',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo
                    Text(
                      'Basado en tus intereses: ${widget.selectedTags.join(", ")}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Lista de creadores
                    ..._recommendedCreators.map((creator) {
                      final isFollowing = _followedCreators.contains(creator.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFollowing
                                ? AppColors.primary
                                : AppColors.border,
                            width: isFollowing ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.network(
                                  creator.avatarUrl ?? 'https://i.pravatar.cc/300',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.background,
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.textTertiary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    creator.name,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    creator.username ?? '@${creator.name.toLowerCase()}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: creator.creatorTags
                                        .take(3)
                                        .map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            // Botón seguir
                            ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _toggleFollow(creator.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? AppColors.cardBackground
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: isFollowing
                                      ? const BorderSide(color: AppColors.primary)
                                      : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowing ? Icons.check : Icons.add,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFollowing ? 'Siguiendo' : 'Seguir',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // Info
                    if (_followedCreators.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Estás siguiendo a ${_followedCreators.length} ${_followedCreators.length == 1 ? 'creador' : 'creadores'}',
                                style: AppTextStyles.body2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: _isSaving
                    ? 'Guardando...'
                    : _followedCreators.isEmpty
                    ? 'Saltar por ahora'
                    : 'Empezar a usar REELITY',
                onPressed: _isSaving ? null : _continue,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}