import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/two_factor_service.dart';

/// Écran affiché après un login email/mot de passe réussi, quand l'utilisateur
/// a activé la 2FA par email. Bloque l'accès à l'app jusqu'à saisie du bon code.
class TwoFactorVerificationScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const TwoFactorVerificationScreen({Key? key, required this.onVerified})
      : super(key: key);

  @override
  State<TwoFactorVerificationScreen> createState() =>
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState
    extends State<TwoFactorVerificationScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  final TextEditingController _codeController = TextEditingController();

  bool _isSendingCode = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
    });

    try {
      await _twoFactorService.sendCode();
      _startCooldown();
      if (mounted) {
        _showSnackBar('Code envoyé par email', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible d\'envoyer le code. Réessayez.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Le code doit contenir 6 chiffres');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _twoFactorService.verifyCode(code);

      if (result.success) {
        widget.onVerified();
        return;
      }

      setState(() {
        switch (result.reason) {
          case TwoFactorFailureReason.expired:
            _errorMessage = 'Ce code a expiré. Demandez-en un nouveau.';
            break;
          case TwoFactorFailureReason.tooManyAttempts:
            _errorMessage =
                'Trop de tentatives. Demandez un nouveau code.';
            break;
          case TwoFactorFailureReason.invalidCode:
            _errorMessage = 'Code incorrect. Réessayez.';
            break;
          default:
            _errorMessage = 'Une erreur est survenue. Réessayez.';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: AppTheme.primaryViolet,
                ),
                const SizedBox(height: 24),
                Text(
                  'Vérification de sécurité',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Entrez le code à 6 chiffres envoyé à votre adresse email',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '000000',
                  ),
                  onSubmitted: (_) => _verifyCode(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Vérifier',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (_resendCooldown > 0 || _isSendingCode)
                      ? null
                      : _sendCode,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Renvoyer le code (${_resendCooldown}s)'
                        : 'Renvoyer le code',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}