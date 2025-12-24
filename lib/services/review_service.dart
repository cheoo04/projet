import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

/// Service pour gérer les avis clients
class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'reviews';

  /// Obtenir les avis d'un produit (stream temps réel)
  static Stream<List<Review>> getProductReviews(
    String productId, {
    int limit = 10,
    bool approvedOnly = true,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList());
  }

  /// Obtenir les avis d'un produit (one-shot)
  static Future<List<Review>> fetchProductReviews(
    String productId, {
    int limit = 10,
    bool approvedOnly = true,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Review.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  /// Ajouter un avis (sera en attente de modération)
  static Future<String> addReview({
    required String productId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required int rating,
    required String comment,
    bool isVerifiedPurchase = false,
    List<String> imageUrls = const [],
  }) async {
    final review = Review(
      id: '',
      productId: productId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      isVerifiedPurchase: isVerifiedPurchase,
      imageUrls: imageUrls,
      isModerated: false,
      isApproved: false, // En attente de modération
    );

    final docRef = await _firestore.collection(_collection).add(review.toMap());
    return docRef.id;
  }

  /// Vérifier si l'utilisateur a déjà laissé un avis
  static Future<bool> hasUserReviewed(String productId, String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Vérifier si l'utilisateur a acheté le produit
  static Future<bool> hasUserPurchased(String productId, String userId) async {
    final orders = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .get();

    for (final order in orders.docs) {
      final items = order.data()['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item['productId'] == productId) {
          return true;
        }
      }
    }
    return false;
  }

  /// Marquer un avis comme utile
  static Future<void> markHelpful(String reviewId) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }

  /// Mettre à jour le rating global du produit
  static Future<void> updateProductRating(String productId) async {
    final reviews = await _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .where('isApproved', isEqualTo: true)
        .get();

    if (reviews.docs.isEmpty) {
      // Réinitialiser le rating si aucun avis
      await _firestore.collection('products').doc(productId).update({
        'rating': null,
      });
      return;
    }

    final ratings = reviews.docs.map((doc) {
      final data = doc.data();
      return (data['rating'] as num?)?.toInt() ?? 5;
    }).toList();

    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    
    // Calculer la distribution
    final distribution = <String, int>{
      '5': ratings.where((r) => r == 5).length,
      '4': ratings.where((r) => r == 4).length,
      '3': ratings.where((r) => r == 3).length,
      '2': ratings.where((r) => r == 2).length,
      '1': ratings.where((r) => r == 1).length,
    };

    await _firestore.collection('products').doc(productId).update({
      'rating': {
        'average': double.parse(average.toStringAsFixed(1)),
        'count': ratings.length,
        'distribution': distribution,
      },
    });
  }

  // ========== ADMIN METHODS ==========

  /// Obtenir les avis en attente de modération
  static Stream<List<Review>> getPendingReviews() {
    return _firestore
        .collection(_collection)
        .where('isModerated', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Approuver un avis
  static Future<void> approveReview(
    String reviewId, {
    required String moderatorId,
    String? moderatorNote,
  }) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'isModerated': true,
      'isApproved': true,
      'moderatorId': moderatorId,
      'moderatorNote': moderatorNote,
      'moderatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Récupérer le review pour mettre à jour le rating du produit
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (doc.exists) {
      final productId = doc.data()?['productId'] as String?;
      if (productId != null) {
        await updateProductRating(productId);
      }
    }
  }

  /// Rejeter un avis
  static Future<void> rejectReview(
    String reviewId, {
    required String moderatorId,
    String? moderatorNote,
  }) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'isModerated': true,
      'isApproved': false,
      'moderatorId': moderatorId,
      'moderatorNote': moderatorNote,
      'moderatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Supprimer un avis
  static Future<void> deleteReview(String reviewId) async {
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    final productId = doc.data()?['productId'] as String?;

    await _firestore.collection(_collection).doc(reviewId).delete();

    // Mettre à jour le rating du produit
    if (productId != null) {
      await updateProductRating(productId);
    }
  }

  /// Répondre à un avis (vendeur)
  static Future<void> respondToReview(
    String reviewId,
    String response,
  ) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'response': response,
      'responseAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
