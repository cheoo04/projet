/// Web implementation for SEO using package:web
/// Modifies DOM meta tags dynamically for SEO

import 'package:web/web.dart' as web;

/// Met à jour une meta tag dans le DOM
void updateMetaTag(String name, String content) {
  try {
    // Chercher par name ou property (pour Open Graph)
    web.HTMLMetaElement? meta = web.document.querySelector('meta[name="$name"]') as web.HTMLMetaElement?;
    meta ??= web.document.querySelector('meta[property="$name"]') as web.HTMLMetaElement?;
    
    if (meta != null) {
      meta.content = content;
    } else {
      // Créer la meta tag si elle n'existe pas
      final newMeta = web.document.createElement('meta') as web.HTMLMetaElement;
      
      // Utiliser property pour les tags Open Graph, name pour les autres
      if (name.startsWith('og:') || name.startsWith('twitter:')) {
        newMeta.setAttribute('property', name);
      } else {
        newMeta.name = name;
      }
      newMeta.content = content;
      
      web.document.head?.appendChild(newMeta);
    }
  } catch (e) {
    // Silently fail - SEO is not critical for functionality
  }
}

/// Met à jour ou crée le script JSON-LD pour Schema.org
void updateJsonLd(String jsonLd) {
  try {
    // Chercher le script JSON-LD existant
    web.HTMLScriptElement? script = web.document.querySelector(
      'script[type="application/ld+json"]'
    ) as web.HTMLScriptElement?;
    
    if (script != null) {
      script.text = jsonLd;
    } else {
      // Créer le script s'il n'existe pas
      final newScript = web.document.createElement('script') as web.HTMLScriptElement;
      newScript.type = 'application/ld+json';
      newScript.text = jsonLd;
      web.document.head?.appendChild(newScript);
    }
  } catch (e) {
    // Silently fail
  }
}

/// Met à jour le titre du document
void updateDocumentTitle(String title) {
  try {
    web.document.title = title;
  } catch (e) {
    // Silently fail
  }
}
