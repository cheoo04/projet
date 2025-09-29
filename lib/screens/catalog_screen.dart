import 'package:flutter/material.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Liste de produits fictifs pour l'exemple
    final products = [
      {'name': 'iPhone 14', 'category': 'phone'},
      {'name': 'Écran iPhone', 'category': 'screen'},
      {'name': 'Casque Bluetooth', 'category': 'accessory'},
      {'name': 'PC Portable HP', 'category': 'pc'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name']!),
            subtitle: Text(product['category']!),
            onTap: () {
              Navigator.pushNamed(context, '/product');
            },
          );
        },
      ),
    );
  }
}
