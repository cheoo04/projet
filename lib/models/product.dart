import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_extensions.dart';

class Product {
  final String id;
  final String name;
  final String category; // 'phone', 'accessory', 'screen', 'pc'
  final String categoryId; // ID de catégorie (pour référence)
  final String brand; // 'Apple', 'Samsung', 'HP', etc.
  final double price;
  final String description;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final bool isInStock;
  final int stock;
  final String supplierReference;
  final Map<String, dynamic> specs;
  final Map<String, String> specifications; // Alias pour specs formaté en String
  final DateTime createdAt;

  // ========== NOUVEAUX CHAMPS (SIGNAUX DE CONFIANCE) ==========
  
  // Prix et promotions
  final double? originalPrice;       // Prix avant promo (optionnel)
  
  // Social proof
  final ProductRating? rating;       // Note moyenne + nombre d'avis
  final int soldCount;               // Nombre de ventes
  
  // Livraison
  final ShippingInfo shipping;       // Délais, coût, zones
  
  // Garanties
  final WarrantyInfo warranty;       // Durée, type, couverture
  final ReturnPolicy returnPolicy;   // Jours, conditions, gratuit ou non
  
  // Authenticité
  final AuthenticityInfo authenticity;  // Vérifié, source officielle
  
  // Variantes (couleurs, stockage)
  final List<ProductVariant> variants;
  
  // Badges (Nouveau, Promo, Best-seller)
  final List<ProductBadge> badges;
  
  // Descriptions
  final String? shortDescription;    // 120 caractères max
  final List<String> highlights;     // Points forts
  
  // Spécifications détaillées
  final List<ProductSpec> detailedSpecs;
  
  // Métadonnées
  final bool isFeatured;             // Produit mis en avant
  final int lowStockThreshold;       // Seuil stock limité (défaut: 5)
  
  // Promotions liées
  final List<String> promotionIds;   // IDs des promotions applicables

  Product({
    required this.id,
    required this.name,
    required this.category,
    String? categoryId,
    required this.brand,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.videoUrls = const [],
    required this.isInStock,
    this.stock = 0,
    this.supplierReference = '',
    this.specs = const {},
    Map<String, String>? specifications,
    DateTime? createdAt,
    // Nouveaux champs avec valeurs par défaut
    this.originalPrice,
    this.rating,
    this.soldCount = 0,
    this.shipping = const ShippingInfo(),
    this.warranty = const WarrantyInfo(),
    this.returnPolicy = const ReturnPolicy(),
    this.authenticity = const AuthenticityInfo(),
    this.variants = const [],
    this.badges = const [],
    this.shortDescription,
    this.highlights = const [],
    this.detailedSpecs = const [],
    this.isFeatured = false,
    this.lowStockThreshold = 5,
    this.promotionIds = const [],
  }) : categoryId = categoryId ?? category,
       specifications = specifications ?? specs.map((k, v) => MapEntry(k, v.toString())),
       createdAt = createdAt ?? DateTime.now();

  // ========== GETTERS CALCULÉS ==========
  
  /// Pourcentage de réduction (calculé automatiquement)
  int? get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }
  
  /// Économie en FCFA
  double? get savings {
    if (originalPrice == null || originalPrice! <= price) return null;
    return originalPrice! - price;
  }
  
  /// Statut du stock
  StockStatus get stockStatus {
    if (!isInStock || stock <= 0) return StockStatus.outOfStock;
    if (stock <= lowStockThreshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }
  
  /// Badge promo auto-généré
  ProductBadge? get promoBadge {
    final percent = discountPercent;
    if (percent != null && percent > 0) {
      return ProductBadge.promo(percent);
    }
    return null;
  }
  
  /// Tous les badges (y compris auto-générés)
  List<ProductBadge> get allBadges {
    final result = <ProductBadge>[...badges];
    final promo = promoBadge;
    if (promo != null && !result.any((b) => b.type == 'PROMO')) {
      result.insert(0, promo);
    }
    result.sort((a, b) => a.priority.compareTo(b.priority));
    return result;
  }
  
  /// Texte social proof
  String get socialProofText {
    if (soldCount > 0) {
      return '$soldCount personnes ont acheté ce produit';
    }
    return '';
  }
  
  /// A des avis ?
  bool get hasRatings => rating != null && rating!.count > 0;

  // Conversion depuis Firestore
  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    final specsMap = map['specs'] as Map<String, dynamic>? ?? {};
    return Product(
      id: docId,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      categoryId: map['categoryId'] as String?,
      brand: map['brand'] as String? ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      isInStock: map['isInStock'] as bool? ?? false,
      stock: map['stock'] as int? ?? 0,
      supplierReference: map['supplierReference'] as String? ?? '',
      specs: specsMap,
      specifications: specsMap.map((k, v) => MapEntry(k, v.toString())),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      // Nouveaux champs
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      rating: map['rating'] is Map<String, dynamic>
          ? ProductRating.fromMap(map['rating'] as Map<String, dynamic>) 
          : null,
      soldCount: map['soldCount'] as int? ?? 0,
      shipping: ShippingInfo.fromMap(map['shipping'] is Map<String, dynamic> ? map['shipping'] as Map<String, dynamic> : null),
      warranty: WarrantyInfo.fromMap(map['warranty'] is Map<String, dynamic> ? map['warranty'] as Map<String, dynamic> : null),
      returnPolicy: ReturnPolicy.fromMap(map['returnPolicy'] is Map<String, dynamic> ? map['returnPolicy'] as Map<String, dynamic> : null),
      authenticity: AuthenticityInfo.fromMap(map['authenticity'] is Map<String, dynamic> ? map['authenticity'] as Map<String, dynamic> : null),
      variants: (map['variants'] as List<dynamic>?)
          ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
          .toList() ?? [],
      badges: (map['badges'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((b) => ProductBadge.fromMap(b))
          .toList() ?? [],
      shortDescription: map['shortDescription'] as String?,
      highlights: List<String>.from(map['highlights'] ?? []),
      detailedSpecs: (map['detailedSpecs'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((s) => ProductSpec.fromMap(s))
          .toList() ?? [],
      isFeatured: map['isFeatured'] as bool? ?? false,
      lowStockThreshold: map['lowStockThreshold'] as int? ?? 5,
      promotionIds: List<String>.from(map['promotionIds'] ?? []),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'brand': brand,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'isInStock': isInStock,
      'stock': stock,
      'supplierReference': supplierReference,
      'specs': specs,
      'createdAt': Timestamp.fromDate(createdAt),
      // Nouveaux champs
      'originalPrice': originalPrice,
      'rating': rating?.toMap(),
      'soldCount': soldCount,
      'shipping': shipping.toMap(),
      'warranty': warranty.toMap(),
      'returnPolicy': returnPolicy.toMap(),
      'authenticity': authenticity.toMap(),
      'variants': variants.map((v) => v.toMap()).toList(),
      'badges': badges.map((b) => b.toMap()).toList(),
      'shortDescription': shortDescription,
      'highlights': highlights,
      'detailedSpecs': detailedSpecs.map((s) => s.toMap()).toList(),
      'isFeatured': isFeatured,
      'lowStockThreshold': lowStockThreshold,
      'promotionIds': promotionIds,
    };
  }

  // CopyWith pour modifications
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? brand,
    double? price,
    String? description,
    List<String>? imageUrls,
    List<String>? videoUrls,
    bool? isInStock,
    int? stock,
    String? supplierReference,
    Map<String, dynamic>? specs,
    DateTime? createdAt,
    // Nouveaux champs
    double? originalPrice,
    ProductRating? rating,
    int? soldCount,
    ShippingInfo? shipping,
    WarrantyInfo? warranty,
    ReturnPolicy? returnPolicy,
    AuthenticityInfo? authenticity,
    List<ProductVariant>? variants,
    List<ProductBadge>? badges,
    String? shortDescription,
    List<String>? highlights,
    List<ProductSpec>? detailedSpecs,
    bool? isFeatured,
    int? lowStockThreshold,
    List<String>? promotionIds,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      isInStock: isInStock ?? this.isInStock,
      stock: stock ?? this.stock,
      supplierReference: supplierReference ?? this.supplierReference,
      specs: specs ?? this.specs,
      createdAt: createdAt ?? this.createdAt,
      // Nouveaux champs
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      shipping: shipping ?? this.shipping,
      warranty: warranty ?? this.warranty,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      authenticity: authenticity ?? this.authenticity,
      variants: variants ?? this.variants,
      badges: badges ?? this.badges,
      shortDescription: shortDescription ?? this.shortDescription,
      highlights: highlights ?? this.highlights,
      detailedSpecs: detailedSpecs ?? this.detailedSpecs,
      isFeatured: isFeatured ?? this.isFeatured,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      promotionIds: promotionIds ?? this.promotionIds,
    );
  }
}