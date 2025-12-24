import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';

/// Configuration des seuils pour les badges dynamiques
class BadgeThresholds {
  /// Seuil de ventes pour le badge "Best-seller"
  final int bestSellerSales;

  /// Seuil de ventes pour le badge "Populaire"
  final int popularSales;

  /// Nombre de jours pour considérer un produit comme "Nouveau"
  final int newProductDays;

  /// Note minimale pour le badge "Top noté"
  final double topRatedMinRating;

  /// Nombre minimum d'avis pour "Top noté"
  final int topRatedMinReviews;

  /// Pourcentage minimum de réduction pour badge "Promo"
  final int promoMinPercent;

  /// Seuil de stock pour "Stock limité"
  final int lowStockThreshold;

  /// Seuil de stock pour "Dernières pièces"
  final int lastItemsThreshold;

  /// Nombre de ventes récentes (7 jours) pour "Tendance"
  final int trendingSalesWeek;

  const BadgeThresholds({
    this.bestSellerSales = 100,
    this.popularSales = 50,
    this.newProductDays = 30,
    this.topRatedMinRating = 4.5,
    this.topRatedMinReviews = 10,
    this.promoMinPercent = 10,
    this.lowStockThreshold = 10,
    this.lastItemsThreshold = 3,
    this.trendingSalesWeek = 20,
  });

  /// Seuils par défaut pour le marché africain
  static const BadgeThresholds defaultAfrica = BadgeThresholds(
    bestSellerSales: 50,    // Marché plus petit
    popularSales: 20,
    newProductDays: 30,
    topRatedMinRating: 4.3,
    topRatedMinReviews: 5,
    promoMinPercent: 10,
    lowStockThreshold: 5,
    lastItemsThreshold: 2,
    trendingSalesWeek: 10,
  );

  /// Seuils agressifs pour booster les conversions
  static const BadgeThresholds aggressive = BadgeThresholds(
    bestSellerSales: 30,
    popularSales: 10,
    newProductDays: 45,
    topRatedMinRating: 4.0,
    topRatedMinReviews: 3,
    promoMinPercent: 5,
    lowStockThreshold: 15,
    lastItemsThreshold: 5,
    trendingSalesWeek: 5,
  );
}

/// Types de badges dynamiques
enum DynamicBadgeType {
  /// Produit ajouté récemment
  newProduct,

  /// Beaucoup de ventes
  bestSeller,

  /// Ventes modérées
  popular,

  /// En promotion
  promo,

  /// Très bien noté
  topRated,

  /// Produit vérifié/authentique
  verified,

  /// Stock limité (urgence)
  lowStock,

  /// Dernières pièces (forte urgence)
  lastItems,

  /// Tendance (ventes récentes élevées)
  trending,

  /// Livraison gratuite
  freeShipping,

  /// Exclusivité web
  exclusive,

  /// Recommandé
  recommended,
}

/// Résultat de l'analyse des badges pour un produit
class BadgeAnalysis {
  final String productId;
  final List<ProductBadge> badges;
  final Map<DynamicBadgeType, bool> qualifications;
  final Map<String, dynamic> metrics;
  final DateTime analyzedAt;

  BadgeAnalysis({
    required this.productId,
    required this.badges,
    required this.qualifications,
    required this.metrics,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// Nombre de badges qualifiés
  int get badgeCount => badges.length;

  /// A le badge best-seller
  bool get isBestSeller =>
      qualifications[DynamicBadgeType.bestSeller] ?? false;

  /// A le badge nouveau
  bool get isNew => qualifications[DynamicBadgeType.newProduct] ?? false;

  /// A le badge promo
  bool get hasPromo => qualifications[DynamicBadgeType.promo] ?? false;

  /// A le badge top noté
  bool get isTopRated => qualifications[DynamicBadgeType.topRated] ?? false;

  /// A le badge stock limité
  bool get hasLowStock => qualifications[DynamicBadgeType.lowStock] ?? false;

  @override
  String toString() {
    return 'BadgeAnalysis(productId: $productId, badges: ${badges.length}, '
        'qualifications: ${qualifications.entries.where((e) => e.value).map((e) => e.key.name).join(", ")})';
  }
}

/// Service pour générer automatiquement les badges basés sur les métriques
class DynamicBadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Configuration des seuils (peut être modifiée)
  static BadgeThresholds thresholds = BadgeThresholds.defaultAfrica;

  /// Analyser un produit et déterminer ses badges
  static BadgeAnalysis analyzeProduct(
    Product product, {
    DateTime? referenceDate,
    int? recentSalesCount,
  }) {
    final now = referenceDate ?? DateTime.now();
    final qualifications = <DynamicBadgeType, bool>{};
    final badges = <ProductBadge>[];
    final metrics = <String, dynamic>{};

    // 1. Badge NOUVEAU - basé sur la date de création
    final daysSinceCreation = now.difference(product.createdAt).inDays;
    metrics['daysSinceCreation'] = daysSinceCreation;
    qualifications[DynamicBadgeType.newProduct] =
        daysSinceCreation <= thresholds.newProductDays;

    if (qualifications[DynamicBadgeType.newProduct]!) {
      badges.add(ProductBadge.newProduct);
    }

    // 2. Badge BEST-SELLER - basé sur le nombre de ventes
    metrics['soldCount'] = product.soldCount;
    qualifications[DynamicBadgeType.bestSeller] =
        product.soldCount >= thresholds.bestSellerSales;
    qualifications[DynamicBadgeType.popular] =
        product.soldCount >= thresholds.popularSales &&
            !qualifications[DynamicBadgeType.bestSeller]!;

    if (qualifications[DynamicBadgeType.bestSeller]!) {
      badges.add(ProductBadge.bestSeller);
    } else if (qualifications[DynamicBadgeType.popular]!) {
      badges.add(const ProductBadge(
        type: 'POPULAR',
        label: 'Populaire',
        colorHex: '#8B5CF6',
        priority: 3,
      ));
    }

    // 3. Badge PROMO - basé sur le prix original vs actuel
    final discountPercent = product.discountPercent ?? 0;
    metrics['discountPercent'] = discountPercent;
    qualifications[DynamicBadgeType.promo] =
        discountPercent >= thresholds.promoMinPercent;

    if (qualifications[DynamicBadgeType.promo]!) {
      badges.add(ProductBadge.promo(discountPercent));
    }

    // 4. Badge TOP NOTÉ - basé sur la note et le nombre d'avis
    final ratingAvg = product.rating?.average ?? 0.0;
    final ratingCount = product.rating?.count ?? 0;
    metrics['rating'] = ratingAvg;
    metrics['reviewCount'] = ratingCount;
    qualifications[DynamicBadgeType.topRated] =
        ratingAvg >= thresholds.topRatedMinRating &&
            ratingCount >= thresholds.topRatedMinReviews;

    if (qualifications[DynamicBadgeType.topRated]!) {
      badges.add(const ProductBadge(
        type: 'TOP_RATED',
        label: 'Top noté',
        colorHex: '#FBBF24',
        priority: 4,
      ));
    }

    // 5. Badge VÉRIFIÉ - basé sur l'authenticité
    qualifications[DynamicBadgeType.verified] = product.authenticity.verified;
    if (qualifications[DynamicBadgeType.verified]!) {
      badges.add(ProductBadge.verified);
    }

    // 6. Badge STOCK LIMITÉ / DERNIÈRES PIÈCES - basé sur le stock
    metrics['stock'] = product.stock;
    qualifications[DynamicBadgeType.lastItems] =
        product.stock > 0 && product.stock <= thresholds.lastItemsThreshold;
    qualifications[DynamicBadgeType.lowStock] =
        product.stock > thresholds.lastItemsThreshold &&
            product.stock <= thresholds.lowStockThreshold;

    if (qualifications[DynamicBadgeType.lastItems]!) {
      badges.add(ProductBadge(
        type: 'LAST_ITEMS',
        label: 'Plus que ${product.stock}!',
        colorHex: '#DC2626',
        priority: 1,
      ));
    } else if (qualifications[DynamicBadgeType.lowStock]!) {
      badges.add(const ProductBadge(
        type: 'LOW_STOCK',
        label: 'Stock limité',
        colorHex: '#F59E0B',
        priority: 2,
      ));
    }

    // 7. Badge TENDANCE - basé sur les ventes récentes
    if (recentSalesCount != null) {
      metrics['recentSales'] = recentSalesCount;
      qualifications[DynamicBadgeType.trending] =
          recentSalesCount >= thresholds.trendingSalesWeek;

      if (qualifications[DynamicBadgeType.trending]!) {
        badges.add(const ProductBadge(
          type: 'TRENDING',
          label: '🔥 Tendance',
          colorHex: '#F97316',
          priority: 2,
        ));
      }
    }

    // 8. Badge LIVRAISON GRATUITE
    qualifications[DynamicBadgeType.freeShipping] = product.shipping.isFree;
    if (qualifications[DynamicBadgeType.freeShipping]!) {
      badges.add(const ProductBadge(
        type: 'FREE_SHIPPING',
        label: 'Livraison gratuite',
        colorHex: '#10B981',
        priority: 5,
      ));
    }

    // Trier les badges par priorité
    badges.sort((a, b) => a.priority.compareTo(b.priority));

    return BadgeAnalysis(
      productId: product.id,
      badges: badges,
      qualifications: qualifications,
      metrics: metrics,
    );
  }

  /// Mettre à jour les badges d'un produit dans Firestore
  static Future<void> updateProductBadges(String productId) async {
    try {
      // Récupérer le produit
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        debugPrint('❌ Produit non trouvé: $productId');
        return;
      }

      final product = Product.fromMap(doc.data()!, doc.id);

      // Récupérer les ventes récentes (7 derniers jours)
      final recentSales = await _getRecentSalesCount(productId, days: 7);

      // Analyser les badges
      final analysis = analyzeProduct(product, recentSalesCount: recentSales);

      // Mettre à jour Firestore
      await _firestore.collection('products').doc(productId).update({
        'badges': analysis.badges.map((b) => b.toMap()).toList(),
        'badgesUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Badges mis à jour pour $productId: ${analysis.badgeCount} badges');
      debugPrint('   ${analysis.badges.map((b) => b.label).join(', ')}');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour badges: $e');
      rethrow;
    }
  }

  /// Mettre à jour les badges de tous les produits
  static Future<Map<String, int>> updateAllProductBadges({
    void Function(int current, int total)? onProgress,
  }) async {
    final stats = <String, int>{
      'total': 0,
      'updated': 0,
      'errors': 0,
    };

    try {
      final productsSnapshot = await _firestore.collection('products').get();
      stats['total'] = productsSnapshot.docs.length;

      for (int i = 0; i < productsSnapshot.docs.length; i++) {
        final doc = productsSnapshot.docs[i];
        try {
          await updateProductBadges(doc.id);
          stats['updated'] = stats['updated']! + 1;
        } catch (e) {
          debugPrint('❌ Erreur pour ${doc.id}: $e');
          stats['errors'] = stats['errors']! + 1;
        }

        onProgress?.call(i + 1, stats['total']!);
      }

      debugPrint('✅ Mise à jour terminée: ${stats['updated']}/${stats['total']} produits');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour globale: $e');
    }

    return stats;
  }

  /// Obtenir le nombre de ventes récentes d'un produit
  static Future<int> _getRecentSalesCount(String productId,
      {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .where('status', whereIn: ['confirmed', 'shipped', 'delivered']).get();

      int salesCount = 0;
      for (final doc in ordersSnapshot.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          if (item['productId'] == productId) {
            salesCount += (item['quantity'] as int? ?? 1);
          }
        }
      }

      return salesCount;
    } catch (e) {
      debugPrint('⚠️ Erreur calcul ventes récentes: $e');
      return 0;
    }
  }

  /// Incrémenter le compteur de ventes lors d'une commande
  static Future<void> incrementSoldCount(
    String productId, {
    int quantity = 1,
  }) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'soldCount': FieldValue.increment(quantity),
      });

      // Recalculer les badges après la vente
      await updateProductBadges(productId);
    } catch (e) {
      debugPrint('❌ Erreur incrémentation ventes: $e');
    }
  }

  /// Obtenir les produits best-sellers
  static Future<List<Product>> getBestSellers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('soldCount', isGreaterThanOrEqualTo: thresholds.bestSellerSales)
          .orderBy('soldCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération best-sellers: $e');
      return [];
    }
  }

  /// Obtenir les produits tendance
  static Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    try {
      // Récupérer les produits avec le plus de ventes récentes
      final startDate = DateTime.now().subtract(const Duration(days: 7));

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .where('status', whereIn: ['confirmed', 'shipped', 'delivered']).get();

      // Compter les ventes par produit
      final salesByProduct = <String, int>{};
      for (final doc in ordersSnapshot.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final productId = item['productId'] as String?;
          if (productId != null) {
            salesByProduct[productId] =
                (salesByProduct[productId] ?? 0) + (item['quantity'] as int? ?? 1);
          }
        }
      }

      // Trier par nombre de ventes
      final sortedProductIds = salesByProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Récupérer les produits
      final topProductIds = sortedProductIds.take(limit).map((e) => e.key).toList();
      
      if (topProductIds.isEmpty) return [];

      final productsSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: topProductIds)
          .get();

      final products = productsSnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();

      // Trier dans l'ordre des ventes
      products.sort((a, b) {
        final salesA = salesByProduct[a.id] ?? 0;
        final salesB = salesByProduct[b.id] ?? 0;
        return salesB.compareTo(salesA);
      });

      return products;
    } catch (e) {
      debugPrint('❌ Erreur récupération tendances: $e');
      return [];
    }
  }

  /// Obtenir les nouveaux produits
  static Future<List<Product>> getNewProducts({int limit = 10}) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: thresholds.newProductDays));

      final snapshot = await _firestore
          .collection('products')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération nouveautés: $e');
      return [];
    }
  }

  /// Obtenir les produits en promotion
  static Future<List<Product>> getPromoProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('originalPrice', isGreaterThan: 0)
          .limit(limit * 2) // Récupérer plus pour filtrer
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((p) => (p.discountPercent ?? 0) >= thresholds.promoMinPercent)
          .take(limit)
          .toList();

      // Trier par % de réduction
      products.sort((a, b) =>
          (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));

      return products;
    } catch (e) {
      debugPrint('❌ Erreur récupération promos: $e');
      return [];
    }
  }

  /// Obtenir les produits top notés
  static Future<List<Product>> getTopRatedProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('rating.average',
              isGreaterThanOrEqualTo: thresholds.topRatedMinRating)
          .orderBy('rating.average', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération top notés: $e');
      return [];
    }
  }

  /// Planifier la mise à jour automatique des badges (à appeler périodiquement)
  static Future<void> scheduleBadgeUpdate() async {
    debugPrint('🔄 Mise à jour planifiée des badges...');
    await updateAllProductBadges();
  }
}
