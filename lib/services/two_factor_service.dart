import 'package:cloud_functions/cloud_functions.dart';

/// Raisons d'échec possibles lors de la vérification d'un code 2FA.
enum TwoFactorFailureReason { expired, invalidCode, tooManyAttempts, unknown }

/// Résultat d'une tentative de vérification de code 2FA.
class TwoFactorResult {
  final bool success;
  final TwoFactorFailureReason? reason;
  TwoFactorResult({required this.success, this.reason});
}

/// Service d'appel aux Cloud Functions de 2FA par email
/// (sendTwoFactorCode / verifyTwoFactorCode).
class TwoFactorService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Demande l'envoi d'un nouveau code de vérification par email.
  /// Lève une exception (FirebaseFunctionsException) en cas d'échec.
  Future<void> sendCode() async {
    final callable = _functions.httpsCallable('sendTwoFactorCode');
    await callable.call();
  }

  /// Vérifie le code saisi par l'utilisateur.
  Future<TwoFactorResult> verifyCode(String code) async {
    final callable = _functions.httpsCallable('verifyTwoFactorCode');
    final result = await callable.call({'code': code});
    final data = result.data as Map<String, dynamic>;

    if (data['success'] == true) {
      return TwoFactorResult(success: true);
    }

    switch (data['reason']) {
      case 'expired':
        return TwoFactorResult(
            success: false, reason: TwoFactorFailureReason.expired);
      case 'too_many_attempts':
        return TwoFactorResult(
            success: false, reason: TwoFactorFailureReason.tooManyAttempts);
      case 'invalid_code':
        return TwoFactorResult(
            success: false, reason: TwoFactorFailureReason.invalidCode);
      default:
        return TwoFactorResult(
            success: false, reason: TwoFactorFailureReason.unknown);
    }
  }
}