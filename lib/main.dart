import 'package:flutter/material.dart';
import 'models/product.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-commerce Multi-plateforme',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/catalog': (context) => const CatalogScreen(),
        '/admin': (context) => const AdminScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/product') {
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          );
        }
        return null;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
