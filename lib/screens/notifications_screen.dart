import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/fcm_service.dart';

/// Écran des paramètres de notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newProducts = false;
  bool _priceDrops = true;
  bool _stockAlerts = false;
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  
  final FCMService _fcmService = FCMService();
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkNotificationStatus();
  }
  
  Future<void> _checkNotificationStatus() async {
    final enabled = await _fcmService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool('notif_orders') ?? true;
      _promotions = prefs.getBool('notif_promos') ?? true;
      _newProducts = prefs.getBool('notif_new_products') ?? false;
      _priceDrops = prefs.getBool('notif_price_drops') ?? true;
      _stockAlerts = prefs.getBool('notif_stock') ?? false;
      _isLoading = false;
    });
  }
  
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Mettre à jour l'abonnement FCM
    await _fcmService.updateTopicSubscription(key, value);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statut des notifications
          if (!_notificationsEnabled)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications désactivées',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activez les notifications dans les paramètres de votre appareil',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryViolet,
                  AppTheme.accentVioletLight,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restez informé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _notificationsEnabled 
                            ? 'Notifications push activées ✓'
                            : 'Personnalisez vos notifications',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Commandes
          _buildSectionHeader(context, 'Commandes', Icons.shopping_bag_outlined),
          const SizedBox(height: 8),
          _buildNotificationTile(
            title: 'Mises à jour des commandes',
            subtitle: 'Confirmation, expédition, livraison',
            value: _orderUpdates,
            onChanged: (val) {
              setState(() => _orderUpdates = val);
              _savePreference('notif_orders', val);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section Promotions
          _buildSectionHeader(context, 'Promotions', Icons.local_offer_outlined),
          const SizedBox(height: 8),
          _buildNotificationTile(
            title: 'Offres et promotions',
            subtitle: 'Réductions et offres spéciales',
            value: _promotions,
            onChanged: (val) {
              setState(() => _promotions = val);
              _savePreference('notif_promos', val);
            },
          ),
          _buildNotificationTile(
            title: 'Baisses de prix',
            subtitle: 'Alertes quand un produit baisse de prix',
            value: _priceDrops,
            onChanged: (val) {
              setState(() => _priceDrops = val);
              _savePreference('notif_price_drops', val);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section Produits
          _buildSectionHeader(context, 'Produits', Icons.smartphone),
          const SizedBox(height: 8),
          _buildNotificationTile(
            title: 'Nouveaux produits',
            subtitle: 'Soyez le premier à découvrir les nouveautés',
            value: _newProducts,
            onChanged: (val) {
              setState(() => _newProducts = val);
              _savePreference('notif_new_products', val);
            },
          ),
          _buildNotificationTile(
            title: 'Alertes de stock',
            subtitle: 'Quand un produit épuisé revient en stock',
            value: _stockAlerts,
            onChanged: (val) {
              setState(() => _stockAlerts = val);
              _savePreference('notif_stock', val);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vous pouvez modifier ces paramètres à tout moment. Les notifications importantes concernant votre compte seront toujours envoyées.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryViolet),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryViolet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
