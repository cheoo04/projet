import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Créer une catégorie
  Future<void> add(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .set(category.toMap());
  }

  // Mettre à jour une catégorie
  Future<void> update(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  // Supprimer une catégorie
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Obtenir toutes les catégories
  Stream<List<Category>> getAll() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Category.fromMap(doc.data())).toList(),
        );
  }

  // Obtenir les catégories actives
  Stream<List<Category>> getActive() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Category.fromMap(doc.data())).toList(),
        );
  }

  // Obtenir une catégorie par ID
  Future<Category?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Category.fromMap(doc.data()!);
    }
    return null;
  }

  // Mettre à jour le nombre de produits dans une catégorie
  Future<void> updateProductCount(String categoryId, int count) async {
    await _firestore.collection(_collection).doc(categoryId).update({
      'productCount': count,
    });
  }

  // Rechercher des catégories
  Future<List<Category>> search(String query) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();

    return snapshot.docs.map((doc) => Category.fromMap(doc.data())).toList();
  }
}
