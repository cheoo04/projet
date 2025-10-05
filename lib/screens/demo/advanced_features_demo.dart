// Page de démonstration des fonctionnalités avancées
// Utilisée pour tester et présenter les nouvelles capacités

import 'package:flutter/material.dart';
import '../../widgets/biometric_auth_widget.dart';
import '../../widgets/google_signin_widget.dart';
import '../../services/offline_cache_service.dart';
import '../../services/performance_service.dart';

class AdvancedFeaturesDemo extends StatefulWidget {
  const AdvancedFeaturesDemo({super.key});

  @override
  State<AdvancedFeaturesDemo> createState() => _AdvancedFeaturesDemoState();
}

class _AdvancedFeaturesDemoState extends State<AdvancedFeaturesDemo> {
  final OfflineCacheService _cacheService = OfflineCacheService();

  Map<String, int> _cacheSize = {};
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    try {
      final size = await _cacheService.getCacheSize();
      final online = _cacheService.isOnline;

      setState(() {
        _cacheSize = size;
        _isOnline = online;
      });
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fonctionnalités Avancées'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut de connexion
            _buildConnectionStatus(),
            const SizedBox(height: 24),

            // Section Authentification Biométrique
            _buildSectionTitle('🔐 Authentification Biométrique'),
            const SizedBox(height: 16),
            const BiometricAuthWidget(
              title: 'Test Biométrie',
              subtitle: 'Démonstration de l\'authentification sécurisée',
            ),
            const SizedBox(height: 24),

            // Section Google Sign-In
            _buildSectionTitle('🌐 Connexion Google'),
            const SizedBox(height: 16),
            GoogleSignInWidget(
              onSuccess: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connexion Google simulée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section Mode Hors Ligne
            _buildSectionTitle('📱 Mode Hors Ligne'),
            const SizedBox(height: 16),
            _buildOfflineSection(),
            const SizedBox(height: 24),

            // Section Performance
            _buildSectionTitle('⚡ Optimisations Performance'),
            const SizedBox(height: 16),
            _buildPerformanceSection(),
            const SizedBox(height: 24),

            // Section Configuration Biométrique
            _buildSectionTitle('⚙️ Configuration'),
            const SizedBox(height: 16),
            const BiometricSettingsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: _isOnline ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isOnline
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  _isOnline
                      ? 'Toutes les fonctionnalités disponibles'
                      : 'Mode dégradé avec cache local',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadCacheInfo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildOfflineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État du Cache Local',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Informations du cache
            ..._cacheSize.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.capitalize()}:',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${entry.value} éléments',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _cacheService.clearCache();
                      _loadCacheInfo();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache vidé'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Vider Cache'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadCacheInfo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optimisations Actives',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Liste des optimisations
            const ListTile(
              leading: Icon(Icons.image, color: Colors.green),
              title: Text('Cache d\'images'),
              subtitle: Text('Chargement instantané des images'),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.list, color: Colors.green),
              title: Text('Pagination automatique'),
              subtitle: Text('Chargement progressif des listes'),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.speed, color: Colors.green),
              title: Text('Debouncing des recherches'),
              subtitle: Text('Optimisation des requêtes'),
              dense: true,
            ),

            const SizedBox(height: 16),

            // Boutons de test
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await PerformanceOptimizationService.clearImageCache();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache d\'images vidé'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.image_not_supported),
                    label: const Text('Vider Images'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Test de performance
                      PerformanceOptimizationService.measureExecutionTime(
                        'Test de performance',
                        () async {
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          return 'Test terminé';
                        },
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Test de performance lancé (voir console)',
                          ),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text('Test Perf'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour capitaliser les strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
