import 'package:flutter/material.dart';
import 'admin_products_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_excel_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _manageProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
    );
  }

  void _managePromotions(BuildContext context) {
    // Implémenter la gestion des promotions
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPromotionsScreen()),
    );
  }

  void _manageExcelOrders(BuildContext context) {
    // Implémenter l'accès à la gestion Excel des commandes
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminExcelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _manageProducts(context),
              child: const Text('Gérer les produits'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _managePromotions(context),
              child: const Text('Gérer les promotions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _manageExcelOrders(context),
              child: const Text('Gestion Excel des commandes'),
            ),
          ],
        ),
      ),
    );
  }
}
