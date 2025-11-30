import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/mock_data_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login con validación real
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Intentar login con MockDataService
    final user = await MockDataService().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Login exitoso
      context.go('/home');
    } else {
      // Credenciales incorrectas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email o contraseña incorrectos'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                  '¡Bienvenido de vuelta!',
                  style: AppTextStyles.h2,
                ),

                const SizedBox(height: 8),

                Text(
                  'Inicia sesión para continuar',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

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
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 12),

                // Link de "Olvidé mi contraseña"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperación de contraseña
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función próximamente disponible'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Botón de Login
                CustomButton(
                  text: 'Iniciar sesión',
                  onPressed: _handleLogin,
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

                // Link para crear cuenta
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/register');
                        },
                        child: Text(
                          'Crear cuenta',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}