import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_extensions.dart';

/// Service pour enrichir les produits existants avec les nouveaux champs
/// de signaux de confiance
class ProductEnrichmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enrichir un produit existant avec des données de confiance
  static Future<void> enrichProduct(
    String productId, {
    double? originalPrice,
    ProductRating? rating,
    int? soldCount,
    ShippingInfo? shipping,
    WarrantyInfo? warranty,
    ReturnPolicy? returnPolicy,
    AuthenticityInfo? authenticity,
    List<String>? highlights,
    String? shortDescription,
    bool? isFeatured,
  }) async {
    final updates = <String, dynamic>{};

    if (originalPrice != null) updates['originalPrice'] = originalPrice;
    if (rating != null) updates['rating'] = rating.toMap();
    if (soldCount != null) updates['soldCount'] = soldCount;
    if (shipping != null) updates['shipping'] = shipping.toMap();
    if (warranty != null) updates['warranty'] = warranty.toMap();
    if (returnPolicy != null) updates['returnPolicy'] = returnPolicy.toMap();
    if (authenticity != null) updates['authenticity'] = authenticity.toMap();
    if (highlights != null) updates['highlights'] = highlights;
    if (shortDescription != null) updates['shortDescription'] = shortDescription;
    if (isFeatured != null) updates['isFeatured'] = isFeatured;

    if (updates.isNotEmpty) {
      await _firestore.collection('products').doc(productId).update(updates);
    }
  }

  /// Mettre à jour les badges d'un produit
  static Future<void> updateBadges(
    String productId,
    List<Map<String, dynamic>> badges,
  ) async {
    await _firestore.collection('products').doc(productId).update({
      'badges': badges,
    });
  }

  /// Mettre à jour les variantes d'un produit
  static Future<void> updateVariants(
    String productId,
    List<Map<String, dynamic>> variants,
  ) async {
    await _firestore.collection('products').doc(productId).update({
      'variants': variants,
    });
  }

  /// Mettre à jour les spécifications détaillées
  static Future<void> updateDetailedSpecs(
    String productId,
    List<Map<String, dynamic>> specs,
  ) async {
    await _firestore.collection('products').doc(productId).update({
      'detailedSpecs': specs,
    });
  }
}
