import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'config/firestore_config.dart';
import 'config/app_theme.dart';
import 'models/product.dart';
import 'providers/app_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/promotion_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/modern_home_screen.dart';
import 'screens/modern_catalog_screen.dart';
import 'screens/modern_product_detail_screen.dart';
import 'screens/modern_cart_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/admin_screens_loader.dart'; // Chargement différé admin
import 'screens/auth_screen.dart';
import 'screens/account_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/security_screen.dart';
import 'screens/help_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/demo_data_screen.dart';
import 'services/analytics_service.dart';
import 'services/crash_handler.dart';
import 'services/fcm_service.dart';
import 'services/app_init_service.dart';
import 'web_config/web_router.dart';

void main() async {
  // Préserver le splash natif pendant l'initialisation (mobile uniquement)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Le splash natif ne fonctionne pas sur web
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Orientation portrait uniquement (mobile)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    // Initialisation Firebase - essentiel avant tout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialiser les données de locale pour le formatage des dates
    await initializeDateFormatting('fr_FR', null);

    // Lancer l'app immédiatement
    runApp(const MyApp());
    
    // Initialisations secondaires en arrière-plan (après le lancement de l'app)
    _initializeServicesInBackground();
    
  } catch (e) {
    // Retirer le splash en cas d'erreur (mobile uniquement)
    if (!kIsWeb) {
      FlutterNativeSplash.remove();
    }
    // En cas d'erreur d'initialisation, afficher un écran d'erreur
    runApp(ErrorApp(error: e.toString()));
  }
}

/// Initialise les services en arrière-plan après le lancement de l'app
Future<void> _initializeServicesInBackground() async {
  try {
    // Configuration du handler de messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Configuration Firestore optimisée
    await FirestoreConfig.configure();

    // Initialisation du monitoring
    await CrashHandler.initialize();
    await AnalyticsService.initialize();
    
    // Démarrer le listener de connectivité pour retry auto
    AppInitService.startConnectivityListener();
    
    // Initialisation FCM pour les notifications push (non-bloquant)
    try {
      await FCMService().initialize();
    } catch (e) {
      debugPrint('⚠️ FCM non initialisé: $e (normal en émulateur)');
    }
  } catch (e) {
    debugPrint('⚠️ Erreur initialisation services: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => ComparisonProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Utiliser GoRouter pour le web (URLs propres SEO-friendly)
          // et MaterialApp classique pour mobile (performance)
          if (kIsWeb) {
            return MaterialApp.router(
              title: 'Pharrell Phone',
              debugShowCheckedModeBanner: false,
              
              // Thèmes modernes avec support clair/sombre
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              
              // Configuration GoRouter pour le web
              routerConfig: WebRouter.router,
            );
          }
          
          // Version mobile classique (sans go_router)
          return MaterialApp(
            title: 'Pharrell Phone',
            debugShowCheckedModeBanner: false,
            
            // Thèmes modernes avec support clair/sombre
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Page d'accueil - Splash Screen
            home: const SplashScreen(),
            
            // Routes
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const ModernHomeScreen(),
              '/catalog': (context) => const ModernCatalogScreen(),
              '/cart': (context) => const ModernCartScreen(),
              '/comparison': (context) => const ComparisonScreen(),
              '/auth': (context) => const AuthScreen(),
              '/account': (context) => const AccountScreen(),
              '/my-orders': (context) => const MyOrdersScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/addresses': (context) => const AddressesScreen(),
              '/security': (context) => const SecurityScreen(),
              '/help': (context) => const HelpScreen(),
              '/privacy': (context) => const PrivacyScreen(),
              '/admin-login': (context) => const DeferredAdminLogin(),
              '/admin-dashboard': (context) => const DeferredAdminDashboard(),
              '/admin': (context) => const DeferredAdminNavigation(),
              '/demo-data': (context) => const DemoDataScreen(),
            },
            
            // Génération de routes dynamiques
            onGenerateRoute: (settings) {
              if (settings.name == '/product-detail') {
                final productId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => ModernProductDetailScreen(productId: productId),
                );
              }
              if (settings.name == '/product-form') {
                final product = settings.arguments as Product?;
                return MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: product),
                );
              }
              return null;
            },
            
            // Observers pour Analytics
            navigatorObservers: [
              AnalyticsService.observer,
            ],
          );
        },
      ),
    );
  }
}

/// Widget d'erreur en cas d'échec d'initialisation
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Redémarrer l'app
                    SystemNavigator.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Redémarrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}