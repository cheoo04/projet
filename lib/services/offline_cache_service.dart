// Service de cache et mode hors ligne
// Gère le stockage local et la synchronisation des données

import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logging_service.dart';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  // Boxes Hive pour différents types de données
  static const String _productsBox = 'products_cache';
  static const String _usersBox = 'users_cache';
  static const String _ordersBox = 'orders_cache';
  static const String _settingsBox = 'settings_cache';
  static const String _metadataBox = 'metadata_cache';

  Box<dynamic>? _products;
  Box<dynamic>? _users;
  Box<dynamic>? _orders;
  Box<dynamic>? _settings;
  Box<dynamic>? _metadata;

  bool _isInitialized = false;
  bool _isOnline = true;

  // Initialiser le service de cache
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialiser Hive
      await Hive.initFlutter();

      // Ouvrir les boxes
      _products = await Hive.openBox(_productsBox);
      _users = await Hive.openBox(_usersBox);
      _orders = await Hive.openBox(_ordersBox);
      _settings = await Hive.openBox(_settingsBox);
      _metadata = await Hive.openBox(_metadataBox);

      // Surveiller la connectivité
      _initializeConnectivityMonitoring();

      _isInitialized = true;
      LoggingService.info('Service de cache initialisé');
    } catch (e) {
      LoggingService.error('Erreur initialisation cache: $e');
      throw Exception('Impossible d\'initialiser le cache');
    }
  }

  // Surveiller la connectivité réseau
  void _initializeConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);

      if (!wasOnline && _isOnline) {
        LoggingService.info('Connexion rétablie - Synchronisation...');
        _syncPendingChanges();
      } else if (wasOnline && !_isOnline) {
        LoggingService.warning('Connexion perdue - Mode hors ligne activé');
      }
    });
  }

  // Getter pour vérifier l'état de connexion
  bool get isOnline => _isOnline;

  // GESTION DES PRODUITS

  // Mettre en cache les produits
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    await _ensureInitialized();
    try {
      await _products!.clear();
      for (final product in products) {
        await _products!.put(product['id'], product);
      }

      // Mettre à jour les métadonnées
      await _updateMetadata(
        'products_last_sync',
        DateTime.now().toIso8601String(),
      );

      LoggingService.info('${products.length} produits mis en cache');
    } catch (e) {
      LoggingService.error('Erreur cache produits: $e');
    }
  }

  // Récupérer les produits du cache
  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    await _ensureInitialized();
    try {
      final products = <Map<String, dynamic>>[];
      for (final key in _products!.keys) {
        final product = _products!.get(key);
        if (product != null) {
          products.add(Map<String, dynamic>.from(product));
        }
      }
      return products;
    } catch (e) {
      LoggingService.error('Erreur récupération cache produits: $e');
      return [];
    }
  }

  // Rechercher dans le cache local
  Future<List<Map<String, dynamic>>> searchCachedProducts(String query) async {
    final allProducts = await getCachedProducts();
    final lowercaseQuery = query.toLowerCase();

    return allProducts.where((product) {
      final name = (product['name'] as String? ?? '').toLowerCase();
      final description = (product['description'] as String? ?? '')
          .toLowerCase();
      final brand = (product['brand'] as String? ?? '').toLowerCase();

      return name.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery) ||
          brand.contains(lowercaseQuery);
    }).toList();
  }

  // GESTION DES COMMANDES HORS LIGNE

  // Sauvegarder une commande en attente
  Future<void> savePendingOrder(Map<String, dynamic> orderData) async {
    await _ensureInitialized();
    try {
      final orderId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      orderData['id'] = orderId;
      orderData['status'] = 'pending_sync';
      orderData['created_offline'] = true;
      orderData['timestamp'] = DateTime.now().toIso8601String();

      await _orders!.put(orderId, orderData);
      LoggingService.info('Commande sauvée hors ligne: $orderId');
    } catch (e) {
      LoggingService.error('Erreur sauvegarde commande hors ligne: $e');
    }
  }

  // Récupérer les commandes en attente de synchronisation
  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    await _ensureInitialized();
    try {
      final pendingOrders = <Map<String, dynamic>>[];
      for (final key in _orders!.keys) {
        final order = _orders!.get(key);
        if (order != null && order['status'] == 'pending_sync') {
          pendingOrders.add(Map<String, dynamic>.from(order));
        }
      }
      return pendingOrders;
    } catch (e) {
      LoggingService.error('Erreur récupération commandes pendantes: $e');
      return [];
    }
  }

  // Synchroniser les changements en attente
  Future<void> _syncPendingChanges() async {
    try {
      final pendingOrders = await getPendingOrders();

      for (final order in pendingOrders) {
        try {
          // Synchroniser avec Firebase
          final docRef = await FirebaseFirestore.instance
              .collection('orders')
              .add(order);

          // Mettre à jour le cache avec l'ID Firebase
          order['id'] = docRef.id;
          order['status'] = 'synchronized';
          order['synced_at'] = DateTime.now().toIso8601String();

          await _orders!.put(docRef.id, order);
          await _orders!.delete(order['id']); // Supprimer l'ancienne entrée

          LoggingService.info('Commande synchronisée: ${docRef.id}');
        } catch (e) {
          LoggingService.error('Erreur sync commande ${order['id']}: $e');
        }
      }
    } catch (e) {
      LoggingService.error('Erreur synchronisation générale: $e');
    }
  }

  // GESTION DES PARAMÈTRES

  // Sauvegarder un paramètre
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    try {
      await _settings!.put(key, value);
    } catch (e) {
      LoggingService.error('Erreur sauvegarde paramètre $key: $e');
    }
  }

  // Récupérer un paramètre
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    await _ensureInitialized();
    try {
      return _settings!.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      LoggingService.error('Erreur récupération paramètre $key: $e');
      return defaultValue;
    }
  }

  // GESTION DES MÉTADONNÉES

  // Mettre à jour les métadonnées
  Future<void> _updateMetadata(String key, dynamic value) async {
    await _ensureInitialized();
    try {
      await _metadata!.put(key, value);
    } catch (e) {
      LoggingService.error('Erreur métadonnées $key: $e');
    }
  }

  // Récupérer les métadonnées
  Future<T?> getMetadata<T>(String key) async {
    await _ensureInitialized();
    try {
      return _metadata!.get(key) as T?;
    } catch (e) {
      return null;
    }
  }

  // Vérifier si les données sont obsolètes
  Future<bool> isDataStale(
    String dataType, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final lastSync = await getMetadata<String>('${dataType}_last_sync');
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.parse(lastSync);
    return DateTime.now().difference(lastSyncTime) > maxAge;
  }

  // UTILITAIRES

  // Vérifier l'initialisation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Nettoyer le cache
  Future<void> clearCache() async {
    await _ensureInitialized();
    try {
      await _products!.clear();
      await _users!.clear();
      await _orders!.clear();
      await _metadata!.clear();

      LoggingService.info('Cache nettoyé');
    } catch (e) {
      LoggingService.error('Erreur nettoyage cache: $e');
    }
  }

  // Obtenir la taille du cache
  Future<Map<String, int>> getCacheSize() async {
    await _ensureInitialized();
    return {
      'products': _products!.length,
      'users': _users!.length,
      'orders': _orders!.length,
      'settings': _settings!.length,
      'metadata': _metadata!.length,
    };
  }

  // Fermer les connexions
  Future<void> dispose() async {
    await _products?.close();
    await _users?.close();
    await _orders?.close();
    await _settings?.close();
    await _metadata?.close();
  }
}