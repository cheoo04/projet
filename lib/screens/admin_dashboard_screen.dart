import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  List<Order> _orders = [];
  List<Product> _products = [];
  bool _isLoading = true;

  // Statistiques
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _lowStockProducts = 0;
  final Map<String, double> _revenueByMonth = {};
  final Map<String, int> _ordersByStatus = {};
  List<Product> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les commandes et produits
      final ordersSnapshot = await _orderService.getAll().first;
      final productsSnapshot = await _productService.getAll().first;

      _orders = ordersSnapshot;
      _products = productsSnapshot;

      _calculateStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStatistics() {
    // Revenus totaux - utiliser totalAmount directement
    _totalRevenue = _orders.fold(0.0, (sum, order) => sum + order.totalAmount);
    _totalOrders = _orders.length;
    _totalProducts = _products.length;

    // Produits en stock faible (< 10)
    _lowStockProducts = _products.where((p) => p.stock < 10).length;

    // Revenus par mois (6 derniers mois)
    _revenueByMonth.clear();
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('MMM yyyy').format(month);
      _revenueByMonth[monthStr] = 0;
    }

    for (final order in _orders) {
      final monthStr = DateFormat('MMM yyyy').format(order.createdAt);
      if (_revenueByMonth.containsKey(monthStr)) {
        _revenueByMonth[monthStr] =
            _revenueByMonth[monthStr]! + order.totalAmount;
      }
    }

    // Commandes par statut
    _ordersByStatus.clear();
    for (final order in _orders) {
      String statusStr = order.status.toString().split('.').last;
      _ordersByStatus[statusStr] = (_ordersByStatus[statusStr] ?? 0) + 1;
    }

    // Top 5 produits les plus vendus
    final productSales = <String, int>{};
    for (final order in _orders) {
      for (final item in order.items) {
        productSales[item.productId] =
            (productSales[item.productId] ?? 0) + item.quantity;
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topProducts = sortedProducts
        .take(5)
        .map(
          (entry) => _products.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => Product(
              id: entry.key,
              name: 'Produit inconnu',
              brand: '',
              category: '',
              price: 0,
              description: '',
              imageUrls: const [],
              isInStock: false,
              stock: 0,
              supplierReference: '',
              specs: const {},
              createdAt: DateTime.now(),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques principales
              _buildStatsCards(),
              const SizedBox(height: 24),

              // Graphique des revenus
              _buildRevenueChart(),
              const SizedBox(height: 24),

              // Graphique des commandes par statut
              _buildOrderStatusChart(),
              const SizedBox(height: 24),

              // Top produits
              _buildTopProducts(),
              const SizedBox(height: 24),

              // Alertes
              _buildAlerts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Revenus totaux',
          '${_totalRevenue.toStringAsFixed(0)} FCFA',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Commandes',
          _totalOrders.toString(),
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildStatCard(
          'Produits',
          _totalProducts.toString(),
          Icons.inventory,
          Colors.orange,
        ),
        _buildStatCard(
          'Stock faible',
          _lowStockProducts.toString(),
          Icons.warning,
          _lowStockProducts > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution des revenus (6 derniers mois)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = _revenueByMonth.keys.toList();
                          if (value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueByMonth.values
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des commandes par statut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _ordersByStatus.entries.map((entry) {
                    final colors = {
                      'pending': Colors.orange,
                      'confirmed': Colors.blue,
                      'shipped': Colors.purple,
                      'delivered': Colors.green,
                      'cancelled': Colors.red,
                    };
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      color: colors[entry.key] ?? Colors.grey,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 des produits les plus vendus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topProducts.length,
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(product.name),
                  subtitle: Text('${product.price.toStringAsFixed(0)} FCFA'),
                  trailing: Text('Stock: ${product.stock}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    final lowStockProducts = _products.where((p) => p.stock < 10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Alertes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lowStockProducts.isEmpty)
              const Text(
                'Aucune alerte pour le moment',
                style: TextStyle(color: Colors.green),
              )
            else
              Column(
                children: lowStockProducts.map((product) {
                  return ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.red),
                    title: Text(product.name),
                    subtitle: Text('Stock critique: ${product.stock} unités'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Naviguer vers l'édition du produit
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réapprovisionner'),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
