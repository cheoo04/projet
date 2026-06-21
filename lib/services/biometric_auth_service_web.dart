// Implémentation web du service d'authentification biométrique.
// La biométrie n'existe pas sur le web : ce stub ne dépend jamais
// du package local_auth, afin qu'il soit absent du bundle web compilé.

import 'package:flutter/material.dart';
import 'biometric_auth_types.dart';
import 'logging_service.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  Future<void> initialize() async {
    LoggingService.info(
      'Service biométrique désactivé sur web',
      category: 'BIOMETRIC',
    );
  }

  Future<bool> get isAvailable async => false;

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return [BiometricType.none];
  }

  Future<BiometricAuthResult> authenticate({
    String reason = 'Veuillez vous authentifier',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    return BiometricAuthResult(
      success: false,
      errorMessage: 'Authentification biométrique non disponible',
      errorType: BiometricErrorType.notAvailable,
    );
  }

  Future<String> getBiometricTypeText() async => 'Biométrie';

  Future<IconData> getBiometricIcon() async => Icons.security;

  Future<bool> get isDeviceSupported async => false;

  Future<bool> stopAuthentication() async => false;
}