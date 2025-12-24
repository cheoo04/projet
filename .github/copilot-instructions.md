# Pharrell Phone - Copilot Instructions

## Architecture Overview
Flutter e-commerce app with **feature-based architecture**:
```
UI (Screens/Widgets) → Providers (State) → Services (Business Logic) → Firebase/Hive (Data)
```
- **State Management**: Provider with `ChangeNotifier` (see `lib/providers/`)
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics)
- **Offline Support**: Hive + Firestore persistent cache
- **Responsive Design**: Adaptive layouts for mobile and desktop

## 🌐 MIGRATION WEB EN COURS

### Contexte
Migration de l'app mobile Flutter vers application web pour:
- Permettre accès aux utilisateurs iOS (majorité des clients)
- Éviter coût développement iOS natif
- Déploiement sur Firebase Hosting

### Objectifs techniques
- **Performance**: < 3s temps de chargement, Lighthouse > 90
- **SEO**: Indexable Google, meta tags dynamiques
- **Responsive**: Desktop (1920x1080) + Mobile (375x667)
- **PWA**: Installable, offline-capable
- **Parité fonctionnelle**: ~95% des features mobiles

### Stack web additionnel
```yaml
# Ajouter à pubspec.yaml
dependencies:
  go_router: ^17.0.0              # Navigation web avec URLs propres
  web: ^1.1.1                     # SEO dynamique (DOM manipulation)
  responsive_framework: ^1.5.1    # Layouts adaptatifs
  visibility_detector: ^0.4.0+2   # Lazy loading
```

### Routing web (go_router)
```dart
// Configuration routes web
final router = GoRouter(
  urlPathStrategy: UrlPathStrategy.path, // URLs sans #
  routes: [
    GoRoute(path: '/', name: 'home', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/products', name: 'catalog', builder: (_, __) => CatalogScreen()),
    GoRoute(path: '/product/:id', name: 'product_detail', 
      builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/cart', name: 'cart', builder: (_, __) => CartScreen()),
    GoRoute(path: '/admin', name: 'admin', redirect: _adminGuard),
  ],
);
```

### Adaptations fonctionnalités mobile → web

| Fonctionnalité Mobile | Adaptation Web | Status |
|-----------------------|----------------|--------|
| FCM Notifications | Firebase Cloud Messaging Web + Browser API | ✅ Implémenté |
| Auth biométrique | Désactivée (non supportée web) | ⚠️ À remplacer par 2FA |
| ImagePicker | Input HTML5 `<input type="file">` | ✅ Implémenté |
| SharePlus | Web Share API + boutons sociaux | 🔄 En cours |
| Cache Hive/SQLite | IndexedDB + Cache API | 🔄 En cours |

### Responsive breakpoints
```dart
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) => 
    MediaQuery.of(context).size.width < mobile;
  static bool isDesktop(BuildContext context) => 
    MediaQuery.of(context).size.width >= desktop;
}

// Usage dans widgets
Widget build(BuildContext context) {
  return ResponsiveBreakpoints.isDesktop(context)
    ? DesktopLayout()
    : MobileLayout();
}
```

### SEO Configuration
```dart
// lib/web_config/seo_config.dart (avec conditional imports)
// Utilise package:web pour manipulation DOM native
class SEOConfig {
  static void updateMetaTags(Product product) {
    // Met à jour title, meta description, Open Graph, JSON-LD
    updateDocumentTitle('${product.name} - Pharrell Phone');
    updateMetaTag('description', product.shortDescription ?? '');
    updateMetaTag('og:title', '${product.name} - Pharrell Phone');
    updateMetaTag('og:image', product.imageUrls.first);
    updateJsonLd(_buildProductJsonLd(product)); // Schema.org
  }
}

// Fichiers: seo_config.dart + seo_config_stub.dart + seo_config_web.dart
```

### Build & Deploy web
```bash
# Build production optimisé (Flutter 3.38+)
flutter build web --release -O4

# Note: --web-renderer html est obsolète depuis Flutter 3.38
# Le renderer est maintenant automatiquement optimisé

# Test local
flutter run -d chrome

# Déploiement Firebase
firebase deploy --only hosting

# CI/CD
# Voir .github/workflows/deploy-web.yml
```

### Performance web patterns
1. **Lazy loading images**: Utiliser `CachedNetworkImage` avec `BlurHash`
2. **Code splitting**: `import 'admin.dart' deferred as admin;`
3. **Pagination**: 20 produits par page avec `DocumentSnapshot`
4. **Cache agressif**: Service worker avec stratégie `network-first`

### PWA Configuration
Fichiers essentiels:
- `web/manifest.json`: Configuration PWA (nom, icônes, couleurs, shortcuts)
- `web/custom-service-worker.js`: Stratégie de cache personnalisée (network-first)
- `web/index.html`: Meta tags SEO optimisés

### Migration checklist
- [x] Phase 1: Configuration base (go_router, responsive) ✅ **DONE**
  - [x] Installer packages web (go_router, responsive_framework, visibility_detector, web)
  - [x] Créer structure lib/web_config/
  - [x] Configurer go_router avec routes propres
  
- [x] Phase 2: Adaptation UI (layouts desktop/mobile) ✅ **DONE**
  - [x] Implémenter ResponsiveBreakpoints (lib/web_config/responsive_config.dart)
  - [x] Créer layouts desktop avec sidebar (lib/widgets/layouts/desktop_layout.dart)
  - [x] Adapter ProductCard pour desktop (lib/widgets/desktop_product_card.dart)
  - [x] Appliquer grille responsive au catalogue (modern_catalog_screen.dart)
  - [x] Adapter HomeScreen pour desktop (max-width, grille produits, masquer bottom nav)
  
- [x] Phase 3: Optimisations (lazy loading, code splitting) ✅ **DONE**
  - [x] Convertir images hero en WebP (économie ~8.8 MB) ✅
  - [x] Implémenter lazy loading images (lib/widgets/lazy_image.dart) ✅
  - [x] Code splitting admin avec `deferred as admin` (admin_screens_loader.dart) ✅
  - [ ] Optimiser bundle size (< 2MB) - Actuellement 7.6MB main.dart.js ⚠️
  - [x] Configurer service worker avec cache strategy (custom-service-worker.js) ✅
  
- [x] Phase 4: SEO (meta tags dynamiques, sitemap) ✅ **DONE**
  - [x] Créer SEOConfig.updateMetaTags() avec package:web ✅
  - [x] Implémenter Schema.org JSON-LD pour produits ✅
  - [x] Configurer manifest.json PWA complet ✅
  - [x] Favicon et icônes PWA avec logo Pharrell Phone ✅
  - [x] Titre page personnalisé (Pharrell Phone - Boutique Smartphones) ✅
  - [ ] Générer sitemap.xml automatiquement
  - [ ] Tester Google Search Console

- [x] Phase 5: Corrections bugs web ✅ **EN COURS**
  - [x] Corriger Image.file pour web (kIsWeb check) ✅
  - [x] Corriger Crashlytics pour web (non supporté) ✅
  - [x] Corriger routes Navigator.pushNamed → context.go/push ✅
  - [x] Corriger export Excel/PDF pour web (WebFileSaver) ✅
  - [x] Corriger bouton déconnexion admin ✅
  - [x] Corriger bouton "Voir la boutique" ✅
  
- [ ] Phase 6: Testing (Lighthouse > 90, Safari iOS) ⏳ **TODO**
  - [ ] Tests Lighthouse (Performance, SEO, Accessibility, Best Practices)
  - [ ] Tests manuels Safari iOS (cible prioritaire)
  - [ ] Tests responsive sur devices réels
  - [ ] Load testing avec Artillery ou K6
  
- [ ] Phase 7: Déploiement (Firebase Hosting + CI/CD) ⏳ **TODO**
  - [ ] Configurer .github/workflows/deploy-web.yml
  - [ ] Setup environnements staging/prod
  - [ ] Premier déploiement staging
  - [ ] Migration DNS vers Firebase Hosting

## Key Patterns

### Provider Pattern
Use `_notifySafely()` to avoid "setState during build" errors:
```dart
void _notifySafely() {
  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
    notifyListeners();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}
```

### Model Serialization
Models have dual serialization methods:
- `toMap()` / `fromMap()` - generic Map handling
- `toFirestore()` / `fromFirestore()` - Firestore-specific with Timestamp conversion

### Service Singletons
Services use factory singleton pattern:
```dart
static final MyService _instance = MyService._internal();
factory MyService() => _instance;
MyService._internal();
```

## Services Hierarchy
**TIER 1 - Critical (always used):**
- `auth_service.dart` - Authentication, user management, Google Sign-In
- `product_service.dart` - CRUD products, search, pagination
- `offline_cache_service.dart` - Hive cache, offline mode, sync

**TIER 2 - Important:**
- `order_service.dart` - Order management, status updates
- `review_service.dart` - Review moderation
- `fcm_service.dart` - Push notifications

**TIER 3 - Utilities:**
- `image_compression_service.dart` - Image optimization
- `analytics_service.dart` - Tracking
- `excel_service.dart`, `invoice_service.dart` - Data export

## Web-Specific Services

**New services for web migration:**
- `lib/services/web_fcm_service.dart` - Firebase Cloud Messaging for web (browser notifications)
- `lib/services/web_image_picker_service.dart` - HTML5 file input wrapper
- `lib/services/web_file_saver.dart` - Cross-platform file download (conditional imports)
- `lib/services/web_file_saver_web.dart` - HTML5 Blob download for web
- `lib/services/web_file_saver_stub.dart` - Stub for non-web platforms
- `lib/services/crash_handler.dart` - Crashlytics with kIsWeb check (disabled on web)
- `lib/web_config/web_router.dart` - Go Router configuration
- `lib/web_config/seo_config.dart` - Dynamic meta tags (conditional imports)
- `lib/web_config/seo_config_web.dart` - DOM manipulation avec package:web
- `lib/web_config/seo_config_stub.dart` - No-op pour mobile
- `lib/web_config/responsive_config.dart` - Breakpoint utilities + ResponsiveContainer
- `lib/widgets/layouts/desktop_layout.dart` - Layout desktop avec sidebar
- `lib/widgets/desktop_product_card.dart` - ProductCard optimisé desktop

**Web adaptations pattern:**
```dart
// Platform detection
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Use web-specific implementation
  await WebImagePickerService.pickImage();
} else {
  // Use mobile implementation
  await ImagePicker().pickImage(source: ImageSource.gallery);
}
```

## Project Structure
| Directory | Purpose |
|-----------|---------|
| `lib/config/` | Theme (`app_theme.dart`), Firestore config |
| `lib/models/` | Data classes with Firebase serialization |
| `lib/providers/` | `ProductProvider`, `CartProvider`, `ThemeProvider` |
| `lib/services/` | 30+ service classes (auth, product, order, cache, etc.) |
| `lib/screens/` | UI screens, organized by feature (`admin/`, `client/`, `visitor/`) |
| `lib/widgets/` | Reusable components (`OptimizedProductCard`, `skeleton_loaders`, etc.) |

## Styling
- **Primary color**: `#9B6DB8` (violet) defined in `lib/config/app_theme.dart`
- **Font**: Poppins (local fallback) with Google Fonts
- **Theme modes**: Light (`AppTheme.lightTheme`) and Dark (`AppTheme.darkTheme`)

## 🚀 WORKFLOWS WEB SPÉCIFIQUES

### Développement web
```bash
# Lancer en mode web avec hot reload
flutter run -d chrome

# Lancer avec DevTools
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Build développement (non minifié)
flutter build web

# Build production optimisé (Flutter 3.38+)
flutter build web --release -O4

# Analyser taille bundle
flutter build web --analyze-size
```

### Testing web
```bash
# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage

# Test Lighthouse (après build)
npm install -g lighthouse
cd build/web && python -m http.server 8000
lighthouse http://localhost:8000 --view
```

### Déploiement
```bash
# Firebase Hosting
firebase deploy --only hosting

# Déploiement canal staging
firebase hosting:channel:deploy staging --expires 7d

# Rollback si nécessaire
firebase hosting:rollback
```

### Debug web
1. **Chrome DevTools**: F12 → Onglet "Console" pour logs Flutter
2. **Network throttling**: DevTools → Network → Fast 3G (simuler mobile)
3. **Responsive mode**: Ctrl+Shift+M (tester breakpoints)
4. **Flutter DevTools**: `flutter run -d chrome` puis ouvrir lien dans console

### Performance monitoring
```bash
# Profiler performance
flutter run -d chrome --profile

# Générer rapport dependencies
flutter pub deps --style=compact > deps.txt

# Analyser code mort
flutter analyze
```

## Firebase Collections
| Collection | Key fields | Security |
|------------|------------|----------|
| `products` | name, price, stock, category, imageUrls, specs | Public read, admin write |
| `users` | email, role (visitor/client/admin/manager), firstName, lastName | Owner or admin |
| `orders` | items[], status, customerEmail, deliveryAddress | Owner or admin |

## Security Considerations

### Firebase Security Rules (firestore.rules)
**Key principles:**
- Public read for products/categories (SEO-friendly)
- Authenticated write for orders/reviews
- Admin-only write for products/users management

**Critical rules:**
```javascript
// Product write protection
match /products/{productId} {
  allow read: if true; // Public for SEO
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

// User data privacy
match /users/{userId} {
  allow read: if request.auth.uid == userId || isAdmin();
  allow write: if request.auth.uid == userId;
}

function isAdmin() {
  return request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
}
```

### Web-Specific Security
1. **HTTPS Enforced**: Firebase Hosting auto-redirects HTTP → HTTPS
2. **CSP Headers**: Configure in `firebase.json`:
```json
{
  "hosting": {
    "headers": [{
      "source": "**",
      "headers": [{
        "key": "Content-Security-Policy",
        "value": "default-src 'self'; img-src 'self' https://firebasestorage.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
      }]
    }]
  }
}
```
3. **API Keys**: Exposées côté client OK (Firebase gère la sécurité via rules)
4. **Rate Limiting**: Activer Cloud Armor si trafic important

### Authentication Security
- **Password strength**: Minimum 8 caractères (enforced in `auth_service.dart`)
- **Brute force protection**: 5 tentatives max, verrouillage 15 min
- **Session management**: Firebase tokens auto-refresh
- **Google Sign-In**: OAuth 2.0 sécurisé

## User Roles
Defined in `lib/models/app_user.dart`: `visitor`, `client`, `admin`, `manager`
- Admin check: `user.canAccessAdmin` or `user.isAdmin`
- Firestore rules enforce role-based access

## Routing Strategy
**Current (Mobile):** `MaterialApp` with simple named routes in `main.dart`

**Web Migration:** `go_router` with clean URLs (no `#`)
```dart
// Target route structure
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_,__) => HomeScreen()),
    GoRoute(path: '/product/:id', builder: (_,s) => ProductDetail(id: s.pathParameters['id']!)),
    GoRoute(path: '/cart', builder: (_,__) => CartScreen()),
    GoRoute(path: '/admin', builder: (_,__) => AdminDashboard()),
  ],
)
```
**Why go_router:** SEO indexing + deep linking require clean URLs without hash fragments.

## Commands
```bash
# Development
flutter pub get              # Install dependencies
flutter run                  # Run app (auto-selects platform)
flutter run -d chrome        # Run web version

# Testing
flutter test                 # Run all tests
flutter test --coverage      # Generate coverage report

# Build - Mobile
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle (Play Store)

# Build - Web
flutter build web --release --web-renderer html   # Web build (Safari compatible)

# Deployment
./deploy_firebase.sh                  # Firebase App Distribution (mobile)
firebase deploy --only hosting        # Firebase Hosting (web)
firebase hosting:channel:deploy staging  # Staging channel
```

### Web (nouveau)
```bash
# Développement
flutter run -d chrome                    # Lancer app web
flutter run -d web-server --web-port 3000  # Serveur web personnalisé

# Build
flutter build web --release              # Build production
flutter build web --web-renderer html    # Build optimisé SEO

# Tests
flutter test                             # Tests unitaires
flutter test test/services/product_service_test.dart  # Test spécifique
flutter drive --target=test_driver/app.dart  # Tests d'intégration

# Déploiement
firebase deploy --only hosting           # Deploy production
firebase hosting:channel:deploy staging  # Deploy staging

# Maintenance
flutter clean                            # Nettoyer cache build
flutter pub get                          # Installer dépendances
flutter pub upgrade                      # Mettre à jour packages
```

### Firebase
```bash
# Firestore
firebase firestore:indexes               # Vérifier index
firebase firestore:rules                 # Vérifier règles

# Hosting
firebase hosting:sites:list              # Lister sites
firebase hosting:channel:list            # Lister canaux staging

# Logs
firebase functions:log                   # Logs Cloud Functions (si utilisé)
```

## Testing Patterns
**Unit Tests (Services):**
```dart
// Mock Firebase with fake_cloud_firestore
final fakeFirestore = FakeFirebaseFirestore();
final productService = ProductService(firestore: fakeFirestore);
await productService.add(testProduct);
```

**Widget Tests:**
```dart
// Use pump/pumpAndSettle for async widgets
await tester.pumpWidget(MaterialApp(home: ProductCard(product: mock)));
await tester.pumpAndSettle();
expect(find.text('iPhone 15'), findsOneWidget);
```

**TODO:** Integration tests not yet implemented.

## Common Web Issues & Solutions

### Issue 1: "setState during build" errors
**Symptom:** `setState() or markNeedsBuild() called during build`
**Solution:** Use `_notifySafely()` pattern (see Key Patterns section)

### Issue 2: Images not loading on web
**Symptom:** CORS errors in browser console
**Solution:** Configure Firebase Storage CORS:
```bash
# Create cors.json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]

# Apply to bucket
gsutil cors set cors.json gs://your-bucket-name.appspot.com
```

### Issue 3: Slow initial load on web
**Symptom:** White screen > 5 seconds
**Solutions:**
1. Enable code splitting: `import 'admin.dart' deferred as admin;`
2. Optimize images: WebP format, max 1000px width
3. Use `--web-renderer html` for better performance
4. Enable aggressive caching in service worker

### Issue 4: FCM notifications not working on web
**Symptom:** No browser permission popup
**Solution:** Generate VAPID key in Firebase Console:
```dart
String? token = await FirebaseMessaging.instance.getToken(
  vapidKey: 'YOUR_VAPID_KEY_HERE', // From Firebase Console > Project Settings > Cloud Messaging
);
```

### Issue 5: Authentication biométrique fails on web
**Symptom:** LocalAuth not supported error
**Solution:** Platform check before using:
```dart
if (!kIsWeb && Platform.isAndroid || Platform.isIOS) {
  final canAuth = await BiometricAuthService.canAuthenticate();
  if (canAuth) await BiometricAuthService.authenticate();
}
```

### Issue 6: Hive not working on web
**Symptom:** HiveError: Box not found
**Solution:** Use IndexedDB adapter for web:
```dart
if (kIsWeb) {
  // Web uses IndexedDB automatically
  await Hive.initFlutter();
} else {
  // Mobile uses local storage
  await Hive.initFlutter();
}
```

## Environments
| Env | Firebase Project | Deployment |
|-----|------------------|------------|
| dev | first-pro-cheoo | Local emulator |
| staging | first-pro-cheoo | `firebase hosting:channel` |
| prod | first-pro-cheoo | `firebase deploy` |

CI/CD: `.github/workflows/deploy-web.yml` (web deployment pipeline)

## Performance Benchmarks

### Target Metrics (Web Production)
| Metric | Target | Tool |
|--------|--------|------|
| Lighthouse Performance | > 90 | PageSpeed Insights |
| First Contentful Paint (FCP) | < 1.5s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Time to Interactive (TTI) | < 3.0s | Lighthouse |
| Total Blocking Time (TBT) | < 200ms | Lighthouse |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse |
| Bundle Size (main.dart.js) | < 2MB | `flutter build web --analyze-size` |

### Current Results (à mettre à jour après optimisations)
```bash
# Mesurer performance
flutter build web --release --web-renderer html
cd build/web && python -m http.server 8000
lighthouse http://localhost:8000 --output json --output-path ./report.json

# Résultats attendus après Phase 3-4
Performance: 92/100
Accessibility: 95/100
Best Practices: 100/100
SEO: 98/100
```

### Optimization Checklist
- [ ] Images: WebP format, lazy loading, BlurHash placeholders
- [ ] Code: Tree shaking, deferred imports, minification
- [ ] Caching: Service worker, HTTP cache headers
- [ ] CDN: Firebase Hosting CDN activé
- [ ] Fonts: Local fallback avant Google Fonts

## Test Accounts
- Admin: `admin@pharrell.com` / `admin123`
- Client: `client@pharrell.com` / `client123`

## Web Migration Notes (Current Goal)
Per `code.instructions.md`, migrating to web with:
1. **Routing**: Implement `go_router` for web-friendly URLs
2. **Responsive**: Use breakpoints (mobile/tablet/desktop)
3. **PWA**: Configure `manifest.json` and service worker
4. **Adaptations**: Replace `ImagePicker` with HTML5 input, disable biometric auth on web

## Code Conventions
- French comments and UI text (localized for France)
- Date formatting: `intl` package with `fr_FR` locale
- Async initialization in `main.dart` splits critical (Firebase) from background (FCM, analytics)
- Use `debugPrint()` with emoji prefixes: ✅ success, ⚠️ warning, ❌ error
