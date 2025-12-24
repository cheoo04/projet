#!/bin/bash
# Script pour générer le sitemap.xml depuis Firestore
# Usage: ./scripts/generate_sitemap.sh

set -e

SITE_URL="https://pharrell-phone.web.app"
OUTPUT_FILE="web/sitemap.xml"

echo "🗺️ Génération du sitemap.xml..."

# Pages statiques
cat > $OUTPUT_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <!-- Pages statiques -->
  <url>
    <loc>${SITE_URL}/</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>${SITE_URL}/catalog</loc>
    <changefreq>daily</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>${SITE_URL}/cart</loc>
    <changefreq>weekly</changefreq>
    <priority>0.5</priority>
  </url>
  <url>
    <loc>${SITE_URL}/account</loc>
    <changefreq>monthly</changefreq>
    <priority>0.4</priority>
  </url>
  
  <!-- Pages catégories -->
  <url>
    <loc>${SITE_URL}/catalog?category=Smartphones</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>${SITE_URL}/catalog?category=Accessoires</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>${SITE_URL}/catalog?category=Promotions</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
EOF

echo "✅ Sitemap généré: $OUTPUT_FILE"
echo ""
echo "ℹ️ Pour ajouter les produits dynamiquement, exécutez:"
echo "   dart run scripts/generate_sitemap_products.dart"
