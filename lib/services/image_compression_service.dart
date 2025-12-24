import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Niveaux de compression disponibles
enum CompressionLevel {
  /// Haute qualité, compression minimale (90%)
  high,

  /// Qualité moyenne, bon équilibre (75%)
  medium,

  /// Compression maximale, qualité réduite (60%)
  low,

  /// Miniatures très compressées (50%)
  thumbnail,
}

/// Configuration de compression personnalisée
class CompressionConfig {
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final bool keepExif;
  final CompressFormat format;

  const CompressionConfig({
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
    this.keepExif = false,
    this.format = CompressFormat.jpeg,
  });

  /// Presets de compression
  static const CompressionConfig productImage = CompressionConfig(
    quality: 80,
    maxWidth: 1200,
    maxHeight: 1200,
    keepExif: false,
  );

  static const CompressionConfig productThumbnail = CompressionConfig(
    quality: 70,
    maxWidth: 400,
    maxHeight: 400,
    keepExif: false,
  );

  static const CompressionConfig profileImage = CompressionConfig(
    quality: 85,
    maxWidth: 500,
    maxHeight: 500,
    keepExif: false,
  );

  static const CompressionConfig reviewImage = CompressionConfig(
    quality: 75,
    maxWidth: 800,
    maxHeight: 800,
    keepExif: false,
  );

  static const CompressionConfig categoryBanner = CompressionConfig(
    quality: 80,
    maxWidth: 1920,
    maxHeight: 600,
    keepExif: false,
  );
}

/// Résultat de compression avec statistiques
class CompressionResult {
  final Uint8List? compressedBytes;
  final File? compressedFile;
  final int originalSize;
  final int compressedSize;
  final int originalWidth;
  final int originalHeight;
  final int compressedWidth;
  final int compressedHeight;
  final Duration processingTime;
  final bool success;
  final String? error;

  CompressionResult({
    this.compressedBytes,
    this.compressedFile,
    required this.originalSize,
    required this.compressedSize,
    required this.originalWidth,
    required this.originalHeight,
    required this.compressedWidth,
    required this.compressedHeight,
    required this.processingTime,
    required this.success,
    this.error,
  });

  /// Pourcentage de réduction
  double get reductionPercent =>
      originalSize > 0 ? (1 - compressedSize / originalSize) * 100 : 0;

  /// Taille originale formatée
  String get originalSizeFormatted => _formatSize(originalSize);

  /// Taille compressée formatée
  String get compressedSizeFormatted => _formatSize(compressedSize);

  /// Économie d'espace
  String get savingsFormatted => _formatSize(originalSize - compressedSize);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  String toString() {
    return '''
CompressionResult:
  ✅ Succès: $success
  📦 Original: $originalSizeFormatted (${originalWidth}x$originalHeight)
  📦 Compressé: $compressedSizeFormatted (${compressedWidth}x$compressedHeight)
  📉 Réduction: ${reductionPercent.toStringAsFixed(1)}% ($savingsFormatted économisés)
  ⏱️ Temps: ${processingTime.inMilliseconds}ms
''';
  }
}

/// Service de compression d'images avant upload vers Firebase Storage
class ImageCompressionService {
  /// Singleton
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  /// Compresse un fichier image (Mobile/Desktop)
  Future<CompressionResult> compressFile(
    File file, {
    CompressionLevel level = CompressionLevel.medium,
    CompressionConfig? config,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Obtenir la taille originale
      final originalSize = await file.length();
      
      // Lire les bytes pour obtenir les dimensions
      final originalBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      
      if (originalImage == null) {
        return CompressionResult(
          originalSize: originalSize,
          compressedSize: originalSize,
          originalWidth: 0,
          originalHeight: 0,
          compressedWidth: 0,
          compressedHeight: 0,
          processingTime: stopwatch.elapsed,
          success: false,
          error: 'Impossible de décoder l\'image',
        );
      }

      // Configuration de compression
      final compressionConfig = config ?? _getConfigForLevel(level);

      // Compression avec flutter_image_compress (plus performant sur mobile)
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: compressionConfig.quality,
        minWidth: compressionConfig.maxWidth,
        minHeight: compressionConfig.maxHeight,
        format: compressionConfig.format,
        keepExif: compressionConfig.keepExif,
      );

      stopwatch.stop();

      if (result == null) {
        return CompressionResult(
          originalSize: originalSize,
          compressedSize: originalSize,
          originalWidth: originalImage.width,
          originalHeight: originalImage.height,
          compressedWidth: originalImage.width,
          compressedHeight: originalImage.height,
          processingTime: stopwatch.elapsed,
          success: false,
          error: 'Échec de la compression',
        );
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      
      // Lire les dimensions compressées
      final compressedBytes = await compressedFile.readAsBytes();
      final compressedImage = img.decodeImage(compressedBytes);

      debugPrint('✅ Image compressée avec succès');
      debugPrint('   📦 Original: ${(originalSize / 1024).toStringAsFixed(0)} KB');
      debugPrint('   📦 Compressé: ${(compressedSize / 1024).toStringAsFixed(0)} KB');
      debugPrint('   📉 Réduction: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');

      return CompressionResult(
        compressedFile: compressedFile,
        compressedBytes: compressedBytes,
        originalSize: originalSize,
        compressedSize: compressedSize,
        originalWidth: originalImage.width,
        originalHeight: originalImage.height,
        compressedWidth: compressedImage?.width ?? 0,
        compressedHeight: compressedImage?.height ?? 0,
        processingTime: stopwatch.elapsed,
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Erreur compression: $e');
      
      return CompressionResult(
        originalSize: 0,
        compressedSize: 0,
        originalWidth: 0,
        originalHeight: 0,
        compressedWidth: 0,
        compressedHeight: 0,
        processingTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Compresse des bytes d'image (Web compatible)
  Future<CompressionResult> compressBytes(
    Uint8List imageBytes, {
    CompressionLevel level = CompressionLevel.medium,
    CompressionConfig? config,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final originalSize = imageBytes.length;
      
      // Décoder l'image originale
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        return CompressionResult(
          originalSize: originalSize,
          compressedSize: originalSize,
          originalWidth: 0,
          originalHeight: 0,
          compressedWidth: 0,
          compressedHeight: 0,
          processingTime: stopwatch.elapsed,
          success: false,
          error: 'Impossible de décoder l\'image',
        );
      }

      // Configuration de compression
      final compressionConfig = config ?? _getConfigForLevel(level);

      // Compression avec la bibliothèque 'image' (compatible Web)
      img.Image processedImage = originalImage;

      // Redimensionner si nécessaire
      if (originalImage.width > compressionConfig.maxWidth ||
          originalImage.height > compressionConfig.maxHeight) {
        // Calculer le ratio pour maintenir les proportions
        final widthRatio = compressionConfig.maxWidth / originalImage.width;
        final heightRatio = compressionConfig.maxHeight / originalImage.height;
        final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

        final newWidth = (originalImage.width * ratio).round();
        final newHeight = (originalImage.height * ratio).round();

        processedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encoder en JPEG avec la qualité spécifiée
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: compressionConfig.quality),
      );

      stopwatch.stop();

      final compressedSize = compressedBytes.length;

      debugPrint('✅ Image compressée (bytes) avec succès');
      debugPrint('   📦 Original: ${(originalSize / 1024).toStringAsFixed(0)} KB (${originalImage.width}x${originalImage.height})');
      debugPrint('   📦 Compressé: ${(compressedSize / 1024).toStringAsFixed(0)} KB (${processedImage.width}x${processedImage.height})');
      debugPrint('   📉 Réduction: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');

      return CompressionResult(
        compressedBytes: compressedBytes,
        originalSize: originalSize,
        compressedSize: compressedSize,
        originalWidth: originalImage.width,
        originalHeight: originalImage.height,
        compressedWidth: processedImage.width,
        compressedHeight: processedImage.height,
        processingTime: stopwatch.elapsed,
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Erreur compression bytes: $e');
      
      return CompressionResult(
        originalSize: imageBytes.length,
        compressedSize: imageBytes.length,
        originalWidth: 0,
        originalHeight: 0,
        compressedWidth: 0,
        compressedHeight: 0,
        processingTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Compresse plusieurs images en parallèle
  Future<List<CompressionResult>> compressMultipleFiles(
    List<File> files, {
    CompressionLevel level = CompressionLevel.medium,
    CompressionConfig? config,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <CompressionResult>[];
    final total = files.length;

    for (int i = 0; i < files.length; i++) {
      final result = await compressFile(
        files[i],
        level: level,
        config: config,
      );
      results.add(result);
      onProgress?.call(i + 1, total);
    }

    return results;
  }

  /// Génère une miniature carrée
  Future<CompressionResult> generateThumbnail(
    Uint8List imageBytes, {
    int size = 200,
    int quality = 70,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final originalSize = imageBytes.length;
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return CompressionResult(
          originalSize: originalSize,
          compressedSize: originalSize,
          originalWidth: 0,
          originalHeight: 0,
          compressedWidth: 0,
          compressedHeight: 0,
          processingTime: stopwatch.elapsed,
          success: false,
          error: 'Impossible de décoder l\'image',
        );
      }

      // Créer une miniature carrée centrée
      final thumbnail = img.copyResizeCropSquare(originalImage, size: size);
      final thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: quality),
      );

      stopwatch.stop();

      return CompressionResult(
        compressedBytes: thumbnailBytes,
        originalSize: originalSize,
        compressedSize: thumbnailBytes.length,
        originalWidth: originalImage.width,
        originalHeight: originalImage.height,
        compressedWidth: size,
        compressedHeight: size,
        processingTime: stopwatch.elapsed,
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      return CompressionResult(
        originalSize: imageBytes.length,
        compressedSize: imageBytes.length,
        originalWidth: 0,
        originalHeight: 0,
        compressedWidth: 0,
        compressedHeight: 0,
        processingTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Génère plusieurs tailles de miniatures
  Future<Map<String, CompressionResult>> generateMultipleThumbnails(
    Uint8List imageBytes, {
    Map<String, int> sizes = const {
      'small': 100,
      'medium': 300,
      'large': 600,
    },
  }) async {
    final results = <String, CompressionResult>{};

    for (final entry in sizes.entries) {
      results[entry.key] = await generateThumbnail(
        imageBytes,
        size: entry.value,
        quality: entry.value < 200 ? 60 : 75,
      );
    }

    return results;
  }

  /// Vérifie si une image nécessite une compression
  bool needsCompression(
    int fileSize, {
    int maxSizeKB = 500,
  }) {
    return fileSize > maxSizeKB * 1024;
  }

  /// Estime la taille après compression
  int estimateCompressedSize(
    int originalSize, {
    CompressionLevel level = CompressionLevel.medium,
  }) {
    final reductionFactor = switch (level) {
      CompressionLevel.high => 0.85,
      CompressionLevel.medium => 0.65,
      CompressionLevel.low => 0.45,
      CompressionLevel.thumbnail => 0.25,
    };
    return (originalSize * reductionFactor).round();
  }

  /// Obtient la configuration pour un niveau de compression
  CompressionConfig _getConfigForLevel(CompressionLevel level) {
    return switch (level) {
      CompressionLevel.high => const CompressionConfig(
          quality: 90,
          maxWidth: 2048,
          maxHeight: 2048,
        ),
      CompressionLevel.medium => const CompressionConfig(
          quality: 75,
          maxWidth: 1200,
          maxHeight: 1200,
        ),
      CompressionLevel.low => const CompressionConfig(
          quality: 60,
          maxWidth: 800,
          maxHeight: 800,
        ),
      CompressionLevel.thumbnail => const CompressionConfig(
          quality: 50,
          maxWidth: 400,
          maxHeight: 400,
        ),
    };
  }

  /// Obtient les informations d'une image sans la comprimer
  Future<Map<String, dynamic>> getImageInfo(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return {'error': 'Impossible de décoder l\'image'};
      }

      return {
        'width': image.width,
        'height': image.height,
        'size': imageBytes.length,
        'sizeFormatted': _formatSize(imageBytes.length),
        'aspectRatio': image.width / image.height,
        'isLandscape': image.width > image.height,
        'isPortrait': image.height > image.width,
        'isSquare': image.width == image.height,
        'megapixels': (image.width * image.height / 1000000).toStringAsFixed(2),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
