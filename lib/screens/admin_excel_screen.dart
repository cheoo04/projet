import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';
import '../services/excel_service.dart';
import '../services/order_service.dart';

class AdminExcelScreen extends StatefulWidget {
  const AdminExcelScreen({super.key});

  @override
  State<AdminExcelScreen> createState() => _AdminExcelScreenState();
}

class _AdminExcelScreenState extends State<AdminExcelScreen> {
  final ExcelService _excelService = ExcelService();
  final OrderService _orderService = OrderService();

  bool _isLoading = false;
  bool _exportInProgress = false; // debounce flag
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _orderService.getOrderStats();
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des stats: $e')),
        );
      }
    }
  }

  Future<void> _exportWithLoading(
    Future<String> Function() exportFunction,
    String actionName,
  ) async {
    if (_exportInProgress) return; // prevent rapid double tap
    _exportInProgress = true;
    setState(() => _isLoading = true);

    try {
      final filePath = await exportFunction();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('$actionName réussi!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Partager',
              onPressed: () async {
                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(filePath)],
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur partage: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      });
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _exportInProgress = false;
    }
  }

  Future<void> _exportAllOrders() async {
    await _exportWithLoading(
      () => _excelService.exportAllOrders(),
      'Export de toutes les commandes',
    );
  }

  Future<void> _exportByStatus(OrderStatus status) async {
    await _exportWithLoading(
      () => _excelService.exportOrdersByStatus(status),
      'Export des commandes ${status.displayName.toLowerCase()}',
    );
  }

  Future<void> _exportByDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (dateRange != null) {
      await _exportWithLoading(
        () => _excelService.exportOrdersByDateRange(
          dateRange.start,
          dateRange.end,
        ),
        'Export des commandes par période',
      );
    }
  }

  Future<void> _exportMonthlyReport() async {
    final date = await showMonthYearPicker(context);
    if (date != null) {
      await _exportWithLoading(
        () => _excelService.exportMonthlyReport(date.year, date.month),
        'Export du rapport mensuel',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Excel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isLoading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_stats != null) _buildStatsCard(),
                const SizedBox(height: 16),
                _buildSectionCard(
                  'Exports Rapides',
                  Icons.flash_on,
                  Colors.orange,
                  [
                    _buildExportTile(
                      'Toutes les commandes',
                      'Export complet de toutes les commandes',
                      Icons.download,
                      _exportAllOrders,
                    ),
                    _buildExportTile(
                      'Rapport mensuel complet',
                      'Rapport détaillé avec statistiques',
                      Icons.assessment,
                      _exportMonthlyReport,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  'Export par Statut',
                  Icons.filter_list,
                  Colors.blue,
                  OrderStatus.values
                      .map(
                        (status) => _buildExportTile(
                          'Commandes ${status.displayName.toLowerCase()}',
                          'Export des commandes avec le statut ${status.displayName}',
                          Icons.file_download,
                          () => _exportByStatus(status),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  'Exports Personnalisés',
                  Icons.tune,
                  Colors.green,
                  [
                    _buildExportTile(
                      'Par période',
                      'Sélectionner une plage de dates',
                      Icons.date_range,
                      _exportByDateRange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Génération du fichier Excel en cours...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Statistiques Rapides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Commandes totales',
                    _stats!['totalOrders'].toString(),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ce mois',
                    _stats!['thisMonthOrders'].toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'CA Total',
                    '${(_stats!['totalRevenue'] as double).toStringAsFixed(0)} F',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Panier moyen',
                    '${(_stats!['averageOrderValue'] as double).toStringAsFixed(0)} F',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
  color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Future<DateTime?> showMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner le mois'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(now.year - 2),
            lastDate: now,
            selectedDate: now,
            onChanged: (date) => Navigator.pop(context, date),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
