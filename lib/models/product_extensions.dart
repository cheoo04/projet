import 'package:flutter/material.dart';

/// Statut du stock produit
enum StockStatus {
  inStock,    // En stock
  lowStock,   // Stock limité
  outOfStock; // Rupture

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'En stock';
      case StockStatus.lowStock:
        return 'Stock limité';
      case StockStatus.outOfStock:
        return 'Rupture';
    }
  }

  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return const Color(0xFF16A34A); // Vert
      case StockStatus.lowStock:
        return const Color(0xFFF59E0B); // Orange
      case StockStatus.outOfStock:
        return const Color(0xFF6B7280); // Gris
    }
  }

  IconData get icon {
    switch (this) {
      case StockStatus.inStock:
        return Icons.check_circle;
      case StockStatus.lowStock:
        return Icons.warning_amber;
      case StockStatus.outOfStock:
        return Icons.cancel;
    }
  }
}

/// Note et avis produit
class ProductRating {
  final double average;              // Ex: 4.7
  final int count;                   // Ex: 128 avis
  final Map<int, int> distribution;  // {5: 80, 4: 30, 3: 10, 2: 5, 1: 3}

  const ProductRating({
    this.average = 0.0,
    this.count = 0,
    this.distribution = const {},
  });

  factory ProductRating.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ProductRating();
    
    // Convertir la distribution en Map<int, int>
    final distMap = <int, int>{};
    final distData = map['distribution'] as Map<String, dynamic>? ?? {};
    distData.forEach((key, value) {
      distMap[int.tryParse(key) ?? 0] = value as int? ?? 0;
    });

    return ProductRating(
      average: (map['average'] ?? 0).toDouble(),
      count: map['count'] as int? ?? 0,
      distribution: distMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'average': average,
      'count': count,
      'distribution': distribution.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  bool get hasRatings => count > 0;
  
  String get displayText => hasRatings 
      ? '${average.toStringAsFixed(1)} ($count avis)' 
      : 'Pas encore d\'avis';
}

/// Informations de livraison
class ShippingInfo {
  final bool isFree;                 // Livraison gratuite ?
  final int minDays;                 // Délai min (ex: 2)
  final int maxDays;                 // Délai max (ex: 5)
  final List<String> cities;         // ["Abidjan", "Bouaké"] ou ["all"]
  final bool trackingAvailable;      // Suivi disponible ?
  final int? cost;                   // Coût si non gratuit (en FCFA)

  const ShippingInfo({
    this.isFree = false,
    this.minDays = 3,
    this.maxDays = 7,
    this.cities = const ['Abidjan'],
    this.trackingAvailable = true,
    this.cost,
  });

  factory ShippingInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ShippingInfo();
    return ShippingInfo(
      isFree: map['isFree'] as bool? ?? false,
      minDays: map['minDays'] as int? ?? 3,
      maxDays: map['maxDays'] as int? ?? 7,
      cities: List<String>.from(map['cities'] ?? ['Abidjan']),
      trackingAvailable: map['trackingAvailable'] as bool? ?? true,
      cost: map['cost'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isFree': isFree,
      'minDays': minDays,
      'maxDays': maxDays,
      'cities': cities,
      'trackingAvailable': trackingAvailable,
      'cost': cost,
    };
  }

  String get delayText => minDays == maxDays 
      ? '$minDays jours' 
      : '$minDays-$maxDays jours';

  String get displayText {
    final delay = 'Livraison $delayText';
    if (isFree) return '$delay • Gratuite';
    if (cost != null) return '$delay • $cost FCFA';
    return delay;
  }
}

/// Informations de garantie
class WarrantyInfo {
  final int months;                  // Durée (ex: 12)
  final String type;                 // "constructeur" | "revendeur"
  final String coverage;             // "Défauts de fabrication"

  const WarrantyInfo({
    this.months = 12,
    this.type = 'revendeur',
    this.coverage = 'Défauts de fabrication',
  });

  factory WarrantyInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WarrantyInfo();
    return WarrantyInfo(
      months: map['months'] as int? ?? 12,
      type: map['type'] as String? ?? 'revendeur',
      coverage: map['coverage'] as String? ?? 'Défauts de fabrication',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'months': months,
      'type': type,
      'coverage': coverage,
    };
  }

  String get displayText => 'Garantie $months mois';
  
  String get typeLabel => type == 'constructeur' 
      ? 'Garantie constructeur' 
      : 'Garantie revendeur';
}

/// Politique de retour
class ReturnPolicy {
  final int days;                    // Nombre de jours (ex: 7)
  final String conditions;           // "Produit non ouvert"
  final bool freeReturn;             // Retour gratuit ?

  const ReturnPolicy({
    this.days = 7,
    this.conditions = 'Produit non ouvert',
    this.freeReturn = true,
  });

  factory ReturnPolicy.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ReturnPolicy();
    return ReturnPolicy(
      days: map['days'] as int? ?? 7,
      conditions: map['conditions'] as String? ?? 'Produit non ouvert',
      freeReturn: map['freeReturn'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'conditions': conditions,
      'freeReturn': freeReturn,
    };
  }

  String get displayText => freeReturn 
      ? 'Retour gratuit sous $days jours' 
      : 'Retour sous $days jours';
}

/// Informations d'authenticité
class AuthenticityInfo {
  final bool verified;               // Produit vérifié ?
  final String source;               // "Distributeur officiel Apple"
  final String? certificateUrl;      // URL du certificat (optionnel)

  const AuthenticityInfo({
    this.verified = false,
    this.source = '',
    this.certificateUrl,
  });

  factory AuthenticityInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AuthenticityInfo();
    return AuthenticityInfo(
      verified: map['verified'] as bool? ?? false,
      source: map['source'] as String? ?? '',
      certificateUrl: map['certificateUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verified': verified,
      'source': source,
      'certificateUrl': certificateUrl,
    };
  }
}

/// Variante de produit (couleur, stockage, etc.)
class ProductVariant {
  final String id;
  final String type;                 // "color" | "storage" | "size"
  final String value;                // "Noir" | "128GB"
  final String sku;
  final int? priceAdjustment;        // +50000 pour 256GB
  final int stock;
  final String? imageUrl;

  const ProductVariant({
    required this.id,
    required this.type,
    required this.value,
    required this.sku,
    this.priceAdjustment,
    this.stock = 0,
    this.imageUrl,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'color',
      value: map['value'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      priceAdjustment: map['priceAdjustment'] as int?,
      stock: map['stock'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'sku': sku,
      'priceAdjustment': priceAdjustment,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }
}

/// Badge produit (Nouveau, Promo, Best-seller)
class ProductBadge {
  final String type;                 // "NEW" | "PROMO" | "BESTSELLER" | "VERIFIED"
  final String label;                // "Nouveau" | "-15%" | "Best-seller"
  final String colorHex;             // Hex color "#9B6DB8"
  final int priority;                // 1-5 pour ordre d'affichage

  const ProductBadge({
    required this.type,
    required this.label,
    this.colorHex = '#9B6DB8',
    this.priority = 1,
  });

  factory ProductBadge.fromMap(Map<String, dynamic> map) {
    return ProductBadge(
      type: map['type'] as String? ?? 'NEW',
      label: map['label'] as String? ?? '',
      colorHex: map['color'] as String? ?? '#9B6DB8',
      priority: map['priority'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'color': colorHex,
      'priority': priority,
    };
  }

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF9B6DB8);
    }
  }

  static ProductBadge promo(int percent) => ProductBadge(
    type: 'PROMO',
    label: '-$percent%',
    colorHex: '#EF4444',
    priority: 1,
  );

  static const ProductBadge newProduct = ProductBadge(
    type: 'NEW',
    label: 'Nouveau',
    colorHex: '#3B82F6',
    priority: 2,
  );

  static const ProductBadge bestSeller = ProductBadge(
    type: 'BESTSELLER',
    label: 'Best-seller',
    colorHex: '#F59E0B',
    priority: 3,
  );

  static const ProductBadge verified = ProductBadge(
    type: 'VERIFIED',
    label: 'Vérifié',
    colorHex: '#16A34A',
    priority: 4,
  );
}

/// Spécification produit
class ProductSpec {
  final String label;                // "Autonomie"
  final String value;                // "6h (ANC activé)"
  final String? category;            // "Batterie" (optionnel)

  const ProductSpec({
    required this.label,
    required this.value,
    this.category,
  });

  factory ProductSpec.fromMap(Map<String, dynamic> map) {
    return ProductSpec(
      label: map['label'] as String? ?? '',
      value: map['value'] as String? ?? '',
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'category': category,
    };
  }
}
