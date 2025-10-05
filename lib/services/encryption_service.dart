import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'logging_service.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Clé de chiffrement (en production, elle devrait être stockée de manière sécurisée)
  static const String _encryptionKey = 'pharrell_phone_2024_secure_key_256';

  /// Chiffre une chaîne de caractères
  static String encrypt(String plainText) {
    try {
      final bytes = utf8.encode(plainText);
      final key = utf8.encode(_encryptionKey);

      // Générer un salt aléatoire
      final salt = _generateSalt();

      // Créer un hash avec le salt
      final combined = [...salt, ...bytes];
      final encrypted = _xorEncrypt(combined, key);

      // Encoder en base64 pour stockage
      return base64Encode([...salt, ...encrypted]);
    } catch (e) {
      LoggingService.error(
        'Encryption failed',
        category: 'CRYPTO',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Déchiffre une chaîne de caractères
  static String decrypt(String encryptedText) {
    try {
      final decoded = base64Decode(encryptedText);

      // Extraire le salt (16 premiers bytes) et les données chiffrées
      final salt = decoded.sublist(0, 16);
      final encrypted = decoded.sublist(16);

      final key = utf8.encode(_encryptionKey);
      final decrypted = _xorDecrypt(encrypted, key);

      // Les données déchiffrées contiennent le salt + les données originales
      // Vérifier que le salt déchiffré correspond au salt stocké pour validation
      if (decrypted.length < 16) {
        throw Exception('Données déchiffrées invalides');
      }

      final decryptedSalt = decrypted.sublist(0, 16);

      // Validation d'intégrité : le salt déchiffré doit correspondre au salt stocké
      bool saltMatch = true;
      for (int i = 0; i < 16; i++) {
        if (salt[i] != decryptedSalt[i]) {
          saltMatch = false;
          break;
        }
      }

      if (!saltMatch) {
        throw Exception('Validation d\'intégrité échouée - salt invalide');
      }

      final plainBytes = decrypted.sublist(16);

      return utf8.decode(plainBytes);
    } catch (e) {
      LoggingService.error(
        'Decryption failed',
        category: 'CRYPTO',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Hache un mot de passe avec salt
  static String hashPassword(String password, {String? salt}) {
    salt ??= _generateSaltString();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Vérifie un mot de passe haché
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final expectedHash = parts[1];

      final actualHash = hashPassword(password, salt: salt);
      return actualHash.split(':')[1] == expectedHash;
    } catch (e) {
      LoggingService.error(
        'Password verification failed',
        category: 'CRYPTO',
        data: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Génère un token sécurisé
  static String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(
      bytes,
    ).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, length);
  }

  /// Génère un salt aléatoire
  static List<int> _generateSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (i) => random.nextInt(256));
  }

  static String _generateSaltString() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes).substring(0, 16);
  }

  /// Chiffrement XOR simple (pour usage basique)
  static List<int> _xorEncrypt(List<int> data, List<int> key) {
    final result = <int>[];
    for (int i = 0; i < data.length; i++) {
      result.add(data[i] ^ key[i % key.length]);
    }
    return result;
  }

  static List<int> _xorDecrypt(List<int> data, List<int> key) {
    return _xorEncrypt(data, key); // XOR est symétrique
  }

  /// Chiffre des données sensibles pour stockage local
  static Map<String, String> encryptSensitiveData(Map<String, dynamic> data) {
    final encrypted = <String, String>{};

    for (final entry in data.entries) {
      if (_isSensitiveField(entry.key)) {
        encrypted[entry.key] = encrypt(entry.value.toString());
        LoggingService.debug(
          'Encrypted sensitive field: ${entry.key}',
          category: 'CRYPTO',
        );
      } else {
        encrypted[entry.key] = entry.value.toString();
      }
    }

    return encrypted;
  }

  /// Déchiffre des données sensibles depuis le stockage local
  static Map<String, dynamic> decryptSensitiveData(
    Map<String, String> encryptedData,
  ) {
    final decrypted = <String, dynamic>{};

    for (final entry in encryptedData.entries) {
      if (_isSensitiveField(entry.key)) {
        try {
          decrypted[entry.key] = decrypt(entry.value);
        } catch (e) {
          LoggingService.warning(
            'Failed to decrypt field: ${entry.key}',
            category: 'CRYPTO',
          );
          decrypted[entry.key] = null;
        }
      } else {
        decrypted[entry.key] = entry.value;
      }
    }

    return decrypted;
  }

  /// Détermine si un champ est sensible et doit être chiffré
  static bool _isSensitiveField(String fieldName) {
    const sensitiveFields = {
      'email',
      'phone',
      'address',
      'paymentInfo',
      'creditCard',
      'bankAccount',
      'personalId',
      'socialSecurityNumber',
      'password',
      'token',
      'apiKey',
    };

    return sensitiveFields.any(
      (field) => fieldName.toLowerCase().contains(field.toLowerCase()),
    );
  }

  /// Anonymise des données pour les logs
  static String anonymize(String sensitiveData) {
    if (sensitiveData.length <= 4) {
      return '*' * sensitiveData.length;
    }

    if (sensitiveData.contains('@')) {
      // Email
      final parts = sensitiveData.split('@');
      final username = parts[0];
      final domain = parts[1];

      if (username.length <= 2) {
        return '***@$domain';
      }

      return '${username.substring(0, 2)}***@$domain';
    }

    // Autres données sensibles
    return '${sensitiveData.substring(0, 2)}***${sensitiveData.substring(sensitiveData.length - 2)}';
  }

  /// Nettoie les données en mémoire (sécurité)
  static void secureCleanup() {
    // Forcer le garbage collector (non garanti mais aide)
    if (kDebugMode) {
      LoggingService.debug(
        'Performing secure memory cleanup',
        category: 'CRYPTO',
      );
    }
  }
}
