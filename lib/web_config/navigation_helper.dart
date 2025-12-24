import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper de navigation cross-platform
/// Utilise go_router sur web (URLs propres) et Navigator sur mobile
class AppNavigator {
  /// Naviguer vers une route (push)
  static void push(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      // Sur web, utiliser go_router
      if (arguments != null) {
        context.push(route, extra: arguments);
      } else {
        context.push(route);
      }
    } else {
      // Sur mobile, utiliser Navigator classique
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  /// Naviguer vers une route en remplaçant la route actuelle
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

  /// Naviguer vers une route en effaçant l'historique (go)
  static void go(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      if (arguments != null) {
        context.go(route, extra: arguments);
      } else {
        context.go(route);
      }
    } else {
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false, arguments: arguments);
    }
  }

  /// Retour arrière
  static void pop(BuildContext context, [Object? result]) {
    if (kIsWeb) {
      context.pop(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  /// Peut-on revenir en arrière ?
  static bool canPop(BuildContext context) {
    if (kIsWeb) {
      return context.canPop();
    } else {
      return Navigator.canPop(context);
    }
  }

  // Routes web-friendly (mapping pour go_router)
  static String productDetailRoute(String productId) => '/product/$productId';
  static const String homeRoute = '/';
  static const String catalogRoute = '/catalog';
  static const String cartRoute = '/cart';
  static const String authRoute = '/auth';
  static const String accountRoute = '/account';
  static const String myOrdersRoute = '/my-orders';
  static const String notificationsRoute = '/notifications';
  static const String addressesRoute = '/addresses';
  static const String securityRoute = '/security';
  static const String helpRoute = '/help';
  static const String privacyRoute = '/privacy';
  static const String adminRoute = '/admin';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String adminLoginRoute = '/admin-login';
  static const String onboardingRoute = '/onboarding';
  static const String demoDataRoute = '/demo-data';

  /// Naviguer vers le catalogue avec filtre optionnel
  static void toCatalog(BuildContext context, {String? category, bool focusSearch = false}) {
    final args = <String, dynamic>{};
    if (category != null) args['category'] = category;
    if (focusSearch) args['focusSearch'] = true;
    
    debugPrint('🔍 AppNavigator.toCatalog - category: $category, focusSearch: $focusSearch, args: $args');
    
    if (args.isEmpty) {
      push(context, catalogRoute);
    } else {
      push(context, catalogRoute, arguments: args);
    }
  }

  /// Naviguer vers le détail d'un produit (route spéciale avec ID)
  static void toProductDetail(BuildContext context, String productId) {
    if (kIsWeb) {
      context.push('/product/$productId');
    } else {
      Navigator.pushNamed(context, '/product-detail', arguments: productId);
    }
  }

  /// Naviguer vers le formulaire produit (admin)
  static Future<T?> toProductForm<T>(BuildContext context, {dynamic product}) async {
    if (kIsWeb) {
      // Sur web, utiliser extra pour passer le produit
      return await context.push<T>('/product-form', extra: product);
    } else {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(
          builder: (context) {
            // Import dynamique pour éviter les dépendances circulaires
            return _buildProductFormScreen(product);
          },
        ),
      );
    }
  }

  static Widget _buildProductFormScreen(dynamic product) {
    // Lazy import pour éviter les imports circulaires
    // ignore: avoid_dynamic_calls
    throw UnimplementedError('Use direct import of ProductFormScreen');
  }
}
