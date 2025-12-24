// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Imports conditionnels pour le web
import 'web_file_saver_stub.dart'
    if (dart.library.html) 'web_file_saver_web.dart' as impl;

/// Service de téléchargement de fichiers pour le web
class WebFileSaver {
  /// Télécharger un fichier sur le web
  static Future<void> saveFile(Uint8List bytes, String fileName, String mimeType) async {
    if (kIsWeb) {
      await impl.saveFileWeb(bytes, fileName, mimeType);
    } else {
      throw UnsupportedError('Cette méthode est uniquement pour le web');
    }
  }
}
