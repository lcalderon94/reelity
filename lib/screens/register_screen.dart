import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/mock_data_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Registro con validación de email duplicado
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Intentar crear cuenta con MockDataService
    final user = await MockDataService().register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Registro exitoso, ir directamente a HOME
      context.go('/home');
    } else {
      // Email ya existe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este email ya está registrado'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!value.contains('@')) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Título
                Text(
                  'Crea tu cuenta',
                  style: AppTextStyles.h2,
                ),

                const SizedBox(height: 8),

                Text(
                  'Únete a REELITY y comienza tu reality',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Campo Nombre
                CustomTextField(
                  label: 'Nombre',
                  hint: 'Tu nombre completo',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Email
                CustomTextField(
                  label: 'Email',
                  hint: 'tu@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Contraseña
                CustomTextField(
                  label: 'Contraseña',
                  hint: 'Mínimo 6 caracteres',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Confirmar Contraseña
                CustomTextField(
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 24),

                // Checkbox de términos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptedTerms = !_acceptedTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos de uso',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de privacidad',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón de Registro
                CustomButton(
                  text: 'Crear cuenta',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Divider con "O"
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón de Google (placeholder)
                CustomButton(
                  text: 'Continuar con Google',
                  onPressed: () {
                    // TODO: Implementar Google Sign In
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign In próximamente'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  isOutlined: true,
                ),

                const SizedBox(height: 40),

                // Link para ir a login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/login');
                        },
                        child: Text(
                          'Iniciar sesión',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}