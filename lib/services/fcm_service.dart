import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Handler pour les messages en arrière-plan (doit être une fonction top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message reçu en arrière-plan: ${message.messageId}');
  // Les notifications sont automatiquement affichées par le système
}

/// Service de gestion des notifications push avec Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;

  /// Token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Initialiser le service FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Demander les permissions
      await _requestPermissions();

      // Configurer les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      await _getAndSaveToken();

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Configurer les handlers de messages
      _setupMessageHandlers();

      // S'abonner aux topics selon les préférences
      await _subscribeToTopicsFromPreferences();

      _isInitialized = true;
      debugPrint('✅ FCM Service initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation FCM: $e');
    }
  }

  /// Demander les permissions de notification
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Permission notifications: ${settings.authorizationStatus}');

    // Pour iOS, configurer les options de notification au premier plan
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialiser les notifications locales (pour afficher en foreground)
  Future<void> _initializeLocalNotifications() async {
    // Les notifications locales ne sont pas supportées sur web
    if (kIsWeb) {
      debugPrint('ℹ️ Notifications locales non disponibles sur web');
      return;
    }
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'pharrell_phone_channel',
        'Pharrell Phone Notifications',
        description: 'Notifications de l\'application Pharrell Phone',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Clé VAPID pour les notifications push web
  /// À générer dans Firebase Console > Project Settings > Cloud Messaging > Web Push certificates
  static const String _webVapidKey = 'BDnj9ilH3WCCYLsZ8_kit2mpXEjlfrNccdUg3fYNdkYkgX_oalE5xEqSK9_vQhop2Qg7vnONZMmp1Lr2eQF2IbQ';
  
  /// Obtenir et sauvegarder le token FCM
  Future<void> _getAndSaveToken() async {
    try {
      // Pour le web, on doit passer la clé VAPID
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(vapidKey: _webVapidKey);
      } else {
        _fcmToken = await _messaging.getToken();
      }
      
      if (_fcmToken != null) {
        debugPrint('🔑 Token FCM: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      } else {
        debugPrint('⚠️ Token FCM non disponible (normal en émulateur/debug)');
      }
    } catch (e) {
      // En mode debug ou émulateur, FCM peut ne pas être disponible
      debugPrint('⚠️ FCM non disponible: $e');
      debugPrint('ℹ️ Les notifications push fonctionneront sur un appareil réel');
    }
  }

  /// Callback quand le token change
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('🔄 Token FCM rafraîchi: $newToken');
    _fcmToken = newToken;
    await _saveTokenToFirestore(newToken);
  }

  /// Sauvegarder le token dans Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Ne pas sauvegarder pour les utilisateurs anonymes (pas de document Firestore)
    if (user.isAnonymous) {
      debugPrint('ℹ️ Token FCM non sauvegardé (utilisateur anonyme)');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Token FCM sauvegardé pour ${user.uid}');
    } catch (e) {
      // Ignorer silencieusement les erreurs de permission pour ne pas bloquer l'app
      debugPrint('⚠️ Token FCM non sauvegardé: $e');
    }
  }

  /// Supprimer le token (lors de la déconnexion)
  Future<void> removeToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _fcmToken == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([_fcmToken]),
      });
      debugPrint('✅ Token FCM supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression token: $e');
    }
  }

  /// Configurer les handlers de messages
  void _setupMessageHandlers() {
    // Message reçu quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message reçu quand l'app s'ouvre depuis une notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Vérifier si l'app a été ouverte depuis une notification
    _checkInitialMessage();
  }

  /// Gérer un message reçu en premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Message en premier plan: ${message.notification?.title}');

    // Afficher la notification locale
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'Pharrell Phone',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Gérer l'ouverture de l'app depuis une notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📲 App ouverte depuis notification: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  /// Vérifier le message initial (app ouverte depuis notification)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📲 Message initial: ${initialMessage.data}');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Gérer la navigation depuis une notification
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final entityId = data['entityId'];

    debugPrint('🧭 Navigation: type=$type, entityId=$entityId');
    
    // Navigation selon le type de notification
    switch (type) {
      case 'order':
        // Naviguer vers l'écran des commandes
        debugPrint('Navigation vers /my-orders');
        break;
      case 'stock':
        // Naviguer vers l'écran de gestion de stock
        debugPrint('Navigation vers stock management');
        break;
      case 'promotion':
        // Naviguer vers l'écran des promotions
        debugPrint('Navigation vers promotions');
        break;
      case 'product':
        // Naviguer vers le détail du produit
        if (entityId != null) {
          debugPrint('Navigation vers product/$entityId');
        }
        break;
      default:
        debugPrint('Type de notification non géré: $type');
    }
  }

  /// Callback quand une notification locale est tapée
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification tapée: ${response.payload}');
    // Gérer la navigation
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pharrell_phone_channel',
      'Pharrell Phone Notifications',
      channelDescription: 'Notifications de l\'application Pharrell Phone',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ==================== GESTION DES TOPICS ====================

  /// S'abonner à un topic (non supporté sur web)
  Future<void> subscribeToTopic(String topic) async {
    // subscribeToTopic n'est pas supporté sur web
    if (kIsWeb) {
      debugPrint('ℹ️ subscribeToTopic non supporté sur web - ignoré');
      return;
    }
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Abonné au topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur abonnement topic $topic: $e');
    }
  }

  /// Se désabonner d'un topic (non supporté sur web)
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur désabonnement topic $topic: $e');
    }
  }

  /// Topics disponibles
  static const String topicOrders = 'orders';
  static const String topicPromotions = 'promotions';
  static const String topicNewProducts = 'new_products';
  static const String topicPriceDrops = 'price_drops';
  static const String topicStock = 'stock_alerts';
  static const String topicAll = 'all_users';

  /// S'abonner aux topics selon les préférences sauvegardées
  Future<void> _subscribeToTopicsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Toujours s'abonner au topic général
    await subscribeToTopic(topicAll);

    // Topics selon les préférences
    if (prefs.getBool('notif_orders') ?? true) {
      await subscribeToTopic(topicOrders);
    }
    if (prefs.getBool('notif_promos') ?? true) {
      await subscribeToTopic(topicPromotions);
    }
    if (prefs.getBool('notif_new_products') ?? false) {
      await subscribeToTopic(topicNewProducts);
    }
    if (prefs.getBool('notif_price_drops') ?? true) {
      await subscribeToTopic(topicPriceDrops);
    }
    if (prefs.getBool('notif_stock') ?? false) {
      await subscribeToTopic(topicStock);
    }
  }

  /// Mettre à jour l'abonnement à un topic selon la préférence
  Future<void> updateTopicSubscription(String prefKey, bool enabled) async {
    String? topic;
    
    switch (prefKey) {
      case 'notif_orders':
        topic = topicOrders;
        break;
      case 'notif_promos':
        topic = topicPromotions;
        break;
      case 'notif_new_products':
        topic = topicNewProducts;
        break;
      case 'notif_price_drops':
        topic = topicPriceDrops;
        break;
      case 'notif_stock':
        topic = topicStock;
        break;
    }

    if (topic != null) {
      if (enabled) {
        await subscribeToTopic(topic);
      } else {
        await unsubscribeFromTopic(topic);
      }
    }
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  /// Vérifier si les notifications sont autorisées
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Obtenir les paramètres de notification actuels
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Rafraîchir le token manuellement (après connexion)
  Future<void> refreshToken() async {
    await _getAndSaveToken();
    await _subscribeToTopicsFromPreferences();
  }
}
