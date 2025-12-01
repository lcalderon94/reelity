import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'No se pudo crear el usuario';
      }

      final userId = credential.user!.uid;

      // 2. Generar username automático
      final username = '@${name.toLowerCase().replaceAll(' ', '')}';

      // 3. Crear documento en Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'username': username,
        'bio': null,
        'avatarUrl': 'https://i.pravatar.cc/300?u=$userId',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Manejo de errores
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error: ${e.message ?? 'Desconocido'}';
    }
  }
}