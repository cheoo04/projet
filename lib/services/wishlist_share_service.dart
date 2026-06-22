import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gère la publication et la consultation de listes de favoris partagées
/// publiquement. Chaque publication crée un nouveau document (snapshot figé
/// au moment du partage, pas de mise à jour live).
class WishlistShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'shared_wishlists';

  /// Génère un identifiant court, suffisamment unique pour ce volume
  /// d'usage (pas besoin d'un vrai UUID — le projet n'a pas ce package en
  /// dépendance, et un id de ce type suffit largement ici).
  String _generateShareId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      10,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Publie la liste de favoris actuelle. Retourne le shareId généré.
  /// Lève une exception si l'utilisateur n'est pas connecté ou si la
  /// liste est vide.
  Future<String> publishWishlist(List<String> productIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Connexion requise pour partager votre liste');
    }
    if (productIds.isEmpty) {
      throw Exception('Ajoutez des favoris avant de partager votre liste');
    }

    final shareId = _generateShareId();

    await _firestore.collection(_collection).doc(shareId).set({
      'productIds': productIds,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    });

    return shareId;
  }

  /// Récupère les productIds d'une liste partagée. Retourne une liste vide
  /// si le shareId est introuvable (lien invalide ou expiré).
  Future<List<String>> getSharedWishlist(String shareId) async {
    final doc = await _firestore.collection(_collection).doc(shareId).get();
    if (!doc.exists) return [];

    final data = doc.data();
    return List<String>.from(data?['productIds'] ?? []);
  }
}