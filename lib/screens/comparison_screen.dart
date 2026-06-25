import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/ai_chat_service.dart';
import '../services/product_service.dart';
import '../web_config/navigation_helper.dart';
import '../widgets/responsive_scaffold.dart';

// ── Modèles pour l'analyse IA structurée ──────────────────────────────────

class _ProductStrength {
  final String name;
  final List<String> points;
  _ProductStrength({required this.name, required this.points});

  factory _ProductStrength.fromJson(Map<String, dynamic> j) =>
      _ProductStrength(
        name: j['name'] as String? ?? '',
        points: List<String>.from(j['points'] as List? ?? []),
      );
}

class _VerdictItem {
  final String profile;
  final String winner;
  final String reason;
  _VerdictItem({required this.profile, required this.winner, required this.reason});

  factory _VerdictItem.fromJson(Map<String, dynamic> j) => _VerdictItem(
        profile: j['profile'] as String? ?? '',
        winner: j['winner'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
      );
}

class _AiAnalysis {
  final List<_ProductStrength> strengths;
  final List<_VerdictItem> verdict;
  final String summary;

  _AiAnalysis({required this.strengths, required this.verdict, required this.summary});

  factory _AiAnalysis.fromJson(Map<String, dynamic> j) => _AiAnalysis(
        strengths: (j['strengths'] as List? ?? [])
            .map((e) => _ProductStrength.fromJson(e as Map<String, dynamic>))
            .toList(),
        verdict: (j['verdict'] as List? ?? [])
            .map((e) => _VerdictItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: j['summary'] as String? ?? '',
      );

  static _AiAnalysis? tryParse(String raw) {
    try {
      // Nettoyer les éventuels backticks markdown autour du JSON
      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      return _AiAnalysis.fromJson(jsonDecode(cleaned) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

// ── Écran principal ────────────────────────────────────────────────────────

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
  _AiAnalysis? _aiAnalysis;
  String? _aiRawFallback; // si JSON non parsable, affiche le texte brut
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
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _aiAnalysis = null;
      _aiRawFallback = null;
    });
    try {
      final raw = await _aiService.compareProducts(_products.map((p) => p.id).toList());
      if (!mounted) return;
      final parsed = _AiAnalysis.tryParse(raw);
      setState(() {
        if (parsed != null) {
          _aiAnalysis = parsed;
        } else {
          _aiRawFallback = raw; // fallback texte brut si JSON invalide
        }
      });
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

  int? _winnerIndex(List<double?> values, {bool lowerIsBetter = false}) {
    if (values.any((v) => v == null)) return null;
    final nums = values.cast<double>();
    final best = lowerIsBetter
        ? nums.reduce((a, b) => a < b ? a : b)
        : nums.reduce((a, b) => a > b ? a : b);
    if (nums.where((n) => n == best).length > 1) return null;
    return nums.indexOf(best);
  }

  int? _winnerIndexForSpec(String label, {bool lowerIsBetter = false}) {
    final nums = _products.map((p) {
      final v = _specValueFor(p, label);
      if (v == null) return null;
      return double.tryParse(v.replaceAll(RegExp(r'[^\d.]'), ''));
    }).toList();
    return _winnerIndex(nums, lowerIsBetter: lowerIsBetter);
  }

  int? _winnerIndexForPrice() {
    return _winnerIndex(_products.map((p) => p.price).toList(), lowerIsBetter: true);
  }

  static const _higherIsBetter = {
    'ram', 'mémoire ram', 'batterie', 'battery', 'stockage', 'storage',
    'rom', 'résolution', 'resolution', 'appareil photo', 'camera', 'zoom',
  };
  static const _lowerIsBetter = {'épaisseur', 'poids', 'weight'};

  void _removeProduct(Product product) {
    context.read<ComparisonProvider>().remove(product.id);
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      _aiAnalysis = null;
      _aiRawFallback = null;
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
            // ── Tableau ──────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(170),
                border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.grey.shade200)),
                children: [
                  // En-tête produits
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade50),
                    children: _products.map((p) => _headerCell(p)).toList(),
                  ),
                  // Prix
                  _specRow(
                    label: 'Prix',
                    cells: _products.map((p) {
                      final hasPromo = p.originalPrice != null && p.originalPrice! > p.price;
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${p.price.toStringAsFixed(0)} FCFA',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 15, color: AppTheme.primaryViolet)),
                        if (hasPromo)
                          Text('${p.originalPrice!.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey)),
                      ]);
                    }).toList(),
                    winnerIndex: _winnerIndexForPrice(),
                    winnerColor: const Color(0xFFFFF3E0),
                    winnerBorder: const Color(0xFFFF9800),
                    winnerLabel: 'Prix le plus bas',
                    winnerLabelColor: const Color(0xFFE65100),
                    isEven: false,
                  ),
                  // Stock
                  _specRow(
                    label: 'Disponibilité',
                    cells: _products.map((p) {
                      final ok = p.isInStock && p.stock > 0;
                      return Row(mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, children: [
                        Icon(ok ? Icons.check_circle : Icons.cancel,
                            size: 16, color: ok ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(ok ? '${p.stock} en stock' : 'Rupture',
                            style: TextStyle(fontSize: 12,
                                color: ok ? Colors.green.shade700 : Colors.red,
                                fontWeight: FontWeight.w500)),
                      ]);
                    }).toList(),
                    winnerIndex: null,
                    isEven: true,
                  ),
                  // Specs détaillées
                  for (int i = 0; i < specLabels.length; i++)
                    _specRow(
                      label: specLabels[i],
                      cells: _products.map((p) {
                        final val = _specValueFor(p, specLabels[i]);
                        return Text(val ?? '—', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13,
                                fontWeight: val != null ? FontWeight.w500 : FontWeight.normal,
                                color: val != null ? Colors.black87 : Colors.grey.shade400));
                      }).toList(),
                      winnerIndex: _lowerIsBetter.contains(specLabels[i].toLowerCase())
                          ? _winnerIndexForSpec(specLabels[i], lowerIsBetter: true)
                          : _higherIsBetter.contains(specLabels[i].toLowerCase())
                              ? _winnerIndexForSpec(specLabels[i])
                              : null,
                      isEven: (i + 2).isEven,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Analyse IA ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AiSection(
                productCount: _products.length,
                analysis: _aiAnalysis,
                rawFallback: _aiRawFallback,
                isAnalyzing: _isAnalyzing,
                error: _analysisError,
                onRequest: _requestAnalysis,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── En-tête produit ──────────────────────────────────────────────────────
  Widget _headerCell(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(children: [
        Align(alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => _removeProduct(p),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          )),
        if (p.imageUrls.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(p.imageUrls.first,
                height: 90, fit: BoxFit.contain)),
        const SizedBox(height: 8),
        Text(p.name, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: Text(p.brand,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ),
      ]),
    );
  }

  // ── Ligne de spec avec highlight ─────────────────────────────────────────
  TableRow _specRow({
    required String label,
    required List<Widget> cells,
    required int? winnerIndex,
    Color winnerColor = const Color(0xFFE8F5E9),
    Color winnerBorder = const Color(0xFF4CAF50),
    String winnerLabel = 'Meilleur',
    Color winnerLabelColor = const Color(0xFF2E7D32),
    required bool isEven,
  }) {
    return TableRow(
      children: List.generate(_products.length, (i) {
        final isWinner = winnerIndex == i;
        return Container(
          color: isWinner ? winnerColor : (isEven ? Colors.grey.shade50 : Colors.white),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Badge "Meilleur" en haut de la cellule gagnante
            if (isWinner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: winnerBorder,
                child: Text(winnerLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            // Label de la spec
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: isWinner ? winnerLabelColor : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
            ),
            // Valeur
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
              child: cells[i],
            ),
          ]),
        );
      }),
    );
  }
}

// ── Section Analyse IA ─────────────────────────────────────────────────────

class _AiSection extends StatelessWidget {
  final int productCount;
  final _AiAnalysis? analysis;
  final String? rawFallback;
  final bool isAnalyzing;
  final String? error;
  final VoidCallback onRequest;

  const _AiSection({
    required this.productCount,
    required this.analysis,
    required this.rawFallback,
    required this.isAnalyzing,
    required this.error,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Titre section
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.primaryViolet, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('Analyse de l\'assistant',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        _buildBody(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isAnalyzing) return _loadingCard();
    if (error != null) return _errorCard();
    if (analysis != null) return _analysisCards(context);
    if (rawFallback != null) return _fallbackCard();
    return _inviteCard();
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppTheme.primaryViolet.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.15))),
      child: Column(children: [
        CircularProgressIndicator(color: AppTheme.primaryViolet, strokeWidth: 2.5),
        const SizedBox(height: 16),
        Text('Gemini analyse les $productCount produits…',
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text('Ça prend 5 à 10 secondes',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ]),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRequest,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Réessayer'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
        ),
      ]),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryViolet.withOpacity(0.08),
                   AppTheme.primaryViolet.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Tu hésites entre ces $productCount produits ?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Notre assistant va analyser leurs specs, comparer ce qui compte vraiment, '
            'et te dire lequel choisir selon ton profil — en quelques secondes.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: onRequest,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Analyser avec l\'IA'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ]),
    );
  }

  Widget _fallbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(rawFallback!, style: const TextStyle(fontSize: 13, height: 1.6)),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: onRequest,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Relancer')),
      ]),
    );
  }

  Widget _analysisCards(BuildContext context) {
    final a = analysis!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Points forts ────────────────────────────────────────────
      if (a.strengths.isNotEmpty) ...[
        _sectionTitle('Points forts', Icons.star_outline, Colors.amber.shade700),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: a.strengths.map((s) => Expanded(
            child: _strengthCard(s),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],

      // ── Verdict ──────────────────────────────────────────────────
      if (a.verdict.isNotEmpty) ...[
        _sectionTitle('Quel téléphone pour toi ?', Icons.emoji_events_outlined,
            AppTheme.primaryViolet),
        const SizedBox(height: 10),
        ...a.verdict.map((v) => _verdictRow(v)),
        const SizedBox(height: 24),
      ],

      // ── Résumé ────────────────────────────────────────────────────
      if (a.summary.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text('En résumé',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 10),
            Text(a.summary,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // Bouton relancer
      TextButton.icon(
        onPressed: onRequest,
        icon: Icon(Icons.refresh, size: 15, color: Colors.grey.shade500),
        label: Text('Relancer l\'analyse',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ),
    ]);
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _strengthCard(_ProductStrength s) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                color: Colors.amber.shade900)),
        const SizedBox(height: 8),
        ...s.points.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 6),
              child: Container(width: 5, height: 5,
                  decoration: BoxDecoration(
                      color: Colors.amber.shade600, shape: BoxShape.circle)),
            ),
            Expanded(child: Text(p,
                style: TextStyle(fontSize: 12, height: 1.4,
                    color: Colors.amber.shade900))),
          ]),
        )),
      ]),
    );
  }

  Widget _verdictRow(_VerdictItem v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppTheme.primaryViolet,
              borderRadius: BorderRadius.circular(8)),
          child: Text(v.winner,
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.profile,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(v.reason,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
        ])),
      ]),
    );
  }
}