import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'promotions';

  // Récupérer toutes les promotions
  Future<List<Promotion>> fetchAll() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Promotion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des promotions: $e');
    }
  }

  // Stream pour récupérer toutes les promotions
  Stream<List<Promotion>> getAll() {
    return _firestore
        .collection(_collection)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Promotion.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Récupérer les promotions actives uniquement
  Future<List<Promotion>> fetchActive() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
          .where('endDate', isGreaterThan: now.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => Promotion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des promotions actives: $e',
      );
    }
  }

  // Récupérer les promotions pour un produit spécifique
  Future<List<Promotion>> fetchForProduct(String productId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('productIds', arrayContains: productId)
          .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
          .where('endDate', isGreaterThan: now.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => Promotion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des promotions du produit: $e',
      );
    }
  }

  // Ajouter une nouvelle promotion
  Future<void> add(Promotion promotion) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(promotion.id)
          .set(promotion.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la promotion: $e');
    }
  }

  // Mettre à jour une promotion existante
  Future<void> update(Promotion promotion) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(promotion.id)
          .update(promotion.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la promotion: $e');
    }
  }

  // Supprimer une promotion
  Future<void> delete(String promotionId) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la promotion: $e');
    }
  }

  // Activer/Désactiver une promotion
  Future<void> toggleActive(String promotionId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  // Stream pour écouter les changements en temps réel
  Stream<List<Promotion>> streamPromotions() {
    return _firestore
        .collection(_collection)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Promotion.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
