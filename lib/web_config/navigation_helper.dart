import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Philosophie de navigation Pharrell Phone :
///
/// Sur le WEB, toutes les navigations utilisent context.push() — l'URL change
/// ET l'historique est conservé. Le bouton ← du navigateur et le bouton retour
/// dans l'app fonctionnent tous les deux.
///
/// context.go() n'est utilisé QUE pour les cas exceptionnels : logout (vider
/// la pile) et redirection depuis l'onboarding.
///
/// Sur MOBILE, on utilise le Navigator classique.
class AppNavigator {

  static void push(BuildContext context, String route, {Object? arguments}) {
    if (kIsWeb) {
      if (arguments != null) {
        context.push(route, extra: arguments);
      } else {
        context.push(route);
      }
    } else {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  static void pushReplacement(BuildContext context, String route,
      {Object? arguments}) {
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

  /// Vide toute la pile et navigue (logout, onboarding → home).
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

  static void pop(BuildContext context, [Object? result]) {
    if (kIsWeb) {
      if (context.canPop()) {
        context.pop(result);
      } else {
        // Si rien à dépiler, retourner à la home
        context.go('/');
      }
    } else {
      Navigator.pop(context, result);
    }
  }

  static bool canPop(BuildContext context) {
    if (kIsWeb) return context.canPop();
    return Navigator.canPop(context);
  }

  // ── Routes ──────────────────────────────────────────────────────────────
  static const String homeRoute          = '/';
  static const String catalogRoute       = '/catalog';
  static const String cartRoute          = '/cart';
  static const String authRoute          = '/auth';
  static const String accountRoute       = '/account';
  static const String myOrdersRoute      = '/my-orders';
  static const String notificationsRoute = '/notifications';
  static const String addressesRoute     = '/addresses';
  static const String securityRoute      = '/security';
  static const String helpRoute          = '/help';
  static const String privacyRoute       = '/privacy';
  static const String adminRoute         = '/admin';
  static const String adminLoginRoute    = '/admin-login';
  static const String onboardingRoute    = '/onboarding';
  static const String chatRoute          = '/chat';
  static const String cartLoginRoute     = '/cart';

  static String productDetailRoute(String id) => '/product/$id';

  // ── Navigations spécialisées ─────────────────────────────────────────────

  static void toCatalog(BuildContext context,
      {String? category, bool focusSearch = false}) {
    final args = <String, dynamic>{};
    if (category != null) args['category'] = category;
    if (focusSearch) args['focusSearch'] = true;

    if (args.isEmpty) {
      push(context, catalogRoute);
    } else {
      push(context, catalogRoute, arguments: args);
    }
  }

  static void toProductDetail(BuildContext context, String productId) {
    go(context, '/product/$productId');
  }

  static Future<T?> toProductForm<T>(BuildContext context,
      {dynamic product}) async {
    if (kIsWeb) {
      return await context.push<T>('/product-form', extra: product);
    } else {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                throw UnimplementedError('Use ProductFormScreen directly')),
      );
    }
  }
}