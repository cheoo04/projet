import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

/// Mixin pour ajouter facilement Analytics aux écrans
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  /// Enregistre la vue d'un écran
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object>? parameters,
  }) async {
    await AnalyticsService.logCustomEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
        'screen_class': T.toString(),
        ...?parameters,
      },
    );
  }

  /// Enregistre une action utilisateur
  Future<void> logUserAction(
    String action, {
    Map<String, Object>? parameters,
  }) async {
    await AnalyticsService.logCustomEvent(
      'user_action',
      parameters: {'action': action, 'screen': T.toString(), ...?parameters},
    );
  }

  /// Enregistre une erreur d'interface utilisateur
  Future<void> logUIError(String error, {Map<String, Object>? context}) async {
    await AnalyticsService.logAppError(
      errorType: 'ui_error',
      errorMessage: error,
      screen: T.toString(),
    );
  }
}

/// Widget pour tracker automatiquement les vues d'écran
class AnalyticsScreenTracker extends StatefulWidget {
  final String screenName;
  final Widget child;
  final Map<String, Object>? screenParameters;

  const AnalyticsScreenTracker({
    super.key,
    required this.screenName,
    required this.child,
    this.screenParameters,
  });

  @override
  State<AnalyticsScreenTracker> createState() => _AnalyticsScreenTrackerState();
}

class _AnalyticsScreenTrackerState extends State<AnalyticsScreenTracker> {
  @override
  void initState() {
    super.initState();
    // Enregistrer la vue d'écran au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenView();
    });
  }

  Future<void> _logScreenView() async {
    await AnalyticsService.logCustomEvent(
      'screen_view',
      parameters: {
        'screen_name': widget.screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?widget.screenParameters,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Bouton avec tracking Analytics automatique
class AnalyticsTrackedButton extends StatelessWidget {
  final String buttonName;
  final String actionName;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final Map<String, Object>? additionalParameters;

  const AnalyticsTrackedButton({
    super.key,
    required this.buttonName,
    required this.actionName,
    required this.onPressed,
    required this.child,
    this.style,
    this.additionalParameters,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: () {
        // Enregistrer l'action avant de l'exécuter
        _logButtonPress();
        onPressed();
      },
      child: child,
    );
  }

  Future<void> _logButtonPress() async {
    await AnalyticsService.logCustomEvent(
      'button_press',
      parameters: {
        'button_name': buttonName,
        'action': actionName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParameters,
      },
    );
  }
}

/// Extension pour ajouter facilement le tracking aux widgets existants
extension AnalyticsExtensions on Widget {
  /// Enveloppe le widget avec un tracker d'écran
  Widget withScreenTracking(
    String screenName, {
    Map<String, Object>? parameters,
  }) {
    return AnalyticsScreenTracker(
      screenName: screenName,
      screenParameters: parameters,
      child: this,
    );
  }
}

/// Helper pour les événements e-commerce dans l'app
class ECommerceAnalytics {
  /// Track l'ajout au panier depuis un écran produit
  static Future<void> trackAddToCartFromProduct({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
    String? sourceScreen,
  }) async {
    await AnalyticsService.logAddToCart(
      itemId: productId,
      itemName: productName,
      category: category,
      price: price,
      quantity: quantity,
    );

    // Événement personnalisé pour plus de contexte
    await AnalyticsService.logCustomEvent(
      'pharrell_add_to_cart_detail',
      parameters: {
        'product_id': productId,
        'source_screen': sourceScreen ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track le processus de checkout
  static Future<void> trackCheckoutStep({
    required int step,
    required String stepName,
    required double cartValue,
    required int itemCount,
  }) async {
    await AnalyticsService.logCustomEvent(
      'pharrell_checkout_step',
      parameters: {
        'step': step,
        'step_name': stepName,
        'cart_value': cartValue,
        'item_count': itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track les erreurs de paiement
  static Future<void> trackPaymentError({
    required String errorCode,
    required String errorMessage,
    required double amount,
    String? paymentMethod,
  }) async {
    await AnalyticsService.logAppError(
      errorType: 'payment_error',
      errorMessage: '$errorCode: $errorMessage',
      screen: 'checkout',
    );

    await AnalyticsService.logCustomEvent(
      'pharrell_payment_error',
      parameters: {
        'error_code': errorCode,
        'amount': amount,
        'payment_method': paymentMethod ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Helper pour les événements admin
class AdminAnalytics {
  /// Track les actions d'administration
  static Future<void> trackAdminAction({
    required String action,
    required String module, // stock, orders, users, etc.
    required String adminId,
    Map<String, Object>? additionalData,
  }) async {
    await AnalyticsService.logCustomEvent(
      'pharrell_admin_action',
      parameters: {
        'action': action,
        'module': module,
        'admin_id': adminId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      },
    );
  }

  /// Track l'accès aux analytics
  static Future<void> trackAnalyticsAccess({
    required String adminId,
    required String section,
    String? dateRange,
  }) async {
    await AnalyticsService.logViewAnalytics(section: section);

    await AnalyticsService.logCustomEvent(
      'pharrell_admin_analytics_access',
      parameters: {
        'admin_id': adminId,
        'section': section,
        'date_range': dateRange ?? 'default',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
