// Types partagés entre les implémentations web et mobile
// du service d'authentification biométrique.
// Ce fichier n'importe jamais local_auth : il reste neutre pour les deux plateformes.

enum BiometricType { none, fingerprint, face, iris }

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorType? errorType;

  BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorType,
  });
}

enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  authenticationFailed,
  unknown,
}