import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Web Share API implementation
Future<bool> shareViaWebAPI({
  required String title,
  required String text,
  required String url,
}) async {
  try {
    // Vérifier si Web Share API est disponible
    if (!_isWebShareSupported()) {
      return false;
    }
    
    // Créer l'objet de partage via package:web ShareData
    final shareData = web.ShareData(
      title: title,
      text: text,
      url: url,
    );
    
    await web.window.navigator.share(shareData).toDart;
    return true;
  } catch (e) {
    // L'utilisateur a annulé ou erreur
    return false;
  }
}

/// Vérifier si Web Share API est supportée
bool _isWebShareSupported() {
  // Check if share method exists on navigator using js_interop_unsafe
  final shareFunc = (web.window.navigator as JSObject)['share'];
  return shareFunc != null && !shareFunc.isUndefinedOrNull;
}

/// Partager sur WhatsApp
void shareToWhatsApp(String message, String url) {
  final encodedMessage = Uri.encodeComponent('$message\n\n$url');
  final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
  _openUrl(whatsappUrl);
}

/// Partager sur Facebook
void shareToFacebook(String url) {
  final encodedUrl = Uri.encodeComponent(url);
  final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl';
  _openUrl(facebookUrl);
}

/// Partager sur Twitter/X
void shareToTwitter(String message, String url) {
  final encodedText = Uri.encodeComponent(message);
  final encodedUrl = Uri.encodeComponent(url);
  final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl';
  _openUrl(twitterUrl);
}

/// Copier dans le presse-papiers
void copyToClipboard(String text) {
  web.window.navigator.clipboard.writeText(text);
}

/// Ouvrir une URL dans un nouvel onglet
void _openUrl(String url) {
  web.window.open(url, '_blank');
}
