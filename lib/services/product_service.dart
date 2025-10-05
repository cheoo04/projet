import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'products',
  );

  // Seuil de stock faible par défaut
  static const int defaultLowStockThreshold = 10;

  Future<List<Product>> fetchAll() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> add(Product p) async {
    await _col.doc(p.id).set(p.toMap());
  }

  Future<void> update(Product p) async {
    await _col.doc(p.id).update(p.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // Méthode getAll() pour compatibilité avec le dashboard
  Stream<List<Product>> getAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// Obtenir les produits avec stock faible
  Future<List<Product>> getLowStockProducts({
    int threshold = defaultLowStockThreshold,
  }) async {
    try {
      final snapshot = await _col
          .where('stock', isLessThanOrEqualTo: threshold)
          .where('stock', isGreaterThan: 0)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des produits à stock faible: $e',
      );
    }
  }

  /// Obtenir les produits en rupture de stock
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      final snapshot = await _col.where('stock', isEqualTo: 0).get();

      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des produits en rupture: $e',
      );
    }
  }

  /// Stream pour les produits avec stock faible
  Stream<List<Product>> getLowStockProductsStream({
    int threshold = defaultLowStockThreshold,
  }) {
    return _col
        .where('stock', isLessThanOrEqualTo: threshold)
        .where('stock', isGreaterThan: 0)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// Stream pour les produits en rupture de stock
  Stream<List<Product>> getOutOfStockProductsStream() {
    return _col
        .where('stock', isEqualTo: 0)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// Mettre à jour le stock d'un produit
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _col.doc(productId).update({
        'stock': newStock,
        'isInStock': newStock > 0,
      });

      // Vérifier les alertes de stock faible
      final productDoc = await _col.doc(productId).get();
      if (productDoc.exists) {
        final product = Product.fromMap(
          productDoc.data() as Map<String, dynamic>,
          productDoc.id,
        );
        await _checkLowStockAlert(product);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du stock: $e');
    }
  }

  /// Vérifier et envoyer des alertes de stock faible
  Future<void> _checkLowStockAlert(Product product) async {
    try {
      // Cette fonctionnalité nécessite l'intégration complète du système de notifications
      // Pour l'instant, on peut logger les alertes
      if (product.stock <= defaultLowStockThreshold && product.stock > 0) {
        debugPrint(
          'ALERTE STOCK FAIBLE: ${product.name} - ${product.stock} unités restantes',
        );
        // TODO: Implémenter l'envoi de notifications via NotificationService
      } else if (product.stock == 0) {
        debugPrint('ALERTE RUPTURE STOCK: ${product.name} - Stock épuisé');
        // TODO: Implémenter l'envoi de notifications via NotificationService
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking main operations
      debugPrint('Erreur envoi alerte stock: $e');
    }
  }

  /// Obtenir le nombre total de produits par statut de stock
  Future<Map<String, int>> getStockStatusCounts() async {
    try {
      final snapshot = await _col.get();

      int inStock = 0;
      int lowStock = 0;
      int outOfStock = 0;

      for (var doc in snapshot.docs) {
        final product = Product.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (product.stock > defaultLowStockThreshold) {
          inStock++;
        } else if (product.stock > 0) {
          lowStock++;
        } else {
          outOfStock++;
        }
      }

      return {
        'inStock': inStock,
        'lowStock': lowStock,
        'outOfStock': outOfStock,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statuts de stock: $e');
    }
  }

  /// Rechercher des produits par nom ou catégorie avec filtre de stock
  Future<List<Product>> searchProducts({
    String? query,
    String? category,
    bool? inStockOnly,
    bool? lowStockOnly,
  }) async {
    try {
      Query queryRef = _col;

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (inStockOnly == true) {
        queryRef = queryRef.where('stock', isGreaterThan: 0);
      }

      if (lowStockOnly == true) {
        queryRef = queryRef
            .where('stock', isLessThanOrEqualTo: defaultLowStockThreshold)
            .where('stock', isGreaterThan: 0);
      }

      final snapshot = await queryRef.get();
      List<Product> products = snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Filtrer par nom si une requête est fournie
      if (query != null && query.isNotEmpty) {
        products = products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.brand.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      return products;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de produits: $e');
    }
  }
}
