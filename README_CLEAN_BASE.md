# Application E-commerce - Base Propre

Cette version représente une base propre et simple de l'application e-commerce, prête à être étendue avec Firebase et d'autres fonctionnalités avancées.

## 🎯 Fonctionnalités actuelles

### ✅ Implémenté
- **4 écrans fonctionnels:**
  - Écran d'accueil avec navigation
  - Catalogue de produits avec filtre par catégorie
  - Détails du produit avec intégration WhatsApp
  - Écran d'administration avec formulaire de connexion

- **Modèle Product simplifié:**
  - Structure immutable (const)
  - Champs: id, name, category, brand, price, description, imageUrls, isInStock

- **Intégration WhatsApp:**
  - Bouton pour commander directement via WhatsApp
  - Message pré-rempli avec infos du produit
  - Désactivé pour les produits en rupture de stock

- **Catalogue avec données locales:**
  - 4 produits exemples
  - Filtre par catégorie (all, phone, accessory, screen, pc)
  - Indicateur de rupture de stock

## 🚀 Démarrage rapide

### Prérequis
- Flutter SDK (version 3.x recommandée)
- Dart SDK

### Installation

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Lancer l'application
flutter run

# Pour le web
flutter run -d chrome

# Pour Android
flutter run -d android

# Pour iOS (macOS uniquement)
flutter run -d ios
```

## 📱 Structure des écrans

### 1. HomeScreen (`/`)
Écran d'accueil avec deux boutons:
- "Voir le catalogue" → Navigation vers CatalogScreen
- "Administration" → Navigation vers AdminScreen

### 2. CatalogScreen (`/catalog`)
Liste des produits avec:
- Dropdown de filtrage par catégorie
- Affichage du nom, marque, catégorie, prix
- Indicateur de rupture de stock
- Navigation vers les détails au tap

### 3. ProductDetailScreen (`/product`)
Détails d'un produit avec:
- Image placeholder (à remplacer)
- Marque et nom
- Prix
- Description
- Bouton "Commander sur WhatsApp"

### 4. AdminScreen (`/admin`)
Interface d'administration avec:
- Formulaire de connexion (simulation)
- Validation email/mot de passe
- Action "Gérer les produits" (placeholder)

## 🔧 Configuration

### Personnaliser le numéro WhatsApp

Dans `lib/screens/product_detail_screen.dart`, ligne 10:
```dart
final phone = '221771234567'; // Remplace par ton numéro
```

### Modifier les produits

Dans `lib/screens/catalog_screen.dart`, modifier la liste `_allProducts`:
```dart
final List<Product> _allProducts = const [
  Product(
    id: '1',
    name: 'Votre produit',
    category: 'phone', // ou 'accessory', 'screen', 'pc'
    brand: 'Marque',
    price: 100.0,
    description: 'Description du produit',
    imageUrls: [],
    isInStock: true,
  ),
  // Ajouter d'autres produits...
];
```

## 🔮 Prochaines étapes (à implémenter)

Voir `MIGRATION_NOTES.md` pour les détails complets.

### Intégration Firebase
1. Ajouter l'initialisation Firebase dans `main.dart`
2. Créer un `ProductService` pour gérer Firestore
3. Ajouter les méthodes `fromMap()` et `toMap()` dans `Product`
4. Remplacer les données locales par des requêtes Firestore

### Authentification
1. Créer un `AuthService`
2. Implémenter login/register avec Firebase Auth
3. Remplacer la simulation dans AdminScreen

### Fonctionnalités supplémentaires
- Upload d'images avec Firebase Storage
- Système de panier
- Gestion des commandes
- Notifications push
- Analytics
- Mode hors ligne

## 📦 Dépendances

Principales dépendances utilisées:
- `url_launcher: ^6.3.2` - Pour l'intégration WhatsApp

Toutes les autres dépendances Firebase sont déjà dans `pubspec.yaml` et prêtes à être utilisées.

## 🛠️ Développement

### Structure du projet
```
lib/
├── main.dart                    # Point d'entrée
├── models/
│   └── product.dart            # Modèle Product
└── screens/
    ├── home_screen.dart        # Écran d'accueil
    ├── catalog_screen.dart     # Liste des produits
    ├── product_detail_screen.dart  # Détails + WhatsApp
    └── admin_screen.dart       # Administration
```

### Conventions de code
- Utilisation de `const` quand possible
- Widgets stateless par défaut
- StatefulWidget uniquement si nécessaire
- Noms de fichiers en snake_case
- Classes en PascalCase

## 📝 Notes

- Cette version est intentionnellement simplifiée pour faciliter la compréhension et l'extension
- Aucune dépendance Firebase n'est utilisée dans cette version, mais elles sont prêtes à être intégrées
- Les images utilisent des placeholders (icône grise) - à remplacer par de vraies images
- L'authentification admin est simulée - à remplacer par Firebase Auth

## 🆘 Support

Pour toute question ou problème:
1. Vérifier `MIGRATION_NOTES.md` pour les détails de migration
2. Consulter la documentation Flutter: https://flutter.dev/docs
3. Documentation url_launcher: https://pub.dev/packages/url_launcher

## 📄 Licence

Ce projet est fourni tel quel pour usage personnel ou commercial.
