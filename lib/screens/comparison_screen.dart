import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/ai_chat_service.dart';
import '../services/product_service.dart';
import '../widgets/responsive_scaffold.dart';

/// Écran de comparaison enrichi avec analyse IA.
/// Affiche jusqu'à 3 produits côte à côte (specs détaillées) + une section
/// d'analyse Gemini générée à la demande, qui explique en langage naturel
/// les différences, points forts, et quel profil devrait choisir quoi.
class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({Key? key}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final ProductService _productService = ProductService();
  final AiChatService _aiService = AiChatService();

  List<Product> _products = [];
  bool _isLoading = true;

  // État de l'analyse IA
  String? _aiAnalysis;
  bool _isAnalyzing = false;
  String? _analysisError;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final ids = context.read<ComparisonProvider>().productIds;
    final products = await _productService.getByIds(ids);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestAnalysis() async {
    if (_products.length < 2) return;
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _aiAnalysis = null;
    });
    try {
      final analysis =
          await _aiService.compareProducts(_products.map((p) => p.id).toList());
      if (mounted) setState(() => _aiAnalysis = analysis);
    } catch (e) {
      if (mounted) {
        setState(() => _analysisError =
            e.toString().contains('resource-exhausted')
                ? 'Service temporairement occupé. Réessayez dans quelques instants.'
                : 'Impossible de générer l\'analyse. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  List<String> get _allSpecLabels {
    final labels = <String>[];
    for (final product in _products) {
      for (final spec in product.detailedSpecs) {
        if (!labels.contains(spec.label)) labels.add(spec.label);
      }
    }
    return labels;
  }

  String? _specValueFor(Product product, String label) {
    for (final spec in product.detailedSpecs) {
      if (spec.label == label) return spec.value;
    }
    return null;
  }

  void _removeProduct(Product product) {
    context.read<ComparisonProvider>().remove(product.id);
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      // Réinitialise l'analyse si les produits changent
      _aiAnalysis = null;
      _analysisError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_products.isEmpty) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Comparer')),
        body: const Center(child: Text('Aucun produit à comparer')),
      );
    }

    final specLabels = _allSpecLabels;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Comparer'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ComparisonProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Tout effacer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tableau de comparaison ──────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(160),
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.shade300),
                ),
                children: [
                  // Photo + nom + bouton retirer
                  TableRow(
                    children: _products.map((product) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeProduct(product),
                              ),
                            ),
                            if (product.imageUrls.isNotEmpty)
                              Image.network(
                                product.imageUrls.first,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            const SizedBox(height: 6),
                            Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.brand,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // Prix (+ promo si applicable)
                  TableRow(
                    decoration:
                        BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.06)),
                    children: _products.map((product) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              'Prix',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${product.price.toStringAsFixed(0)} FCFA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.primaryViolet,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (product.originalPrice != null &&
                                product.originalPrice! > product.price)
                              Text(
                                '${product.originalPrice!.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // Disponibilité
                  TableRow(
                    children: _products.map((product) {
                      final inStock = product.isInStock && product.stock > 0;
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text('Stock',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  inStock
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  size: 14,
                                  color: inStock ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  inStock
                                      ? '${product.stock} dispo'
                                      : 'Rupture',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: inStock ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // Specs détaillées
                  for (final label in specLabels)
                    TableRow(
                      decoration: BoxDecoration(
                          color: specLabels.indexOf(label).isEven
                              ? Colors.grey.shade50
                              : Colors.white),
                      children: _products.map((product) {
                        final value = _specValueFor(product, label);
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                value ?? '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: value != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: value != null
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section analyse IA ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AiAnalysisSection(
                productCount: _products.length,
                analysis: _aiAnalysis,
                isAnalyzing: _isAnalyzing,
                error: _analysisError,
                onRequest: _requestAnalysis,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Section analyse IA — affichée sous le tableau de comparaison.
/// 3 états : invitation à analyser, chargement, résultat (ou erreur).
class _AiAnalysisSection extends StatelessWidget {
  final int productCount;
  final String? analysis;
  final bool isAnalyzing;
  final String? error;
  final VoidCallback onRequest;

  const _AiAnalysisSection({
    required this.productCount,
    required this.analysis,
    required this.isAnalyzing,
    required this.error,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryViolet.withOpacity(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 18, color: AppTheme.primaryViolet),
                const SizedBox(width: 8),
                const Text(
                  'Analyse IA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Chargement
    if (isAnalyzing) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            'Gemini analyse les $productCount produits…',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    // Erreur
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    // Résultat affiché
    if (analysis != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MarkdownText(analysis!),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Relancer l\'analyse'),
          ),
        ],
      );
    }

    // Invitation initiale
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Laisse Gemini comparer ces $productCount produits pour toi : '
          'points forts, différences clés, et quel profil devrait choisir quoi.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onRequest,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Analyser avec l\'IA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryViolet,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Rendu minimal du Markdown retourné par Gemini.
/// Gère **gras**, les titres ## et les listes à puces - sans dépendance externe.
class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText(this.text);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Titre ## ou ###
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Text(
            line.substring(4),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(3),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.primaryViolet,
            ),
          ),
        ));
        continue;
      }

      // Puce - ou *
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 6),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _inlineText(line.substring(2))),
            ],
          ),
        ));
        continue;
      }

      // Ligne normale
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: _inlineText(line),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Rendu inline : gère **gras** dans le texte.
  Widget _inlineText(String line) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final match in boldRegex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
        children: spans,
      ),
    );
  }
}