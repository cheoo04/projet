import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({required this.product, super.key});

  void openWhatsApp(BuildContext context) async {
    String phone = "+2250788711896"; // Numéro de téléphone du vendeur
    String message =
        "Bonjour, je suis intéressé par ce produit : ${product.name} (Réf: ${product.id}). Pouvez-vous m'aider ?";
    String url = "https://wa.me/$phone?text=${Uri.encodeFull(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 16),
            Text(
              'Prix: ${product.price} FCFA',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openWhatsApp(context),
              child: const Text('Commander sur WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
