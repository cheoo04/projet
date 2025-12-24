import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service d'initialisation de l'application
/// Gère la première utilisation, l'authentification anonyme et le chargement des données
class AppInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Clés pour SharedPreferences
  static const String _onboardingKey = 'onboarding_completed';
  static const String _dataLoadedKey = 'initial_data_loaded';
  
  /// Flag pour éviter les appels multiples
  static bool _isRetrying = false;
  
  /// Vérifie si c'est la première utilisation (onboarding non complété)
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }
  
  /// Marque l'onboarding comme complété
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  /// Tente de se connecter et charger les données quand le réseau revient
  static Future<void> retryAuthAndLoadData() async {
    if (_isRetrying) return;
    _isRetrying = true;
    
    try {
      // Vérifier la connectivité
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = _hasInternetConnection(connectivity);
      
      if (!hasInternet) {
        print('⚠️ Pas de connexion internet - Retry annulé');
        _isRetrying = false;
        return;
      }
      
      // Si pas encore authentifié, réessayer
      if (_auth.currentUser == null) {
        print('🔄 Tentative de reconnexion anonyme...');
        await ensureAuthenticated();
      }
      
      // Si authentifié maintenant, charger les données
      if (_auth.currentUser != null) {
        await loadInitialDataIfNeeded();
      }
    } catch (e) {
      print('❌ Erreur retry: $e');
    } finally {
      _isRetrying = false;
    }
  }
  
  /// Écoute les changements de connectivité et retente si nécessaire
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  /// Vérifie si le résultat de connectivité indique une connexion internet
  static bool _hasInternetConnection(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
           result == ConnectivityResult.mobile ||
           result == ConnectivityResult.ethernet;
  }
  
  static void startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasInternet = _hasInternetConnection(result);
      
      if (hasInternet && _auth.currentUser == null) {
        print('🌐 Connexion rétablie - Tentative d\'authentification...');
        retryAuthAndLoadData();
      }
    });
  }
  
  static void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Connecte l'utilisateur anonymement s'il n'est pas déjà connecté
  static Future<User?> ensureAuthenticated() async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      try {
        final credential = await _auth.signInAnonymously();
        user = credential.user;
        print('✅ Connexion anonyme réussie: ${user?.uid}');
      } catch (e) {
        print('❌ Erreur connexion anonyme: $e');
        // Continuer sans authentification - les données publiques sont accessibles
      }
    } else {
      print('✅ Utilisateur déjà connecté: ${user.uid}');
    }
    
    return user;
  }
  
  /// Vérifie si la base de données contient des produits
  static Future<bool> hasProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification produits: $e');
      return false;
    }
  }
  
  /// Charge les données initiales si la base est vide
  /// IMPORTANT: Ne charge les données que si l'utilisateur est authentifié
  /// DÉSACTIVÉ: Utilisez l'écran "Données test" pour créer des données de démo
  static Future<bool> loadInitialDataIfNeeded() async {
    try {
      // DÉSACTIVÉ - Pour créer des données, utilisez "Données test" dans l'admin
      print('ℹ️ Chargement automatique des données désactivé');
      print('ℹ️ Utilisez "Données test" dans l\'admin pour créer des données de démo');
      return true;
      
      /* ANCIEN CODE - DÉSACTIVÉ
      // Vérifier si l'utilisateur est authentifié
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Utilisateur non authentifié - Impossible de charger les données initiales');
        print('ℹ️ Les données seront chargées à la prochaine connexion avec internet');
        return false;
      }
      
      // Vérifier si des produits existent déjà
      if (await hasProducts()) {
        print('✅ Produits déjà présents dans la base');
        return true;
      }
      
      print('📦 Base vide - Chargement des données initiales...');
      print('👤 Utilisateur authentifié: ${user.uid}');
      
      // Créer les catégories
      await _createInitialCategories();
      
      // Créer les produits
      await _createInitialProducts();
      
      // Marquer comme chargé
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataLoadedKey, true);
      
      print('✅ Données initiales chargées avec succès');
      return true;
      */
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      return false;
    }
  }
  
  /// Crée les catégories initiales
  static Future<void> _createInitialCategories() async {
    final categories = [
      {
        'id': 'smartphones',
        'name': 'Smartphones',
        'description': 'Téléphones mobiles dernière génération',
        'icon': 'phone_android',
        'order': 1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'accessories',
        'name': 'Accessoires',
        'description': 'Coques, chargeurs, écouteurs et plus',
        'icon': 'headphones',
        'order': 2,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tablets',
        'name': 'Tablettes',
        'description': 'Tablettes tactiles pour tous les usages',
        'icon': 'tablet',
        'order': 3,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'watches',
        'name': 'Montres',
        'description': 'Montres connectées et smartwatches',
        'icon': 'watch',
        'order': 4,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    final batch = _firestore.batch();
    for (final category in categories) {
      final docRef = _firestore.collection('categories').doc(category['id'] as String);
      batch.set(docRef, category);
    }
    await batch.commit();
    print('✅ ${categories.length} catégories créées');
  }
  
  /// Crée les produits initiaux
  static Future<void> _createInitialProducts() async {
    final products = [
      // Smartphones
      {
        'name': 'iPhone 15 Pro Max',
        'description': 'Le smartphone le plus puissant d\'Apple avec puce A17 Pro, écran Super Retina XDR et système de caméra professionnelle.',
        'price': 850000,
        'originalPrice': 950000,
        'categoryId': 'smartphones',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=600',
        'images': [
          'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=600',
        ],
        'stock': 15,
        'isAvailable': true,
        'isFeatured': true,
        'isPromotion': true,
        'rating': 4.9,
        'reviewCount': 128,
        'specifications': {
          'Écran': '6.7 pouces Super Retina XDR',
          'Processeur': 'A17 Pro',
          'RAM': '8 Go',
          'Stockage': '256 Go',
          'Caméra': '48 MP + 12 MP + 12 MP',
          'Batterie': '4422 mAh',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Samsung Galaxy S24 Ultra',
        'description': 'Le flagship Samsung avec S Pen intégré, écran Dynamic AMOLED 2X et zoom optique 5x.',
        'price': 750000,
        'originalPrice': 850000,
        'categoryId': 'smartphones',
        'brand': 'Samsung',
        'imageUrl': 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600',
        'images': [
          'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600',
        ],
        'stock': 20,
        'isAvailable': true,
        'isFeatured': true,
        'isPromotion': true,
        'rating': 4.8,
        'reviewCount': 95,
        'specifications': {
          'Écran': '6.8 pouces Dynamic AMOLED 2X',
          'Processeur': 'Snapdragon 8 Gen 3',
          'RAM': '12 Go',
          'Stockage': '256 Go',
          'Caméra': '200 MP + 50 MP + 12 MP + 10 MP',
          'Batterie': '5000 mAh',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'iPhone 14',
        'description': 'Performance exceptionnelle avec la puce A15 Bionic et un excellent système photo.',
        'price': 550000,
        'originalPrice': 650000,
        'categoryId': 'smartphones',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600',
        'images': [
          'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600',
        ],
        'stock': 25,
        'isAvailable': true,
        'isFeatured': false,
        'isPromotion': true,
        'rating': 4.7,
        'reviewCount': 234,
        'specifications': {
          'Écran': '6.1 pouces Super Retina XDR',
          'Processeur': 'A15 Bionic',
          'RAM': '6 Go',
          'Stockage': '128 Go',
          'Caméra': '12 MP + 12 MP',
          'Batterie': '3279 mAh',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Samsung Galaxy A54',
        'description': 'Excellent rapport qualité-prix avec écran Super AMOLED et triple caméra.',
        'price': 280000,
        'originalPrice': 320000,
        'categoryId': 'smartphones',
        'brand': 'Samsung',
        'imageUrl': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600',
        'images': [
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600',
        ],
        'stock': 40,
        'isAvailable': true,
        'isFeatured': false,
        'isPromotion': false,
        'rating': 4.5,
        'reviewCount': 156,
        'specifications': {
          'Écran': '6.4 pouces Super AMOLED',
          'Processeur': 'Exynos 1380',
          'RAM': '8 Go',
          'Stockage': '128 Go',
          'Caméra': '50 MP + 12 MP + 5 MP',
          'Batterie': '5000 mAh',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Accessoires
      {
        'name': 'AirPods Pro 2',
        'description': 'Écouteurs sans fil avec réduction de bruit active et audio spatial personnalisé.',
        'price': 150000,
        'originalPrice': 180000,
        'categoryId': 'accessories',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=600',
        'images': [
          'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=600',
        ],
        'stock': 30,
        'isAvailable': true,
        'isFeatured': true,
        'isPromotion': false,
        'rating': 4.8,
        'reviewCount': 89,
        'specifications': {
          'Type': 'Intra-auriculaires',
          'Réduction de bruit': 'Active',
          'Autonomie': '6h (30h avec boîtier)',
          'Résistance': 'IPX4',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Chargeur MagSafe 15W',
        'description': 'Chargeur sans fil magnétique pour iPhone avec charge rapide 15W.',
        'price': 35000,
        'originalPrice': 45000,
        'categoryId': 'accessories',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1628815113969-0487917f7a68?w=600',
        'images': [
          'https://images.unsplash.com/photo-1628815113969-0487917f7a68?w=600',
        ],
        'stock': 50,
        'isAvailable': true,
        'isFeatured': false,
        'isPromotion': true,
        'rating': 4.6,
        'reviewCount': 67,
        'specifications': {
          'Puissance': '15W',
          'Type': 'Sans fil magnétique',
          'Compatibilité': 'iPhone 12 et ultérieur',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Coque iPhone 15 Pro',
        'description': 'Coque de protection en silicone avec MagSafe intégré.',
        'price': 25000,
        'originalPrice': 30000,
        'categoryId': 'accessories',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600',
        'images': [
          'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600',
        ],
        'stock': 100,
        'isAvailable': true,
        'isFeatured': false,
        'isPromotion': false,
        'rating': 4.4,
        'reviewCount': 45,
        'specifications': {
          'Matériau': 'Silicone',
          'MagSafe': 'Oui',
          'Couleur': 'Noir',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Tablettes
      {
        'name': 'iPad Pro 12.9" M2',
        'description': 'La tablette la plus puissante avec puce M2, écran Liquid Retina XDR et compatibilité Apple Pencil.',
        'price': 800000,
        'originalPrice': 900000,
        'categoryId': 'tablets',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600',
        'images': [
          'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600',
        ],
        'stock': 10,
        'isAvailable': true,
        'isFeatured': true,
        'isPromotion': false,
        'rating': 4.9,
        'reviewCount': 56,
        'specifications': {
          'Écran': '12.9 pouces Liquid Retina XDR',
          'Processeur': 'Apple M2',
          'RAM': '8 Go',
          'Stockage': '256 Go',
          'Caméra': '12 MP + 10 MP',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Samsung Galaxy Tab S9',
        'description': 'Tablette Android haut de gamme avec S Pen inclus et écran Dynamic AMOLED.',
        'price': 500000,
        'originalPrice': 580000,
        'categoryId': 'tablets',
        'brand': 'Samsung',
        'imageUrl': 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=600',
        'images': [
          'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=600',
        ],
        'stock': 15,
        'isAvailable': true,
        'isFeatured': false,
        'isPromotion': true,
        'rating': 4.7,
        'reviewCount': 43,
        'specifications': {
          'Écran': '11 pouces Dynamic AMOLED 2X',
          'Processeur': 'Snapdragon 8 Gen 2',
          'RAM': '8 Go',
          'Stockage': '128 Go',
          'S Pen': 'Inclus',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Montres
      {
        'name': 'Apple Watch Ultra 2',
        'description': 'La montre connectée la plus robuste d\'Apple avec GPS double fréquence et écran toujours allumé.',
        'price': 550000,
        'originalPrice': 600000,
        'categoryId': 'watches',
        'brand': 'Apple',
        'imageUrl': 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=600',
        'images': [
          'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=600',
        ],
        'stock': 8,
        'isAvailable': true,
        'isFeatured': true,
        'isPromotion': false,
        'rating': 4.9,
        'reviewCount': 34,
        'specifications': {
          'Écran': '49mm Always-On Retina',
          'Processeur': 'S9 SiP',
          'Autonomie': '36 heures',
          'Résistance': '100m étanche',
          'GPS': 'Double fréquence',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    final batch = _firestore.batch();
    for (final product in products) {
      final docRef = _firestore.collection('products').doc();
      batch.set(docRef, product);
    }
    await batch.commit();
    print('✅ ${products.length} produits créés');
  }
  
  /// Initialise complètement l'application pour un nouvel utilisateur
  static Future<InitResult> initializeApp() async {
    final result = InitResult();
    
    // 1. Vérifier si c'est la première utilisation
    result.isFirstLaunch = await isFirstLaunch();
    
    // 2. Authentification anonyme
    result.user = await ensureAuthenticated();
    
    // 3. Charger les données si nécessaire
    result.dataLoaded = await loadInitialDataIfNeeded();
    
    return result;
  }
}

/// Résultat de l'initialisation
class InitResult {
  bool isFirstLaunch = false;
  User? user;
  bool dataLoaded = false;
  
  @override
  String toString() {
    return 'InitResult(isFirstLaunch: $isFirstLaunch, user: ${user?.uid}, dataLoaded: $dataLoaded)';
  }
}
