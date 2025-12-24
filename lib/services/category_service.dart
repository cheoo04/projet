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

  // Obtenir toutes les catégories (version Future)
  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data()))
        .toList();
  }

  // Créer une catégorie (alias pour add)
  Future<void> createCategory({
    required String name,
    String? description,
    String? iconName,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final category = Category(
      id: id,
      name: name,
      description: description ?? '',
      imageUrl: imageUrl ?? '',
      iconName: iconName ?? 'category',
      isActive: isActive,
      createdAt: DateTime.now(),
    );
    return add(category);
  }

  // Mettre à jour une catégorie (version simplifiée)
  Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
    String? iconName,
    String? imageUrl,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (iconName != null) updates['iconName'] = iconName;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (isActive != null) updates['isActive'] = isActive;
    
    if (updates.isNotEmpty) {
      await _firestore.collection(_collection).doc(id).update(updates);
    }
  }

  // Supprimer une catégorie (alias pour delete)
  Future<void> deleteCategory(String id) => delete(id);

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
