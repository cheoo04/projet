// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Télécharger un fichier sur le web via l'API HTML5
Future<void> saveFileWeb(Uint8List bytes, String fileName, String mimeType) async {
  // Créer un Blob avec les données
  final blob = html.Blob([bytes], mimeType);
  
  // Créer une URL pour le blob
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Créer un élément <a> pour le téléchargement
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  
  // Ajouter au DOM et cliquer
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Nettoyer
  html.document.body?.children.remove(anchor);
  
  // Révoquer l'URL après un court délai
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });
}
