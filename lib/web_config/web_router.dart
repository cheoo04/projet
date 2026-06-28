import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../screens/onboarding_screen.dart';
import '../screens/modern_home_screen.dart';
import '../screens/modern_catalog_screen.dart';
import '../screens/modern_product_detail_screen.dart';
import '../screens/modern_cart_screen.dart';
import '../screens/comparison_screen.dart';
import '../screens/shared_wishlist_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/admin_screens_loader.dart'; // Chargement différé admin
import '../screens/auth_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/account_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/addresses_screen.dart';
import '../screens/security_screen.dart';
import '../screens/help_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/demo_data_screen.dart';
import '../services/analytics_service.dart';

/// Page sans animation de swipe-back iOS — remplace NoTransitionPage
/// pour éviter l'effet de double-écran causé par le conflit entre
/// l'animation native iOS et l'absence de transition Flutter.
class _FadeRootPage<T> extends CustomTransitionPage<T> {
  const _FadeRootPage({required super.child, super.key, super.name})
      : super(
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: _buildFade,
        );

  static Widget _buildFade(context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child);
}

/// Configuration du routeur GoRouter pour le support web
/// Utilise des URLs propres sans hash (#) pour le SEO
class WebRouter {
  // Clé de navigation globale
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Instance singleton du router
  static GoRouter? _router;
  
  /// Obtenir l'instance du router
  static GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  /// Créer le router avec toutes les routes
  static GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true, // Logs en mode debug
      observers: [
        AnalyticsService.observer,
      ],
      
      // Redirection globale (ex: vérification auth)
      redirect: (context, state) {
        // Pour le web, on peut ajouter des redirections SEO ici
        // Ex: rediriger /products vers /catalog
        if (state.matchedLocation == '/products') {
          return '/catalog';
        }
        // /home redirige vers / (racine)
        if (state.matchedLocation == '/home') {
          return '/';
        }
        return null; // Pas de redirection
      },
      
      // Configuration des routes
      routes: [
        // Web: Aller directement au Home (pas de splash - chargement instantané)
        GoRoute(
          path: '/',
          name: 'home',
          // NoTransitionPage : pas d'animation iOS swipe-back (pile vide)
          pageBuilder: (context, state) => const _FadeRootPage(child: ModernHomeScreen()),
        ),
        
        // Onboarding (optionnel sur web)
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) => _FadeRootPage(child: const OnboardingScreen()),
        ),
        
        // Catalogue avec support des filtres
        GoRoute(
          path: '/catalog',
          name: 'catalog',
          // NoTransitionPage : pas d'animation iOS swipe-back (pile vide après go())
          pageBuilder: (context, state) {
            final extra = state.extra;
            String? category;
            String? searchQuery;
            bool focusSearch = false;
            
            if (extra != null && extra is Map<String, dynamic>) {
              category = extra['category'] as String?;
              searchQuery = extra['searchQuery'] as String?;
              focusSearch = extra['focusSearch'] as bool? ?? false;
            }
            
            debugPrint('🔍 WebRouter /catalog - extra: $extra, category: $category, searchQuery: $searchQuery, focusSearch: $focusSearch');
            
            return _FadeRootPage(
              child: ModernCatalogScreen(
                initialCategory: category,
                initialSearchQuery: searchQuery,
                initialFocusSearch: focusSearch,
              ),
            );
          },
        ),
        
        // Détail produit avec ID dans l'URL (SEO friendly)
        GoRoute(
          path: '/product/:id',
          name: 'product_detail',
          pageBuilder: (context, state) {
            final productId = state.pathParameters['id']!;
            return _FadeRootPage(
              child: ModernProductDetailScreen(productId: productId),
            );
          },
        ),
        
        // Panier
        GoRoute(
          path: '/cart',
          name: 'cart',
          pageBuilder: (context, state) => _FadeRootPage(child: const ModernCartScreen()),
        ),
        
        // Comparateur de produits
        GoRoute(
          path: '/comparison',
          name: 'comparison',
          pageBuilder: (context, state) => _FadeRootPage(child: const ComparisonScreen()),
        ),
        
        // Wishlist partagée (lien public, sans authentification requise)
        GoRoute(
          path: '/wishlist/:shareId',
          name: 'shared_wishlist',
          pageBuilder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return _FadeRootPage(child: SharedWishlistScreen(shareId: shareId));
          },
        ),
        
        // Assistant IA (chat)
        GoRoute(
          path: '/chat',
          name: 'chat',
          pageBuilder: (context, state) => const _FadeRootPage(child: ChatScreen()),
        ),
        
        // Authentification
        GoRoute(
          path: '/auth',
          name: 'auth',
          pageBuilder: (context, state) => _FadeRootPage(child: const AuthScreen()),
        ),
        
        // Compte utilisateur
        GoRoute(
          path: '/account',
          name: 'account',
          pageBuilder: (context, state) => const _FadeRootPage(child: AccountScreen()),
        ),
        
        // Mes commandes
        GoRoute(
          path: '/my-orders',
          name: 'my_orders',
          pageBuilder: (context, state) => const _FadeRootPage(child: MyOrdersScreen()),
        ),
        
        // Notifications
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          pageBuilder: (context, state) => _FadeRootPage(child: const NotificationsScreen()),
        ),
        
        // Adresses
        GoRoute(
          path: '/addresses',
          name: 'addresses',
          pageBuilder: (context, state) => _FadeRootPage(child: const AddressesScreen()),
        ),
        
        // Sécurité
        GoRoute(
          path: '/security',
          name: 'security',
          pageBuilder: (context, state) => _FadeRootPage(child: const SecurityScreen()),
        ),
        
        // Aide
        GoRoute(
          path: '/help',
          name: 'help',
          pageBuilder: (context, state) => _FadeRootPage(child: const HelpScreen()),
        ),
        
        // Confidentialité
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          pageBuilder: (context, state) => _FadeRootPage(child: const PrivacyScreen()),
        ),
        
        // === ROUTES ADMIN ===
        GoRoute(
          path: '/admin-login',
          name: 'admin_login',
          builder: (context, state) => const DeferredAdminLogin(),
        ),
        
        GoRoute(
          path: '/admin-dashboard',
          name: 'admin_dashboard',
          builder: (context, state) => const DeferredAdminDashboard(),
        ),
        
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const DeferredAdminNavigation(),
        ),
        
        // Formulaire produit (création/édition)
        GoRoute(
          path: '/product-form',
          name: 'product_form',
          pageBuilder: (context, state) {
            final product = state.extra as Product?;
            return _FadeRootPage(child: ProductFormScreen(product: product));
          },
        ),
        
        // Données démo
        GoRoute(
          path: '/demo-data',
          name: 'demo_data',
          pageBuilder: (context, state) => _FadeRootPage(child: const DemoDataScreen()),
        ),
        
        // Login
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => _FadeRootPage(child: const LoginScreen()),
        ),
        
        // Register
        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder: (context, state) => _FadeRootPage(child: const RegisterScreen()),
        ),
      ],
      
      // Page d'erreur 404
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                '404 - Page non trouvée',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'La page "${state.matchedLocation}" n\'existe pas.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reset le router (utile pour les tests)
  static void reset() {
    _router = null;
  }
}

/// Extension pour faciliter la navigation
extension GoRouterExtension on BuildContext {
  /// Naviguer vers le détail d'un produit
  void goToProduct(String productId) {
    go('/product/$productId');
  }
  
  /// Naviguer vers le panier
  void goToCart() {
    go('/cart');
  }
  
  /// Naviguer vers l'accueil
  void goToHome() {
    go('/home');
  }
  
  /// Naviguer vers le catalogue
  void goToCatalog() {
    go('/catalog');
  }
  
  /// Naviguer vers l'admin
  void goToAdmin() {
    go('/admin');
  }
}