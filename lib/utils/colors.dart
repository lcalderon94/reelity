import 'package:flutter/material.dart';

/// Colores de REELITY - Estilo Netflix dark
class AppColors {
  // Colores principales
  static const Color primary = Color(0xFFE50914); // Rojo REELITY/Netflix
  static const Color primaryDark = Color(0xFFB20710); // Rojo más oscuro para hover
  
  // Backgrounds
  static const Color background = Color(0xFF000000); // Negro puro
  static const Color backgroundLight = Color(0xFF141414); // Negro ligeramente más claro
  static const Color cardBackground = Color(0xFF1F1F1F); // Cards/contenedores
  
  // Grises
  static const Color textPrimary = Color(0xFFFFFFFF); // Blanco para textos principales
  static const Color textSecondary = Color(0xFFB3B3B3); // Gris claro para textos secundarios
  static const Color textTertiary = Color(0xFF808080); // Gris medio para hints
  
  // Borders y divisores
  static const Color border = Color(0xFF333333); // Bordes sutiles
  static const Color divider = Color(0xFF2A2A2A); // Divisores
  
  // Estados
  static const Color success = Color(0xFF46D369); // Verde para éxito
  static const Color error = Color(0xFFE50914); // Rojo para errores (mismo que primary)
  static const Color warning = Color(0xFFFFB800); // Amarillo para advertencias
  static const Color info = Color(0xFF0071EB); // Azul para info
  
  // Overlay y sombras
  static const Color overlay = Color(0x80000000); // Negro semi-transparente
  static const Color shimmer = Color(0xFF2A2A2A); // Para efectos de loading
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE50914), Color(0xFFB20710)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F1F1F), Color(0xFF141414)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Colores para badges y streak
  static const Color streakFire = Color(0xFFFF6B35); // Naranja fuego para streaks
  static const Color activeIndicator = Color(0xFF46D369); // Verde para indicador activo
  static const Color inactiveIndicator = Color(0xFF808080); // Gris para inactivo
}
