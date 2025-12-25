import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';

// Conditional import for web
import 'web_share_stub.dart'
    if (dart.library.html) 'web_share_web.dart' as web_share;

/// Options de partage
enum ShareOption { textOnly, imageOnly, both }

/// Service pour partager des produits
/// Supporte le web via Web Share API et mobile via share_plus
class ShareService {
  /// Partager un produit - affiche un dialog pour choisir le mode
  static Future<void> shareProduct(Product product, BuildContext context) async {
    // Sur web, utiliser Web Share API avec fallback boutons sociaux
    if (kIsWeb) {
      await _shareProductWeb(product, context);
      return;
    }
    
    final hasImage = product.imageUrls.isNotEmpty;
    
    if (!hasImage) {
      // Pas d'image, partager le texte directement
      await _shareTextOnly(product);
      return;
    }
    
    // Afficher le dialog de choix
    final choice = await showModalBottomSheet<ShareOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildShareOptionsSheet(ctx, product),
    );
    
    if (choice == null) return;
    
    switch (choice) {
      case ShareOption.textOnly:
        await _shareTextOnly(product);
        break;
      case ShareOption.imageOnly:
        await _shareImageOnly(product);
        break;
      case ShareOption.both:
        await _shareImageWithCaption(product);
        break;
    }
  }
  
  /// Partage web via Web Share API ou fallback
  static Future<void> _shareProductWeb(Product product, BuildContext context) async {
    final message = _buildShareMessage(product);
    final productUrl = 'https://pharrellphone.com/product/${product.id}';
    
    // Essayer Web Share API
    final success = await web_share.shareViaWebAPI(
      title: product.name,
      text: message,
      url: productUrl,
    );
    
    if (!success) {
      // Fallback: afficher dialog avec boutons sociaux
      await _showWebShareDialog(context, product, message, productUrl);
    }
  }
  
  /// Dialog de partage pour web (boutons sociaux)
  static Future<void> _showWebShareDialog(
    BuildContext context,
    Product product,
    String message,
    String productUrl,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Partager ${product.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Boutons de partage social
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    web_share.shareToWhatsApp(message, productUrl);
                  },
                ),
                _buildSocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    web_share.shareToFacebook(productUrl);
                  },
                ),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    web_share.shareToTwitter(message, productUrl);
                  },
                ),
                _buildSocialButton(
                  icon: Icons.link,
                  label: 'Copier',
                  color: Colors.grey[700]!,
                  onTap: () {
                    Navigator.pop(ctx);
                    web_share.copyToClipboard(productUrl);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié !')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construire le bottom sheet des options de partage
  static Widget _buildShareOptionsSheet(BuildContext context, Product product) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Comment partager ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Option 1: Texte seulement
          _buildShareOption(
            context,
            icon: Icons.text_fields,
            title: 'Texte uniquement',
            subtitle: 'Message avec détails du produit',
            color: Colors.blue,
            onTap: () => Navigator.pop(context, ShareOption.textOnly),
          ),
          
          const SizedBox(height: 12),
          
          // Option 2: Image seulement
          _buildShareOption(
            context,
            icon: Icons.image,
            title: 'Image uniquement',
            subtitle: 'Photo du produit',
            color: Colors.green,
            onTap: () => Navigator.pop(context, ShareOption.imageOnly),
          ),
          
          const SizedBox(height: 12),
          
          // Option 3: Les deux
          _buildShareOption(
            context,
            icon: Icons.photo_library,
            title: 'Image + Texte',
            subtitle: 'Photo avec message (certaines apps ignorent le texte)',
            color: Colors.purple,
            onTap: () => Navigator.pop(context, ShareOption.both),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  static Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  /// Partager uniquement le texte
  static Future<void> _shareTextOnly(Product product) async {
    final message = _buildShareMessage(product);
    await Share.share(
      message,
      subject: 'Découvrez ${product.name} sur Pharrell Phone',
    );
  }
  
  /// Partager uniquement l'image
  static Future<void> _shareImageOnly(Product product) async {
    if (product.imageUrls.isEmpty) return;
    
    try {
      final imageFile = await _downloadImage(product.imageUrls.first, product.id);
      if (imageFile != null) {
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          subject: product.name,
        );
      }
    } catch (e) {
      debugPrint('Erreur partage image: $e');
    }
  }
  
  /// Partager l'image avec le texte en caption
  static Future<void> _shareImageWithCaption(Product product) async {
    if (product.imageUrls.isEmpty) {
      await _shareTextOnly(product);
      return;
    }
    
    try {
      final imageFile = await _downloadImage(product.imageUrls.first, product.id);
      if (imageFile != null) {
        final message = _buildShareMessage(product);
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: message,
          subject: 'Découvrez ${product.name} sur Pharrell Phone',
        );
      }
    } catch (e) {
      debugPrint('Erreur partage image+texte: $e');
      await _shareTextOnly(product);
    }
  }
  
  /// Télécharger une image temporairement pour le partage
  static Future<File?> _downloadImage(String imageUrl, String productId) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final extension = _getImageExtension(imageUrl);
        final file = File('${tempDir.path}/share_$productId$extension');
        
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Erreur téléchargement image: $e');
    }
    return null;
  }
  
  /// Obtenir l'extension de l'image depuis l'URL
  static String _getImageExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    
    if (path.contains('.png')) return '.png';
    if (path.contains('.webp')) return '.webp';
    if (path.contains('.gif')) return '.gif';
    return '.jpg';
  }
  
  /// Construire le message de partage
  static String _buildShareMessage(Product product) {
    final buffer = StringBuffer();
    
    buffer.writeln('🛍️ ${product.name}');
    buffer.writeln('');
    buffer.writeln('💰 Prix: ${product.price.toStringAsFixed(0)} FCFA');
    buffer.writeln('🏷️ Marque: ${product.brand}');
    
    if (product.description.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 ${product.description}');
    }
    
    buffer.writeln('');
    
    if (product.stock > 0) {
      buffer.writeln('✅ En stock (${product.stock} disponibles)');
    } else {
      buffer.writeln('❌ Rupture de stock');
    }
    
    buffer.writeln('');
    buffer.writeln('📱 Découvrez ce produit sur Pharrell Phone !');
    buffer.writeln('📞 Contact WhatsApp: +225 07 88 71 18 96');
    
    return buffer.toString();
  }
  
  /// Partager un texte simple
  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }
}
