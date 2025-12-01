import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

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
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos y condiciones';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Ir al onboarding después de registrarse
        context.go('/onboarding');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Únete a REELITY y crea tu reality show',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),

                const SizedBox(height: 40),

                // Nombre
                CustomTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Contraseña
                CustomTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: true,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirmar contraseña
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  obscureText: true,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Checkbox términos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                          if (_acceptTerms) {
                            _errorMessage = null;
                          }
                        });
                      },
                      activeColor: const Color(0xFFE50914),
                      checkColor: Colors.white,
                      side: BorderSide(color: Colors.white30),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                              if (_acceptTerms) {
                                _errorMessage = null;
                              }
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Acepto los ',
                                ),
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: TextStyle(
                                    color: Color(0xFFE50914),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de Privacidad',
                                  style: TextStyle(
                                    color: Color(0xFFE50914),
                                    decoration: TextDecoration.underline,
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

                const SizedBox(height: 24),

                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFE50914)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFE50914),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Botón registrar
                CustomButton(
                  text: _isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Ya tienes cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: Color(0xFFE50914),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}