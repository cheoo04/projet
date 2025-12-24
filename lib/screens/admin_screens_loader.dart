/// Loader pour les écrans admin avec deferred loading (code splitting)
/// Permet de réduire la taille du bundle initial en chargeant
/// les écrans admin uniquement quand nécessaire.
library;

import 'package:flutter/material.dart';

// Import différé des écrans admin lourds
import 'modern_admin_screens.dart' deferred as admin_screens;
import 'modern_admin_navigation.dart' deferred as admin_nav;
import 'modern_admin_products_screen.dart' deferred as admin_products;
import 'modern_stock_management_screen.dart' deferred as admin_stock;
import 'modern_order_management_screen.dart' deferred as admin_orders;
import 'modern_category_management_screen.dart' deferred as admin_categories;
import 'promotion_management_screen.dart' deferred as admin_promotions;
import 'user_management_screen.dart' deferred as admin_users;
import 'supplier_management_screen.dart' deferred as admin_suppliers;
import 'image_management_screen.dart' deferred as admin_images;
import 'review_management_screen.dart' deferred as admin_reviews;
import 'advanced_analytics_screen.dart' deferred as admin_analytics;

/// Gestionnaire de chargement des modules admin
class AdminModuleLoader {
  static bool _isLoaded = false;
  static bool _isLoading = false;
  
  /// Vérifie si le module admin est chargé
  static bool get isLoaded => _isLoaded;
  
  /// Précharge tous les modules admin en arrière-plan
  static Future<void> preloadAll() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    
    try {
      await Future.wait([
        admin_screens.loadLibrary(),
        admin_nav.loadLibrary(),
        admin_products.loadLibrary(),
        admin_stock.loadLibrary(),
        admin_orders.loadLibrary(),
        admin_categories.loadLibrary(),
        admin_promotions.loadLibrary(),
        admin_users.loadLibrary(),
        admin_suppliers.loadLibrary(),
        admin_images.loadLibrary(),
        admin_reviews.loadLibrary(),
        admin_analytics.loadLibrary(),
      ]);
      _isLoaded = true;
      debugPrint('✅ Modules admin chargés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur chargement modules admin: $e');
      _isLoading = false;
      rethrow;
    }
  }
  
  /// Charge uniquement le module principal (dashboard + navigation)
  static Future<void> loadCore() async {
    if (_isLoaded) return;
    
    await Future.wait([
      admin_screens.loadLibrary(),
      admin_nav.loadLibrary(),
    ]);
  }
}

/// Widget wrapper qui charge le module admin avant d'afficher l'écran
class DeferredAdminScreen extends StatefulWidget {
  final Widget Function() screenBuilder;
  final Future<void> Function() loader;
  
  const DeferredAdminScreen({
    super.key,
    required this.screenBuilder,
    required this.loader,
  });
  
  @override
  State<DeferredAdminScreen> createState() => _DeferredAdminScreenState();
}

class _DeferredAdminScreenState extends State<DeferredAdminScreen> {
  late Future<void> _loadFuture;
  
  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loader();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error);
        }
        
        return widget.screenBuilder();
      },
    );
  }
  
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement du module admin...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen(Object? error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadFuture = widget.loader();
                });
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Widgets de chargement différé pour chaque écran admin
// ============================================================================

/// Dashboard admin (écran principal)
class DeferredAdminDashboard extends StatelessWidget {
  const DeferredAdminDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_screens.loadLibrary(),
      screenBuilder: () => admin_screens.ModernAdminDashboardScreen(),
    );
  }
}

/// Login admin
class DeferredAdminLogin extends StatelessWidget {
  const DeferredAdminLogin({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_screens.loadLibrary(),
      screenBuilder: () => admin_screens.ModernAdminLoginScreen(),
    );
  }
}

/// Navigation admin
class DeferredAdminNavigation extends StatelessWidget {
  const DeferredAdminNavigation({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_nav.loadLibrary(),
      screenBuilder: () => admin_nav.ModernAdminNavigation(),
    );
  }
}

/// Gestion des produits
class DeferredAdminProducts extends StatelessWidget {
  const DeferredAdminProducts({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_products.loadLibrary(),
      screenBuilder: () => admin_products.ModernAdminProductsScreen(),
    );
  }
}

/// Gestion du stock
class DeferredAdminStock extends StatelessWidget {
  const DeferredAdminStock({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_stock.loadLibrary(),
      screenBuilder: () => admin_stock.ModernStockManagementScreen(),
    );
  }
}

/// Gestion des commandes
class DeferredAdminOrders extends StatelessWidget {
  const DeferredAdminOrders({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_orders.loadLibrary(),
      screenBuilder: () => admin_orders.ModernOrderManagementScreen(),
    );
  }
}

/// Gestion des catégories
class DeferredAdminCategories extends StatelessWidget {
  const DeferredAdminCategories({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_categories.loadLibrary(),
      screenBuilder: () => admin_categories.ModernCategoryManagementScreen(),
    );
  }
}

/// Gestion des promotions
class DeferredAdminPromotions extends StatelessWidget {
  const DeferredAdminPromotions({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_promotions.loadLibrary(),
      screenBuilder: () => admin_promotions.PromotionManagementScreen(),
    );
  }
}

/// Gestion des utilisateurs
class DeferredAdminUsers extends StatelessWidget {
  const DeferredAdminUsers({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_users.loadLibrary(),
      screenBuilder: () => admin_users.UserManagementScreen(),
    );
  }
}

/// Gestion des fournisseurs
class DeferredAdminSuppliers extends StatelessWidget {
  const DeferredAdminSuppliers({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_suppliers.loadLibrary(),
      screenBuilder: () => admin_suppliers.SupplierManagementScreen(),
    );
  }
}

/// Gestion des images
class DeferredAdminImages extends StatelessWidget {
  const DeferredAdminImages({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_images.loadLibrary(),
      screenBuilder: () => admin_images.ImageManagementScreen(),
    );
  }
}

/// Gestion des avis
class DeferredAdminReviews extends StatelessWidget {
  const DeferredAdminReviews({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_reviews.loadLibrary(),
      screenBuilder: () => admin_reviews.ReviewManagementScreen(),
    );
  }
}

/// Analytics avancées
class DeferredAdminAnalytics extends StatelessWidget {
  const DeferredAdminAnalytics({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DeferredAdminScreen(
      loader: () => admin_analytics.loadLibrary(),
      screenBuilder: () => admin_analytics.AdvancedAnalyticsScreen(),
    );
  }
}
