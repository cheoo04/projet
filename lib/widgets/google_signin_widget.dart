// Widget de connexion Google
// Interface utilisateur pour l'authentification Google

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GoogleSignInWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool isRegister;

  const GoogleSignInWidget({
    super.key,
    this.onSuccess,
    this.onError,
    this.isRegister = false,
  });

  @override
  State<GoogleSignInWidget> createState() => _GoogleSignInWidgetState();
}

class _GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        widget.onSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isRegister
                    ? 'Compte créé avec Google avec succès'
                    : 'Connexion Google réussie',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onError?.call('Connexion Google annulée');
      }
    } catch (e) {
      widget.onError?.call('Erreur connexion Google: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.asset(
                'assets/google_logo.png', // Vous devrez ajouter le logo Google
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.account_circle, color: Colors.red),
              ),
        label: Text(
          _isLoading
              ? 'Connexion...'
              : widget.isRegister
              ? 'S\'inscrire avec Google'
              : 'Se connecter avec Google',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Widget de statut de connexion
class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _getConnectivityStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final isOnline = snapshot.data!;

        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange.shade100,
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode hors ligne - Fonctionnalités limitées',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<bool> _getConnectivityStream() {
    // Simulation d'un stream de connectivité
    // Dans une vraie app, vous utiliseriez connectivity_plus
    return Stream.periodic(
      const Duration(seconds: 5),
      (count) => DateTime.now().second % 2 == 0, // Simulation alternée
    );
  }
}
