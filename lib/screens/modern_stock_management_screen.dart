import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../providers/app_providers.dart';
import '../services/stock_service.dart';
import '../services/excel_service.dart';

/// Écran moderne de gestion des stocks
/// Permet d'ajuster les stocks et de voir l'historique des mouvements
class ModernStockManagementScreen extends StatefulWidget {
  const ModernStockManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModernStockManagementScreen> createState() => _ModernStockManagementScreenState();
}

class _ModernStockManagementScreenState extends State<ModernStockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StockService _stockService = StockService();
  List<StockMovement> _movements = [];
  bool _isLoadingMovements = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMovements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoadingMovements = true);
    try {
      final movements = await _stockService.getMovements(limit: 50);
      setState(() {
        _movements = movements;
        _isLoadingMovements = false;
      });
    } catch (e) {
      setState(() => _isLoadingMovements = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Stocks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Ajustements'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportStock,
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdjustmentsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  /// Onglet des ajustements de stock
  Widget _buildAdjustmentsTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.products.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2,
            title: 'Aucun produit',
            message: 'Ajoutez des produits pour gérer les stocks',
            actionLabel: 'Ajouter un produit',
            onAction: () {
              context.push('/product-form');
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              return _buildStockCard(provider.products[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildStockCard(Product product) {
    final theme = Theme.of(context);
    final stockColor = AppTheme.getStockColor(product.stock);
    final stockText = AppTheme.getStockText(product.stock);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec image et infos
            Row(
              children: [
                // Image produit
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : 'https://via.placeholder.com/60',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.grey200,
                      child: const Icon(Icons.phone_android, color: AppTheme.grey400),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Infos produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Stock actuel et ajustements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stock actuel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock actuel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          AppTheme.getStockIcon(product.stock),
                          color: stockColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stock}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: stockColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Boutons d'ajustement
                Row(
                  children: [
                    _buildAdjustmentButton(
                      icon: Icons.remove,
                      color: AppTheme.error,
                      onPressed: () => _showAdjustmentDialog(
                        product,
                        StockMovementType.decrease,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAdjustmentButton(
                      icon: Icons.add,
                      color: AppTheme.success,
                      onPressed: () => _showAdjustmentDialog(
                        product,
                        StockMovementType.increase,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAdjustmentButton(
                      icon: Icons.edit,
                      color: AppTheme.primaryViolet,
                      onPressed: () => _showSetStockDialog(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Onglet de l'historique
  Widget _buildHistoryTab() {
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movements.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: 'Aucun historique',
        message: 'Les mouvements de stock apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          return _buildMovementCard(_movements[index]);
        },
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    final theme = Theme.of(context);
    final isIncrease = movement.type == StockMovementType.increase;
    final color = isIncrease ? AppTheme.success : AppTheme.error;
    final icon = isIncrease ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          movement.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(movement.reason),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(movement.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isIncrease ? '+' : '-'}${movement.quantity}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Dialog d'ajustement de stock (ajouter/retirer)
  void _showAdjustmentDialog(Product product, StockMovementType type) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final isIncrease = type == StockMovementType.increase;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isIncrease ? 'Ajouter au stock' : 'Retirer du stock',
          style: TextStyle(
            color: isIncrease ? AppTheme.success : AppTheme.error,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info produit
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock actuel: ${product.stock}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              
              // Quantité
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    isIncrease ? Icons.add : Icons.remove,
                    color: isIncrease ? AppTheme.success : AppTheme.error,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              // Raison
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantité invalide')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final reason = reasonController.text.isEmpty
                    ? (isIncrease ? 'Ajout manuel' : 'Retrait manuel')
                    : reasonController.text;

                await _stockService.recordMovement(
                  productId: product.id,
                  productName: product.name,
                  quantity: quantity,
                  type: type,
                  reason: reason,
                );

                // Recharger les données
                await _loadMovements();
                if (mounted) {
                  final provider = Provider.of<ProductProvider>(context, listen: false);
                  await provider.loadProducts();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock ${isIncrease ? 'ajouté' : 'retiré'} avec succès'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncrease ? AppTheme.success : AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  /// Dialog pour définir un stock exact
  void _showSetStockDialog(Product product) {
    final stockController = TextEditingController(text: product.stock.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Définir le stock',
          style: TextStyle(color: AppTheme.primaryViolet),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock actuel: ${product.stock}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nouveau stock',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory, color: AppTheme.primaryViolet),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock == null || newStock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock invalide')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final difference = newStock - product.stock;
                if (difference == 0) return;

                final type = difference > 0
                    ? StockMovementType.increase
                    : StockMovementType.decrease;
                final quantity = difference.abs();
                final reason = reasonController.text.isEmpty
                    ? 'Ajustement manuel'
                    : reasonController.text;

                await _stockService.recordMovement(
                  productId: product.id,
                  productName: product.name,
                  quantity: quantity,
                  type: type,
                  reason: reason,
                );

                await _loadMovements();
                if (mounted) {
                  final provider = Provider.of<ProductProvider>(context, listen: false);
                  await provider.loadProducts();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock mis à jour avec succès'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _exportStock() async {
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      
      if (provider.products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun produit à exporter'),
          ),
        );
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Exporter via ExcelService
      final excelService = ExcelService();
      final filePath = await excelService.exportAllProducts();
      
      // Fermer le dialogue de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export réussi: $filePath'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement si ouvert
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
