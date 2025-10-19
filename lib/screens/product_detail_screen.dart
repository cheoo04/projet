import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  Future<void> openWhatsApp(Product product) async {
    final phone = '221771234567'; // Remplace par ton numéro en format international
    final message =
        'Bonjour, je suis intéressé par ce produit : ${product.name} (Réf: ${product.id}). Pouvez-vous m\'aider ?';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeFull(message)}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Fallback: ouvrir dans le navigateur
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = !product.isInStock;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Placeholder image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.brand, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${product.price.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 20, color: Colors.deepPurple)),
            const SizedBox(height: 16),
            if (outOfStock)
              const Text('Stock épuisé', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text(product.description),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: outOfStock ? null : () => openWhatsApp(product),
              icon: const Icon(Icons.whatsapp),
              label: const Text('Commander sur WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
