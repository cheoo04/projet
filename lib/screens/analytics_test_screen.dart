import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/logging_service.dart';

class AnalyticsTestScreen extends StatelessWidget {
  const AnalyticsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Analytics'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tests d\'événements Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Tests d'événements utilisateur
            _buildSectionTitle('Événements Utilisateur'),
            _buildTestButton(context, 'Test Login', Colors.green, () async {
              await AnalyticsService.logLogin('email');
              LoggingService.logInfo('Événement login envoyé');
              _showSnackBar(context, 'Événement login envoyé');
            }),

            _buildTestButton(context, 'Test Sign Up', Colors.teal, () async {
              await AnalyticsService.logSignUp('email');
              LoggingService.logInfo('Événement sign up envoyé');
              _showSnackBar(context, 'Événement sign up envoyé');
            }),

            _buildTestButton(
              context,
              'Set User Properties',
              Colors.indigo,
              () async {
                await AnalyticsService.setUserId('test_user_123');
                await AnalyticsService.setUserProperty('user_type', 'premium');
                await AnalyticsService.setUserProperty('app_version', '1.0.0');
                _showSnackBar(context, 'Propriétés utilisateur définies');
              },
            ),

            const SizedBox(height: 10),

            // Tests d'événements e-commerce
            _buildSectionTitle('Événements E-commerce'),
            _buildTestButton(
              context,
              'Test View Item',
              Colors.orange,
              () async {
                await AnalyticsService.logViewItem(
                  itemId: 'phone_001',
                  itemName: 'iPhone 15 Pro',
                  category: 'smartphones',
                  price: 1299.99,
                  brand: 'Apple',
                );
                _showSnackBar(context, 'Événement view item envoyé');
              },
            ),

            _buildTestButton(
              context,
              'Test Add to Cart',
              Colors.deepOrange,
              () async {
                await AnalyticsService.logAddToCart(
                  itemId: 'phone_001',
                  itemName: 'iPhone 15 Pro',
                  category: 'smartphones',
                  price: 1299.99,
                  quantity: 1,
                  brand: 'Apple',
                );
                _showSnackBar(context, 'Événement add to cart envoyé');
              },
            ),

            _buildTestButton(context, 'Test Purchase', Colors.red, () async {
              await AnalyticsService.logPurchase(
                transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
                value: 1299.99,
                currency: 'EUR',
                items: [
                  {
                    'item_id': 'phone_001',
                    'item_name': 'iPhone 15 Pro',
                    'item_category': 'smartphones',
                    'price': 1299.99,
                    'quantity': 1,
                  },
                ],
              );
              _showSnackBar(context, 'Événement purchase envoyé');
            }),

            const SizedBox(height: 10),

            // Tests d'événements métier
            _buildSectionTitle('Événements Métier Pharrell'),
            _buildTestButton(
              context,
              'Test View Catalog',
              Colors.purple,
              () async {
                await AnalyticsService.logViewCatalog(
                  category: 'smartphones',
                  filter: 'price_high_to_low',
                );
                _showSnackBar(context, 'Événement view catalog envoyé');
              },
            ),

            _buildTestButton(
              context,
              'Test Stock Management',
              Colors.brown,
              () async {
                await AnalyticsService.logStockManagement(
                  action: 'update',
                  productId: 'phone_001',
                  quantity: 50,
                );
                _showSnackBar(context, 'Événement stock management envoyé');
              },
            ),

            _buildTestButton(
              context,
              'Test Custom Event',
              Colors.grey,
              () async {
                await AnalyticsService.logCustomEvent(
                  'pharrell_test_event',
                  parameters: {
                    'test_parameter': 'test_value',
                    'timestamp': DateTime.now().toIso8601String(),
                    'screen': 'analytics_test',
                  },
                );
                _showSnackBar(context, 'Événement personnalisé envoyé');
              },
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Informations Analytics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Les événements sont envoyés à Firebase Analytics\n'
                    '• En mode debug : collecte désactivée, logs en console\n'
                    '• En mode release : collecte activée automatiquement\n'
                    '• Vérifiez Firebase Console > Analytics > Events',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}
