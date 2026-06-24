import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
/// Utilise HTTP direct — contournement bug FlutterFire #17924 (dart2js/Int64).
class TwoFactorService {
  static const String _base =
      'https://europe-west1-first-pro-cheoo.cloudfunctions.net';

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _call(
      String functionName, Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse('$_base/$functionName'),
          headers: await _authHeaders(),
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'Erreur ${response.statusCode}');
    }
    return (jsonDecode(response.body)['result'] as Map<String, dynamic>);
  }

  /// Demande l'envoi d'un nouveau code de vérification par email.
  Future<void> sendCode() async {
    await _call('sendTwoFactorCode', {});
  }

  /// Vérifie le code saisi par l'utilisateur.
  Future<TwoFactorResult> verifyCode(String code) async {
    final data = await _call('verifyTwoFactorCode', {'code': code});

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