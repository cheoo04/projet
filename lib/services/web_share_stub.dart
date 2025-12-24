/// Stub implementation for non-web platforms
/// Ces méthodes ne sont jamais appelées sur mobile (kIsWeb check)

Future<bool> shareViaWebAPI({
  required String title,
  required String text,
  required String url,
}) async {
  return false;
}

void shareToWhatsApp(String message, String url) {}

void shareToFacebook(String url) {}

void shareToTwitter(String message, String url) {}

void copyToClipboard(String text) {}
