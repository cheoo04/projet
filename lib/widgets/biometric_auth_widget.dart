// Widget d'authentification biométrique
// Interface utilisateur pour l'authentification par empreinte/Face ID

import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../services/auth_service.dart';

class BiometricAuthWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String title;
  final String subtitle;

  const BiometricAuthWidget({
    super.key,
    this.onSuccess,
    this.onError,
    this.title = 'Authentification Biométrique',
    this.subtitle = 'Utilisez votre empreinte ou Face ID',
  });

  @override
  State<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget> {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _biometricType = 'Biométrie';
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    try {
      await _biometricAuth.initialize();
      final type = await _biometricAuth.getBiometricTypeText();
      final icon = await _biometricAuth.getBiometricIcon();

      setState(() {
        _biometricType = type;
        _biometricIcon = icon;
      });
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  Future<void> _authenticate() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.authenticateWithBiometrics(
        reason: 'Authentifiez-vous pour accéder à votre compte',
      );

      if (success) {
        widget.onSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentification $_biometricType réussie'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onError?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentification $_biometricType échouée'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      widget.onError?.call();
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
    return FutureBuilder<bool>(
      future: _biometricAuth.isAvailable,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentification biométrique non disponible',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre appareil ne supporte pas l\'authentification biométrique ou aucune biométrie n\'est configurée.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône biométrique
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(
                    _biometricIcon,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Sous-titre
                Text(
                  widget.subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Bouton d'authentification
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _authenticate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(_biometricIcon),
                    label: Text(
                      _isLoading
                          ? 'Authentification...'
                          : 'Utiliser $_biometricType',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Texte d'aide
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Placez votre doigt sur le capteur ou regardez votre appareil',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget d'activation/désactivation de la biométrie
class BiometricSettingsWidget extends StatefulWidget {
  const BiometricSettingsWidget({super.key});

  @override
  State<BiometricSettingsWidget> createState() =>
      _BiometricSettingsWidgetState();
}

class _BiometricSettingsWidgetState extends State<BiometricSettingsWidget> {
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _isEnabled = false;
  bool _isLoading = true;
  String _biometricType = 'Biométrie';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _authService.isBiometricEnabled();
      final type = await _biometricAuth.getBiometricTypeText();

      setState(() {
        _isEnabled = enabled;
        _biometricType = type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        // Tester l'authentification avant d'activer
        final success = await _authService.authenticateWithBiometrics(
          reason: 'Authentifiez-vous pour activer $_biometricType',
        );

        if (success) {
          await _authService.setBiometricEnabled(true);
          setState(() {
            _isEnabled = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$_biometricType activé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        await _authService.setBiometricEnabled(false);
        setState(() {
          _isEnabled = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType désactivé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _biometricAuth.isAvailable,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Vérification biométrie...'),
          );
        }

        if (!snapshot.data!) {
          return ListTile(
            leading: Icon(Icons.security_outlined, color: Colors.grey.shade400),
            title: const Text('Authentification biométrique'),
            subtitle: const Text('Non disponible sur cet appareil'),
            enabled: false,
          );
        }

        return ListTile(
          leading: Icon(
            _isEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
            color: _isEnabled ? Colors.green : Colors.grey,
          ),
          title: Text('Authentification $_biometricType'),
          subtitle: Text(
            _isEnabled
                ? 'Activé - Connexion rapide et sécurisée'
                : 'Désactivé - Utilisez votre $_biometricType',
          ),
          trailing: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _isEnabled,
                  onChanged: _toggleBiometric,
                  activeTrackColor: Colors.green,
                  activeThumbColor: Colors.white,
                ),
        );
      },
    );
  }
}
