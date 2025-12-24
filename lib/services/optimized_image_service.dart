import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'image_compression_service.dart';

/// Service optimisé pour la gestion des images
class OptimizedImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImageCompressionService _compressionService =
      ImageCompressionService();

  /// Compression d'image avant upload (optimisation mobile)
  /// @deprecated Utilisez [compressWithLevel] pour plus de contrôle
  static Future<File?> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        debugPrint('❌ Échec compression image');
        return null;
      }

      final originalSize = await file.length();
      final compressedSize = await result.length();
      final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      debugPrint('✅ Image compressée: $reduction% de réduction');
      debugPrint('   Original: ${(originalSize / 1024).toStringAsFixed(0)} KB');
      debugPrint('   Compressée: ${(compressedSize / 1024).toStringAsFixed(0)} KB');

      return File(result.path);
    } catch (e) {
      debugPrint('❌ Erreur compression: $e');
      return null;
    }
  }

  /// Compression avec niveau configurable
  static Future<CompressionResult> compressWithLevel(
    File file, {
    CompressionLevel level = CompressionLevel.medium,
    CompressionConfig? config,
  }) async {
    return _compressionService.compressFile(file, level: level, config: config);
  }

  /// Compression de bytes (compatible Web)
  static Future<CompressionResult> compressBytesWithLevel(
    Uint8List bytes, {
    CompressionLevel level = CompressionLevel.medium,
    CompressionConfig? config,
  }) async {
    return _compressionService.compressBytes(bytes, level: level, config: config);
  }

  /// Upload d'image avec compression automatique améliorée
  static Future<String?> uploadProductImage(
    File imageFile,
    String productId, {
    bool compress = true,
    CompressionLevel compressionLevel = CompressionLevel.medium,
    void Function(double progress)? onProgress,
  }) async {
    try {
      File fileToUpload = imageFile;
      CompressionResult? compressionResult;

      // Compression avant upload avec le nouveau service
      if (compress) {
        compressionResult = await compressWithLevel(
          imageFile,
          level: compressionLevel,
        );
        
        if (compressionResult.success && compressionResult.compressedFile != null) {
          fileToUpload = compressionResult.compressedFile!;
          debugPrint(compressionResult.toString());
        } else {
          // Fallback vers l'ancienne méthode si échec
          final compressed = await compressImage(imageFile);
          if (compressed != null) {
            fileToUpload = compressed;
          }
        }
      }

      // Upload vers Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('products/$productId/$fileName');

      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'productId': productId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'compressed': compress.toString(),
            'compressionLevel': compressionLevel.name,
            if (compressionResult != null) ...{
              'originalSize': compressionResult.originalSize.toString(),
              'compressedSize': compressionResult.compressedSize.toString(),
              'reductionPercent':
                  compressionResult.reductionPercent.toStringAsFixed(1),
            },
          },
        ),
      );

      // Suivre la progression
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        debugPrint('Upload: ${(progress * 100).toStringAsFixed(1)}%');
        onProgress?.call(progress);
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload: $e');
      return null;
    }
  }

  /// Upload multiple avec compression et progression
  static Future<List<String>> uploadMultipleProductImages(
    List<File> imageFiles,
    String productId, {
    CompressionLevel compressionLevel = CompressionLevel.medium,
    void Function(int completed, int total, double overallProgress)? onProgress,
  }) async {
    final urls = <String>[];
    final total = imageFiles.length;

    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadProductImage(
        imageFiles[i],
        productId,
        compressionLevel: compressionLevel,
        onProgress: (fileProgress) {
          final overallProgress = (i + fileProgress) / total;
          onProgress?.call(i + 1, total, overallProgress);
        },
      );

      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Upload d'image de profil avec compression optimisée
  static Future<String?> uploadProfileImage(
    File imageFile,
    String userId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Compression spécifique pour les photos de profil
      final result = await compressWithLevel(
        imageFile,
        config: CompressionConfig.profileImage,
      );

      File fileToUpload = imageFile;
      if (result.success && result.compressedFile != null) {
        fileToUpload = result.compressedFile!;
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/$fileName');

      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress?.call(progress);
      });

      final snapshot = await uploadTask;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Erreur upload profil: $e');
      return null;
    }
  }

  /// Upload d'image d'avis avec compression
  static Future<String?> uploadReviewImage(
    File imageFile,
    String reviewId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final result = await compressWithLevel(
        imageFile,
        config: CompressionConfig.reviewImage,
      );

      File fileToUpload = imageFile;
      if (result.success && result.compressedFile != null) {
        fileToUpload = result.compressedFile!;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('reviews/$reviewId/$fileName');

      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress?.call(progress);
      });

      final snapshot = await uploadTask;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Erreur upload image avis: $e');
      return null;
    }
  }

  /// Génère et upload une miniature
  static Future<String?> uploadThumbnail(
    Uint8List imageBytes,
    String path, {
    int size = 200,
  }) async {
    try {
      final thumbnail = await _compressionService.generateThumbnail(
        imageBytes,
        size: size,
      );

      if (!thumbnail.success || thumbnail.compressedBytes == null) {
        return null;
      }

      final ref = _storage.ref().child('$path/thumbnail_$size.jpg');
      final snapshot = await ref.putData(
        thumbnail.compressedBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Erreur upload miniature: $e');
      return null;
    }
  }

  /// Widget optimisé pour afficher les images réseau
  static Widget cachedImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 48),
          );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Placeholder pendant chargement
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      // Widget en cas d'erreur
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 48),
          ),
      // Configuration du cache
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }

  /// Variante avec Hero animation
  static Widget cachedImageWithHero(
    String? imageUrl,
    String heroTag, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Hero(
      tag: heroTag,
      child: cachedImage(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  /// Supprimer une image de Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Image supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
      return false;
    }
  }

  /// Supprimer toutes les images d'un produit
  static Future<void> deleteProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
        debugPrint('✅ Image supprimée: ${item.name}');
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression images: $e');
    }
  }

  /// Précharger les images pour améliorer les performances
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (e) {
        debugPrint('Erreur precache $url: $e');
      }
    }
  }

  /// Effacer le cache des images
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      debugPrint('✅ Cache images effacé');
    } catch (e) {
      debugPrint('❌ Erreur effacement cache: $e');
    }
  }
}
