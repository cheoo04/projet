import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';

// Import conditionnel pour le web
import 'seo_config_stub.dart'
    if (dart.library.js_interop) 'seo_config_web.dart' as seo_impl;

/// Configuration SEO pour le web
/// Gère les meta tags dynamiques pour l'indexation Google
class SEOConfig {
  // Constructeur privé
  SEOConfig._();

  /// Meta tags par défaut pour l'application
  static const String defaultTitle = 'Pharrell Phone - Smartphones et Accessoires';
  static const String defaultDescription = 
      'Boutique en ligne de smartphones, accessoires et objets connectés. '
      'iPhone, Samsung, Xiaomi et plus. Livraison rapide en France.';
  static const String defaultKeywords = 
      'smartphone, téléphone, iPhone, Samsung, accessoires, coque, chargeur, écouteurs';
  static const String defaultImage = 'assets/images/og-image.png';
  static const String siteUrl = 'https://pharrellphone.com';

  /// Met à jour les meta tags pour un produit (web uniquement)
  static void updateMetaTags(Product product) {
    if (!kIsWeb) return;

    final title = '${product.name} - Pharrell Phone';
    final description = product.shortDescription ?? 
        '${product.name} - ${product.brand} disponible chez Pharrell Phone';
    final image = product.imageUrls.isNotEmpty ? product.imageUrls.first : defaultImage;
    final keywords = '${product.brand}, ${product.name}, ${product.category}, smartphone';
    final url = '$siteUrl/product/${product.id}';

    seo_impl.updateMetaTag('title', title);
    seo_impl.updateMetaTag('description', description);
    seo_impl.updateMetaTag('keywords', keywords);
    
    // Open Graph tags
    seo_impl.updateMetaTag('og:title', title);
    seo_impl.updateMetaTag('og:description', description);
    seo_impl.updateMetaTag('og:image', image);
    seo_impl.updateMetaTag('og:url', url);
    seo_impl.updateMetaTag('og:type', 'product');
    
    // Twitter Card tags
    seo_impl.updateMetaTag('twitter:card', 'summary_large_image');
    seo_impl.updateMetaTag('twitter:title', title);
    seo_impl.updateMetaTag('twitter:description', description);
    seo_impl.updateMetaTag('twitter:image', image);
    
    // Schema.org JSON-LD pour produit
    seo_impl.updateJsonLd(_buildProductJsonLd(product));
    
    // Mettre à jour le titre de la page
    seo_impl.updateDocumentTitle(title);
  }

  /// Met à jour les meta tags pour une page générique
  static void updatePageMeta({
    required String title,
    required String description,
    String? image,
    String? url,
  }) {
    if (!kIsWeb) return;

    final fullTitle = '$title - Pharrell Phone';
    
    seo_impl.updateMetaTag('title', fullTitle);
    seo_impl.updateMetaTag('description', description);
    seo_impl.updateMetaTag('og:title', fullTitle);
    seo_impl.updateMetaTag('og:description', description);
    if (image != null) seo_impl.updateMetaTag('og:image', image);
    if (url != null) seo_impl.updateMetaTag('og:url', '$siteUrl$url');
    
    seo_impl.updateDocumentTitle(fullTitle);
  }

  /// Reset les meta tags aux valeurs par défaut
  static void resetToDefault() {
    if (!kIsWeb) return;

    seo_impl.updateMetaTag('title', defaultTitle);
    seo_impl.updateMetaTag('description', defaultDescription);
    seo_impl.updateMetaTag('keywords', defaultKeywords);
    seo_impl.updateMetaTag('og:title', defaultTitle);
    seo_impl.updateMetaTag('og:description', defaultDescription);
    seo_impl.updateMetaTag('og:image', '$siteUrl/$defaultImage');
    seo_impl.updateMetaTag('og:url', siteUrl);
    
    seo_impl.updateDocumentTitle(defaultTitle);
  }
  
  /// Construit le JSON-LD Schema.org pour un produit
  static String _buildProductJsonLd(Product product) {
    return '''
{
  "@context": "https://schema.org/",
  "@type": "Product",
  "name": "${product.name}",
  "image": ${product.imageUrls.isNotEmpty ? '["${product.imageUrls.join('","')}"]' : '[]'},
  "description": "${product.shortDescription ?? product.name}",
  "brand": {
    "@type": "Brand",
    "name": "${product.brand}"
  },
  "offers": {
    "@type": "Offer",
    "price": "${product.price}",
    "priceCurrency": "XOF",
    "availability": "${product.stock > 0 ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock'}",
    "seller": {
      "@type": "Organization",
      "name": "Pharrell Phone"
    }
  }
}
''';
  }

  /// Génère le sitemap.xml (à appeler côté serveur ou build)
  static String generateSitemap(List<Product> products) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    
    // Pages statiques
    final staticPages = [
      '/',
      '/home',
      '/catalog',
      '/auth',
      '/help',
      '/privacy',
    ];
    
    for (final page in staticPages) {
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>$siteUrl$page</loc>');
      buffer.writeln('    <changefreq>weekly</changefreq>');
      buffer.writeln('    <priority>0.8</priority>');
      buffer.writeln('  </url>');
    }
    
    // Pages produits
    for (final product in products) {
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>$siteUrl/product/${product.id}</loc>');
      buffer.writeln('    <lastmod>${DateTime.now().toIso8601String().split('T')[0]}</lastmod>');
      buffer.writeln('    <changefreq>daily</changefreq>');
      buffer.writeln('    <priority>0.9</priority>');
      buffer.writeln('  </url>');
    }
    
    buffer.writeln('</urlset>');
    return buffer.toString();
  }
}
