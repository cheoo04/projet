# Notes de migration - Application de base

## Changements effectués

Cette migration a simplifié l'application pour créer une base propre qui pourra être étendue avec Firebase plus tard.

### 1. Modèle Product (`lib/models/product.dart`)

**Simplifié:**
- Tous les champs sont maintenant `final` (immutables)
- Suppression de `stock`, `supplierReference`, `specs`, `createdAt`
- Suppression des méthodes `fromMap()` et `toMap()` (spécifiques à Firestore)
- Suppression du getter `isOutOfStock`
- Le constructeur est maintenant `const` pour de meilleures performances

**Champs conservés:**
- `id`, `name`, `category`, `brand`, `price`, `description`, `imageUrls`, `isInStock`

### 2. Main.dart (`lib/main.dart`)

**Simplifié:**
- Suppression de l'initialisation Firebase
- Suppression des services avancés (BiometricAuth, OfflineCache, Performance, Analytics, Crashlytics)
- Suppression de l'AuthWrapper et des routes d'authentification
- Routes simplifiées: '/', '/catalog', '/admin', et génération dynamique pour '/product'
- Thème simplifié avec Material 3 et couleur deepPurple

### 3. HomeScreen (`lib/screens/home_screen.dart`)

**Simplifié:**
- Ajout d'icônes aux boutons (Icons.store et Icons.admin_panel_settings)
- Utilisation de `ElevatedButton.icon` et `OutlinedButton.icon`
- Suppression du style personnalisé des boutons

### 4. CatalogScreen (`lib/screens/catalog_screen.dart`)

**Simplifié:**
- Suppression de l'intégration ProductService/Firestore
- Utilisation de données locales en mémoire (4 produits exemples)
- Ajout d'un filtre par catégorie avec dropdown
- Affichage en liste au lieu de grille
- Affichage du statut "Rupture" pour les produits non disponibles

**Produits exemples:**
1. iPhone 14 (phone, Apple, 950€)
2. Écran iPhone (screen, Apple, 120€)
3. Casque Bluetooth (accessory, Sony, 85€) - Rupture de stock
4. PC Portable HP (pc, HP, 699€)

### 5. ProductDetailScreen (`lib/screens/product_detail_screen.dart`)

**Amélioré:**
- Meilleure gestion de l'ouverture WhatsApp avec fallback
- Utilisation de `LaunchMode.externalApplication` comme mode principal
- Fallback vers `LaunchMode.platformDefault` si nécessaire
- Affichage amélioré avec ListView au lieu de Column
- Placeholder pour l'image (à remplacer par de vraies images plus tard)
- Désactivation du bouton WhatsApp si le produit est en rupture

**Numéro WhatsApp:** 221771234567 (à personnaliser)

### 6. AdminScreen (`lib/screens/admin_screen.dart`)

**Simplifié:**
- Suppression de la navigation vers AdminProductsScreen, AdminPromotionsScreen, AdminExcelScreen
- Ajout d'un formulaire de connexion simple (simulation)
- Validation des champs email et mot de passe
- Message indiquant que l'authentification sera branchée plus tard
- Action "Gérer les produits" avec message placeholder

## Dépendances

✅ `url_launcher: ^6.3.2` - Déjà présent dans pubspec.yaml

## Pour brancher Firebase plus tard

1. **Restaurer l'initialisation Firebase dans main.dart:**
   - Ajouter `WidgetsFlutterBinding.ensureInitialized()`
   - Ajouter `await Firebase.initializeApp()`
   - Optionnel: configurer l'émulateur Firestore

2. **Créer un ProductService:**
   - Créer `lib/services/product_service.dart`
   - Implémenter les méthodes CRUD avec Firestore
   - Ajouter les méthodes `fromMap()` et `toMap()` dans Product

3. **Intégrer l'authentification Firebase:**
   - Créer AuthService
   - Remplacer le formulaire de simulation dans AdminScreen
   - Ajouter les écrans de login/register

4. **Remplacer les données locales:**
   - Modifier CatalogScreen pour utiliser ProductService
   - Remplacer la liste `_allProducts` par un StreamBuilder ou FutureBuilder

## Commandes pour lancer l'application

```bash
# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run

# Ou pour le web
flutter run -d chrome
```

## Structure actuelle

```
lib/
├── main.dart                           # Point d'entrée simplifié
├── models/
│   └── product.dart                    # Modèle Product simplifié
└── screens/
    ├── home_screen.dart                # Écran d'accueil
    ├── catalog_screen.dart             # Catalogue avec données locales
    ├── product_detail_screen.dart      # Détails produit + WhatsApp
    └── admin_screen.dart               # Écran admin simplifié
```

## Fonctionnalités actuelles

✅ Navigation entre les écrans
✅ Catalogue de produits avec filtrage par catégorie
✅ Détails des produits
✅ Intégration WhatsApp pour commander
✅ Écran d'administration avec formulaire de connexion
✅ Gestion de l'état de stock (en stock / rupture)

## À implémenter plus tard

- [ ] Authentification Firebase
- [ ] Stockage des produits dans Firestore
- [ ] Upload d'images avec Firebase Storage
- [ ] Gestion des commandes
- [ ] Système de notifications
- [ ] Analytics et monitoring
- [ ] Mode hors ligne avec cache
