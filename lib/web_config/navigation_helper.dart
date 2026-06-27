import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Routes "principales" qui doivent changer l'URL du navigateur.
/// Toutes les autres restent en push (pas de changement d'URL).
// Routes qui utilisent go() - changent l'URL mais GARDENT la pile de navigation
// NB: /cart intentionnellement absent - go() viderait la pile et le retour = page blanche
// NB: /auth idem - on veut pouvoir revenir à la page précédente après login
const _urlRoutes = {
  '/',
  '/catalog',
  '/account',
  '/my-orders',
  '/chat',
  '/onboarding',
};

/// Helper de navigation cross-platform.
///
/// Sur le WEB :
///   - Routes "principales" (_urlRoutes) → context.go()  → URL change dans la barre
///   - Autres routes (fiche produit, sécurité, aide…) → context.push() → URL change
///     aussi avec GoRouter mais on peut revenir avec le bouton ←
///   - pushReplacement → context.pushReplacement()
///
/// Sur MOBILE :
///   - push → Navigator.pushNamed
///   - go   → Navigator.pushNamedAndRemoveUntil (vide la pile)
class AppNavigator {

  /// Navigation principale.
  /// Sur web : go() pour les routes URL principales, push() pour les autres.
  static void push(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      // Routes principales → go() pour que l'URL change proprement
      if (_urlRoutes.contains(route)) {
        if (arguments != null) {
          context.go(route, extra: arguments);
        } else {
          context.go(route);
        }
      } else {
        // Fiche produit, sécurité, aide, admin, etc. → push()
        if (arguments != null) {
          context.push(route, extra: arguments);
        } else {
          context.push(route);
        }
      }
    } else {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  /// Remplace la route courante (pas de retour possible).
  static void pushReplacement(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      if (arguments != null) {
        context.pushReplacement(route, extra: arguments);
      } else {
        context.pushReplacement(route);
      }
    } else {
      Navigator.pushReplacementNamed(context, route, arguments: arguments);
    }
  }

  /// Navigation qui efface tout l'historique (ex: logout → home).
  static void go(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      if (arguments != null) {
        context.go(route, extra: arguments);
      } else {
        context.go(route);
      }
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, route, (r) => false, arguments: arguments);
    }
  }

  /// Retour arrière.
  static void pop(BuildContext context, [Object? result]) {
    if (kIsWeb) {
      context.pop(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  /// Peut-on revenir en arrière ?
  static bool canPop(BuildContext context) {
    if (kIsWeb) return context.canPop();
    return Navigator.canPop(context);
  }

  // ── Constantes de routes ────────────────────────────────────────────────
  static String productDetailRoute(String productId) => '/product/$productId';
  static const String homeRoute         = '/';
  static const String catalogRoute      = '/catalog';
  static const String cartRoute         = '/cart';
  static const String authRoute         = '/auth';
  static const String accountRoute      = '/account';
  static const String myOrdersRoute     = '/my-orders';
  static const String notificationsRoute= '/notifications';
  static const String addressesRoute    = '/addresses';
  static const String securityRoute     = '/security';
  static const String helpRoute         = '/help';
  static const String privacyRoute      = '/privacy';
  static const String adminRoute        = '/admin';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String adminLoginRoute   = '/admin-login';
  static const String onboardingRoute   = '/onboarding';
  static const String demoDataRoute     = '/demo-data';
  static const String chatRoute         = '/chat';

  // ── Méthodes spécialisées ───────────────────────────────────────────────

  /// Vers le catalogue avec filtre optionnel — change l'URL.
  static void toCatalog(BuildContext context, {String? category, bool focusSearch = false}) {
    final args = <String, dynamic>{};
    if (category != null) args['category'] = category;
    if (focusSearch) args['focusSearch'] = true;

    debugPrint('🔍 AppNavigator.toCatalog - category: $category, '
        'focusSearch: $focusSearch');

    if (args.isEmpty) {
      go(context, catalogRoute);
    } else {
      go(context, catalogRoute, arguments: args);
    }
  }

  /// Vers la fiche produit — change l'URL (important pour partage & SEO).
  static void toProductDetail(BuildContext context, String productId) {
    if (kIsWeb) {
      context.go('/product/$productId');
    } else {
      Navigator.pushNamed(context, '/product-detail', arguments: productId);
    }
  }

  /// Vers le formulaire produit admin — push (pas de changement d'URL majeur).
  static Future<T?> toProductForm<T>(BuildContext context, {dynamic product}) async {
    if (kIsWeb) {
      return await context.push<T>('/product-form', extra: product);
    } else {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => _buildProductFormScreen(product)),
      );
    }
  }

  static Widget _buildProductFormScreen(dynamic product) {
    throw UnimplementedError('Use direct import of ProductFormScreen');
  }
}