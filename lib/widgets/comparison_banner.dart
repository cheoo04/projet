import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../screens/comparison_screen.dart';

/// Bandeau flottant affiché quand au moins 1 produit est en comparaison.
/// Ouvre le comparateur en modal bottom sheet — slide depuis le bas,
/// sans quitter l'écran courant.
class ComparisonBanner extends StatelessWidget {
  const ComparisonBanner({Key? key}) : super(key: key);

  void _openComparison(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,        // Permet d'occuper jusqu'à 92% de l'écran
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ComparisonSheet(),
    );
  }

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
            elevation: 6,
            shadowColor: AppTheme.primaryViolet.withOpacity(0.4),
            color: AppTheme.primaryViolet,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _openComparison(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.compare_arrows, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '$count produit${count > 1 ? "s" : ""} sélectionné${count > 1 ? "s" : ""} · Comparer',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

/// Sheet modal qui contient l'écran de comparaison.
/// Occupe 92% de la hauteur de l'écran, avec coins arrondis en haut
/// et handle de glissement — exactement le pattern "drawer from bottom".
class _ComparisonSheet extends StatelessWidget {
  const _ComparisonSheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F5FC), // fond légèrement teinté violet
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle de glissement
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Contenu de la comparaison (scrollable)
          const Expanded(child: ComparisonScreen(embeddedInSheet: true)),
        ],
      ),
    );
  }
}