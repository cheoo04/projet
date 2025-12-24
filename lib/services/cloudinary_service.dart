import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Service pour uploader et gérer les images sur Cloudinary
/// 
/// Configuration requise dans votre compte Cloudinary :
/// 1. Créez un compte sur https://cloudinary.com (gratuit)
/// 2. Récupérez vos credentials dans Dashboard > Settings
/// 3. Configurez les valeurs ci-dessous
class CloudinaryService {
  // ========== CONFIGURATION CLOUDINARY ==========
  // Remplacez ces valeurs par vos credentials Cloudinary
  static const String cloudName = 'dp8lng1aj';  // Ex: 'dxxxxxxxxx'
  static const String apiKey = '745144142628186';        // Ex: '123456789012345'
  static const String apiSecret = '_Pv67LDHwULgRtNP56a0UdQN0mQ';  // Ex: 'aBcDeFgHiJkLmNoPqRsTuVwXyZ'
  static const String uploadPreset = 'pharrell_phone'; // Preset unsigned (optionnel)
  
  // Singleton
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  /// URL de base pour l'upload
  String get _uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Vérifie si la configuration est valide
  bool get isConfigured => 
      cloudName != 'VOTRE_CLOUD_NAME' && 
      apiKey != 'VOTRE_API_KEY' && 
      apiSecret != 'VOTRE_API_SECRET';

  /// Upload une image vers Cloudinary (méthode unsigned avec preset)
  /// Retourne l'URL de l'image uploadée
  Future<String?> uploadImageUnsigned(Uint8List imageBytes, {
    String? folder,
    String? publicId,
  }) async {
    try {
      if (!isConfigured) {
        debugPrint('❌ Cloudinary non configuré. Configurez cloudName, apiKey et apiSecret.');
        return null;
      }

      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter le fichier image
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '${publicId ?? DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      // Paramètres
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final url = data['secure_url'] as String;
        debugPrint('✅ Image uploadée sur Cloudinary: $url');
        return url;
      } else {
        debugPrint('❌ Erreur Cloudinary: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception Cloudinary: $e');
      return null;
    }
  }

  /// Upload une image vers Cloudinary (méthode signed - plus sécurisée)
  Future<String?> uploadImageSigned(Uint8List imageBytes, {
    String? folder,
    String? publicId,
    Map<String, String>? transformations,
  }) async {
    try {
      if (!isConfigured) {
        debugPrint('❌ Cloudinary non configuré.');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Construire les paramètres pour la signature
      final params = <String, String>{
        'timestamp': timestamp.toString(),
      };
      if (folder != null) params['folder'] = folder;
      if (publicId != null) params['public_id'] = publicId;
      
      // Générer la signature
      final signature = _generateSignature(params);
      
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '${publicId ?? DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final url = data['secure_url'] as String;
        debugPrint('✅ Image uploadée sur Cloudinary: $url');
        return url;
      } else {
        debugPrint('❌ Erreur Cloudinary signed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception Cloudinary signed: $e');
      return null;
    }
  }

  /// Génère la signature pour l'upload signed
  String _generateSignature(Map<String, String> params) {
    // Trier les paramètres par clé
    final sortedKeys = params.keys.toList()..sort();
    final stringToSign = sortedKeys.map((key) => '$key=${params[key]}').join('&');
    final signatureString = '$stringToSign$apiSecret';
    
    // SHA-1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Upload une image avec génération de miniatures
  /// Cloudinary génère automatiquement les miniatures via transformations
  Future<Map<String, String>> uploadImageWithThumbnails(
    Uint8List imageBytes, {
    required String folder,
    String? publicId,
  }) async {
    final results = <String, String>{};
    
    final originalUrl = await uploadImageSigned(
      imageBytes,
      folder: folder,
      publicId: publicId,
    );
    
    if (originalUrl != null) {
      results['original'] = originalUrl;
      
      // Générer les URLs des miniatures via transformations Cloudinary
      // Cloudinary génère ces variantes automatiquement à la demande
      results['thumbnail_small'] = _addTransformation(originalUrl, 'w_150,h_150,c_fill');
      results['thumbnail_medium'] = _addTransformation(originalUrl, 'w_300,h_300,c_fill');
      results['thumbnail_large'] = _addTransformation(originalUrl, 'w_600,h_600,c_fill');
    }
    
    return results;
  }

  /// Ajoute une transformation à une URL Cloudinary
  String _addTransformation(String url, String transformation) {
    // URL format: https://res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{public_id}
    final uploadIndex = url.indexOf('/upload/');
    if (uploadIndex != -1) {
      final insertIndex = uploadIndex + '/upload/'.length;
      return '${url.substring(0, insertIndex)}$transformation/${url.substring(insertIndex)}';
    }
    return url;
  }

  /// Supprime une image de Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };
      final signature = _generateSignature(params);
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur suppression Cloudinary: $e');
      return false;
    }
  }

  /// Génère une URL optimisée pour le web
  /// Avec compression automatique, format auto (WebP si supporté), etc.
  String getOptimizedUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    transformations.add('c_fill'); // Crop to fill
    
    return _addTransformation(originalUrl, transformations.join(','));
  }
}
