import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  User? _user;
  File? _newAvatar;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final user = await _firestoreService.getUser(uid);
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _nameCtrl.text = user.name;
        _usernameCtrl.text = user.username?.replaceFirst('@', '') ?? '';
        _bioCtrl.text = user.bio ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xfile != null && mounted) {
      setState(() => _newAvatar = File(xfile.path));
    }
  }

  Future<void> _save() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('El nombre no puede estar vacío');
      return;
    }

    setState(() => _isSaving = true);

    String? avatarUrl;
    if (_newAvatar != null) {
      avatarUrl = await _storageService.uploadAvatar(
        file: _newAvatar!,
        userId: uid,
      );
      if (avatarUrl == null) {
        _showError('Error al subir la foto');
        if (mounted) setState(() => _isSaving = false);
        return;
      }
    }

    final rawUsername = _usernameCtrl.text.trim();
    final username = rawUsername.isEmpty
        ? null
        : (rawUsername.startsWith('@') ? rawUsername : '@$rawUsername');

    try {
      await _firestoreService.updateUserProfile(
        uid,
        name: name,
        username: username,
        bio: _bioCtrl.text.trim().isEmpty ? '' : _bioCtrl.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Editar perfil', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text(
                      'Guardar',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: _newAvatar != null
                          ? Image.file(_newAvatar!, fit: BoxFit.cover)
                          : Image.network(
                              _user?.avatarUrl ?? 'https://i.pravatar.cc/300',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.cardBackground,
                                child: const Icon(Icons.person,
                                    size: 50, color: AppColors.textTertiary),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cambiar foto',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 32),

            // Nombre
            _field(
              label: 'Nombre',
              controller: _nameCtrl,
              hint: 'Tu nombre',
            ),
            const SizedBox(height: 20),

            // Username
            _field(
              label: 'Username',
              controller: _usernameCtrl,
              hint: 'tuusername',
              prefix: '@',
            ),
            const SizedBox(height: 20),

            // Bio
            _field(
              label: 'Bio',
              controller: _bioCtrl,
              hint: 'Cuéntanos algo sobre ti...',
              maxLines: 4,
              maxLength: 150,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        'Guardar cambios',
                        style: AppTextStyles.body1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
    int? maxLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          style: AppTextStyles.body1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            prefixText: prefix,
            prefixStyle: AppTextStyles.body1.copyWith(color: AppColors.primary),
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
        ),
      ],
    );
  }
}
