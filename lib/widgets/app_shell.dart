import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../web_config/responsive_config.dart';
import 'desktop_header.dart';

/// Shell partagé entre tous les onglets principaux.
/// Sur desktop → DesktopHeader en haut, pas de BottomNav.
/// Sur mobile  → BottomNavigationBar en bas, pas de header.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  // Correspondance index ↔ route racine de chaque branche
  static const _branches = ['/', '/catalog', '/cart', '/account'];

  void _onTap(BuildContext context, int index) {
    // Si déjà sur l'onglet, on remonte en haut de la pile de la branche
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDesktop) {
      // ── Desktop : header fixe, pas de BottomNav ──
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: Column(
          children: [
            const DesktopHeader(),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // ── Mobile : BottomNav partagée ──
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryViolet,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Compte',
          ),
        ],
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}