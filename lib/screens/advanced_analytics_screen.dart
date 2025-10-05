import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/advanced_analytics_service.dart';
import '../models/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  // Filtres
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedCategory;
  String _granularity = 'day';

  // Données
  Map<String, dynamic>? _categoryStats;
  Map<String, dynamic>? _timeSeriesStats;
  Map<String, dynamic>? _trendAnalysis;
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get();
      setState(() {
        _categories = categoriesSnapshot.docs
            .map((doc) => Category.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getCategoryStats(
          startDate: _startDate,
          endDate: _endDate,
          categoryFilter: _selectedCategory,
        ),
        _analyticsService.getTimeSeriesStats(
          startDate: _startDate,
          endDate: _endDate,
          granularity: _granularity,
          categoryFilter: _selectedCategory,
        ),
        _analyticsService.getTrendAnalysis(
          startDate: _startDate,
          endDate: _endDate,
          categoryFilter: _selectedCategory,
        ),
      ]);

      setState(() {
        _categoryStats = results[0];
        _timeSeriesStats = results[1];
        _trendAnalysis = results[2];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques avancées'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Catégories'),
            Tab(icon: Icon(Icons.timeline), text: 'Évolution'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendances'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFiltersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryAnalysisTab(),
                _buildTimeSeriesTab(),
                _buildTrendAnalysisTab(),
              ],
            ),
    );
  }

  Widget _buildCategoryAnalysisTab() {
    if (_categoryStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final categoryStatsMap =
        _categoryStats!['categoryStats'] as Map<String, dynamic>;
    final categories = categoryStatsMap.entries.toList()
      ..sort(
        (a, b) => (b.value['totalRevenue'] as double).compareTo(
          a.value['totalRevenue'] as double,
        ),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé de la période
          _buildPeriodSummary(),

          const SizedBox(height: 24),

          // Graphique en secteurs des revenus par catégorie
          _buildCategoryRevenueChart(categories),

          const SizedBox(height: 24),

          // Liste détaillée des catégories
          _buildCategoryDetailsList(categories),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesTab() {
    if (_timeSeriesStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final timeSeries = _timeSeriesStats!['timeSeries'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé
          _buildTimeSeriesSummary(),

          const SizedBox(height: 24),

          // Graphique des revenus dans le temps
          _buildRevenueTimeChart(timeSeries),

          const SizedBox(height: 24),

          // Graphique du nombre de commandes
          _buildOrdersTimeChart(timeSeries),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysisTab() {
    if (_trendAnalysis == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendSummary(),
          const SizedBox(height: 24),
          _buildVolatilityIndicator(),
          const SizedBox(height: 24),
          _buildPerformanceIndicators(),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary() {
    final period = _categoryStats!['period'];
    final totalRevenue = _categoryStats!['totalRevenue'] as double;
    final totalOrders = _categoryStats!['totalOrders'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la période',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${DateFormat('dd/MM/yyyy').format(period['startDate'])} - ${DateFormat('dd/MM/yyyy').format(period['endDate'])}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Revenus totaux',
                    '${totalRevenue.toStringAsFixed(0)} FCFA',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Commandes',
                    totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRevenueChart(
    List<MapEntry<String, dynamic>> categories,
  ) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des revenus par catégorie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: categories.take(6).map((entry) {
                    final revenue = entry.value['totalRevenue'] as double;
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                      Colors.purple,
                      Colors.teal,
                    ];
                    final colorIndex =
                        categories.indexOf(entry) % colors.length;

                    return PieChartSectionData(
                      value: revenue,
                      title:
                          '${entry.key}\n${(revenue / 1000).toStringAsFixed(0)}k',
                      color: colors[colorIndex],
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

  Widget _buildCategoryDetailsList(List<MapEntry<String, dynamic>> categories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails par catégorie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...categories.map((entry) {
              final stats = entry.value;
              return ExpansionTile(
                title: Text(entry.key),
                subtitle: Text(
                  '${(stats['totalRevenue'] as double).toStringAsFixed(0)} FCFA',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Revenus',
                                '${(stats['totalRevenue'] as double).toStringAsFixed(0)} FCFA',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Quantité vendue',
                                '${stats['totalQuantitySold']}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Commandes',
                                '${stats['totalOrders']}',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Panier moyen',
                                '${(stats['averageOrderValue'] as double).toStringAsFixed(0)} FCFA',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeSeriesSummary() {
    final summary = _timeSeriesStats!['summary'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution temporelle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Revenus totaux',
                    '${(summary['totalRevenue'] as double).toStringAsFixed(0)} FCFA',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Commandes',
                    '${summary['totalOrders']}',
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Périodes actives',
                    '${summary['periodsWithSales']}',
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTimeChart(List timeSeries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution des revenus',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
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
                          if (value.toInt() < timeSeries.length) {
                            final date =
                                timeSeries[value.toInt()]['date'] as String;
                            return Text(
                              date.split('-').last,
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
                      spots: timeSeries
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value['revenue'] as double,
                            ),
                          )
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

  Widget _buildOrdersTimeChart(List timeSeries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre de commandes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < timeSeries.length) {
                            final date =
                                timeSeries[value.toInt()]['date'] as String;
                            return Text(
                              date.split('-').last,
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
                  barGroups: timeSeries
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['orders'] as int).toDouble(),
                              color: Colors.green,
                              width: 16,
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSummary() {
    final trend = _trendAnalysis!['trend'];
    final summary = _trendAnalysis!['summary'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse des tendances',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  trend['direction'] == 'ascending'
                      ? Icons.trending_up
                      : trend['direction'] == 'descending'
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  color: trend['direction'] == 'ascending'
                      ? Colors.green
                      : trend['direction'] == 'descending'
                      ? Colors.red
                      : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tendance ${_getTrendText(trend['direction'])}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Force: ${_getStrengthText(trend['strength'])}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Revenus moyen par période: ${(summary['averageRevenue'] as double).toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolatilityIndicator() {
    final volatility = _trendAnalysis!['volatility'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volatilité des ventes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  volatility['level'] == 'high'
                      ? Icons.warning
                      : volatility['level'] == 'moderate'
                      ? Icons.info
                      : Icons.check_circle,
                  color: volatility['level'] == 'high'
                      ? Colors.red
                      : volatility['level'] == 'moderate'
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Niveau ${_getVolatilityText(volatility['level'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    final summary = _trendAnalysis!['summary'];
    final bestPeriod = summary['bestPeriod'];
    final worstPeriod = summary['worstPeriod'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicateurs de performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (bestPeriod != null) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Meilleure période: ${bestPeriod['date']}'),
                ],
              ),
              Text(
                '  Revenus: ${(bestPeriod['revenue'] as double).toStringAsFixed(0)} FCFA',
              ),
              const SizedBox(height: 8),
            ],
            if (worstPeriod != null) ...[
              Row(
                children: [
                  const Icon(Icons.trending_down, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Période la plus faible: ${worstPeriod['date']}'),
                ],
              ),
              Text(
                '  Revenus: ${(worstPeriod['revenue'] as double).toStringAsFixed(0)} FCFA',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTrendText(String direction) {
    switch (direction) {
      case 'ascending':
        return 'à la hausse 📈';
      case 'descending':
        return 'à la baisse 📉';
      default:
        return 'stable 📊';
    }
  }

  String _getStrengthText(String strength) {
    switch (strength) {
      case 'strong':
        return 'Forte';
      case 'moderate':
        return 'Modérée';
      default:
        return 'Faible';
    }
  }

  String _getVolatilityText(String level) {
    switch (level) {
      case 'high':
        return 'élevé (variations importantes)';
      case 'moderate':
        return 'modéré';
      default:
        return 'faible (stable)';
    }
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection de période
              ListTile(
                title: const Text('Date de début'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),

              // Sélection de catégorie
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Toutes les catégories'),
                  ),
                  ..._categories.map(
                    (category) => DropdownMenuItem(
                      value: category.name,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),

              // Granularité temporelle
              DropdownButtonFormField<String>(
                initialValue: _granularity,
                decoration: const InputDecoration(labelText: 'Granularité'),
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Par jour')),
                  DropdownMenuItem(value: 'week', child: Text('Par semaine')),
                  DropdownMenuItem(value: 'month', child: Text('Par mois')),
                ],
                onChanged: (value) => setState(() => _granularity = value!),
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
            onPressed: () {
              Navigator.pop(context);
              _loadAnalytics();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }
}
