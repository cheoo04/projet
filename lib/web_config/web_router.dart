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
import '../screens/admin_screens_loader.dart';
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
import '../widgets/app_shell.dart';

/// Transition fade légère pour les pages racines du shell.
class _FadeRootPage<T> extends CustomTransitionPage<T> {
  const _FadeRootPage({required super.child, super.key, super.name})
      : super(
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: _fade,
        );

  static Widget _fade(context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child);
}

/// Transition slide standard pour les pages secondaires (détail, compte…).
/// Désactive le swipe-back iOS natif via fullscreenDialog = false et
/// une animation personnalisée, évitant le double-écran.
class _SlidePage<T> extends CustomTransitionPage<T> {
  _SlidePage({required super.child, super.key, super.name})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class WebRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter? _router;

  static GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  static GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      observers: [AnalyticsService.observer],

      redirect: (context, state) {
        if (state.matchedLocation == '/products') return '/catalog';
        if (state.matchedLocation == '/home') return '/';
        if (state.matchedLocation == '/visitor') return '/';
        return null;
      },

      routes: [
        // ═══════════════════════════════════════════════════════════════
        // SHELL — 4 onglets avec BottomNav partagée
        // ═══════════════════════════════════════════════════════════════
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // ── Branche 0 : Accueil ──
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  pageBuilder: (context, state) =>
                      const _FadeRootPage(child: ModernHomeScreen()),
                ),
              ],
            ),

            // ── Branche 1 : Catalogue ──
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catalog',
                  name: 'catalog',
                  pageBuilder: (context, state) {
                    final extra = state.extra;
                    String? category;
                    String? searchQuery;
                    bool focusSearch = false;
                    if (extra is Map<String, dynamic>) {
                      category = extra['category'] as String?;
                      searchQuery = extra['searchQuery'] as String?;
                      focusSearch = extra['focusSearch'] as bool? ?? false;
                    }
                    return _FadeRootPage(
                      child: ModernCatalogScreen(
                        initialCategory: category,
                        initialSearchQuery: searchQuery,
                        initialFocusSearch: focusSearch,
                      ),
                    );
                  },
                  routes: const [],
                ),
              ],
            ),

            // ── Branche 2 : Panier ──
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  name: 'cart',
                  pageBuilder: (context, state) =>
                      const _FadeRootPage(child: ModernCartScreen()),
                ),
              ],
            ),

            // ── Branche 3 : Compte ──
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/account',
                  name: 'account',
                  pageBuilder: (context, state) =>
                      const _FadeRootPage(child: AccountScreen()),
                  routes: [
                    GoRoute(
                      path: '/my-orders',
                      name: 'my_orders',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const MyOrdersScreen()),
                    ),
                    GoRoute(
                      path: '/notifications',
                      name: 'notifications',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const NotificationsScreen()),
                    ),
                    GoRoute(
                      path: '/addresses',
                      name: 'addresses',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const AddressesScreen()),
                    ),
                    GoRoute(
                      path: '/security',
                      name: 'security',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const SecurityScreen()),
                    ),
                    GoRoute(
                      path: '/help',
                      name: 'help',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const HelpScreen()),
                    ),
                    GoRoute(
                      path: '/privacy',
                      name: 'privacy',
                      pageBuilder: (context, state) =>
                          _SlidePage(child: const PrivacyScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════
        // ROUTES HORS SHELL — pas de BottomNav
        // ═══════════════════════════════════════════════════════════════

        // Détail produit — hors shell pour garder /product/:id propre
        GoRoute(
          path: '/product/:id',
          name: 'product_detail',
          pageBuilder: (context, state) {
            final productId = state.pathParameters['id']!;
            // _SlidePage (comme toutes les autres pages secondaires) désactive
            // le swipe-back natif géré par Safari/iOS, qui entrait en conflit
            // avec la transition Flutter et provoquait un double retour visible.
            return _SlidePage(
              key: state.pageKey,
              child: ModernProductDetailScreen(productId: productId),
            );
          },
        ),

        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) =>
              _SlidePage(child: const OnboardingScreen()),
        ),

        GoRoute(
          path: '/comparison',
          name: 'comparison',
          pageBuilder: (context, state) =>
              _SlidePage(child: const ComparisonScreen()),
        ),

        GoRoute(
          path: '/wishlist/:shareId',
          name: 'shared_wishlist',
          pageBuilder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return _SlidePage(child: SharedWishlistScreen(shareId: shareId));
          },
        ),

        GoRoute(
          path: '/chat',
          name: 'chat',
          pageBuilder: (context, state) =>
              _SlidePage(child: const ChatScreen()),
        ),

        GoRoute(
          path: '/auth',
          name: 'auth',
          pageBuilder: (context, state) =>
              _SlidePage(child: const AuthScreen()),
        ),

        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) =>
              _SlidePage(child: const LoginScreen()),
        ),

        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder: (context, state) =>
              _SlidePage(child: const RegisterScreen()),
        ),

        // === ADMIN ===
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

        GoRoute(
          path: '/product-form',
          name: 'product_form',
          pageBuilder: (context, state) {
            final product = state.extra as Product?;
            return _SlidePage(child: ProductFormScreen(product: product));
          },
        ),

        GoRoute(
          path: '/demo-data',
          name: 'demo_data',
          pageBuilder: (context, state) =>
              _SlidePage(child: const DemoDataScreen()),
        ),
      ],

      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text('404 - Page non trouvée',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text('La page "${state.matchedLocation}" n\'existe pas.',
                  style: Theme.of(context).textTheme.bodyLarge),
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

  static void reset() => _router = null;
}

extension GoRouterExtension on BuildContext {
  void goToProduct(String productId) => go('/product/$productId');
  void goToCart() => go('/cart');
  void goToHome() => go('/');
  void goToCatalog() => go('/catalog');
  void goToAdmin() => go('/admin');
}