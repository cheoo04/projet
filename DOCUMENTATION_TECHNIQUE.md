# 📱 Pharrell Phone - Documentation Technique Complète

> Application mobile e-commerce Flutter pour la vente de smartphones, accessoires et équipements informatiques.

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Technologies utilisées](#technologies-utilisées)
3. [Architecture du projet](#architecture-du-projet)
4. [Structure des fichiers](#structure-des-fichiers)
5. [Modèles de données](#modèles-de-données)
6. [Services](#services)
7. [Providers (Gestion d'état)](#providers-gestion-détat)
8. [Écrans](#écrans)
9. [Widgets réutilisables](#widgets-réutilisables)
10. [Configuration](#configuration)
11. [Fonctionnalités clés](#fonctionnalités-clés)
12. [Installation et démarrage](#installation-et-démarrage)
13. [Base de données Firebase](#base-de-données-firebase)
14. [Bonnes pratiques](#bonnes-pratiques)

---

## 🎯 Vue d'ensemble

**Pharrell Phone** est une application e-commerce moderne développée avec Flutter, permettant :

- 🛒 **Clients** : Parcourir le catalogue, ajouter au panier, passer des commandes
- 👨‍💼 **Administrateurs** : Gérer les produits, stocks, commandes, avis et utilisateurs
- 📊 **Analytics** : Tableaux de bord, statistiques de ventes, analyses avancées

### Caractéristiques principales

| Fonctionnalité | Description |
|----------------|-------------|
| Multi-plateforme | Android, iOS, Web, Desktop (Windows, macOS, Linux) |
| Mode hors-ligne | Cache local avec Hive et SQLite |
| Thème adaptatif | Mode clair et sombre automatique |
| Notifications Push | Firebase Cloud Messaging |
| Authentification | Email/mot de passe + Google Sign-In |
| Sécurité | Authentification biométrique optionnelle |

---

## 🛠 Technologies utilisées

### Framework principal
```yaml
Flutter SDK: ^3.9.2
Dart: ^3.9.0
```

### Backend & Base de données
| Package | Version | Utilisation |
|---------|---------|-------------|
| `firebase_core` | ^4.1.1 | Initialisation Firebase |
| `cloud_firestore` | ^6.0.2 | Base de données NoSQL |
| `firebase_auth` | ^6.1.0 | Authentification |
| `firebase_storage` | ^13.0.2 | Stockage de fichiers/images |
| `firebase_messaging` | ^16.1.0 | Notifications push |
| `firebase_analytics` | ^12.0.2 | Analytics |
| `firebase_crashlytics` | ^5.0.2 | Rapports de crash |

### Gestion d'état
| Package | Version | Utilisation |
|---------|---------|-------------|
| `provider` | ^6.1.5 | State management réactif |

### Cache & Mode hors-ligne
| Package | Version | Utilisation |
|---------|---------|-------------|
| `hive` | ^2.2.3 | Cache local léger |
| `hive_flutter` | ^1.1.0 | Intégration Flutter pour Hive |
| `sqflite` | ^2.3.0 | Base de données SQLite |
| `dio` | ^5.4.0 | Client HTTP avancé |
| `dio_cache_interceptor` | ^3.4.4 | Cache HTTP |

### UI/UX
| Package | Version | Utilisation |
|---------|---------|-------------|
| `google_fonts` | ^6.3.2 | Polices Google |
| `cached_network_image` | ^3.3.0 | Images avec cache |
| `shimmer` | ^3.0.0 | Skeleton loaders |
| `flutter_slidable` | ^3.0.0 | Actions par glissement |
| `badges` | ^3.1.1 | Badges de notification |
| `fl_chart` | ^1.1.1 | Graphiques interactifs |

### Utilitaires
| Package | Version | Utilisation |
|---------|---------|-------------|
| `intl` | ^0.18.0 | Internationalisation/formatage |
| `image_picker` | ^0.8.4+11 | Sélection d'images |
| `flutter_image_compress` | ^2.1.0 | Compression d'images |
| `share_plus` | ^12.0.0 | Partage natif |
| `url_launcher` | ^6.3.2 | Ouverture d'URLs |
| `pdf` / `printing` | ^3.11.3 / ^5.14.2 | Génération de PDF |
| `excel` | ^2.0.6 | Export Excel |
| `local_auth` | ^2.1.8 | Auth biométrique |
| `connectivity_plus` | ^5.0.2 | Vérification réseau |

---

## 🏗 Architecture du projet

L'application suit une architecture **Feature-based** avec séparation claire des responsabilités :

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│  (Screens, Widgets)                                     │
├─────────────────────────────────────────────────────────┤
│                    State Management                     │
│  (Providers: ProductProvider, CartProvider, Theme)      │
├─────────────────────────────────────────────────────────┤
│                    Business Logic                       │
│  (Services: Auth, Product, Order, Review, etc.)         │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                         │
│  (Models: Product, Order, AppUser, Review, etc.)        │
├─────────────────────────────────────────────────────────┤
│                    External Services                    │
│  (Firebase, Hive, SQLite, APIs)                         │
└─────────────────────────────────────────────────────────┘
```

### Flux de données

```
User Action → Widget → Provider → Service → Firebase/Cache
                ↑                              ↓
                └──────── State Update ────────┘
```

---

## 📁 Structure des fichiers

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── firebase_options.dart     # Configuration Firebase auto-générée
│
├── config/                   # Configuration globale
│   ├── app_theme.dart        # Thèmes clair/sombre
│   ├── firestore_config.dart # Configuration Firestore
│   └── font_config.dart      # Configuration des polices
│
├── models/                   # Modèles de données
│   ├── product.dart          # Modèle Produit (principal)
│   ├── product_extensions.dart # Extensions du produit
│   ├── app_user.dart         # Modèle Utilisateur
│   ├── order.dart            # Modèle Commande
│   ├── review.dart           # Modèle Avis
│   ├── category.dart         # Modèle Catégorie
│   ├── promotion.dart        # Modèle Promotion
│   ├── supplier.dart         # Modèle Fournisseur
│   ├── notification.dart     # Modèle Notification
│   ├── stock_movement.dart   # Modèle Mouvement de stock
│   └── audit_log.dart        # Modèle Journal d'audit
│
├── providers/                # Gestion d'état
│   ├── app_providers.dart    # ProductProvider, CartProvider
│   └── theme_provider.dart   # Gestion du thème
│
├── services/                 # Logique métier
│   ├── auth_service.dart     # Authentification
│   ├── product_service.dart  # CRUD Produits
│   ├── order_service.dart    # Gestion commandes
│   ├── review_service.dart   # Gestion avis
│   ├── category_service.dart # Gestion catégories
│   ├── stock_service.dart    # Gestion stocks
│   ├── promotion_service.dart # Gestion promotions
│   ├── notification_service.dart # Notifications locales
│   ├── fcm_service.dart      # Firebase Cloud Messaging
│   ├── analytics_service.dart # Analytics
│   ├── audit_service.dart    # Journalisation
│   ├── offline_cache_service.dart # Cache hors-ligne
│   ├── biometric_auth_service.dart # Auth biométrique
│   ├── image_compression_service.dart # Compression images
│   ├── excel_service.dart    # Export Excel
│   ├── invoice_service.dart  # Génération factures
│   └── ...                   # Autres services
│
├── screens/                  # Écrans de l'application
│   ├── splash_screen.dart    # Écran de démarrage
│   ├── onboarding_screen.dart # Onboarding
│   ├── auth_screen.dart      # Connexion/Inscription
│   ├── modern_home_screen.dart # Accueil
│   ├── modern_catalog_screen.dart # Catalogue
│   ├── modern_product_detail_screen.dart # Détail produit
│   ├── modern_cart_screen.dart # Panier
│   ├── account_screen.dart   # Compte utilisateur
│   ├── my_orders_screen.dart # Mes commandes
│   ├── all_reviews_screen.dart # Tous les avis
│   ├── admin/                # Écrans admin
│   ├── client/               # Écrans client
│   ├── visitor/              # Écrans visiteur
│   └── ...                   # Autres écrans
│
├── widgets/                  # Composants réutilisables
│   ├── optimized_product_card.dart # Cartes produit
│   ├── trust_signal_card.dart # Signaux de confiance
│   ├── skeleton_loaders.dart  # Placeholders de chargement
│   ├── optimized_image.dart   # Images optimisées
│   ├── add_review_dialog.dart # Dialog ajout avis
│   ├── styled_dialogs.dart    # Dialogs stylisés
│   ├── admin_app_bar.dart     # AppBar admin
│   └── ...                    # Autres widgets
│
└── data/                     # Données statiques
```

---

## 📊 Modèles de données

### 🛍️ Product (Produit)

Le modèle principal de l'application, très riche en informations :

```dart
class Product {
  // Identifiants
  final String id;
  final String name;
  final String category;      // 'phone', 'accessory', 'screen', 'pc'
  final String categoryId;
  final String brand;         // 'Apple', 'Samsung', 'HP', etc.
  
  // Prix
  final double price;
  final double? originalPrice; // Prix avant promo (optionnel)
  
  // Stock
  final bool isInStock;
  final int stock;
  final int lowStockThreshold; // Seuil alerte stock (défaut: 5)
  
  // Descriptions
  final String description;
  final String? shortDescription; // 120 caractères max
  final List<String> highlights;  // Points forts
  
  // Médias
  final List<String> imageUrls;
  
  // Spécifications
  final Map<String, dynamic> specs;
  final List<ProductSpec> detailedSpecs;
  
  // Social proof (signaux de confiance)
  final ProductRating? rating;      // Note moyenne + nombre d'avis
  final int soldCount;              // Nombre de ventes
  
  // Livraison & Garantie
  final ShippingInfo shipping;      // Délais, coût, zones
  final WarrantyInfo warranty;      // Durée, type, couverture
  final ReturnPolicy returnPolicy;  // Conditions de retour
  
  // Authenticité
  final AuthenticityInfo authenticity;
  
  // Variantes & Badges
  final List<ProductVariant> variants;  // Couleurs, stockage
  final List<ProductBadge> badges;      // Nouveau, Promo, Best-seller
  
  // Métadonnées
  final bool isFeatured;
  final DateTime createdAt;
  
  // Getters calculés
  int? get discountPercent;    // % de réduction
  double? get savings;         // Économie en FCFA
  bool get hasPromotion;
  bool get isLowStock;
  bool get isOutOfStock;
}
```

### 👤 AppUser (Utilisateur)

```dart
enum UserRole { visitor, client, admin, manager }

class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final Map<String, dynamic> permissions;
  final bool profileCompleted;
  
  // Getters
  String get fullName;
  bool get canAccessAdmin;
  bool get canManageUsers;
  bool get isClient;
  bool get isAdmin;
}
```

### 📦 Order (Commande)

```dart
enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;  // Calculé automatiquement
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
}

class OrderItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;  // Calculé automatiquement
}
```

### ⭐ Review (Avis)

```dart
enum ReviewStatus { pending, approved, rejected }

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final int rating;           // 1-5
  final String? comment;
  final List<String> photoUrls;
  final DateTime createdAt;
  final ReviewStatus status;
  final bool isVerifiedPurchase;
  final String? adminResponse;
  final DateTime? moderatedAt;
  final String? moderatedBy;
}
```

---

## ⚙️ Services

### AuthService - Authentification

```dart
class AuthService {
  // Flux d'authentification
  Stream<User?> get authStateChanges;
  User? get currentUser;
  bool get isAuthenticated;
  
  // Méthodes principales
  Future<UserCredential?> signInWithEmailAndPassword(email, password);
  Future<UserCredential?> signInWithGoogle();
  Future<UserCredential> signUp(email, password, firstName, lastName);
  Future<void> signOut();
  Future<void> resetPassword(email);
  
  // Gestion utilisateur Firestore
  Future<AppUser?> getUserData(userId);
  Future<void> updateUserProfile(userId, data);
  
  // Sécurité
  bool _isAccountLocked(email);  // Protection brute force
}
```

### ProductService - Gestion des produits

```dart
class ProductService {
  // CRUD
  Future<List<Product>> fetchAll();
  Future<void> add(Product p);
  Future<void> update(Product p);
  Future<void> delete(String id);
  
  // Streaming temps réel
  Stream<List<Product>> getAll();
  Stream<List<Product>> getProductsPaginated({limit, lastDocument});
  
  // Requêtes spécifiques
  Future<List<Product>> getProductsByCategory({category, limit});
  Future<List<Product>> getLowStockProducts({threshold});
  Future<List<Product>> searchProducts(query);
  Future<List<Product>> getFeaturedProducts();
}
```

### ReviewService - Gestion des avis

```dart
class ReviewService {
  // Lecture
  Stream<List<Review>> getProductReviews(productId);
  Future<List<Review>> getPendingReviews();
  Future<Map<String, dynamic>> getProductReviewStats(productId);
  
  // Écriture
  Future<void> addReview(Review review);
  Future<void> approveReview(reviewId, {adminId});
  Future<void> rejectReview(reviewId, {adminId});
  Future<void> addAdminResponse(reviewId, response);
}
```

### OrderService - Gestion des commandes

```dart
class OrderService {
  // CRUD
  Stream<List<Order>> getOrders();
  Future<Order?> getOrder(orderId);
  Future<void> createOrder(Order order);
  Future<void> updateOrderStatus(orderId, OrderStatus status);
  
  // Requêtes utilisateur
  Stream<List<Order>> getUserOrders(userId);
}
```

### Autres services importants

| Service | Description |
|---------|-------------|
| `FCMService` | Notifications push Firebase |
| `NotificationService` | Notifications locales |
| `OfflineCacheService` | Cache Hive pour mode hors-ligne |
| `BiometricAuthService` | Authentification empreinte/face |
| `AnalyticsService` | Tracking Firebase Analytics |
| `CrashHandler` | Rapports Crashlytics |
| `ImageCompressionService` | Compression avant upload |
| `ExcelService` | Export de données en Excel |
| `InvoiceService` | Génération de factures PDF |
| `AuditService` | Journal des actions admin |
| `StockService` | Mouvements de stock |

---

## 🔄 Providers (Gestion d'état)

### ProductProvider

```dart
class ProductProvider extends ChangeNotifier {
  // État
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  static const int _pageSize = 20;
  
  // Méthodes
  Future<void> loadProducts({bool refresh});
  Future<void> loadMoreProducts();
  void searchProducts(String query);
  void filterByCategory(String category);
  void _applyFilters();
  
  // Notifie de manière sécurisée (évite les erreurs setState pendant build)
  void _notifySafely();
}
```

### CartProvider

```dart
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  
  // Getters
  List<CartItem> get items;
  int get itemCount;
  double get totalAmount;
  
  // Méthodes
  void addToCart(Product product, {int quantity = 1});
  void removeFromCart(String productId);
  void updateQuantity(String productId, int quantity);
  void clearCart();
}
```

### ThemeProvider

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode;
  bool get isDarkMode;
  
  void toggleTheme();
  void setThemeMode(ThemeMode mode);
}
```

---

## 📱 Écrans

### Écrans publics (Client/Visiteur)

| Écran | Fichier | Description |
|-------|---------|-------------|
| Splash | `splash_screen.dart` | Écran de démarrage avec logo animé |
| Onboarding | `onboarding_screen.dart` | Présentation première utilisation |
| Accueil | `modern_home_screen.dart` | Produits vedettes, catégories, promos |
| Catalogue | `modern_catalog_screen.dart` | Liste produits avec filtres |
| Détail produit | `modern_product_detail_screen.dart` | Fiche produit complète |
| Panier | `modern_cart_screen.dart` | Gestion du panier |
| Authentification | `auth_screen.dart` | Connexion/Inscription |
| Compte | `account_screen.dart` | Profil utilisateur |
| Mes commandes | `my_orders_screen.dart` | Historique commandes |
| Tous les avis | `all_reviews_screen.dart` | Avis d'un produit |
| Notifications | `notifications_screen.dart` | Centre de notifications |

### Écrans administrateur

| Écran | Fichier | Description |
|-------|---------|-------------|
| Login Admin | `modern_admin_screens.dart` | Connexion sécurisée admin |
| Dashboard | `modern_admin_screens.dart` | Tableau de bord statistiques |
| Navigation | `modern_admin_navigation.dart` | Navigation bottom tabs |
| Produits | `modern_admin_products_screen.dart` | CRUD produits |
| Formulaire produit | `product_form_screen.dart` | Ajout/Édition produit |
| Commandes | `modern_order_management_screen.dart` | Gestion commandes |
| Stocks | `modern_stock_management_screen.dart` | Gestion des stocks |
| Avis | `review_management_screen.dart` | Modération des avis |
| Catégories | `modern_category_management_screen.dart` | Gestion catégories |
| Promotions | `promotion_management_screen.dart` | Gestion promos |
| Utilisateurs | `user_management_screen.dart` | Gestion utilisateurs |
| Notifications | `modern_notification_management_screen.dart` | Envoi notifications |
| Analytics | `advanced_analytics_screen.dart` | Analyses avancées |
| Données démo | `demo_data_screen.dart` | Import données test |

---

## 🧩 Widgets réutilisables

### OptimizedProductCard

Carte produit pour le catalogue avec toutes les informations :

```dart
class OptimizedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  
  // Affiche: image, marque, nom, prix, promo, garantie
}
```

### CompactProductCard

Carte compacte pour l'accueil (informations essentielles) :

```dart
class CompactProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  
  // Affiche: image, marque, nom, prix, badge promo
}
```

### Trust Signal Cards

Signaux de confiance (livraison, garantie, avis) :

```dart
class ShippingChip extends StatelessWidget {
  final ShippingInfo shipping;
  // Badge compact avec icône et délai
}

class WarrantyChip extends StatelessWidget {
  final WarrantyInfo warranty;
  // Badge compact avec durée garantie
}

class RatingCard extends StatelessWidget {
  final ProductRating rating;
  // Étoiles + nombre d'avis
}
```

### Skeleton Loaders

Placeholders de chargement animés :

```dart
class ProductCardSkeleton extends StatelessWidget {...}
class ProductDetailSkeleton extends StatelessWidget {...}
class ListItemSkeleton extends StatelessWidget {...}
```

### OptimizedImage

Image avec cache et placeholder :

```dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  // Utilise CachedNetworkImage avec shimmer pendant le chargement
}
```

---

## ⚙️ Configuration

### AppTheme

Système de thème complet avec support clair/sombre :

```dart
class AppTheme {
  // Palette principale (extraite du logo)
  static const Color primaryViolet = Color(0xFF9B6DB8);
  static const Color secondaryVioletDark = Color(0xFF2D1B4E);
  static const Color accentVioletLight = Color(0xFFC084FC);
  
  // Fonds
  static const Color backgroundLight = Color(0xFFF8F7FC);
  static const Color backgroundDark = Color(0xFF1A0F2E);
  
  // États
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Thèmes complets
  static ThemeData lightTheme = ThemeData(...);
  static ThemeData darkTheme = ThemeData(...);
}
```

### FirestoreConfig

Optimisations Firestore :

```dart
class FirestoreConfig {
  static Future<void> configure() async {
    // Cache local activé
    // Persistence hors-ligne
    // Optimisations réseau
  }
}
```

---

## ✨ Fonctionnalités clés

### 1. Signaux de confiance (Trust Signals)

L'application met en avant des éléments de confiance sur chaque produit :

- ⭐ **Notes et avis** : Étoiles + nombre d'avis vérifiés
- 🚚 **Livraison** : Délais, coût, zones de livraison
- 🛡️ **Garantie** : Durée et type de couverture
- ↩️ **Retours** : Politique de retour claire
- ✅ **Authenticité** : Badge produit vérifié/officiel
- 🏷️ **Badges** : Nouveau, Promo, Best-seller

### 2. Mode hors-ligne

- Cache local avec **Hive** pour données fréquentes
- **SQLite** pour données complexes
- Synchronisation automatique au retour en ligne
- Indicateur de connectivité

### 3. Système de notifications

- **Push notifications** via Firebase Cloud Messaging
- **Notifications locales** pour rappels
- Centre de notifications dans l'app
- Ciblage par segment utilisateur

### 4. Authentification sécurisée

- Email/mot de passe avec validation
- Google Sign-In
- Protection contre brute force (verrouillage après 5 échecs)
- Authentification biométrique optionnelle
- Gestion des rôles (visitor, client, admin, manager)

### 5. Gestion avancée des produits

- Variantes (couleur, stockage)
- Images multiples avec galerie
- Spécifications détaillées
- Badges dynamiques
- Stock avec alertes seuil bas

### 6. Modération des avis

- Workflow : En attente → Approuvé/Rejeté
- Badge "Achat vérifié"
- Réponses admin aux avis
- Photos dans les avis
- Calcul statistiques temps réel

### 7. Analytics & Monitoring

- Firebase Analytics pour tracking utilisateur
- Firebase Crashlytics pour rapports d'erreurs
- Dashboard admin avec graphiques
- Export données en Excel

---

## 🚀 Installation et démarrage

### Prérequis

- Flutter SDK ^3.9.2
- Dart ^3.9.0
- Compte Firebase avec projet configuré
- Android Studio ou VS Code

### Installation

```bash
# 1. Cloner le projet
git clone <repository-url>
cd projet

# 2. Installer les dépendances
flutter pub get

# 3. Générer les fichiers Hive (si modifiés)
flutter packages pub run build_runner build

# 4. Lancer en développement
flutter run
```

### Configuration Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com)
2. Ajouter les apps Android/iOS/Web
3. Télécharger les fichiers de configuration :
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Exécuter `flutterfire configure` pour mettre à jour `firebase_options.dart`

### Build production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 🗄️ Base de données Firebase

### Collections Firestore

```
firestore/
├── products/           # Produits
│   └── {productId}
├── users/              # Utilisateurs
│   └── {userId}
├── orders/             # Commandes
│   └── {orderId}
├── reviews/            # Avis
│   └── {reviewId}
├── categories/         # Catégories
│   └── {categoryId}
├── promotions/         # Promotions
│   └── {promoId}
├── notifications/      # Notifications
│   └── {notifId}
├── suppliers/          # Fournisseurs
│   └── {supplierId}
├── stock_movements/    # Mouvements de stock
│   └── {movementId}
└── audit_logs/         # Journaux d'audit
    └── {logId}
```

### Règles de sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Lecture publique des produits
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Avis : lecture publique, écriture authentifiée
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Utilisateurs : lecture/écriture propre profil
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Commandes : lecture propres commandes
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager']);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
  }
}
```

---

## ✅ Bonnes pratiques

### Code

1. **Séparation des responsabilités** : UI, Logic, Data séparés
2. **Modèles immuables** : Utiliser `final` pour les propriétés
3. **Null safety** : Toujours vérifier les valeurs nullables
4. **Gestion d'erreurs** : Try-catch avec messages utilisateur
5. **Logging** : Utiliser `LoggingService` pour le debug

### Performance

1. **Pagination** : Charger les listes par pages de 20
2. **Cache images** : `CachedNetworkImage` partout
3. **Skeleton loaders** : Afficher pendant le chargement
4. **Lazy loading** : Charger les données à la demande
5. **Debounce** : Sur la recherche (300ms)

### Sécurité

1. **Validation serveur** : Règles Firestore strictes
2. **Sanitisation** : Nettoyer les inputs utilisateur
3. **Tokens FCM** : Rafraîchir après connexion
4. **Mots de passe** : Minimum 8 caractères
5. **Logs sensibles** : Ne jamais logger les mots de passe

### UI/UX

1. **Feedback utilisateur** : Snackbars, dialogs informatifs
2. **États vides** : Messages quand liste vide
3. **Gestion erreurs** : Écrans d'erreur avec retry
4. **Responsive** : Adapter aux différentes tailles d'écran
5. **Accessibilité** : Labels pour lecteurs d'écran

---

## 📞 Support

Pour toute question ou problème :

1. Consulter la documentation dans `/docs/`
2. Vérifier les fichiers `*.md` à la racine du projet
3. Consulter les logs Firebase Console

---

*Document généré le <!-- DATE --> - Pharrell Phone v1.0.0*
