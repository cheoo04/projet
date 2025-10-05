import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/product_service.dart';
import '../services/stock_service.dart';
import '../services/excel_service.dart';
import '../widgets/admin_app_bar.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final StockService _stockService = StockService();
  final ExcelService _excelService = ExcelService();

  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Gestion des Stocks',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportDialog,
            tooltip: 'Exporter',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _showImportDialog,
            tooltip: 'Importer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques de stock
          _buildStockStatsCard(),
          const SizedBox(height: 16),

          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Stock Normal', icon: Icon(Icons.inventory)),
              Tab(text: 'Stock Faible', icon: Icon(Icons.warning_amber)),
              Tab(text: 'Rupture', icon: Icon(Icons.error)),
              Tab(text: 'Mouvements', icon: Icon(Icons.history)),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNormalStockTab(),
                _buildLowStockTab(),
                _buildOutOfStockTab(),
                _buildMovementsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStockAdjustmentDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Ajuster Stock'),
      ),
    );
  }

  Widget _buildStockStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _productService.getStockStatusCounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Total',
                  stats['total'].toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
                _buildStatItem(
                  'En Stock',
                  stats['inStock'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Stock Faible',
                  stats['lowStock'].toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Rupture',
                  stats['outOfStock'].toString(),
                  Icons.error,
                  Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNormalStockTab() {
    return FutureBuilder<List<Product>>(
      future: _productService.searchProducts(inStockOnly: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];
        final normalStockProducts = products
            .where((p) => p.stock > ProductService.defaultLowStockThreshold)
            .toList();

        if (normalStockProducts.isEmpty) {
          return const Center(child: Text('Aucun produit avec stock normal'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: normalStockProducts.length,
          itemBuilder: (context, index) {
            final product = normalStockProducts[index];
            return _buildProductCard(product, Colors.green);
          },
        );
      },
    );
  }

  Widget _buildLowStockTab() {
    return FutureBuilder<List<Product>>(
      future: _productService.getLowStockProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Aucun produit avec stock faible'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product, Colors.orange);
          },
        );
      },
    );
  }

  Widget _buildOutOfStockTab() {
    return FutureBuilder<List<Product>>(
      future: _productService.getOutOfStockProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Aucun produit en rupture de stock'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product, Colors.red);
          },
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    return StreamBuilder<List<StockMovement>>(
      stream: _stockService.getAllMovements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return const Center(child: Text('Aucun mouvement de stock'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            return _buildMovementCard(movement);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.2),
          child: Text(
            product.stock.toString(),
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product.brand} • ${product.category}'),
            Text(
              'Prix: ${NumberFormat('#,###', 'fr_FR').format(product.price)} FCFA',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showProductMovements(product),
              tooltip: 'Historique',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showStockAdjustmentDialog(product: product),
              tooltip: 'Ajuster stock',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    final isEntry = movement.isEntry;
    final color = isEntry ? Colors.green : Colors.red;
    final icon = isEntry ? Icons.add : Icons.remove;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          movement.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${movement.typeDisplayName} • ${movement.quantity > 0 ? '+' : ''}${movement.quantity}',
            ),
            Text(
              'Stock: ${movement.stockBefore} → ${movement.stockAfter}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Par ${movement.userName} • ${DateFormat('dd/MM/yyyy HH:mm').format(movement.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: movement.reason.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showMovementDetails(movement),
                tooltip: 'Détails',
              )
            : null,
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Tous les produits'),
              onTap: () {
                Navigator.pop(context);
                _exportData('products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Produits stock faible'),
              onTap: () {
                Navigator.pop(context);
                _exportData('low_stock');
              },
            ),
            ListTile(
              leading: const Icon(Icons.error),
              title: const Text('Produits en rupture'),
              onTap: () {
                Navigator.pop(context);
                _exportData('out_of_stock');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Mouvements de stock'),
              onTap: () {
                Navigator.pop(context);
                _exportData('movements');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer des produits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vous pouvez importer des produits depuis un fichier Excel.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _createImportTemplate();
              },
              icon: const Icon(Icons.download),
              label: const Text('Télécharger le modèle'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _importProducts();
              },
              icon: const Icon(Icons.upload),
              label: const Text('Importer le fichier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockAdjustmentDialog({Product? product}) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final reasonController = TextEditingController();

    if (product != null) {
      nameController.text = product.name;
      stockController.text = product.stock.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          product != null ? 'Ajuster le stock' : 'Rechercher un produit',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product == null)
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  hintText: 'Rechercher...',
                ),
              ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Nouveau stock'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de l\'ajustement',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _adjustStock(
                product,
                nameController.text,
                int.tryParse(stockController.text) ?? 0,
                reasonController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Ajuster'),
          ),
        ],
      ),
    );
  }

  void _showProductMovements(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Historique - ${product.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<StockMovement>>(
                  stream: _stockService.getMovementsByProduct(product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final movements = snapshot.data ?? [];
                    if (movements.isEmpty) {
                      return const Center(
                        child: Text('Aucun mouvement pour ce produit'),
                      );
                    }

                    return ListView.builder(
                      itemCount: movements.length,
                      itemBuilder: (context, index) {
                        return _buildMovementCard(movements[index]);
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovementDetails(StockMovement movement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du mouvement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Produit', movement.productName),
            _buildDetailRow('Type', movement.typeDisplayName),
            _buildDetailRow('Quantité', movement.quantity.toString()),
            _buildDetailRow('Stock avant', movement.stockBefore.toString()),
            _buildDetailRow('Stock après', movement.stockAfter.toString()),
            _buildDetailRow('Raison', movement.reason),
            _buildDetailRow('Utilisateur', movement.userName),
            _buildDetailRow(
              'Date',
              DateFormat('dd/MM/yyyy à HH:mm').format(movement.createdAt),
            ),
            if (movement.orderId != null)
              _buildDetailRow('Commande', movement.orderId!),
            if (movement.supplierId != null)
              _buildDetailRow('Fournisseur', movement.supplierId!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _exportData(String type) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      String filePath;
      switch (type) {
        case 'products':
          filePath = await _excelService.exportAllProducts();
          break;
        case 'low_stock':
          filePath = await _excelService.exportLowStockProducts();
          break;
        case 'out_of_stock':
          filePath = await _excelService.exportOutOfStockProducts();
          break;
        case 'movements':
          filePath = await _excelService.exportStockMovements();
          break;
        default:
          throw Exception('Type d\'export non reconnu');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export réussi: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createImportTemplate() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final filePath = await _excelService.createProductImportTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modèle créé: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importProducts() async {
    // Cette fonctionnalité nécessiterait un file picker
    // Pour l'instant, on affiche juste un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fonctionnalité d\'import à implémenter avec file_picker',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _adjustStock(
    Product? product,
    String productName,
    int newStock,
    String reason,
  ) async {
    if (product == null) {
      // Rechercher le produit par nom
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recherche de produit à implémenter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _stockService.adjustStock(
        productId: product.id,
        productName: product.name,
        newStock: newStock,
        reason: reason.isEmpty ? 'Ajustement manuel' : reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock ajusté avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir l'affichage
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
