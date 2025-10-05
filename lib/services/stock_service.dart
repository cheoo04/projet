import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_movement.dart';
import '../models/product.dart';
import 'auth_service.dart';
import 'logging_service.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'stock_movements';
  final String _productsCollection = 'products';
  final AuthService _authService = AuthService();

  // Seuil de stock faible par défaut
  static const int defaultLowStockThreshold = 10;

  /// Ajouter un mouvement de stock et mettre à jour le produit
  Future<void> addStockMovement({
    required String productId,
    required String productName,
    required StockMovementType type,
    required int quantity,
    required String reason,
    String? orderId,
    String? supplierId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupérer le produit actuel
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('Produit non trouvé');
      }

      final product = Product.fromMap(
        productDoc.data() as Map<String, dynamic>,
        productDoc.id,
      );

      final stockBefore = product.stock;
      final stockAfter = stockBefore + quantity;

      if (stockAfter < 0) {
        throw Exception('Stock insuffisant. Stock actuel: $stockBefore');
      }

      // Créer le mouvement de stock
      final movement = StockMovement(
        id: _firestore.collection(_collection).doc().id,
        productId: productId,
        productName: productName,
        type: type,
        quantity: quantity,
        stockBefore: stockBefore,
        stockAfter: stockAfter,
        reason: reason,
        orderId: orderId,
        supplierId: supplierId,
        userId: user.id,
        userName: user.fullName,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Transaction pour garantir la cohérence
      await _firestore.runTransaction((transaction) async {
        // Ajouter le mouvement
        transaction.set(
          _firestore.collection(_collection).doc(movement.id),
          movement.toFirestore(),
        );

        // Mettre à jour le stock du produit
        transaction.update(
          _firestore.collection(_productsCollection).doc(productId),
          {'stock': stockAfter, 'isInStock': stockAfter > 0},
        );
      });

      // Vérifier les alertes de stock faible
      await _checkLowStockAlert(productId, productName, stockAfter);

      LoggingService.info(
        'Mouvement de stock ajouté: $productName ($quantity)',
      );
    } catch (e) {
      LoggingService.error('Erreur ajout mouvement stock: $e');
      rethrow;
    }
  }

  /// Obtenir tous les mouvements de stock
  Stream<List<StockMovement>> getAllMovements() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockMovement.fromFirestore(doc))
              .toList(),
        );
  }

  /// Obtenir les mouvements de stock pour un produit
  Stream<List<StockMovement>> getMovementsByProduct(String productId) {
    return _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockMovement.fromFirestore(doc))
              .toList(),
        );
  }

  /// Obtenir les mouvements par type
  Stream<List<StockMovement>> getMovementsByType(StockMovementType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockMovement.fromFirestore(doc))
              .toList(),
        );
  }

  /// Obtenir les mouvements par période
  Future<List<StockMovement>> getMovementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockMovement.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggingService.error('Erreur récupération mouvements par période: $e');
      return [];
    }
  }

  /// Obtenir les produits avec stock faible
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int threshold = defaultLowStockThreshold,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('stock', isLessThanOrEqualTo: threshold)
          .where('stock', isGreaterThan: 0)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'product': Product.fromMap(data, doc.id),
          'isLowStock': true,
          'threshold': threshold,
        };
      }).toList();
    } catch (e) {
      LoggingService.error('Erreur récupération produits stock faible: $e');
      return [];
    }
  }

  /// Obtenir les produits en rupture de stock
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('stock', isEqualTo: 0)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      LoggingService.error('Erreur récupération produits rupture stock: $e');
      return [];
    }
  }

  /// Effectuer un ajustement de stock
  Future<void> adjustStock({
    required String productId,
    required String productName,
    required int newStock,
    required String reason,
  }) async {
    try {
      // Récupérer le stock actuel
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('Produit non trouvé');
      }

      final product = Product.fromMap(
        productDoc.data() as Map<String, dynamic>,
        productDoc.id,
      );

      final currentStock = product.stock;
      final adjustment = newStock - currentStock;

      if (adjustment != 0) {
        await addStockMovement(
          productId: productId,
          productName: productName,
          type: StockMovementType.adjustment,
          quantity: adjustment,
          reason: reason,
          metadata: {
            'adjustment_type': adjustment > 0 ? 'increase' : 'decrease',
            'previous_stock': currentStock,
            'new_stock': newStock,
          },
        );
      }
    } catch (e) {
      LoggingService.error('Erreur ajustement stock: $e');
      rethrow;
    }
  }

  /// Enregistrer une entrée de stock (approvisionnement)
  Future<void> addStockEntry({
    required String productId,
    required String productName,
    required int quantity,
    String? supplierId,
    String? reason,
  }) async {
    await addStockMovement(
      productId: productId,
      productName: productName,
      type: StockMovementType.entry,
      quantity: quantity,
      reason: reason ?? 'Approvisionnement',
      supplierId: supplierId,
    );
  }

  /// Enregistrer une sortie de stock (vente)
  Future<void> addStockExit({
    required String productId,
    required String productName,
    required int quantity,
    String? orderId,
    String? reason,
  }) async {
    await addStockMovement(
      productId: productId,
      productName: productName,
      type: StockMovementType.sale,
      quantity: -quantity, // Négatif pour une sortie
      reason: reason ?? 'Vente',
      orderId: orderId,
    );
  }

  /// Vérifier et envoyer des alertes de stock faible
  Future<void> _checkLowStockAlert(
    String productId,
    String productName,
    int currentStock,
  ) async {
    try {
      if (currentStock <= defaultLowStockThreshold && currentStock > 0) {
        // Pour l'instant, on utilise un log simple
        // TODO: Implémenter l'intégration complète avec NotificationService
        LoggingService.info(
          'ALERTE STOCK FAIBLE: $productName - $currentStock unités restantes',
        );
      } else if (currentStock == 0) {
        LoggingService.info(
          'ALERTE RUPTURE STOCK: $productName - Stock épuisé',
        );
      }
    } catch (e) {
      LoggingService.error('Erreur envoi alerte stock: $e');
    }
  }

  /// Obtenir les statistiques de stock
  Future<Map<String, dynamic>> getStockStatistics() async {
    try {
      final productsSnapshot = await _firestore
          .collection(_productsCollection)
          .get();

      int totalProducts = productsSnapshot.docs.length;
      int inStock = 0;
      int lowStock = 0;
      int outOfStock = 0;
      int totalStockValue = 0;

      for (var doc in productsSnapshot.docs) {
        final product = Product.fromMap(doc.data(), doc.id);
        final stock = product.stock;

        if (stock > defaultLowStockThreshold) {
          inStock++;
        } else if (stock > 0) {
          lowStock++;
        } else {
          outOfStock++;
        }

        totalStockValue += (stock * product.price).round();
      }

      return {
        'totalProducts': totalProducts,
        'inStock': inStock,
        'lowStock': lowStock,
        'outOfStock': outOfStock,
        'totalStockValue': totalStockValue,
        'lowStockPercentage': totalProducts > 0
            ? (lowStock / totalProducts * 100)
            : 0,
        'outOfStockPercentage': totalProducts > 0
            ? (outOfStock / totalProducts * 100)
            : 0,
      };
    } catch (e) {
      LoggingService.error('Erreur calcul statistiques stock: $e');
      return {};
    }
  }

  /// Supprimer un mouvement de stock (admin seulement)
  Future<void> deleteMovement(String movementId) async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null || !user.isAdmin) {
        throw Exception('Permission insuffisante');
      }

      await _firestore.collection(_collection).doc(movementId).delete();

      LoggingService.info('Mouvement de stock supprimé: $movementId');
    } catch (e) {
      LoggingService.error('Erreur suppression mouvement stock: $e');
      rethrow;
    }
  }
}
