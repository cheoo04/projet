import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';

/// Provider pour gérer les promotions et calculer les prix effectifs
class PromotionProvider extends ChangeNotifier {
  final PromotionService _service = PromotionService();
  
  List<Promotion> _promotions = [];
  Map<String, List<Promotion>> _productPromotionsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Promotion> get promotions => _promotions;
  List<Promotion> get activePromotions => _promotions.where((p) => p.isCurrentlyActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charger toutes les promotions
  Future<void> loadPromotions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _promotions = await _service.fetchAll();
      _buildProductPromotionsCache();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur chargement promotions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Construire le cache des promotions par produit
  void _buildProductPromotionsCache() {
    _productPromotionsCache.clear();
    
    for (final promo in _promotions) {
      if (!promo.isCurrentlyActive) continue;
      
      // Ajouter la promo pour chaque produit concerné
      for (final productId in promo.productIds) {
        _productPromotionsCache.putIfAbsent(productId, () => []);
        _productPromotionsCache[productId]!.add(promo);
      }
    }
  }

  /// Obtenir les promotions actives pour un produit
  List<Promotion> getPromotionsForProduct(String productId) {
    return _productPromotionsCache[productId] ?? [];
  }

  /// Obtenir la meilleure promotion pour un produit (la plus avantageuse)
  Promotion? getBestPromotionForProduct(Product product) {
    final promos = getPromotionsForProduct(product.id);
    if (promos.isEmpty) return null;

    // Trouver la promo qui donne le prix le plus bas
    Promotion? best;
    double lowestPrice = product.price;

    for (final promo in promos) {
      final discountedPrice = promo.calculateDiscountedPrice(product.price);
      if (discountedPrice < lowestPrice) {
        lowestPrice = discountedPrice;
        best = promo;
      }
    }

    return best;
  }

  /// Calculer le prix effectif d'un produit (avec la meilleure promo)
  double getEffectivePrice(Product product) {
    final bestPromo = getBestPromotionForProduct(product);
    if (bestPromo != null) {
      return bestPromo.calculateDiscountedPrice(product.price);
    }
    // Fallback sur originalPrice si défini manuellement
    return product.price;
  }

  /// Obtenir le prix original (avant toute promo)
  double getOriginalPrice(Product product) {
    // Si originalPrice est défini manuellement, l'utiliser
    if (product.originalPrice != null && product.originalPrice! > product.price) {
      return product.originalPrice!;
    }
    // Sinon, vérifier si une promo s'applique
    final bestPromo = getBestPromotionForProduct(product);
    if (bestPromo != null) {
      return product.price; // Le prix actuel devient le prix original
    }
    return product.price;
  }

  /// Vérifier si un produit a une promotion active
  bool hasActivePromotion(Product product) {
    // Promo manuelle (originalPrice > price)
    if (product.originalPrice != null && product.originalPrice! > product.price) {
      return true;
    }
    // Promo du système
    return getPromotionsForProduct(product.id).isNotEmpty;
  }

  /// Obtenir le pourcentage de réduction
  int? getDiscountPercent(Product product) {
    // Priorité à la promo manuelle
    if (product.originalPrice != null && product.originalPrice! > product.price) {
      return product.discountPercent;
    }
    
    // Sinon, calculer depuis la promo système
    final bestPromo = getBestPromotionForProduct(product);
    if (bestPromo != null && bestPromo.type == 'percentage') {
      return bestPromo.value.round();
    } else if (bestPromo != null && bestPromo.type == 'fixed') {
      return ((bestPromo.value / product.price) * 100).round();
    }
    
    return null;
  }

  /// Obtenir le texte de la réduction
  String? getDiscountText(Product product) {
    final percent = getDiscountPercent(product);
    if (percent != null && percent > 0) {
      return '-$percent%';
    }
    return null;
  }

  /// Lier un produit à une promotion
  Future<void> linkProductToPromotion(String productId, String promotionId) async {
    try {
      final promoIndex = _promotions.indexWhere((p) => p.id == promotionId);
      if (promoIndex == -1) return;

      final promo = _promotions[promoIndex];
      if (!promo.productIds.contains(productId)) {
        promo.productIds.add(productId);
        await _service.update(promo);
        _buildProductPromotionsCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur liaison produit-promo: $e');
    }
  }

  /// Délier un produit d'une promotion
  Future<void> unlinkProductFromPromotion(String productId, String promotionId) async {
    try {
      final promoIndex = _promotions.indexWhere((p) => p.id == promotionId);
      if (promoIndex == -1) return;

      final promo = _promotions[promoIndex];
      if (promo.productIds.contains(productId)) {
        promo.productIds.remove(productId);
        await _service.update(promo);
        _buildProductPromotionsCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur déliaison produit-promo: $e');
    }
  }

  /// Lier plusieurs produits à une promotion
  Future<void> linkProductsToPromotion(List<String> productIds, String promotionId) async {
    try {
      final promoIndex = _promotions.indexWhere((p) => p.id == promotionId);
      if (promoIndex == -1) return;

      final promo = _promotions[promoIndex];
      for (final productId in productIds) {
        if (!promo.productIds.contains(productId)) {
          promo.productIds.add(productId);
        }
      }
      await _service.update(promo);
      _buildProductPromotionsCache();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur liaison produits-promo: $e');
    }
  }

  /// Créer une nouvelle promotion
  Future<void> createPromotion(Promotion promotion) async {
    try {
      await _service.add(promotion);
      _promotions.add(promotion);
      _buildProductPromotionsCache();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur création promotion: $e');
      rethrow;
    }
  }

  /// Mettre à jour une promotion
  Future<void> updatePromotion(Promotion promotion) async {
    try {
      await _service.update(promotion);
      final index = _promotions.indexWhere((p) => p.id == promotion.id);
      if (index != -1) {
        _promotions[index] = promotion;
      }
      _buildProductPromotionsCache();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur mise à jour promotion: $e');
      rethrow;
    }
  }

  /// Supprimer une promotion
  Future<void> deletePromotion(String promotionId) async {
    try {
      await _service.delete(promotionId);
      _promotions.removeWhere((p) => p.id == promotionId);
      _buildProductPromotionsCache();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur suppression promotion: $e');
      rethrow;
    }
  }
}
