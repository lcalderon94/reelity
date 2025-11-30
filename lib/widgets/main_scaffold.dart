import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../services/mock_data_service.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final MockDataService _mockService = MockDataService();

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        context.go('/home');
        break;
      case 1: // Búsqueda
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Búsqueda próximamente'),
            backgroundColor: AppColors.info,
          ),
        );
        break;
      case 2: // Crear
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crear próximamente'),
            backgroundColor: AppColors.info,
          ),
        );
        break;
      case 3: // Notificaciones
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificaciones próximamente'),
            backgroundColor: AppColors.info,
          ),
        );
        break;
      case 4: // Perfil
        final currentUser = _mockService.currentUser;
        if (currentUser != null) {
          context.push('/user-profile/${currentUser.id}');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
