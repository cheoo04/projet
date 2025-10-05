import 'package:flutter/material.dart';
import '../services/logging_service.dart';
import '../services/crash_handler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class EnhancedCrashlyticsTestScreen extends StatelessWidget {
  const EnhancedCrashlyticsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Crashlytics Avancé'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tests de gestion des erreurs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Test d'exception capturée
            _buildTestButton(
              context,
              'Test Exception Capturée',
              Colors.red,
              () {
                try {
                  throw Exception(
                    'Test d\'exception capturée avec CrashHandler',
                  );
                } catch (error, stackTrace) {
                  CrashHandler.recordError(
                    error,
                    stackTrace,
                    context: 'Test exception capturée depuis écran de test',
                  );
                  _showSnackBar(
                    context,
                    'Exception capturée et envoyée à Crashlytics',
                  );
                }
              },
            ),

            // Test d'erreur non fatale
            _buildTestButton(
              context,
              'Test Erreur Non Fatale',
              Colors.orange,
              () {
                FirebaseCrashlytics.instance.recordError(
                  'Erreur non fatale de test',
                  StackTrace.current,
                  fatal: false,
                  information: ['Test erreur non fatale'],
                );
                LoggingService.logError(
                  'Erreur non fatale envoyée à Crashlytics',
                );
                _showSnackBar(context, 'Erreur non fatale envoyée');
              },
            ),

            // Test d'erreur Async
            _buildTestButton(
              context,
              'Test Erreur Async',
              Colors.deepOrange,
              () {
                Future.delayed(const Duration(seconds: 1), () {
                  throw Exception(
                    'Erreur asynchrone de test - gérée automatiquement',
                  );
                });
                _showSnackBar(
                  context,
                  'Erreur async programmée dans 1 seconde',
                );
              },
            ),

            // Test d'erreur de widget
            _buildTestButton(context, 'Test Widget Buggy', Colors.purple, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BuggyWidget()),
              );
            }),

            // Test de log personnalisé
            _buildTestButton(context, 'Test Log Personnalisé', Colors.blue, () {
              FirebaseCrashlytics.instance.setCustomKey(
                'test_action',
                'button_pressed',
              );
              FirebaseCrashlytics.instance.setCustomKey(
                'timestamp',
                DateTime.now().toString(),
              );
              FirebaseCrashlytics.instance.setCustomKey(
                'user_action',
                'enhanced_test',
              );
              FirebaseCrashlytics.instance.log(
                'Action de test utilisateur depuis écran avancé',
              );
              LoggingService.logInfo(
                'Log personnalisé avec données contextuelles envoyé',
              );
              _showSnackBar(context, 'Log personnalisé avec contexte envoyé');
            }),

            // Test d'erreur de type
            _buildTestButton(context, 'Test Erreur de Type', Colors.indigo, () {
              try {
                // Provoquer une erreur de type
                dynamic value = "string";
                int number = value as int; // Ceci va échouer
                // Utilisation du number pour éviter le warning
                debugPrint('Number: $number');
              } catch (error, stackTrace) {
                CrashHandler.recordError(
                  error,
                  stackTrace,
                  context: 'Test erreur de type casting',
                );
                _showSnackBar(context, 'Erreur de type capturée');
              }
            }),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Informations sur les tests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Les erreurs sont automatiquement capturées par le CrashHandler\n'
                    '• Vérifiez la console Firebase Crashlytics pour voir les rapports\n'
                    '• Les erreurs async sont gérées automatiquement\n'
                    '• Les données contextuelles sont ajoutées automatiquement',
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

  Widget _buildTestButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// Widget intentionnellement buggy pour les tests
class BuggyWidget extends StatelessWidget {
  const BuggyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Buggy'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ce widget va provoquer une erreur...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Provoquer une erreur de widget Flutter
                throw FlutterError(
                  'Erreur intentionnelle de widget pour test Crashlytics',
                );
              },
              child: const Text('Cliquez pour provoquer l\'erreur'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
