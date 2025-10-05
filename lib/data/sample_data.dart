// Configuration des données d'exemple
// CE FICHIER CONTIENT UNIQUEMENT DES DONNÉES DE DÉMONSTRATION
// À SUPPRIMER AVANT LA MISE EN PRODUCTION

class SampleDataConfig {
  // Configuration pour désactiver les données d'exemple
  static const bool useSampleData = true; // Mettre à false en production

  // Données d'exemple générique pour le développement
  static List<Map<String, dynamic>> getSampleProducts() {
    if (!useSampleData) return [];

    return [
      {
        'id': 'demo_1',
        'name': 'Produit Démo 1',
        'brand': 'Marque Exemple',
        'category': 'Smartphones',
        'price': 599,
        'oldPrice': 699,
        'description': 'Description du produit de démonstration',
        'stock': 10,
        'hasPromotion': true,
      },
      {
        'id': 'demo_2',
        'name': 'Produit Démo 2',
        'brand': 'Marque Test',
        'category': 'Smartphones',
        'price': 399,
        'oldPrice': null,
        'description': 'Autre produit de test pour la démonstration',
        'stock': 5,
        'hasPromotion': false,
      },
      {
        'id': 'demo_3',
        'name': 'Accessoire Démo',
        'brand': 'Accessoires Plus',
        'category': 'Écouteurs',
        'price': 99,
        'oldPrice': 129,
        'description': 'Accessoire de démonstration',
        'stock': 20,
        'hasPromotion': true,
      },
      {
        'id': 'demo_4',
        'name': 'Casque Test',
        'brand': 'Audio Test',
        'category': 'Écouteurs',
        'price': 149,
        'oldPrice': null,
        'description': 'Produit audio de test',
        'stock': 15,
        'hasPromotion': false,
      },
      {
        'id': 'demo_5',
        'name': 'Protection Démo',
        'brand': 'Protect Plus',
        'category': 'Coques',
        'price': 25,
        'oldPrice': 35,
        'description': 'Coque de protection de démonstration',
        'stock': 50,
        'hasPromotion': true,
      },
      {
        'id': 'demo_6',
        'name': 'Coque Test',
        'brand': 'Case Pro',
        'category': 'Coques',
        'price': 19,
        'oldPrice': null,
        'description': 'Coque de test pour développement',
        'stock': 30,
        'hasPromotion': false,
      },
      {
        'id': 'demo_7',
        'name': 'Chargeur Démo',
        'brand': 'Power Demo',
        'category': 'Accessoires',
        'price': 39,
        'oldPrice': null,
        'description': 'Chargeur de démonstration',
        'stock': 8,
        'hasPromotion': false,
      },
      {
        'id': 'demo_8',
        'name': 'Câble Test',
        'brand': 'Cable Demo',
        'category': 'Accessoires',
        'price': 15,
        'oldPrice': 25,
        'description': 'Câble de test pour développement',
        'stock': 0,
        'hasPromotion': true,
      },
    ];
  }

  // Catégories génériques
  static List<String> getSampleCategories() {
    if (!useSampleData) return [];

    return ['Tous', 'Smartphones', 'Écouteurs', 'Coques', 'Accessoires'];
  }

  // Messages d'avertissement pour le développement
  static String get developmentWarning =>
      'ATTENTION: Application en mode développement avec données d\'exemple';

  static String get productionNote =>
      'Pour la production, définir useSampleData = false dans sample_data.dart';
}
