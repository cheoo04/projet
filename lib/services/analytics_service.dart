import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des événements Firebase Analytics
/// Permet de tracker les actions utilisateur et les événements métier
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static bool _isInitialized = false;

  /// Initialise le service Analytics
  static Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Configuration selon l'environnement
      if (kDebugMode) {
        // En debug, désactiver la collecte automatique
        await _analytics.setAnalyticsCollectionEnabled(false);
        debugPrint('🔧 Analytics: Mode debug - collecte désactivée');
      } else {
        // En production, activer la collecte
        await _analytics.setAnalyticsCollectionEnabled(true);
        debugPrint('📊 Analytics: Mode production - collecte activée');
      }

      _isInitialized = true;
      debugPrint('✅ AnalyticsService initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Analytics: $e');
    }
  }

  /// Observer pour la navigation (à utiliser avec FirebaseAnalyticsObserver)
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ===========================================
  // ÉVÉNEMENTS UTILISATEUR
  // ===========================================

  /// Connexion utilisateur
  static Future<void> logLogin(String method) async {
    await _logEvent(
      'login',
      parameters: {
        'method': method, // email, google, facebook, etc.
      },
    );
  }

  /// Déconnexion utilisateur
  static Future<void> logLogout() async {
    await _logEvent('logout');
  }

  /// Inscription utilisateur
  static Future<void> logSignUp(String method) async {
    await _logEvent('sign_up', parameters: {'method': method});
  }

  /// Définir l'ID utilisateur
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) debugPrint('👤 Analytics User ID: $userId');
    } catch (e) {
      debugPrint('❌ Erreur setUserId: $e');
    }
  }

  /// Définir les propriétés utilisateur
  static Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) debugPrint('🏷️ User Property: $name = $value');
    } catch (e) {
      debugPrint('❌ Erreur setUserProperty: $e');
    }
  }

  // ===========================================
  // ÉVÉNEMENTS E-COMMERCE
  // ===========================================

  /// Voir un produit
  static Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
    String? brand,
  }) async {
    await _logEvent(
      'view_item',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'item_category': category,
        'price': price,
        'currency': 'EUR',
        if (brand != null) 'item_brand': brand,
      },
    );
  }

  /// Ajouter au panier
  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
    required int quantity,
    String? brand,
  }) async {
    await _logEvent(
      'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'item_category': category,
        'price': price,
        'quantity': quantity,
        'currency': 'EUR',
        if (brand != null) 'item_brand': brand,
      },
    );
  }

  /// Retirer du panier
  static Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await _logEvent(
      'remove_from_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        'currency': 'EUR',
      },
    );
  }

  /// Commencer le checkout
  static Future<void> logBeginCheckout({
    required double value,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    await _logEvent(
      'begin_checkout',
      parameters: {'value': value, 'currency': currency, 'items': items},
    );
  }

  /// Achat terminé
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required List<Map<String, dynamic>> items,
    String? coupon,
  }) async {
    await _logEvent(
      'purchase',
      parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
        'items': items,
        if (coupon != null) 'coupon': coupon,
      },
    );
  }

  // ===========================================
  // ÉVÉNEMENTS ENGAGEMENT
  // ===========================================

  /// Recherche
  static Future<void> logSearch(String searchTerm, {String? category}) async {
    await _logEvent(
      'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'search_category': category,
      },
    );
  }

  /// Partage
  static Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _logEvent(
      'share',
      parameters: {
        'content_type': contentType,
        'item_id': itemId,
        if (method != null) 'method': method,
      },
    );
  }

  /// Évaluation/Review
  static Future<void> logRating({
    required String itemId,
    required double rating,
    String? reviewText,
  }) async {
    await _logEvent(
      'rate_content',
      parameters: {
        'item_id': itemId,
        'rating': rating,
        if (reviewText != null) 'review_text': reviewText,
      },
    );
  }

  /// Sélection de contenu
  static Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    await _logEvent(
      'select_content',
      parameters: {'content_type': contentType, 'item_id': itemId},
    );
  }

  // ===========================================
  // ÉVÉNEMENTS MÉTIER PHARRELL PHONE
  // ===========================================

  /// Consultation du catalogue
  static Future<void> logViewCatalog({String? category, String? filter}) async {
    await _logEvent(
      'pharrell_view_catalog',
      parameters: {
        if (category != null) 'category': category,
        if (filter != null) 'filter': filter,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Gestion du stock (admin)
  static Future<void> logStockManagement({
    required String action, // add, remove, update
    required String productId,
    int? quantity,
  }) async {
    await _logEvent(
      'pharrell_stock_management',
      parameters: {
        'action': action,
        'product_id': productId,
        if (quantity != null) 'quantity': quantity,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Gestion des commandes (admin)
  static Future<void> logOrderManagement({
    required String action, // view, update, cancel, ship
    required String orderId,
    String? status,
  }) async {
    await _logEvent(
      'pharrell_order_management',
      parameters: {
        'action': action,
        'order_id': orderId,
        if (status != null) 'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Gestion des utilisateurs (admin)
  static Future<void> logUserManagement({
    required String action, // create, update, delete, suspend
    required String targetUserId,
    String? userRole,
  }) async {
    await _logEvent(
      'pharrell_user_management',
      parameters: {
        'action': action,
        'target_user_id': targetUserId,
        if (userRole != null) 'user_role': userRole,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Consultation des analytics (admin)
  static Future<void> logViewAnalytics({String? section}) async {
    await _logEvent(
      'pharrell_view_analytics',
      parameters: {
        if (section != null) 'section': section,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Promotion appliquée
  static Future<void> logPromotionApplied({
    required String promotionId,
    required String promotionName,
    required double discount,
  }) async {
    await _logEvent(
      'pharrell_promotion_applied',
      parameters: {
        'promotion_id': promotionId,
        'promotion_name': promotionName,
        'discount': discount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Notification envoyée
  static Future<void> logNotificationSent({
    required String type, // push, email, sms
    required String title,
    String? userId,
  }) async {
    await _logEvent(
      'pharrell_notification_sent',
      parameters: {
        'notification_type': type,
        'title': title,
        if (userId != null) 'target_user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Erreur applicative
  static Future<void> logAppError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    await _logEvent(
      'pharrell_app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screen != null) 'screen': screen,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================
  // MÉTHODES UTILITAIRES
  // ===========================================

  /// Log d'événement personnalisé
  static Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _logEvent(eventName, parameters: parameters);
  }

  /// Méthode privée pour logger un événement
  static Future<void> _logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);

      if (kDebugMode) {
        debugPrint('📊 Analytics Event: $eventName');
        if (parameters != null) {
          debugPrint('   Parameters: $parameters');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur log Analytics: $e');
    }
  }

  /// Obtenir l'ID de l'app instance
  static Future<String?> getAppInstanceId() async {
    try {
      return await _analytics.appInstanceId;
    } catch (e) {
      debugPrint('❌ Erreur getAppInstanceId: $e');
      return null;
    }
  }

  /// Reset des données Analytics (pour tests)
  static Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
      if (kDebugMode) debugPrint('🔄 Analytics data reset');
    } catch (e) {
      debugPrint('❌ Erreur resetAnalyticsData: $e');
    }
  }

  /// Vérifier si le service est initialisé
  static bool get isInitialized => _isInitialized;
}
