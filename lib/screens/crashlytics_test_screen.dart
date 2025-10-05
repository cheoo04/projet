import 'package:flutter/material.dart';
import '../services/logging_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Écran de test pour vérifier le fonctionnement de Crashlytics
class CrashlyticsTestScreen extends StatelessWidget {
  const CrashlyticsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Crashlytics'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🔥 Test Firebase Crashlytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              'Ces boutons permettent de tester l\'intégration Crashlytics :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Test logs normaux
            ElevatedButton.icon(
              onPressed: () {
                LoggingService.info(
                  'Test Crashlytics - Log normal',
                  category: 'crashlytics_test',
                  data: {
                    'test_type': 'normal_log',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
                _showSnackBar(context, 'Log normal envoyé à Crashlytics');
              },
              icon: const Icon(Icons.info),
              label: const Text('Envoyer Log Normal'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),

            const SizedBox(height: 10),

            // Test erreur
            ElevatedButton.icon(
              onPressed: () {
                LoggingService.error(
                  'Test Crashlytics - Erreur simulée',
                  category: 'crashlytics_test',
                  data: {
                    'error_type': 'simulated_error',
                    'user_action': 'button_press',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
                _showSnackBar(context, 'Erreur envoyée à Crashlytics');
              },
              icon: const Icon(Icons.error),
              label: const Text('Envoyer Erreur'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),

            const SizedBox(height: 10),

            // Test crash critique
            ElevatedButton.icon(
              onPressed: () {
                LoggingService.critical(
                  'Test Crashlytics - Erreur critique',
                  category: 'crashlytics_test',
                  data: {
                    'severity': 'critical',
                    'impact': 'service_degradation',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                  stackTrace: StackTrace.current,
                );
                _showSnackBar(context, 'Erreur critique envoyée à Crashlytics');
              },
              icon: const Icon(Icons.warning),
              label: const Text('Envoyer Erreur Critique'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Tests Crashlytics directs
            const Text(
              'Tests directs Firebase Crashlytics :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () async {
                // Test direct Crashlytics
                await FirebaseCrashlytics.instance.log(
                  'Test direct Crashlytics',
                );
                await FirebaseCrashlytics.instance.setUserIdentifier(
                  'test_user_123',
                );
                await FirebaseCrashlytics.instance.setCustomKey(
                  'test_screen',
                  'crashlytics_test',
                );
                if (context.mounted) {
                  _showSnackBar(context, 'Métadonnées envoyées à Crashlytics');
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Configurer Métadonnées'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                // Simulation d'un crash réel (à utiliser avec précaution !)
                FirebaseCrashlytics.instance.recordError(
                  'Crash simulé pour test',
                  StackTrace.current,
                  fatal: false,
                  information: ['Test de fonctionnement Crashlytics'],
                );
                _showSnackBar(context, 'Crash simulé envoyé (non fatal)');
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Simuler Crash (non fatal)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),

            const Spacer(),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Les logs et erreurs sont maintenant envoyés vers Firebase Crashlytics. Consultez la console Firebase pour voir les rapports.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
