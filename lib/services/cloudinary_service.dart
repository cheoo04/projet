import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service pour uploader et gérer les images sur Cloudinary
/// 
/// Sécurisé : l'apiSecret n'est JAMAIS dans le code Flutter.
/// La signature est générée par la Cloud Function `getCloudinarySignature`
/// qui lit l'apiSecret depuis les secrets Firebase (côté serveur uniquement).
/// 
/// Setup une seule fois :
///   firebase functions:secrets:set CLOUDINARY_API_SECRET
///   firebase deploy --only functions
class CloudinaryService {
  // Ces valeurs sont publiques — pas de risque à les laisser ici
  static const String cloudName = 'dp8lng1aj';
  static const String apiKey = '745144142628186'; // clé publique, pas le secret
  static const String uploadPreset = 'pharrell_phone';

  // Singleton
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  String get _videoUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

  bool get isConfigured => cloudName != 'VOTRE_CLOUD_NAME';

  /// Upload unsigned (pour les utilisateurs normaux si besoin)
  Future<String?> uploadImageUnsigned(Uint8List imageBytes, {
    String? folder,
    String? publicId,
  }) async {
    try {
      if (!isConfigured) return null;

      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '${publicId ?? DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final url = data['secure_url'] as String;
        debugPrint('✅ Image uploadée (unsigned): $url');
        return url;
      } else {
        debugPrint('❌ Erreur Cloudinary unsigned: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception Cloudinary unsigned: $e');
      return null;
    }
  }

  /// Upload signed (pour les admins — signature générée par Cloud Function)
  /// L'apiSecret ne quitte JAMAIS le serveur Firebase
  Future<String?> uploadImageSigned(Uint8List imageBytes, {
    String? folder,
    String? publicId,
    Map<String, String>? transformations,
  }) async {
    try {
      if (!isConfigured) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Paramètres à signer
      final paramsToSign = <String, String>{
        'timestamp': timestamp.toString(),
      };
      if (folder != null) paramsToSign['folder'] = folder;
      if (publicId != null) paramsToSign['public_id'] = publicId;

      // ✅ Appel à la Cloud Function — l'apiSecret reste côté serveur
      final signature = await _getSignatureFromServer(paramsToSign);
      if (signature == null) return null;

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
        debugPrint('✅ Image uploadée (signed): $url');
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

  /// Upload vidéo signé (pour les admins — signature générée par Cloud Function)
  /// Même principe que [uploadImageSigned] mais pointe vers l'endpoint vidéo
  /// de Cloudinary. L'apiSecret ne quitte JAMAIS le serveur Firebase.
  Future<String?> uploadVideoSigned(
    Uint8List videoBytes, {
    String? folder,
    String? publicId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!isConfigured) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final paramsToSign = <String, String>{
        'timestamp': timestamp.toString(),
      };
      if (folder != null) paramsToSign['folder'] = folder;
      if (publicId != null) paramsToSign['public_id'] = publicId;

      final signature = await _getSignatureFromServer(paramsToSign);
      if (signature == null) return null;

      final uri = Uri.parse(_videoUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        videoBytes,
        filename: '${publicId ?? DateTime.now().millisecondsSinceEpoch}.mp4',
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
        debugPrint('✅ Vidéo uploadée (signed): $url');
        return url;
      } else {
        debugPrint('❌ Erreur Cloudinary vidéo: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception Cloudinary vidéo: $e');
      return null;
    }
  }

  /// Appelle la Cloud Function pour obtenir la signature.
  /// L'apiSecret ne transite jamais vers le client Flutter.
  /// Utilise HTTP direct — contournement bug FlutterFire #17924 (dart2js/Int64).
  Future<String?> _getSignatureFromServer(Map<String, String> paramsToSign) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Signature Cloudinary : utilisateur non connecté');
        return null;
      }
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse(
            'https://europe-west1-first-pro-cheoo.cloudfunctions.net/getCloudinarySignature'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'data': {'paramsToSign': paramsToSign}}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('❌ Erreur signature Cloud Function: ${response.body}');
        return null;
      }

      final result =
          jsonDecode(response.body)['result'] as Map<String, dynamic>;
      return result['signature'] as String?;
    } catch (e) {
      debugPrint('❌ Erreur signature Cloud Function: $e');
      return null;
    }
  }

  /// Génère la signature pour la suppression (aussi via Cloud Function)
  Future<String?> _getSignatureFromServerForDelete(Map<String, String> params) async {
    return _getSignatureFromServer(params);
  }

  /// Upload avec génération de miniatures
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
      results['thumbnail_small'] =
          _addTransformation(originalUrl, 'w_150,h_150,c_fill');
      results['thumbnail_medium'] =
          _addTransformation(originalUrl, 'w_300,h_300,c_fill');
      results['thumbnail_large'] =
          _addTransformation(originalUrl, 'w_600,h_600,c_fill');
    }

    return results;
  }

  /// Ajoute une transformation à une URL Cloudinary
  String _addTransformation(String url, String transformation) {
    final uploadIndex = url.indexOf('/upload/');
    if (uploadIndex != -1) {
      final insertIndex = uploadIndex + '/upload/'.length;
      return '${url.substring(0, insertIndex)}$transformation/${url.substring(insertIndex)}';
    }
    return url;
  }

  /// Supprime une image — signature générée par Cloud Function
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      final signature = await _getSignatureFromServerForDelete(params);
      if (signature == null) return false;

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

  /// Supprime une vidéo — signature générée par Cloud Function
  Future<bool> deleteVideo(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      final signature = await _getSignatureFromServerForDelete(params);
      if (signature == null) return false;

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/destroy'),
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
      debugPrint('❌ Erreur suppression vidéo Cloudinary: $e');
      return false;
    }
  }

  /// Génère une URL optimisée (lecture seule — pas besoin de secret)
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
    transformations.add('c_fill');
    return _addTransformation(originalUrl, transformations.join(','));
  }
}