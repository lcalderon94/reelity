import 'package:flutter/material.dart';
import '../widgets/season_card.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../models/season.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState - Usuario: ${_authService.currentUser?.uid}');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    // Si no hay usuario, redirigir al login
    if (user == null) {
      print('❌ No hay usuario en HomeScreen, redirigiendo a login');
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('✅ Usuario autenticado en HomeScreen: ${user.uid}');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
        ),
        actions: [
          // Botón de logout temporal para debug
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Season>>(
        stream: _firestoreService.getActiveSeasons(user.uid),
        builder: (context, snapshot) {
          print('📡 StreamBuilder state: ${snapshot.connectionState}');

          if (snapshot.hasError) {
            print('❌ Error en StreamBuilder: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ Esperando datos de Firestore...');
            return const Center(child: CircularProgressIndicator());
          }

          final seasons = snapshot.data ?? [];
          print('📊 Temporadas recibidas: ${seasons.length}');

          if (seasons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_outlined, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes temporadas activas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Únete a un grupo para empezar',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Temporadas activas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...seasons.map((season) {
                  print('🎬 Renderizando temporada: ${season.name}');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FutureBuilder<String>(
                      future: _firestoreService.getGroupName(season.groupId),
                      builder: (context, groupSnapshot) {
                        final groupName = groupSnapshot.data ?? 'Cargando...';

                        return SeasonCard(
                          seasonName: season.name,
                          groupName: groupName,
                          currentDay: season.currentDay,
                          totalDays: season.totalDays,
                          streakDays: season.streakDays,
                          thumbnailUrl: season.thumbnailUrl ?? '',
                          onTap: () {
                            print('🎯 Navegando a serie: ${season.id}');
                            Navigator.pushNamed(
                              context,
                              '/series/${season.id}',
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}