import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageManagementService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Redimensionne une image selon les spécifications données
  Future<Uint8List?> resizeImage(
    Uint8List imageBytes, {
    int? width,
    int? height,
    bool maintainAspectRatio = true,
  }) async {
    try {
      // Décoder l'image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image resizedImage;

      if (maintainAspectRatio) {
        // Calculer les nouvelles dimensions en gardant le ratio
        double aspectRatio = image.width / image.height;

        if (width != null && height != null) {
          // Prendre la dimension qui respecte le mieux le ratio
          double targetRatio = width / height;
          if (aspectRatio > targetRatio) {
            // L'image est plus large, ajuster sur la largeur
            height = (width / aspectRatio).round();
          } else {
            // L'image est plus haute, ajuster sur la hauteur
            width = (height * aspectRatio).round();
          }
        } else if (width != null) {
          height = (width / aspectRatio).round();
        } else if (height != null) {
          width = (height * aspectRatio).round();
        }

        resizedImage = img.copyResize(image, width: width, height: height);
      } else {
        resizedImage = img.copyResize(image, width: width, height: height);
      }

      // Encoder en JPEG avec qualité optimisée
      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
    } catch (e) {
      debugPrint('Erreur lors du redimensionnement: $e');
      return null;
    }
  }

  /// Recadre une image selon les coordonnées spécifiées
  Future<Uint8List?> cropImage(
    Uint8List imageBytes, {
    required double cropX,
    required double cropY,
    required double cropWidth,
    required double cropHeight,
  }) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Convertir les coordonnées relatives en pixels
      int x = (cropX * image.width).round();
      int y = (cropY * image.height).round();
      int width = (cropWidth * image.width).round();
      int height = (cropHeight * image.height).round();

      // Vérifier les limites
      x = x.clamp(0, image.width - 1);
      y = y.clamp(0, image.height - 1);
      width = width.clamp(1, image.width - x);
      height = height.clamp(1, image.height - y);

      // Recadrer l'image
      img.Image croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 85));
    } catch (e) {
      debugPrint('Erreur lors du recadrage: $e');
      return null;
    }
  }

  /// Applique un filtre à une image
  Future<Uint8List?> applyFilter(
    Uint8List imageBytes, {
    required ImageFilter filter,
    double intensity = 1.0,
  }) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image processedImage;

      switch (filter) {
        case ImageFilter.brightness:
          // Ajuster la luminosité en modifiant les pixels
          processedImage = img.adjustColor(image, brightness: intensity);
          break;
        case ImageFilter.contrast:
          processedImage = img.adjustColor(image, contrast: intensity);
          break;
        case ImageFilter.saturation:
          processedImage = img.adjustColor(image, saturation: intensity);
          break;
        case ImageFilter.sepia:
          processedImage = img.sepia(image);
          break;
        case ImageFilter.grayscale:
          processedImage = img.grayscale(image);
          break;
        case ImageFilter.blur:
          processedImage = img.gaussianBlur(
            image,
            radius: (intensity * 5).round(),
          );
          break;
        case ImageFilter.emboss:
          processedImage = img.emboss(image);
          break;
        case ImageFilter.edge:
          processedImage = img.sobel(image);
          break;
      }

      return Uint8List.fromList(img.encodeJpg(processedImage, quality: 85));
    } catch (e) {
      debugPrint('Erreur lors de l\'application du filtre: $e');
      return null;
    }
  }

  /// Optimise une image pour le web (compression et format)
  Future<Uint8List?> optimizeForWeb(
    Uint8List imageBytes, {
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 80,
  }) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Redimensionner si nécessaire
      if (image.width > maxWidth || image.height > maxHeight) {
        double scaleWidth = maxWidth / image.width;
        double scaleHeight = maxHeight / image.height;
        double scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

        int newWidth = (image.width * scale).round();
        int newHeight = (image.height * scale).round();

        image = img.copyResize(image, width: newWidth, height: newHeight);
      }

      // Optimiser les couleurs
      image = img.quantize(image, numberOfColors: 256);

      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      debugPrint('Erreur lors de l\'optimisation: $e');
      return null;
    }
  }

  /// Crée des miniatures de différentes tailles
  Future<Map<String, Uint8List>> generateThumbnails(
    Uint8List imageBytes, {
    List<ThumbnailSize> sizes = const [
      ThumbnailSize.small,
      ThumbnailSize.medium,
      ThumbnailSize.large,
    ],
  }) async {
    Map<String, Uint8List> thumbnails = {};

    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return thumbnails;

      for (ThumbnailSize size in sizes) {
        int dimension = _getThumbnailDimension(size);

        // Créer une miniature carrée
        img.Image thumbnail = img.copyResizeCropSquare(image, size: dimension);

        Uint8List thumbnailBytes = Uint8List.fromList(
          img.encodeJpg(thumbnail, quality: 75),
        );

        thumbnails[size.name] = thumbnailBytes;
      }
    } catch (e) {
      debugPrint('Erreur lors de la génération des miniatures: $e');
    }

    return thumbnails;
  }

  /// Upload une image avec ses miniatures vers Firebase Storage
  Future<Map<String, String>> uploadImageWithThumbnails(
    Uint8List imageBytes,
    String path, {
    bool generateThumbnails = true,
    Map<String, dynamic>? metadata,
  }) async {
    Map<String, String> uploadResults = {};

    try {
      // Upload de l'image principale
      Reference mainRef = _storage.ref().child('$path/original.jpg');

      SettableMetadata uploadMetadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: metadata?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      TaskSnapshot mainSnapshot = await mainRef.putData(
        imageBytes,
        uploadMetadata,
      );
      String mainUrl = await mainSnapshot.ref.getDownloadURL();
      uploadResults['original'] = mainUrl;

      // Upload des miniatures si demandé
      if (generateThumbnails) {
        Map<String, Uint8List> thumbnails = await this.generateThumbnails(
          imageBytes,
        );

        for (String size in thumbnails.keys) {
          Reference thumbRef = _storage.ref().child(
            '$path/thumbnail_$size.jpg',
          );
          TaskSnapshot thumbSnapshot = await thumbRef.putData(
            thumbnails[size]!,
            uploadMetadata,
          );
          String thumbUrl = await thumbSnapshot.ref.getDownloadURL();
          uploadResults['thumbnail_$size'] = thumbUrl;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'upload: $e');
      throw Exception('Échec de l\'upload de l\'image: $e');
    }

    return uploadResults;
  }

  /// Supprime une image et ses miniatures de Firebase Storage
  Future<void> deleteImageWithThumbnails(String path) async {
    try {
      // Supprimer l'image principale
      await _storage.ref().child('$path/original.jpg').delete();

      // Supprimer les miniatures
      for (ThumbnailSize size in ThumbnailSize.values) {
        try {
          await _storage
              .ref()
              .child('$path/thumbnail_${size.name}.jpg')
              .delete();
        } catch (e) {
          // Ignorer si la miniature n'existe pas
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      throw Exception('Échec de la suppression de l\'image: $e');
    }
  }

  /// Réorganise l'ordre des images en mettant à jour leurs métadonnées
  Future<void> reorderImages(
    List<String> imagePaths,
    List<int> newOrder,
  ) async {
    try {
      for (int i = 0; i < imagePaths.length; i++) {
        String imagePath = imagePaths[i];
        int order = newOrder[i];

        Reference imageRef = _storage.ref().child('$imagePath/original.jpg');

        // Mettre à jour les métadonnées avec le nouvel ordre
        SettableMetadata metadata = SettableMetadata(
          customMetadata: {'order': order.toString()},
        );

        await imageRef.updateMetadata(metadata);
      }
    } catch (e) {
      debugPrint('Erreur lors de la réorganisation: $e');
      throw Exception('Échec de la réorganisation des images: $e');
    }
  }

  /// Obtient les informations détaillées d'une image
  Future<ImageInfo?> getImageInfo(Uint8List imageBytes) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      return ImageInfo(
        width: image.width,
        height: image.height,
        format: _getImageFormat(imageBytes),
        sizeInBytes: imageBytes.length,
        aspectRatio: image.width / image.height,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'analyse de l\'image: $e');
      return null;
    }
  }

  /// Valide qu'une image respecte les contraintes données
  Future<ImageValidationResult> validateImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int? maxSizeInBytes,
    List<String>? allowedFormats,
  }) async {
    try {
      ImageInfo? info = await getImageInfo(imageBytes);
      if (info == null) {
        return ImageValidationResult(
          isValid: false,
          errors: ['Format d\'image non supporté'],
        );
      }

      List<String> errors = [];

      // Vérifier les dimensions
      if (maxWidth != null && info.width > maxWidth) {
        errors.add('Largeur trop importante (${info.width}px > ${maxWidth}px)');
      }
      if (maxHeight != null && info.height > maxHeight) {
        errors.add(
          'Hauteur trop importante (${info.height}px > ${maxHeight}px)',
        );
      }

      // Vérifier la taille
      if (maxSizeInBytes != null && info.sizeInBytes > maxSizeInBytes) {
        errors.add(
          'Taille de fichier trop importante (${(info.sizeInBytes / 1024 / 1024).toStringAsFixed(1)}MB > ${(maxSizeInBytes / 1024 / 1024).toStringAsFixed(1)}MB)',
        );
      }

      // Vérifier le format
      if (allowedFormats != null && !allowedFormats.contains(info.format)) {
        errors.add('Format non autorisé (${info.format})');
      }

      return ImageValidationResult(isValid: errors.isEmpty, errors: errors);
    } catch (e) {
      debugPrint('Erreur lors de la validation: $e');
      return ImageValidationResult(
        isValid: false,
        errors: ['Erreur lors de la validation: $e'],
      );
    }
  }

  /// Sauvegarde temporaire d'une image pour prévisualisation
  Future<String?> saveTemporaryImage(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(imageBytes);
      return tempFile.path;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde temporaire: $e');
      return null;
    }
  }

  /// Nettoie les fichiers temporaires
  Future<void> cleanTemporaryFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      for (FileSystemEntity file in files) {
        if (file is File && file.path.contains('temp_image_')) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage: $e');
    }
  }

  int _getThumbnailDimension(ThumbnailSize size) {
    switch (size) {
      case ThumbnailSize.small:
        return 100;
      case ThumbnailSize.medium:
        return 200;
      case ThumbnailSize.large:
        return 400;
    }
  }

  String _getImageFormat(Uint8List imageBytes) {
    if (imageBytes.length < 4) return 'unknown';

    // Vérifier les signatures de fichiers
    if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) return 'JPEG';
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'PNG';
    }
    if (imageBytes[0] == 0x47 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46) {
      return 'GIF';
    }
    if (imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) return 'BMP';
    if (imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46) {
      return 'WEBP';
    }

    return 'unknown';
  }
}

enum ImageFilter {
  brightness,
  contrast,
  saturation,
  sepia,
  grayscale,
  blur,
  emboss,
  edge,
}

enum ThumbnailSize { small, medium, large }

class ImageInfo {
  final int width;
  final int height;
  final String format;
  final int sizeInBytes;
  final double aspectRatio;

  ImageInfo({
    required this.width,
    required this.height,
    required this.format,
    required this.sizeInBytes,
    required this.aspectRatio,
  });

  String get sizeInMB => (sizeInBytes / 1024 / 1024).toStringAsFixed(2);
  String get dimensions => '${width}x$height';
}

class ImageValidationResult {
  final bool isValid;
  final List<String> errors;

  ImageValidationResult({required this.isValid, required this.errors});
}
