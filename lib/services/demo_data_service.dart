import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../models/product_extensions.dart';

/// Service pour gérer les données de démonstration
/// Permet de peupler et nettoyer la base de données pour les tests
class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Identifiant pour marquer les données de démo
  static const String _demoPrefix = 'demo_';

  // ============================================================
  // CATÉGORIES DE DÉMONSTRATION
  // ============================================================

  static List<models.Category> get _demoCategories => [
    models.Category(
      id: '${_demoPrefix}cat_smartphones',
      name: 'Smartphones',
      description: 'Téléphones intelligents de toutes marques',
      imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
      iconName: 'phone_android',
      isActive: true,
      createdAt: DateTime.now(),
      productCount: 0,
    ),
    models.Category(
      id: '${_demoPrefix}cat_tablettes',
      name: 'Tablettes',
      description: 'Tablettes tactiles pour travail et loisirs',
      imageUrl: 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400',
      iconName: 'tablet_android',
      isActive: true,
      createdAt: DateTime.now(),
      productCount: 0,
    ),
    models.Category(
      id: '${_demoPrefix}cat_accessoires',
      name: 'Accessoires',
      description: 'Coques, chargeurs, écouteurs et plus',
      imageUrl: 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400',
      iconName: 'headphones',
      isActive: true,
      createdAt: DateTime.now(),
      productCount: 0,
    ),
    models.Category(
      id: '${_demoPrefix}cat_montres',
      name: 'Montres',
      description: 'Montres connectées et smartwatches',
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      iconName: 'watch',
      isActive: true,
      createdAt: DateTime.now(),
      productCount: 0,
    ),
  ];

  // ============================================================
  // PRODUITS DE DÉMONSTRATION
  // ============================================================

  static List<Product> get _demoProducts => [
    // === SMARTPHONES ===
    Product(
      id: '${_demoPrefix}iphone_15_pro',
      name: 'iPhone 15 Pro Max',
      brand: 'Apple',
      category: 'Smartphones',
      categoryId: '${_demoPrefix}cat_smartphones',
      price: 850000,
      originalPrice: 950000,
      description: 'Le dernier iPhone avec puce A17 Pro, écran Super Retina XDR et système de caméra professionnel.',
      shortDescription: 'Puissance et innovation Apple',
      imageUrls: [
        'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600',
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600',
      ],
      isInStock: true,
      stock: 15,
      supplierReference: 'APL-IP15PM-256',
      specs: {
        'Écran': '6.7" Super Retina XDR',
        'Processeur': 'A17 Pro',
        'Stockage': '256 Go',
        'RAM': '8 Go',
        'Batterie': '4422 mAh',
        'Caméra': '48 MP + 12 MP + 12 MP',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      rating: const ProductRating(average: 4.8, count: 127),
      soldCount: 89,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Garantie Apple officielle'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Produit non ouvert', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Distributeur Apple agréé'),
      highlights: ['Écran ProMotion 120Hz', 'Titane grade 5', 'USB-C', 'Action Button'],
      badges: [
        const ProductBadge(type: 'BESTSELLER', label: 'Best-seller', colorHex: '#FF6B35'),
        const ProductBadge(type: 'VERIFIED', label: 'Authentique', colorHex: '#4CAF50'),
      ],
      isFeatured: true,
    ),

    Product(
      id: '${_demoPrefix}samsung_s24_ultra',
      name: 'Samsung Galaxy S24 Ultra',
      brand: 'Samsung',
      category: 'Smartphones',
      categoryId: '${_demoPrefix}cat_smartphones',
      price: 780000,
      originalPrice: 850000,
      description: 'Le smartphone Samsung le plus puissant avec Galaxy AI, S Pen intégré et caméra 200MP.',
      shortDescription: 'L\'IA au service de votre créativité',
      imageUrls: [
        'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600',
        'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=600',
      ],
      isInStock: true,
      stock: 22,
      supplierReference: 'SAM-S24U-256',
      specs: {
        'Écran': '6.8" Dynamic AMOLED 2X',
        'Processeur': 'Snapdragon 8 Gen 3',
        'Stockage': '256 Go',
        'RAM': '12 Go',
        'Batterie': '5000 mAh',
        'Caméra': '200 MP + 12 MP + 50 MP + 10 MP',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      rating: const ProductRating(average: 4.7, count: 98),
      soldCount: 67,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 24, type: 'constructeur', coverage: 'Samsung Côte d\'Ivoire'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Produit en parfait état', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Samsung Store officiel'),
      highlights: ['Galaxy AI intégré', 'S Pen inclus', 'Cadre en titane', 'Zoom 100x'],
      badges: [
        ProductBadge.newProduct,
        const ProductBadge(type: 'TRENDING', label: 'Tendance', colorHex: '#E91E63'),
      ],
      isFeatured: true,
    ),

    Product(
      id: '${_demoPrefix}xiaomi_14',
      name: 'Xiaomi 14 Pro',
      brand: 'Xiaomi',
      category: 'Smartphones',
      categoryId: '${_demoPrefix}cat_smartphones',
      price: 450000,
      originalPrice: 520000,
      description: 'Smartphone premium avec optique Leica, écran LTPO AMOLED et charge ultra-rapide 120W.',
      shortDescription: 'Performance Leica accessible',
      imageUrls: ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600'],
      isInStock: true,
      stock: 18,
      supplierReference: 'XIA-14P-256',
      specs: {
        'Écran': '6.73" LTPO AMOLED',
        'Processeur': 'Snapdragon 8 Gen 3',
        'Stockage': '256 Go',
        'RAM': '12 Go',
        'Batterie': '4880 mAh',
        'Caméra': '50 MP Leica',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      rating: const ProductRating(average: 4.5, count: 45),
      soldCount: 34,
      shipping: const ShippingInfo(isFree: false, minDays: 2, maxDays: 4, cost: 2500),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Garantie Xiaomi'),
      returnPolicy: const ReturnPolicy(days: 7, conditions: 'Emballage d\'origine', freeReturn: false),
      authenticity: const AuthenticityInfo(verified: true, source: 'Importateur officiel'),
      highlights: ['Optique Leica', 'Charge 120W', 'HyperOS'],
      badges: [ProductBadge.promo(13)],
      isFeatured: false,
    ),

    // === ACCESSOIRES ===
    Product(
      id: '${_demoPrefix}airpods_pro_2',
      name: 'AirPods Pro 2',
      brand: 'Apple',
      category: 'Accessoires',
      categoryId: '${_demoPrefix}cat_accessoires',
      price: 175000,
      originalPrice: 195000,
      description: 'Écouteurs sans fil avec réduction de bruit active, audio spatial et boîtier MagSafe.',
      shortDescription: 'Le son Apple sans compromis',
      imageUrls: ['https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=600'],
      isInStock: true,
      stock: 35,
      supplierReference: 'APL-APP2-WHT',
      specs: {
        'Type': 'Intra-auriculaires',
        'Réduction bruit': 'Active (ANC)',
        'Autonomie': '6h (30h avec boîtier)',
        'Connectivité': 'Bluetooth 5.3',
        'Résistance': 'IPX4',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      rating: const ProductRating(average: 4.9, count: 256),
      soldCount: 189,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 1),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Apple Care'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Non utilisé', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Apple Store'),
      highlights: ['ANC 2x plus efficace', 'Audio spatial personnalisé', 'Boîtier USB-C'],
      badges: [
        const ProductBadge(type: 'BESTSELLER', label: 'Top ventes', colorHex: '#FF6B35'),
        const ProductBadge(type: 'VERIFIED', label: '100% Original', colorHex: '#4CAF50'),
      ],
      isFeatured: true,
    ),

    Product(
      id: '${_demoPrefix}samsung_buds_3',
      name: 'Galaxy Buds 3 Pro',
      brand: 'Samsung',
      category: 'Accessoires',
      categoryId: '${_demoPrefix}cat_accessoires',
      price: 125000,
      description: 'Écouteurs premium avec ANC intelligent et son Hi-Fi 24bit.',
      shortDescription: 'Audio premium Samsung',
      imageUrls: ['https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600'],
      isInStock: true,
      stock: 28,
      supplierReference: 'SAM-GB3P-SLV',
      specs: {
        'Type': 'Intra-auriculaires',
        'Réduction bruit': 'ANC adaptatif',
        'Autonomie': '7h (30h avec boîtier)',
        'Codec': 'SSC HiFi, AAC',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      rating: const ProductRating(average: 4.6, count: 78),
      soldCount: 52,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Samsung CI'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Emballage intact', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Samsung officiel'),
      highlights: ['Design Blade Lights', 'Son 24bit Hi-Fi', 'Galaxy AI'],
      badges: [ProductBadge.newProduct],
      isFeatured: false,
    ),

    Product(
      id: '${_demoPrefix}chargeur_anker',
      name: 'Chargeur Anker 100W GaN',
      brand: 'Anker',
      category: 'Accessoires',
      categoryId: '${_demoPrefix}cat_accessoires',
      price: 45000,
      originalPrice: 55000,
      description: 'Chargeur compact 100W avec technologie GaN, 3 ports USB-C et 1 USB-A.',
      shortDescription: 'Puissance compacte',
      imageUrls: ['https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=600'],
      isInStock: true,
      stock: 50,
      supplierReference: 'ANK-100W-BLK',
      specs: {
        'Puissance': '100W max',
        'Ports': '3x USB-C + 1x USB-A',
        'Technologie': 'GaN II',
        'Compatibilité': 'iPhone, Samsung, MacBook',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      rating: const ProductRating(average: 4.7, count: 134),
      soldCount: 98,
      shipping: const ShippingInfo(isFree: false, minDays: 2, maxDays: 3, cost: 1500),
      warranty: const WarrantyInfo(months: 18, type: 'constructeur', coverage: 'Garantie Anker'),
      returnPolicy: const ReturnPolicy(days: 30, conditions: 'Satisfait ou remboursé', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Distributeur Anker'),
      highlights: ['Ultra compact', '4 appareils simultanés', 'Protection intelligente'],
      badges: [
        ProductBadge.promo(18),
        const ProductBadge(type: 'POPULAR', label: 'Populaire', colorHex: '#9C27B0'),
      ],
      isFeatured: false,
    ),

    // === TABLETTES ===
    Product(
      id: '${_demoPrefix}ipad_pro_m4',
      name: 'iPad Pro M4 12.9"',
      brand: 'Apple',
      category: 'Tablettes',
      categoryId: '${_demoPrefix}cat_tablettes',
      price: 950000,
      description: 'La tablette la plus puissante avec puce M4, écran OLED tandem et Apple Pencil Pro.',
      shortDescription: 'Puissance M4, finesse OLED',
      imageUrls: ['https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600'],
      isInStock: true,
      stock: 8,
      supplierReference: 'APL-IPADM4-256',
      specs: {
        'Écran': '12.9" OLED Tandem',
        'Processeur': 'Apple M4',
        'Stockage': '256 Go',
        'RAM': '8 Go',
        'Batterie': '10h',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      rating: const ProductRating(average: 4.9, count: 42),
      soldCount: 23,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Apple Care'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Produit neuf', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Apple Store officiel'),
      highlights: ['Puce M4 révolutionnaire', 'OLED le plus fin', 'Apple Pencil Pro compatible'],
      badges: [
        ProductBadge.newProduct,
        const ProductBadge(type: 'LOW_STOCK', label: 'Stock limité', colorHex: '#FF9800'),
      ],
      isFeatured: true,
    ),

    Product(
      id: '${_demoPrefix}galaxy_tab_s9',
      name: 'Galaxy Tab S9 Ultra',
      brand: 'Samsung',
      category: 'Tablettes',
      categoryId: '${_demoPrefix}cat_tablettes',
      price: 720000,
      originalPrice: 800000,
      description: 'Tablette grand format avec écran 14.6", S Pen inclus et performances gaming.',
      shortDescription: 'L\'ultime tablette Android',
      imageUrls: ['https://images.unsplash.com/photo-1561154464-82e9adf32764?w=600'],
      isInStock: true,
      stock: 12,
      supplierReference: 'SAM-TS9U-256',
      specs: {
        'Écran': '14.6" Dynamic AMOLED 2X',
        'Processeur': 'Snapdragon 8 Gen 2',
        'Stockage': '256 Go',
        'RAM': '12 Go',
        'Batterie': '11200 mAh',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      rating: const ProductRating(average: 4.6, count: 67),
      soldCount: 41,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 24, type: 'constructeur', coverage: 'Samsung CI'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'État neuf', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Samsung Store'),
      highlights: ['Écran géant 14.6"', 'S Pen inclus', 'IP68 étanche'],
      badges: [ProductBadge.promo(10)],
      isFeatured: false,
    ),

    // === MONTRES ===
    Product(
      id: '${_demoPrefix}apple_watch_ultra',
      name: 'Apple Watch Ultra 2',
      brand: 'Apple',
      category: 'Montres',
      categoryId: '${_demoPrefix}cat_montres',
      price: 550000,
      description: 'La montre Apple la plus robuste pour les aventuriers, avec GPS double fréquence et autonomie 36h.',
      shortDescription: 'L\'aventure au poignet',
      imageUrls: ['https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=600'],
      isInStock: true,
      stock: 10,
      supplierReference: 'APL-AWU2-49',
      specs: {
        'Écran': '49mm OLED',
        'Processeur': 'S9 SiP',
        'Autonomie': '36h (72h mode éco)',
        'Résistance': '100m étanche, MIL-STD-810H',
        'GPS': 'Double fréquence L1+L5',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      rating: const ProductRating(average: 4.8, count: 89),
      soldCount: 56,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 12, type: 'constructeur', coverage: 'Apple Care'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'Non portée', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Apple Store'),
      highlights: ['Titane grade 5', 'Bouton Action', 'Double tap', 'Sirène 86 dB'],
      badges: [
        const ProductBadge(type: 'TRENDING', label: 'Tendance', colorHex: '#E91E63'),
        const ProductBadge(type: 'VERIFIED', label: 'Authentique', colorHex: '#4CAF50'),
      ],
      isFeatured: true,
    ),

    Product(
      id: '${_demoPrefix}galaxy_watch_6',
      name: 'Galaxy Watch 6 Classic',
      brand: 'Samsung',
      category: 'Montres',
      categoryId: '${_demoPrefix}cat_montres',
      price: 280000,
      originalPrice: 320000,
      description: 'Montre connectée élégante avec lunette rotative, suivi santé avancé et Wear OS.',
      shortDescription: 'Classique et connectée',
      imageUrls: ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600'],
      isInStock: true,
      stock: 25,
      supplierReference: 'SAM-GW6C-47',
      specs: {
        'Écran': '1.5" Super AMOLED',
        'Processeur': 'Exynos W930',
        'Autonomie': '40h',
        'Résistance': '5ATM + IP68',
        'OS': 'Wear OS 4',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      rating: const ProductRating(average: 4.5, count: 112),
      soldCount: 78,
      shipping: const ShippingInfo(isFree: true, minDays: 1, maxDays: 2),
      warranty: const WarrantyInfo(months: 24, type: 'constructeur', coverage: 'Samsung CI'),
      returnPolicy: const ReturnPolicy(days: 14, conditions: 'État neuf', freeReturn: true),
      authenticity: const AuthenticityInfo(verified: true, source: 'Samsung officiel'),
      highlights: ['Lunette rotative physique', 'BioActive Sensor', 'Suivi sommeil avancé'],
      badges: [
        ProductBadge.promo(12),
        const ProductBadge(type: 'POPULAR', label: 'Populaire', colorHex: '#9C27B0'),
      ],
      isFeatured: false,
    ),
  ];

  // ============================================================
  // MÉTHODES PUBLIQUES
  // ============================================================

  /// Peupler la base de données avec les données de démo
  static Future<DemoDataResult> seedDemoData({
    Function(String message, double progress)? onProgress,
  }) async {
    int categoriesAdded = 0;
    int productsAdded = 0;
    final List<String> errors = [];

    try {
      // 1. Récupérer les catégories existantes
      onProgress?.call('Vérification des catégories existantes...', 0.05);
      final existingCatsSnapshot = await _firestore.collection('categories').get();
      final existingCategoryNames = <String, String>{}; // nom -> id
      for (final doc in existingCatsSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        if (name.isNotEmpty) {
          existingCategoryNames[name.toLowerCase()] = doc.id;
        }
      }

      // 2. Ajouter seulement les catégories qui n'existent pas
      onProgress?.call('Ajout des catégories manquantes...', 0.1);
      final categoryIdMap = <String, String>{}; // demo_id -> real_id
      
      for (final category in _demoCategories) {
        final normalizedName = category.name.toLowerCase();
        if (existingCategoryNames.containsKey(normalizedName)) {
          // La catégorie existe déjà, on utilise son ID
          categoryIdMap[category.id] = existingCategoryNames[normalizedName]!;
          debugPrint('✓ Catégorie "${category.name}" existe déjà');
        } else {
          // Créer la nouvelle catégorie
          try {
            await _firestore.collection('categories').doc(category.id).set(category.toMap());
            categoryIdMap[category.id] = category.id;
            categoriesAdded++;
            debugPrint('+ Catégorie "${category.name}" créée');
          } catch (e) {
            errors.add('Catégorie ${category.name}: $e');
          }
        }
      }

      // 3. Ajouter les produits avec les bons IDs de catégorie
      onProgress?.call('Ajout des produits...', 0.3);
      final products = _demoProducts;
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        try {
          // Remapper le categoryId vers la vraie catégorie
          final realCategoryId = categoryIdMap[product.categoryId] ?? product.categoryId;
          final productWithRealCategory = Product(
            id: product.id,
            name: product.name,
            brand: product.brand,
            category: product.category,
            categoryId: realCategoryId,
            price: product.price,
            originalPrice: product.originalPrice,
            description: product.description,
            shortDescription: product.shortDescription,
            imageUrls: product.imageUrls,
            isInStock: product.isInStock,
            stock: product.stock,
            specs: product.specs,
            createdAt: product.createdAt,
            isFeatured: product.isFeatured,
            rating: product.rating,
            shipping: product.shipping,
            warranty: product.warranty,
            returnPolicy: product.returnPolicy,
            badges: product.badges,
          );
          
          await _firestore.collection('products').doc(product.id).set(productWithRealCategory.toMap());
          productsAdded++;
          onProgress?.call(
            'Produit ${i + 1}/${products.length}: ${product.name}',
            0.3 + (0.6 * (i + 1) / products.length),
          );
        } catch (e) {
          errors.add('Produit ${product.name}: $e');
        }
      }

      // 4. Mettre à jour le compteur de produits par catégorie
      onProgress?.call('Mise à jour des compteurs...', 0.95);
      await _updateCategoryProductCounts();

      onProgress?.call('Terminé !', 1.0);

      return DemoDataResult(
        success: true,
        categoriesAdded: categoriesAdded,
        productsAdded: productsAdded,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Erreur seedDemoData: $e');
      return DemoDataResult(
        success: false,
        categoriesAdded: categoriesAdded,
        productsAdded: productsAdded,
        errors: [...errors, 'Erreur générale: $e'],
      );
    }
  }

  /// Supprimer toutes les données de démo
  static Future<DemoDataResult> clearDemoData({
    Function(String message, double progress)? onProgress,
  }) async {
    int categoriesDeleted = 0;
    int productsDeleted = 0;
    final List<String> errors = [];

    try {
      // 1. Supprimer les produits de démo (ceux dont l'ID commence par demo_)
      onProgress?.call('Suppression des produits...', 0.1);
      final productsSnapshot = await _firestore.collection('products').get();

      for (final doc in productsSnapshot.docs) {
        if (doc.id.startsWith(_demoPrefix)) {
          try {
            await doc.reference.delete();
            productsDeleted++;
            debugPrint('🗑️ Produit supprimé: ${doc.id}');
          } catch (e) {
            errors.add('Suppression produit ${doc.id}: $e');
          }
        }
      }
      onProgress?.call('$productsDeleted produits supprimés', 0.5);

      // 2. Supprimer les catégories de démo (celles dont l'ID commence par demo_)
      onProgress?.call('Suppression des catégories...', 0.6);
      final categoriesSnapshot = await _firestore.collection('categories').get();

      for (final doc in categoriesSnapshot.docs) {
        if (doc.id.startsWith(_demoPrefix)) {
          try {
            await doc.reference.delete();
            categoriesDeleted++;
            debugPrint('🗑️ Catégorie supprimée: ${doc.id}');
          } catch (e) {
            errors.add('Suppression catégorie ${doc.id}: $e');
          }
        }
      }

      // 3. Mettre à jour les compteurs de catégories
      onProgress?.call('Mise à jour des compteurs...', 0.9);
      await _updateCategoryProductCounts();

      onProgress?.call('Terminé !', 1.0);

      return DemoDataResult(
        success: true,
        categoriesAdded: categoriesDeleted,
        productsAdded: productsDeleted,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Erreur clearDemoData: $e');
      return DemoDataResult(
        success: false,
        categoriesAdded: categoriesDeleted,
        productsAdded: productsDeleted,
        errors: [...errors, 'Erreur générale: $e'],
      );
    }
  }

  /// Supprimer TOUTES les données (attention !)
  static Future<DemoDataResult> clearAllData({
    Function(String message, double progress)? onProgress,
  }) async {
    int categoriesDeleted = 0;
    int productsDeleted = 0;
    final List<String> errors = [];

    try {
      // 1. Supprimer tous les produits
      onProgress?.call('Suppression de tous les produits...', 0.1);
      final productsSnapshot = await _firestore.collection('products').get();
      
      for (final doc in productsSnapshot.docs) {
        try {
          await doc.reference.delete();
          productsDeleted++;
        } catch (e) {
          errors.add('Produit ${doc.id}: $e');
        }
      }
      onProgress?.call('$productsDeleted produits supprimés', 0.5);

      // 2. Supprimer toutes les catégories
      onProgress?.call('Suppression de toutes les catégories...', 0.6);
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      for (final doc in categoriesSnapshot.docs) {
        try {
          await doc.reference.delete();
          categoriesDeleted++;
        } catch (e) {
          errors.add('Catégorie ${doc.id}: $e');
        }
      }

      // 3. Supprimer les promotions
      onProgress?.call('Suppression des promotions...', 0.8);
      final promosSnapshot = await _firestore.collection('promotions').get();
      for (final doc in promosSnapshot.docs) {
        await doc.reference.delete();
      }

      onProgress?.call('Terminé !', 1.0);

      return DemoDataResult(
        success: true,
        categoriesAdded: categoriesDeleted,
        productsAdded: productsDeleted,
        errors: errors,
      );
    } catch (e) {
      return DemoDataResult(
        success: false,
        categoriesAdded: categoriesDeleted,
        productsAdded: productsDeleted,
        errors: [...errors, 'Erreur: $e'],
      );
    }
  }

  /// Vérifier si des données de démo existent
  static Future<bool> hasDemoData() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: _demoPrefix)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // MÉTHODES PRIVÉES
  // ============================================================

  /// Met à jour le compteur de produits pour TOUTES les catégories
  static Future<void> _updateCategoryProductCounts() async {
    try {
      // Récupérer toutes les catégories
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      for (final categoryDoc in categoriesSnapshot.docs) {
        final categoryId = categoryDoc.id;
        final categoryName = categoryDoc.data()['name'] as String? ?? '';
        
        // Compter les produits par categoryId OU par nom de catégorie
        final countById = await _firestore
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .count()
            .get();
        
        final countByName = await _firestore
            .collection('products')
            .where('category', isEqualTo: categoryName)
            .count()
            .get();
        
        // Prendre le maximum des deux (au cas où certains produits utilisent categoryId et d'autres category)
        final totalCount = (countById.count ?? 0) > (countByName.count ?? 0) 
            ? (countById.count ?? 0) 
            : (countByName.count ?? 0);
        
        await _firestore.collection('categories').doc(categoryId).update({
          'productCount': totalCount,
        });
        
        debugPrint('📊 Catégorie "$categoryName": $totalCount produits');
      }
    } catch (e) {
      debugPrint('Erreur mise à jour compteurs: $e');
    }
  }
}

/// Résultat d'une opération de données de démo
class DemoDataResult {
  final bool success;
  final int categoriesAdded;
  final int productsAdded;
  final List<String> errors;

  DemoDataResult({
    required this.success,
    required this.categoriesAdded,
    required this.productsAdded,
    this.errors = const [],
  });

  String get summary {
    if (success) {
      return '$categoriesAdded catégories, $productsAdded produits';
    } else {
      return 'Erreur: ${errors.join(", ")}';
    }
  }
}
