import 'package:flutter/material.dart';
import '../models/product.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final List<Product> _allProducts = const [
    Product(
      id: '1',
      name: 'iPhone 14',
      category: 'phone',
      brand: 'Apple',
      price: 950.0,
      description: 'Nouveau smartphone Apple',
      imageUrls: [],
      isInStock: true,
    ),
    Product(
      id: '2',
      name: 'Écran iPhone',
      category: 'screen',
      brand: 'Apple',
      price: 120.0,
      description: 'Écran de remplacement',
      imageUrls: [],
      isInStock: true,
    ),
    Product(
      id: '3',
      name: 'Casque Bluetooth',
      category: 'accessory',
      brand: 'Sony',
      price: 85.0,
      description: 'Casque sans fil confort',
      imageUrls: [],
      isInStock: false,
    ),
    Product(
      id: '4',
      name: 'PC Portable HP',
      category: 'pc',
      brand: 'HP',
      price: 699.0,
      description: 'Portable performant pour le quotidien',
      imageUrls: [],
      isInStock: true,
    ),
  ];

  final List<String> _categories = const ['all', 'phone', 'accessory', 'screen', 'pc'];
  String _selectedCategory = 'all';

  List<Product> get _filtered {
    if (_selectedCategory == 'all') return _allProducts;
    return _allProducts.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c == 'all' ? 'Toutes' : c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v ?? 'all'),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (context, i) {
          final p = _filtered[i];
          final outOfStock = !p.isInStock;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                child: Text(p.name.characters.first),
              ),
              title: Text(p.name),
              subtitle: Text('${p.brand} • ${p.category} • ${p.price.toStringAsFixed(2)} €'),
              trailing: outOfStock
                  ? const Chip(
                      label: Text('Rupture'),
                      backgroundColor: Color(0xFFFFE5E5),
                      labelStyle: TextStyle(color: Colors.red),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/product', arguments: p);
              },
            ),
          );
        },
      ),
    );
  }
}
