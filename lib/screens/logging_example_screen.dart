import 'package:flutter/material.dart';
import '../services/logging_service.dart';

/// Exemple d'utilisation du service de logging
class LoggingExampleScreen extends StatelessWidget {
  const LoggingExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemple Logging Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Exemples d\'utilisation du service de logging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                LoggingService.debug(
                  'Debug button pressed',
                  category: 'ui',
                  data: {'screen': 'logging_example', 'action': 'button_press'},
                );
                _showMessage(context, 'Log DEBUG envoyé');
              },
              child: const Text('Log DEBUG'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                LoggingService.info(
                  'User navigation to example screen',
                  category: 'navigation',
                  data: {'from': 'home', 'to': 'logging_example'},
                );
                _showMessage(context, 'Log INFO envoyé');
              },
              child: const Text('Log INFO'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                LoggingService.warning(
                  'Slow network detected',
                  category: 'performance',
                  data: {'response_time': 5000, 'endpoint': '/api/products'},
                );
                _showMessage(context, 'Log WARNING envoyé');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Log WARNING'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                LoggingService.error(
                  'Failed to load user data',
                  category: 'api',
                  data: {
                    'error_code': 404,
                    'endpoint': '/api/user/123',
                    'retry_count': 3,
                  },
                );
                _showMessage(context, 'Log ERROR envoyé');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Log ERROR'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                LoggingService.critical(
                  'Database connection completely lost',
                  category: 'database',
                  data: {
                    'last_connection': DateTime.now()
                        .subtract(const Duration(minutes: 5))
                        .toIso8601String(),
                    'attempts': 10,
                    'impact': 'total_service_unavailable',
                  },
                  stackTrace: StackTrace.current,
                );
                _showMessage(context, 'Log CRITICAL envoyé');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Log CRITICAL'),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              'Cas d\'usage réels :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _simulateLoginAttempt(),
              child: const Text('Simuler tentative de connexion'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _simulatePaymentProcess(),
              child: const Text('Simuler processus de paiement'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _simulateApiError(),
              child: const Text('Simuler erreur API'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _simulateLoginAttempt() {
    // Simulation d'une tentative de connexion
    LoggingService.info(
      'User login attempt started',
      category: 'auth',
      data: {'method': 'email', 'timestamp': DateTime.now().toIso8601String()},
    );

    // Simulation d'un succès après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      LoggingService.info(
        'User successfully logged in',
        category: 'auth',
        data: {'userId': 'user_123', 'loginDuration': 2000, 'method': 'email'},
      );
    });
  }

  void _simulatePaymentProcess() {
    LoggingService.info(
      'Payment process initiated',
      category: 'payment',
      data: {'amount': 99.99, 'currency': 'EUR', 'method': 'card'},
    );

    // Simulation d'une erreur de paiement
    Future.delayed(const Duration(seconds: 3), () {
      LoggingService.error(
        'Payment failed - insufficient funds',
        category: 'payment',
        data: {
          'amount': 99.99,
          'currency': 'EUR',
          'error_code': 'INSUFFICIENT_FUNDS',
          'bank_response': 'Transaction declined',
        },
      );
    });
  }

  void _simulateApiError() {
    LoggingService.warning(
      'API rate limit approaching',
      category: 'api',
      data: {'requests_remaining': 10, 'window_reset': '60s'},
    );

    Future.delayed(const Duration(seconds: 1), () {
      LoggingService.error(
        'API rate limit exceeded',
        category: 'api',
        data: {
          'endpoint': '/api/products',
          'rate_limit': '100/hour',
          'next_reset': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
        },
      );
    });
  }
}
