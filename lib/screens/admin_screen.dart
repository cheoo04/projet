import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _manageProducts(BuildContext context) {
    // Implémenter la gestion des produits
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gérer les produits - Fonction à implémenter'),
      ),
    );
  }

  void _managePromotions(BuildContext context) {
    // Implémenter la gestion des promotions
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gérer les promotions - Fonction à implémenter'),
      ),
    );
  }

  void _manageExcelOrders(BuildContext context) {
    // Implémenter l'accès à la gestion Excel des commandes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gestion Excel des commandes - Fonction à implémenter'),
      ),
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
            const Text(
              'Interface d\'administration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
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
