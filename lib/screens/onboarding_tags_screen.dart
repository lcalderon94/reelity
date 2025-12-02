import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';

class OnboardingTagsScreen extends StatefulWidget {
  const OnboardingTagsScreen({super.key});

  @override
  State<OnboardingTagsScreen> createState() => _OnboardingTagsScreenState();
}

class _OnboardingTagsScreenState extends State<OnboardingTagsScreen> {
  final Map<String, String> _tagMapping = {
    'Fitness & Gym': 'fitness',
    'Coches & Motor': 'coches',
    'Viajes & Aventura': 'viajes',
    'Gaming & Esports': 'gaming',
    'Cocina & Food': 'cocina',
    'Arte & Diseño': 'arte',
    'Música & Conciertos': 'musica',
    'Tech & Programación': 'programacion',
    'Moda & Lifestyle': 'moda',
    'Deportes': 'deportes',
  };

  final Set<String> _selectedDisplayTags = {};

  Future<void> _continue() async {
    if (_selectedDisplayTags.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos 3 intereses'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 🔥 Convertir display tags a tags de Firebase
    final firebaseTags = _selectedDisplayTags
        .map((displayTag) => _tagMapping[displayTag]!)
        .toList();

    print('🏷️ Tags seleccionados: $firebaseTags');

    // 🔥 Navegar pasando los tags
    if (mounted) {
      context.go('/onboarding-creators', extra: firebaseTags);
    }
  }

  void _toggleTag(String displayTag) {
    setState(() {
      if (_selectedDisplayTags.contains(displayTag)) {
        _selectedDisplayTags.remove(displayTag);
      } else {
        _selectedDisplayTags.add(displayTag);
      }
    });
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      '¿Qué te interesa?',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo
                    Text(
                      'Selecciona al menos 3 temas para personalizar tu feed',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Grid de tags
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _tagMapping.keys.map((displayTag) {
                        final isSelected = _selectedDisplayTags.contains(displayTag);

                        return GestureDetector(
                          onTap: () => _toggleTag(displayTag),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                Text(
                                  displayTag,
                                  style: AppTextStyles.body1.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // Contador
                    if (_selectedDisplayTags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${_selectedDisplayTags.length}',
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDisplayTags.length >= 3
                                        ? '¡Perfecto!'
                                        : 'Selecciona ${3 - _selectedDisplayTags.length} más',
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDisplayTags.length >= 3
                                        ? 'Ya puedes continuar'
                                        : 'Mínimo 3 intereses',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _selectedDisplayTags.length >= 3
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _selectedDisplayTags.length >= 3
                                  ? AppColors.success
                                  : AppColors.textTertiary,
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
                text: 'Continuar',
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}