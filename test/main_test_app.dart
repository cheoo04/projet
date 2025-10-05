import 'package:pharrell_phone/models/product.dart';
import 'package:pharrell_phone/screens/home_screen.dart';
import 'package:pharrell_phone/screens/catalog_screen.dart';
import 'package:pharrell_phone/screens/product_detail_screen.dart';
import 'package:pharrell_phone/screens/admin_screen.dart';
import 'package:pharrell_phone/screens/admin_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharrell_phone/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration pour l'émulateur Firestore (optionnel en debug)
    if (kDebugMode) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      } catch (e) {
        debugPrint(
          'Émulateur Firestore non disponible, utilisation de Firebase en ligne',
        );
      }
    }
  } catch (e) {
    debugPrint('Erreur Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Page non trouvée')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharrell Phone Admin',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/catalog':
            return MaterialPageRoute(builder: (_) => const CatalogScreen());
          case '/product':
            final args = settings.arguments;
            if (args is Product) {
              return MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: args),
              );
            }
            return _errorRoute();
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminScreen());
          case '/admin-full':
            return MaterialPageRoute(
              builder: (_) => const AdminNavigationScreen(),
            );
          default:
            return _errorRoute();
        }
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
