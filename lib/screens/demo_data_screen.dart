import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/demo_data_service.dart';

/// Écran de gestion des données de démonstration
/// Permet de peupler et nettoyer la base de données pour les tests
class DemoDataScreen extends StatefulWidget {
  const DemoDataScreen({super.key});

  @override
  State<DemoDataScreen> createState() => _DemoDataScreenState();
}

class _DemoDataScreenState extends State<DemoDataScreen> {
  bool _isLoading = false;
  bool _hasDemoData = false;
  String _statusMessage = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _checkDemoData();
  }

  Future<void> _checkDemoData() async {
    final has = await DemoDataService.hasDemoData();
    if (mounted) {
      setState(() => _hasDemoData = has);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Données de test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(theme),
            
            const SizedBox(height: 24),

            // Status
            if (_isLoading) _buildProgress(theme),
            
            const SizedBox(height: 24),

            // Actions
            _buildActionCard(
              theme: theme,
              title: 'Peupler avec des données de démo',
              subtitle: '4 catégories, 10 produits avec tous les attributs',
              icon: Icons.add_box,
              color: AppTheme.success,
              onTap: _isLoading ? null : _seedDemoData,
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              theme: theme,
              title: 'Supprimer les données de démo',
              subtitle: 'Supprime uniquement les données créées par ce service',
              icon: Icons.delete_sweep,
              color: Colors.orange,
              onTap: _isLoading || !_hasDemoData ? null : _clearDemoData,
              enabled: _hasDemoData,
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              theme: theme,
              title: 'Supprimer TOUTES les données',
              subtitle: '⚠️ Supprime produits, catégories et promotions',
              icon: Icons.delete_forever,
              color: AppTheme.error,
              onTap: _isLoading ? null : _showClearAllConfirmation,
              isDanger: true,
            ),

            const SizedBox(height: 32),

            // Info
            _buildInfoSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryViolet.withOpacity(0.1),
                AppTheme.accentVioletLight.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.science,
                size: 48,
                color: AppTheme.primaryViolet,
              ),
              const SizedBox(height: 12),
              Text(
                'Mode Test',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryViolet,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gérez les données de démonstration pour tester toutes les fonctionnalités de l\'application.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasDemoData ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasDemoData ? Icons.check_circle : Icons.info_outline,
                      size: 18,
                      color: _hasDemoData ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasDemoData ? 'Données de démo présentes' : 'Aucune donnée de démo',
                      style: TextStyle(
                        color: _hasDemoData ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.grey200,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryViolet),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${(_progress * 100).toInt()}%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryViolet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool enabled = true,
    bool isDanger = false,
  }) {
    final effectiveEnabled = enabled && onTap != null;
    
    return Opacity(
      opacity: effectiveEnabled ? 1.0 : 0.5,
      child: Card(
        elevation: effectiveEnabled ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDanger 
              ? BorderSide(color: color.withOpacity(0.3), width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: effectiveEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.grey400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Données incluses',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('📱 Smartphones', 'iPhone 15 Pro Max, Samsung S24 Ultra, Xiaomi 14 Pro'),
          _buildInfoItem('🎧 Accessoires', 'AirPods Pro 2, Galaxy Buds 3, Chargeur Anker'),
          _buildInfoItem('📟 Tablettes', 'iPad Pro M4, Galaxy Tab S9 Ultra'),
          _buildInfoItem('⌚ Montres', 'Apple Watch Ultra 2, Galaxy Watch 6'),
          const SizedBox(height: 12),
          const Text(
            '✅ Chaque produit inclut: prix, photos, specs, avis, badges, garantie, livraison, etc.',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _seedDemoData() async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _statusMessage = 'Initialisation...';
    });

    final result = await DemoDataService.seedDemoData(
      onProgress: (message, progress) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      await _checkDemoData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ ${result.summary} ajoutés !'
                : '❌ Erreur: ${result.errors.first}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _clearDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les données de démo ?'),
        content: const Text(
          'Cette action supprimera uniquement les produits et catégories créés par ce service de test.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _progress = 0;
      _statusMessage = 'Suppression...';
    });

    final result = await DemoDataService.clearDemoData(
      onProgress: (message, progress) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      await _checkDemoData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Données de démo supprimées'
                : '❌ Erreur: ${result.errors.first}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 8),
            const Text('Attention !'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action va supprimer TOUTES les données :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Tous les produits'),
            Text('• Toutes les catégories'),
            Text('• Toutes les promotions'),
            SizedBox(height: 12),
            Text(
              '⚠️ Cette action est IRRÉVERSIBLE !',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _statusMessage = 'Suppression complète...';
    });

    final result = await DemoDataService.clearAllData(
      onProgress: (message, progress) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      await _checkDemoData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Toutes les données ont été supprimées'
                : '❌ Erreur: ${result.errors.first}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
