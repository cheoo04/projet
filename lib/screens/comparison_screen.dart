import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/ai_chat_service.dart';
import '../services/product_service.dart';
import '../web_config/navigation_helper.dart';
import '../widgets/responsive_scaffold.dart';

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
    if (mounted) setState(() { _products = products; _isLoading = false; });
  }

  Future<void> _requestAnalysis() async {
    if (_products.length < 2) return;
    setState(() { _isAnalyzing = true; _analysisError = null; _aiAnalysis = null; });
    try {
      final analysis = await _aiService.compareProducts(_products.map((p) => p.id).toList());
      if (mounted) setState(() => _aiAnalysis = analysis);
    } catch (e) {
      if (mounted) setState(() => _analysisError = e.toString().contains('resource-exhausted')
          ? 'Service temporairement occupé. Réessayez dans quelques instants.'
          : 'Impossible de générer l\'analyse. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  List<String> get _allSpecLabels {
    final labels = <String>[];
    for (final p in _products) {
      for (final s in p.detailedSpecs) {
        if (!labels.contains(s.label)) labels.add(s.label);
      }
    }
    return labels;
  }

  String? _specValueFor(Product p, String label) {
    for (final s in p.detailedSpecs) { if (s.label == label) return s.value; }
    return null;
  }

  /// Retourne l'index du produit "gagnant" pour une ligne de spec donnée.
  /// Logique : on tente de parser les valeurs numériques.
  /// Pour batterie/RAM/stockage/soldCount → plus grand = meilleur.
  /// Pour prix → plus petit = meilleur (géré séparément).
  /// Retourne null si pas de comparaison possible (valeurs non numériques ou égales).
  int? _winnerIndexForSpec(String label, {bool lowerIsBetter = false}) {
    final values = _products.map((p) => _specValueFor(p, label)).toList();
    final nums = values.map((v) {
      if (v == null) return null;
      final cleaned = v.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }).toList();

    if (nums.any((n) => n == null)) return null;
    final nonNull = nums.cast<double>();
    final best = lowerIsBetter ? nonNull.reduce((a, b) => a < b ? a : b)
                               : nonNull.reduce((a, b) => a > b ? a : b);
    final winners = nonNull.where((n) => n == best).length;
    if (winners > 1) return null; // ex-æquo → pas de highlight
    return nonNull.indexOf(best);
  }

  int? _winnerIndexForPrice() {
    if (_products.isEmpty) return null;
    final prices = _products.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final winners = prices.where((p) => p == minPrice).length;
    if (winners > 1) return null;
    return prices.indexOf(minPrice);
  }

  /// Labels où "plus grand = meilleur"
  static const _higherIsBetter = {
    'ram', 'mémoire ram', 'batterie', 'battery', 'stockage', 'storage',
    'rom', 'écran', 'screen', 'display', 'résolution', 'resolution',
    'appareil photo', 'camera', 'zoom',
  };

  /// Labels où "plus petit = meilleur"
  static const _lowerIsBetter = {'épaisseur', 'poids', 'weight'};

  void _removeProduct(Product product) {
    context.read<ComparisonProvider>().remove(product.id);
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      _aiAnalysis = null;
      _analysisError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            onPressed: () { context.read<ComparisonProvider>().clear(); Navigator.pop(context); },
            child: const Text('Tout effacer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Légende highlight ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _legendDot(Colors.green.shade100, Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text('Meilleur sur ce critère',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  _legendDot(Colors.orange.shade50, Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text('Prix le plus bas',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),

            // ── Tableau ────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(160),
                border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.grey.shade300)),
                children: [
                  // En-tête : photo + nom + bouton retirer
                  TableRow(
                    children: _products.map((p) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(children: [
                        Align(alignment: Alignment.topRight,
                          child: IconButton(icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeProduct(p))),
                        if (p.imageUrls.isNotEmpty)
                          Image.network(p.imageUrls.first, height: 80, fit: BoxFit.contain),
                        const SizedBox(height: 6),
                        Text(p.name, textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(p.brand, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ]),
                    )).toList(),
                  ),

                  // Prix
                  _buildSpecRow(
                    values: _products.map((p) {
                      final hasPromo = p.originalPrice != null && p.originalPrice! > p.price;
                      return Column(children: [
                        Text('Prix', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('${p.price.toStringAsFixed(0)} FCFA',
                            style: TextStyle(color: AppTheme.primaryViolet,
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        if (hasPromo)
                          Text('${p.originalPrice!.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 11,
                                  decoration: TextDecoration.lineThrough, color: Colors.grey)),
                      ]);
                    }).toList(),
                    winnerIndex: _winnerIndexForPrice(),
                    highlightColor: Colors.orange.shade50,
                    highlightBorder: Colors.orange.shade300,
                    isEven: false,
                  ),

                  // Stock
                  _buildSpecRow(
                    values: _products.map((p) {
                      final ok = p.isInStock && p.stock > 0;
                      return Column(children: [
                        Text('Stock', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                              size: 14, color: ok ? Colors.green : Colors.red),
                          const SizedBox(width: 4),
                          Text(ok ? '${p.stock} dispo' : 'Rupture',
                              style: TextStyle(fontSize: 12,
                                  color: ok ? Colors.green : Colors.red)),
                        ]),
                      ]);
                    }).toList(),
                    winnerIndex: null,
                    isEven: true,
                  ),

                  // Specs détaillées avec highlight automatique
                  for (int i = 0; i < specLabels.length; i++) ...[
                    _buildSpecRow(
                      values: _products.map((p) {
                        final val = _specValueFor(p, specLabels[i]);
                        return Column(children: [
                          Text(specLabels[i],
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center),
                          Text(val ?? '—', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13,
                                  fontWeight: val != null ? FontWeight.w500 : FontWeight.normal,
                                  color: val != null ? Colors.black87 : Colors.grey.shade400)),
                        ]);
                      }).toList(),
                      winnerIndex: _lowerIsBetter.contains(specLabels[i].toLowerCase())
                          ? _winnerIndexForSpec(specLabels[i], lowerIsBetter: true)
                          : _higherIsBetter.contains(specLabels[i].toLowerCase())
                              ? _winnerIndexForSpec(specLabels[i])
                              : null,
                      isEven: (i + 2).isEven,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Analyse IA ─────────────────────────────────────────────
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

  /// Construit une TableRow avec highlight conditionnel sur le produit gagnant.
  TableRow _buildSpecRow({
    required List<Widget> values,
    required int? winnerIndex,
    Color? highlightColor,
    Color? highlightBorder,
    required bool isEven,
  }) {
    return TableRow(
      children: List.generate(_products.length, (i) {
        final isWinner = winnerIndex == i;
        return Container(
          margin: isWinner ? const EdgeInsets.all(2) : EdgeInsets.zero,
          padding: const EdgeInsets.all(8),
          decoration: isWinner
              ? BoxDecoration(
                  color: highlightColor ?? Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: highlightBorder ?? Colors.green.shade400, width: 1.5),
                )
              : BoxDecoration(color: isEven ? Colors.grey.shade50 : Colors.white),
          child: Stack(
            alignment: Alignment.center,
            children: [
              values[i],
              if (isWinner)
                Positioned(
                  top: 0, right: 0,
                  child: Icon(Icons.star_rounded,
                      size: 12, color: highlightBorder ?? Colors.green.shade600),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _legendDot(Color bg, Color border) => Container(
    width: 14, height: 14,
    decoration: BoxDecoration(
      color: bg, shape: BoxShape.circle,
      border: Border.all(color: border, width: 1.5),
    ),
  );
}

// ── Section analyse IA ─────────────────────────────────────────────────────

class _AiAnalysisSection extends StatelessWidget {
  final int productCount;
  final String? analysis;
  final bool isAnalyzing;
  final String? error;
  final VoidCallback onRequest;

  const _AiAnalysisSection({
    required this.productCount, required this.analysis,
    required this.isAnalyzing, required this.error, required this.onRequest,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(children: [
              Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              const Text('Analyse IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isAnalyzing) {
      return Column(children: [
        const SizedBox(height: 8),
        const CircularProgressIndicator(strokeWidth: 2),
        const SizedBox(height: 12),
        Text('Gemini analyse les $productCount produits…',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
      ]);
    }
    if (error != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onRequest,
            icon: const Icon(Icons.refresh, size: 16), label: const Text('Réessayer')),
      ]);
    }
    if (analysis != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MarkdownText(analysis!),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: onRequest,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Relancer l\'analyse')),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Laisse Gemini comparer ces $productCount produits pour toi : '
          'points forts, différences clés, et quel profil devrait choisir quoi.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      const SizedBox(height: 14),
      ElevatedButton.icon(
        onPressed: onRequest,
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: const Text('Analyser avec l\'IA'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white),
      ),
    ]);
  }
}

// ── Rendu Markdown minimal ─────────────────────────────────────────────────

class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText(this.text);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) { widgets.add(const SizedBox(height: 6)); continue; }
      if (line.startsWith('### ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(line.substring(4),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(line.substring(3),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                    color: AppTheme.primaryViolet))));
        continue;
      }
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 5, right: 6),
                  child: Container(width: 5, height: 5,
                      decoration: BoxDecoration(color: AppTheme.primaryViolet,
                          shape: BoxShape.circle))),
              Expanded(child: _inlineText(line.substring(2))),
            ])));
        continue;
      }
      widgets.add(Padding(padding: const EdgeInsets.symmetric(vertical: 1),
          child: _inlineText(line)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _inlineText(String line) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in boldRegex.allMatches(line)) {
      if (match.start > last) spans.add(TextSpan(text: line.substring(last, match.start)));
      spans.add(TextSpan(text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold)));
      last = match.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return RichText(text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
        children: spans));
  }
}