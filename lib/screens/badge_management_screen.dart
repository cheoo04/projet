import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../services/dynamic_badge_service.dart';
import '../models/product_extensions.dart';

/// Écran d'administration des badges dynamiques
class BadgeManagementScreen extends StatefulWidget {
  const BadgeManagementScreen({super.key});

  @override
  State<BadgeManagementScreen> createState() => _BadgeManagementScreenState();
}

class _BadgeManagementScreenState extends State<BadgeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUpdating = false;
  int _updateProgress = 0;
  int _updateTotal = 0;
  Map<String, int>? _lastUpdateStats;

  // Listes de produits
  List<Product> _bestSellers = [];
  List<Product> _trending = [];
  List<Product> _newProducts = [];
  List<Product> _promoProducts = [];
  List<Product> _topRated = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        DynamicBadgeService.getBestSellers(limit: 20),
        DynamicBadgeService.getTrendingProducts(limit: 20),
        DynamicBadgeService.getNewProducts(limit: 20),
        DynamicBadgeService.getPromoProducts(limit: 20),
        DynamicBadgeService.getTopRatedProducts(limit: 20),
      ]);

      setState(() {
        _bestSellers = results[0];
        _trending = results[1];
        _newProducts = results[2];
        _promoProducts = results[3];
        _topRated = results[4];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateAllBadges() async {
    setState(() {
      _isUpdating = true;
      _updateProgress = 0;
      _updateTotal = 0;
    });

    try {
      final stats = await DynamicBadgeService.updateAllProductBadges(
        onProgress: (current, total) {
          setState(() {
            _updateProgress = current;
            _updateTotal = total;
          });
        },
      );

      setState(() {
        _lastUpdateStats = stats;
        _isUpdating = false;
      });

      // Recharger les produits
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${stats['updated']} produits mis à jour sur ${stats['total']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Badges Dynamiques'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _buildTab('🏆 Best-sellers', _bestSellers.length),
            _buildTab('🔥 Tendance', _trending.length),
            _buildTab('✨ Nouveaux', _newProducts.length),
            _buildTab('💰 Promos', _promoProducts.length),
            _buildTab('⭐ Top notés', _topRated.length),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isUpdating ? null : _loadProducts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière d'action
          _buildActionBanner(),

          // Progression de mise à jour
          if (_isUpdating) _buildProgressIndicator(),

          // Statistiques
          if (_lastUpdateStats != null && !_isUpdating)
            _buildStatsBar(),

          // Configuration des seuils
          _buildThresholdsCard(),

          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductList(_bestSellers, 'best-sellers'),
                      _buildProductList(_trending, 'tendance'),
                      _buildProductList(_newProducts, 'nouveaux'),
                      _buildProductList(_promoProducts, 'promos'),
                      _buildProductList(_topRated, 'top notés'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryViolet.withValues(alpha: 0.1),
            AppTheme.accentVioletLight.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Badges automatiques',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Générés selon les ventes, notes et stocks',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isUpdating ? null : _updateAllBadges,
            icon: _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isUpdating ? 'En cours...' : 'Mettre à jour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _updateTotal > 0 ? _updateProgress / _updateTotal : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mise à jour en cours...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '$_updateProgress / $_updateTotal',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            '${_lastUpdateStats!['total']}',
            Icons.inventory_2,
          ),
          _buildStatItem(
            'Mis à jour',
            '${_lastUpdateStats!['updated']}',
            Icons.check_circle,
            color: Colors.green,
          ),
          if ((_lastUpdateStats!['errors'] ?? 0) > 0)
            _buildStatItem(
              'Erreurs',
              '${_lastUpdateStats!['errors']}',
              Icons.error,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildThresholdsCard() {
    final thresholds = DynamicBadgeService.thresholds;
    return ExpansionTile(
      title: const Text(
        '⚙️ Configuration des seuils',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildThresholdChip(
              'Best-seller',
              '≥ ${thresholds.bestSellerSales} ventes',
              Colors.amber,
            ),
            _buildThresholdChip(
              'Populaire',
              '≥ ${thresholds.popularSales} ventes',
              Colors.purple,
            ),
            _buildThresholdChip(
              'Nouveau',
              '≤ ${thresholds.newProductDays} jours',
              Colors.blue,
            ),
            _buildThresholdChip(
              'Top noté',
              '≥ ${thresholds.topRatedMinRating}★ (${thresholds.topRatedMinReviews}+ avis)',
              Colors.orange,
            ),
            _buildThresholdChip(
              'Promo',
              '≥ ${thresholds.promoMinPercent}%',
              Colors.red,
            ),
            _buildThresholdChip(
              'Stock limité',
              '≤ ${thresholds.lowStockThreshold}',
              Colors.deepOrange,
            ),
            _buildThresholdChip(
              'Tendance',
              '≥ ${thresholds.trendingSalesWeek}/semaine',
              Colors.pink,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThresholdChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products, String emptyMessage) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun produit $emptyMessage',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final analysis = DynamicBadgeService.analyzeProduct(product);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.phone_android),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.phone_android),
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA • ${product.soldCount} ventes • ${(product.rating?.average ?? 0).toStringAsFixed(1)}★',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: analysis.badges.take(4).map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: badge.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () async {
                await DynamicBadgeService.updateProductBadges(product.id);
                await _loadProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Badges mis à jour'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              tooltip: 'Mettre à jour les badges',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

/// Widget de badge dynamique à utiliser dans les cartes produit
class DynamicBadgeWidget extends StatelessWidget {
  final ProductBadge badge;
  final bool compact;

  const DynamicBadgeWidget({
    super.key,
    required this.badge,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: badge.color,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        boxShadow: [
          BoxShadow(
            color: badge.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Barre de badges pour afficher plusieurs badges horizontalement
class DynamicBadgesBar extends StatelessWidget {
  final List<ProductBadge> badges;
  final int maxBadges;
  final bool compact;

  const DynamicBadgesBar({
    super.key,
    required this.badges,
    this.maxBadges = 3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final displayBadges = badges.take(maxBadges).toList();
    final remaining = badges.length - maxBadges;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayBadges.map((badge) => DynamicBadgeWidget(
              badge: badge,
              compact: compact,
            )),
        if (remaining > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(compact ? 4 : 6),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
