// Implémentation mobile (Android/iOS) du service d'authentification biométrique.
// Gère l'authentification par empreinte digitale et Face ID via local_auth.
// Ce fichier n'est compilé que pour les cibles mobiles (jamais pour le web).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' hide BiometricType;
import 'package:local_auth/error_codes.dart' as auth_error;
import 'biometric_auth_types.dart';
import 'logging_service.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isInitialized = false;

  // Initialiser le service
  Future<void> initialize() async {
    try {
      _isInitialized = await _localAuth.canCheckBiometrics;
      LoggingService.info(
        'Service biométrique initialisé: $_isInitialized',
        category: 'BIOMETRIC',
      );
    } catch (e) {
      LoggingService.error(
        'Erreur initialisation biométrique: $e',
        category: 'BIOMETRIC',
      );
      _isInitialized = false;
    }
  }

  // Vérifier si la biométrie est disponible
  Future<bool> get isAvailable async {
    try {
      if (!_isInitialized) await initialize();
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Obtenir les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final List<BiometricType> types = [];

      for (final type in availableBiometrics) {
        switch (type.toString()) {
          case 'BiometricType.fingerprint':
            types.add(BiometricType.fingerprint);
            break;
          case 'BiometricType.face':
            types.add(BiometricType.face);
            break;
          case 'BiometricType.iris':
            types.add(BiometricType.iris);
            break;
          default:
            // Type biométrique non reconnu, ignorer
            break;
        }
      }

      return types.isEmpty ? [BiometricType.none] : types;
    } catch (e) {
      LoggingService.error('Erreur récupération biométriques: $e');
      return [BiometricType.none];
    }
  }

  // Authentifier avec la biométrie
  Future<BiometricAuthResult> authenticate({
    String reason = 'Veuillez vous authentifier',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      if (!await isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Authentification biométrique non disponible',
          errorType: BiometricErrorType.notAvailable,
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        LoggingService.info('Authentification biométrique réussie');
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Authentification échouée',
          errorType: BiometricErrorType.authenticationFailed,
        );
      }
    } on PlatformException catch (e) {
      LoggingService.error('Erreur authentification biométrique: $e');

      BiometricErrorType errorType;
      String errorMessage;

      switch (e.code) {
        case auth_error.notAvailable:
          errorType = BiometricErrorType.notAvailable;
          errorMessage = 'Authentification biométrique non disponible';
          break;
        case auth_error.notEnrolled:
          errorType = BiometricErrorType.notEnrolled;
          errorMessage = 'Aucune biométrie enregistrée sur cet appareil';
          break;
        case auth_error.lockedOut:
          errorType = BiometricErrorType.lockedOut;
          errorMessage = 'Trop de tentatives. Réessayez plus tard';
          break;
        case auth_error.permanentlyLockedOut:
          errorType = BiometricErrorType.permanentlyLockedOut;
          errorMessage = 'Biométrie verrouillée. Utilisez le code PIN';
          break;
        case auth_error.passcodeNotSet:
          errorType = BiometricErrorType.passcodeNotSet;
          errorMessage = 'Aucun code PIN configuré sur cet appareil';
          break;
        default:
          errorType = BiometricErrorType.unknown;
          errorMessage = 'Erreur inconnue: ${e.message}';
      }

      return BiometricAuthResult(
        success: false,
        errorMessage: errorMessage,
        errorType: errorType,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Erreur inattendue: $e',
        errorType: BiometricErrorType.unknown,
      );
    }
  }

  // Obtenir le texte descriptif pour le type de biométrie
  Future<String> getBiometricTypeText() async {
    final types = await getAvailableBiometrics();

    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Empreinte digitale';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biométrie';
    }
  }

  // Obtenir l'icône appropriée pour la biométrie
  Future<IconData> getBiometricIcon() async {
    final types = await getAvailableBiometrics();

    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (types.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  // Vérifier si l'utilisateur a configuré la biométrie
  Future<bool> get isDeviceSupported async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Arrêter l'authentification en cours
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }
}