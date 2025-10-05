// Service de gestion des produits
// Remplace les données statiques par une interface vers Firebase

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_data.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String productsCollection = 'products';

  // Obtenir tous les produits
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      // En mode développement, utiliser les données d'exemple
      if (SampleDataConfig.useSampleData) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Simuler un délai réseau
        return SampleDataConfig.getSampleProducts();
      }

      // En production, récupérer depuis Firebase
      final querySnapshot = await _firestore
          .collection(productsCollection)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // En cas d'erreur, retourner les données d'exemple comme fallback
      return SampleDataConfig.getSampleProducts();
    }
  }

  // Obtenir les produits par catégorie
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    final allProducts = await getAllProducts();
    if (category == 'Tous') return allProducts;

    return allProducts
        .where((product) => product['category'] == category)
        .toList();
  }

  // Rechercher des produits
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final allProducts = await getAllProducts();
    final lowercaseQuery = query.toLowerCase();

    return allProducts.where((product) {
      final name = (product['name'] as String).toLowerCase();
      final description = (product['description'] as String).toLowerCase();
      final brand = (product['brand'] as String).toLowerCase();

      return name.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery) ||
          brand.contains(lowercaseQuery);
    }).toList();
  }

  // Obtenir un produit par ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      if (SampleDataConfig.useSampleData) {
        final products = SampleDataConfig.getSampleProducts();
        return products.firstWhere(
          (product) => product['id'] == id,
          orElse: () => {},
        );
      }

      final doc = await _firestore.collection(productsCollection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Ajouter un produit (admin seulement)
  Future<String?> addProduct(Map<String, dynamic> productData) async {
    try {
      if (SampleDataConfig.useSampleData) {
        // En mode développement, simuler l'ajout
        return 'demo_${DateTime.now().millisecondsSinceEpoch}';
      }

      final docRef = await _firestore
          .collection(productsCollection)
          .add(productData);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour un produit (admin seulement)
  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      if (SampleDataConfig.useSampleData) {
        // En mode développement, simuler la mise à jour
        return true;
      }

      await _firestore
          .collection(productsCollection)
          .doc(id)
          .update(productData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un produit (admin seulement)
  Future<bool> deleteProduct(String id) async {
    try {
      if (SampleDataConfig.useSampleData) {
        // En mode développement, simuler la suppression
        return true;
      }

      await _firestore.collection(productsCollection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir les catégories disponibles
  Future<List<String>> getCategories() async {
    try {
      if (SampleDataConfig.useSampleData) {
        return SampleDataConfig.getSampleCategories();
      }

      final querySnapshot = await _firestore
          .collection(productsCollection)
          .get();
      final categories = <String>{'Tous'};

      for (final doc in querySnapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) {
          categories.add(category);
        }
      }

      return categories.toList();
    } catch (e) {
      return SampleDataConfig.getSampleCategories();
    }
  }

  // Vérifier si l'application est en mode développement
  static bool get isDevelopmentMode => SampleDataConfig.useSampleData;

  // Obtenir le message d'avertissement pour le développement
  static String get developmentWarning => SampleDataConfig.developmentWarning;
}
