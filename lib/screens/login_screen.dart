import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/home');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo
                const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFFE50914),
                  size: 80,
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'REELITY',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu vida como un reality show',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

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
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
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

                // Botón login
                CustomButton(
                  text: _isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Olvidé mi contraseña
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // TODO: Implementar recuperación de contraseña
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función disponible próximamente'),
                        backgroundColor: Color(0xFFE50914),
                      ),
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),

                const SizedBox(height: 40),

                // Crear cuenta
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Crear una cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Datos de prueba
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white60,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Datos de prueba:',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTestCredentials('luis@reelity.com', '123456'),
                      _buildTestCredentials('sara@example.com', '123456'),
                      _buildTestCredentials('alex@example.com', '123456'),
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

  Widget _buildTestCredentials(String email, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$email / $password',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              _emailController.text = email;
              _passwordController.text = password;
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size(0, 0),
            ),
            child: const Text(
              'Usar',
              style: TextStyle(
                color: Color(0xFFE50914),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}