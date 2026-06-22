import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../screens/comparison_screen.dart';

/// Bandeau flottant affiché quand au moins 1 produit est en comparaison.
/// À placer dans le `body` (via un `Stack`) des écrans concernés.
class ComparisonBanner extends StatelessWidget {
  const ComparisonBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ComparisonProvider>(
      builder: (context, comparison, _) {
        if (comparison.productIds.isEmpty) return const SizedBox.shrink();

        final count = comparison.productIds.length;
        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Material(
            borderRadius: BorderRadius.circular(30),
            elevation: 4,
            color: AppTheme.primaryViolet,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComparisonScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.compare_arrows, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '$count produit${count > 1 ? 's' : ''} à comparer · Voir',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}