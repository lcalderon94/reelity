import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';
import '../models/group.dart';
import '../models/season.dart';

enum _CreateMode { episode, season }

class CreateEpisodeScreen extends StatefulWidget {
  const CreateEpisodeScreen({super.key});

  @override
  State<CreateEpisodeScreen> createState() => _CreateEpisodeScreenState();
}

class _CreateEpisodeScreenState extends State<CreateEpisodeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  double _uploadProgress = 0;
  List<Group> _groups = [];
  List<Season> _activeSeasons = [];
  Season? _selectedSeason;
  _CreateMode _mode = _CreateMode.episode;

  // Canal
  final _groupNameCtrl = TextEditingController();
  final _groupDescCtrl = TextEditingController();

  // Temporada
  final _seasonNameCtrl = TextEditingController();
  final _seasonDescCtrl = TextEditingController();
  int _totalDays = 30;

  // Episodio
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _videoFile;
  int _videoDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _groupDescCtrl.dispose();
    _seasonNameCtrl.dispose();
    _seasonDescCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final groups = await _firestoreService.getGroupsByOwner(userId);
      List<Season> seasons = [];
      if (groups.isNotEmpty) {
        final all = await _firestoreService.getSeriesByCreator(userId);
        seasons = all.where((s) => s.isActive).toList();
      }
      setState(() {
        _groups = groups;
        _activeSeasons = seasons;
        _selectedSeason = seasons.isNotEmpty ? seasons.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Acciones ──────────────────────────────────────────────

  Future<void> _submitGroup() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty) { _error('El nombre del canal es obligatorio'); return; }

    setState(() => _isSubmitting = true);
    final id = await _firestoreService.addGroup(
      ownerId: userId,
      name: name,
      description: _groupDescCtrl.text.trim(),
    );
    if (id != null) {
      _groupNameCtrl.clear();
      _groupDescCtrl.clear();
      await _loadData();
    } else {
      _error('Error al crear el canal');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _submitSeason() async {
    if (_groups.isEmpty) return;
    final name = _seasonNameCtrl.text.trim();
    if (name.isEmpty) { _error('El nombre de la temporada es obligatorio'); return; }

    setState(() => _isSubmitting = true);
    final id = await _firestoreService.addSeason(
      groupId: _groups.first.id,
      name: name,
      description: _seasonDescCtrl.text.trim(),
      totalDays: _totalDays,
    );
    if (id != null) {
      _seasonNameCtrl.clear();
      _seasonDescCtrl.clear();
      _totalDays = 30;
      await _loadData();
    } else {
      _error('Error al crear la temporada');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _recordVideo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: AppColors.primary),
                title: Text('Grabar con cámara', style: AppTextStyles.body1),
                subtitle: Text('Máximo 30 segundos',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading:
                    const Icon(Icons.video_library, color: AppColors.primary),
                title: Text('Elegir de la galería', style: AppTextStyles.body1),
                subtitle: Text('Máximo 30 segundos',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final xfile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (xfile == null) return;

      final file = File(xfile.path);
      final stat = await file.stat();
      setState(() {
        _videoFile = file;
        _videoDurationSeconds = stat.size ~/ 200000;
      });
    } catch (e) {
      _error('No se pudo acceder al video: $e');
    }
  }

  Future<void> _submitEpisode() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) { _error('Debes estar conectado'); return; }
    if (_selectedSeason == null) { _error('Selecciona una temporada'); return; }
    if (_videoFile == null) { _error('Graba un video primero'); return; }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { _error('El título es obligatorio'); return; }

    setState(() { _isSubmitting = true; _uploadProgress = 0; });

    // 1. Subir video a Firebase Storage
    final videoUrl = await _storageService.uploadEpisodeVideo(
      file: _videoFile!,
      userId: userId,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );

    if (videoUrl == null) {
      if (mounted) {
        _error('Error al subir el video. Verifica que Firebase Storage esté activado.');
        setState(() => _isSubmitting = false);
      }
      return;
    }

    // 2. Crear episodio en Firestore
    final id = await _firestoreService.addEpisode(
      seasonId: _selectedSeason!.id,
      userId: userId,
      title: title,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      videoUrl: videoUrl,
      thumbnailUrl: '',
      durationSeconds: _videoDurationSeconds.clamp(1, 30),
    );

    if (mounted) {
      if (id != null) {
        _titleCtrl.clear();
        _descCtrl.clear();
        setState(() { _videoFile = null; _videoDurationSeconds = 0; });
        _success('¡Episodio publicado!');
      } else {
        _error('Error al publicar el episodio');
      }
      setState(() { _isSubmitting = false; _uploadProgress = 0; });
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _success(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_groups.isEmpty) return _buildGroupSetup();
    if (_activeSeasons.isEmpty) return _buildSeasonSetup();
    return _buildCreateHub();
  }

  // ── Paso 1: Crear canal ───────────────────────────────────

  Widget _buildGroupSetup() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar('Crear'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _stepIcon(Icons.movie_creation),
            const SizedBox(height: 24),
            Text('Crea tu canal', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Configura tu canal para empezar a publicar temporadas y episodios',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _field('Nombre del canal *', _groupNameCtrl,
                hint: 'Ej: Mi Canal de Viajes', maxLength: 50),
            const SizedBox(height: 20),
            _field('Descripción', _groupDescCtrl,
                hint: 'De qué va tu canal...', maxLines: 3, maxLength: 150),
            const SizedBox(height: 40),
            _submitButton('Crear canal', _submitGroup),
          ],
        ),
      ),
    );
  }

  // ── Paso 2: Crear temporada ───────────────────────────────

  Widget _buildSeasonSetup() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar('Crear'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _stepIcon(Icons.video_library),
            const SizedBox(height: 24),
            Text('Nueva temporada', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Crea un reto o serie de contenido diario',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _field('Nombre de la temporada *', _seasonNameCtrl,
                hint: 'Ej: 30 días de fitness', maxLength: 60),
            const SizedBox(height: 20),
            _field('Descripción', _seasonDescCtrl,
                hint: 'De qué trata este reto...', maxLines: 3, maxLength: 200),
            const SizedBox(height: 20),
            _label('Duración (días)'),
            const SizedBox(height: 12),
            _buildDaySelector(),
            const SizedBox(height: 40),
            _submitButton('Crear temporada', _submitSeason),
          ],
        ),
      ),
    );
  }

  // ── Paso 3: Hub episodio / temporada ──────────────────────

  Widget _buildCreateHub() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Crear', style: AppTextStyles.h4),
        actions: [
          if (_mode == _CreateMode.episode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isSubmitting ? null : _submitEpisode,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : Text(
                        'Publicar',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _modeChip('Episodio', _CreateMode.episode),
                const SizedBox(width: 8),
                _modeChip('Nueva temporada', _CreateMode.season),
              ],
            ),
          ),
          Expanded(
            child: _mode == _CreateMode.episode
                ? _buildEpisodeForm()
                : _buildSeasonFormInline(),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, _CreateMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Temporada'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<Season>(
              value: _selectedSeason,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.cardBackground,
              items: _activeSeasons
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name, style: AppTextStyles.body1),
                      ))
                  .toList(),
              onChanged: (s) => setState(() => _selectedSeason = s),
            ),
          ),
          const SizedBox(height: 24),
          _field('Título *', _titleCtrl,
              hint: 'Ej: Day 5 - Lo mejor hasta ahora', maxLength: 80),
          const SizedBox(height: 20),
          _field('Descripción', _descCtrl,
              hint: 'Describe tu episodio...', maxLines: 3, maxLength: 200),
          const SizedBox(height: 20),
          _label('Video *'),
          const SizedBox(height: 8),
          _buildVideoSection(),
          const SizedBox(height: 40),
          if (_isSubmitting && _uploadProgress > 0) ...[
            Text(
              'Subiendo video... ${(_uploadProgress * 100).toInt()}%',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _submitButton('Publicar episodio', _submitEpisode),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_videoFile != null) {
      return GestureDetector(
        onTap: _isSubmitting ? null : _recordVideo,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video grabado',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Toca para volver a grabar',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isSubmitting ? null : _recordVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Grabar video',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Máximo 30 segundos',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonFormInline() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Nombre de la temporada *', _seasonNameCtrl,
              hint: 'Ej: 30 días de fitness', maxLength: 60),
          const SizedBox(height: 20),
          _field('Descripción', _seasonDescCtrl,
              hint: 'De qué trata este reto...', maxLines: 3, maxLength: 200),
          const SizedBox(height: 20),
          _label('Duración (días)'),
          const SizedBox(height: 12),
          _buildDaySelector(),
          const SizedBox(height: 40),
          _submitButton('Crear temporada', _submitSeason),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _buildDaySelector() {
    const options = [7, 14, 30, 60, 90];
    return Wrap(
      spacing: 8,
      children: options.map((days) {
        final selected = _totalDays == days;
        return GestureDetector(
          onTap: () => setState(() => _totalDays = days),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              '$days días',
              style: AppTextStyles.body2.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepIcon(IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }

  AppBar _appBar(String title) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(title, style: AppTextStyles.h4),
    );
  }

  Widget _submitButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                label,
                style: AppTextStyles.body1
                    .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    required String hint,
    int? maxLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        _buildTextField(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            maxLength: maxLength),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      style: AppTextStyles.body1,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inputHint,
        filled: true,
        fillColor: AppColors.cardBackground,
        counterStyle:
            AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
