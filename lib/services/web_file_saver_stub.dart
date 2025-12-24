import 'dart:typed_data';

/// Stub pour les plateformes non-web
Future<void> saveFileWeb(Uint8List bytes, String fileName, String mimeType) async {
  throw UnsupportedError('Le téléchargement web n\'est pas supporté sur cette plateforme');
}
