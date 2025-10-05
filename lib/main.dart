import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config/font_config.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/visitor/visitor_home_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'models/product.dart';
import 'screens/product_detail_screen.dart';
import 'screens/analytics_test_screen.dart';
import 'services/biometric_auth_service.dart';
import 'services/offline_cache_service.dart';
import 'services/performance_service.dart';
import 'services/crash_handler.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation préférée
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔥 INITIALISATION DU GESTIONNAIRE DE CRASHES
    await CrashHandler.initialize();

    // Initialise Firebase Analytics
    await AnalyticsService.initialize();

    // Configuration pour l'émulateur Firestore (optionnel en debug)
    if (kDebugMode) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
        debugPrint('✅ Émulateur Firestore connecté');
      } catch (e) {
        debugPrint(
          '⚠️ Émulateur Firestore non disponible, utilisation de Firebase en ligne',
        );
      }
    }
    debugPrint('✅ Firebase initialisé avec succès');

    // Initialiser les nouveaux services
    await _initializeServices();
  } catch (e) {
    debugPrint('❌ Erreur Firebase: $e');
  }

  runApp(const MyApp());
}

// Initialiser tous les services avancés
Future<void> _initializeServices() async {
  try {
    // Initialiser les services avec timeout pour éviter les blocages
    await Future.wait([
      BiometricAuthService().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Timeout initialisation BiometricAuthService');
        },
      ),
      OfflineCacheService().initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout initialisation OfflineCacheService');
        },
      ),
      PerformanceOptimizationService().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            '⚠️ Timeout initialisation PerformanceOptimizationService',
          );
        },
      ),
    ]).catchError((e) {
      debugPrint(
        '⚠️ Erreur lors de l\'initialisation de certains services: $e',
      );
      // Continue quand même
      return <void>[];
    });

    debugPrint('✅ Services avancés initialisés');
  } catch (e) {
    debugPrint('⚠️ Erreur initialisation services: $e');
    // L'application peut continuer même si certains services échouent
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharrell Phone',
      navigatorObservers: [AnalyticsService.observer],
      debugShowCheckedModeBanner: false,
      theme: FontConfig.getAppTheme().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // AuthWrapper gère la navigation basée sur l'état d'authentification
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/visitor': (context) => const VisitorHomeScreen(),
        '/client': (context) => const ClientHomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/analytics_test': (context) => const AnalyticsTestScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/product':
            final args = settings.arguments;
            if (args is Product) {
              return MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: args),
              );
            }
            return _errorRoute();
          default:
            return _errorRoute();
        }
      },
      // Builder pour gérer les erreurs de rendu et de police
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Page non trouvée', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(
                'La page que vous recherchez n\'existe pas.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
