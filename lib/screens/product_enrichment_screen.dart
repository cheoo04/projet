import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';
import '../services/product_service.dart';

/// Écran pour enrichir un produit avec les signaux de confiance
/// Permet de modifier: prix original, livraison, garantie, retour, authenticité,
/// badges, highlights, description courte, mise en avant
class ProductEnrichmentScreen extends StatefulWidget {
  final Product product;

  const ProductEnrichmentScreen({required this.product, super.key});

  @override
  State<ProductEnrichmentScreen> createState() => _ProductEnrichmentScreenState();
}

class _ProductEnrichmentScreenState extends State<ProductEnrichmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();
  bool _isSaving = false;

  // Controllers pour les champs texte
  late TextEditingController _originalPriceC;
  late TextEditingController _shortDescC;
  late TextEditingController _highlightC;
  
  // Livraison
  late bool _freeShipping;
  late int _shippingMinDays;
  late int _shippingMaxDays;
  late bool _trackingAvailable;
  late TextEditingController _shippingCostC;
  late List<String> _shippingCities;
  
  // Garantie
  late int _warrantyMonths;
  late String _warrantyType;
  late TextEditingController _warrantyCoverageC;
  
  // Retour
  late int _returnDays;
  late bool _freeReturn;
  late TextEditingController _returnConditionsC;
  
  // Authenticité
  late bool _isVerified;
  late TextEditingController _authenticitySourceC;
  
  // Badges
  late bool _isNew;
  late bool _isBestseller;
  late bool _isFeatured;
  
  // Highlights
  late List<String> _highlights;

  // Liste des villes disponibles
  static const List<String> _availableCities = [
    'Abidjan',
    'Bouaké',
    'Yamoussoukro',
    'Daloa',
    'Korhogo',
    'San-Pédro',
    'Man',
    'Divo',
    'Gagnoa',
    'Toutes les villes',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    
    // Prix original
    _originalPriceC = TextEditingController(
      text: p.originalPrice?.toStringAsFixed(0) ?? '',
    );
    
    // Description courte
    _shortDescC = TextEditingController(text: p.shortDescription ?? '');
    
    // Controller pour ajouter des highlights
    _highlightC = TextEditingController();
    _highlights = List<String>.from(p.highlights);
    
    // Livraison
    _freeShipping = p.shipping.isFree;
    _shippingMinDays = p.shipping.minDays;
    _shippingMaxDays = p.shipping.maxDays;
    _trackingAvailable = p.shipping.trackingAvailable;
    _shippingCostC = TextEditingController(
      text: p.shipping.cost?.toString() ?? '',
    );
    _shippingCities = List<String>.from(p.shipping.cities);
    
    // Garantie
    _warrantyMonths = p.warranty.months;
    _warrantyType = p.warranty.type;
    _warrantyCoverageC = TextEditingController(text: p.warranty.coverage);
    
    // Retour
    _returnDays = p.returnPolicy.days;
    _freeReturn = p.returnPolicy.freeReturn;
    _returnConditionsC = TextEditingController(text: p.returnPolicy.conditions);
    
    // Authenticité
    _isVerified = p.authenticity.verified;
    _authenticitySourceC = TextEditingController(text: p.authenticity.source);
    
    // Badges
    _isNew = p.badges.any((b) => b.type == 'NEW');
    _isBestseller = p.badges.any((b) => b.type == 'BESTSELLER');
    _isFeatured = p.isFeatured;
  }

  @override
  void dispose() {
    _originalPriceC.dispose();
    _shortDescC.dispose();
    _highlightC.dispose();
    _shippingCostC.dispose();
    _warrantyCoverageC.dispose();
    _returnConditionsC.dispose();
    _authenticitySourceC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProductHeader(),
            const SizedBox(height: 24),
            _buildPricingSection(),
            const SizedBox(height: 24),
            _buildShippingSection(),
            const SizedBox(height: 24),
            _buildWarrantySection(),
            const SizedBox(height: 24),
            _buildReturnSection(),
            const SizedBox(height: 24),
            _buildAuthenticitySection(),
            const SizedBox(height: 24),
            _buildBadgesSection(),
            const SizedBox(height: 24),
            _buildHighlightsSection(),
            const SizedBox(height: 24),
            _buildShortDescriptionSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Enrichir le produit',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Réinitialiser'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProductHeader() {
    final p = widget.product;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image produit
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.imageUrls.isNotEmpty
                ? Image.network(
                    p.imageUrls.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 16),
          // Infos produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.brand,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${p.price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF9B6DB8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400], size: 32),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ==================== SECTION PRIX ====================
  Widget _buildPricingSection() {
    return _buildSectionCard(
      title: 'Prix et promotion',
      icon: Icons.sell_outlined,
      iconColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _originalPriceC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Prix original (avant promo)',
              hintText: 'Ex: 150000',
              suffixText: 'FCFA',
              helperText: _originalPriceC.text.isNotEmpty
                  ? 'Réduction: ${_calculateDiscount()}%'
                  : 'Laissez vide si pas de promotion',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.money_off),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_originalPriceC.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Économie client: ${_calculateSavings()} FCFA',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _calculateDiscount() {
    final original = double.tryParse(_originalPriceC.text) ?? 0;
    if (original <= widget.product.price) return '0';
    return (((original - widget.product.price) / original) * 100).round().toString();
  }

  String _calculateSavings() {
    final original = double.tryParse(_originalPriceC.text) ?? 0;
    if (original <= widget.product.price) return '0';
    return (original - widget.product.price).toStringAsFixed(0);
  }

  // ==================== SECTION LIVRAISON ====================
  Widget _buildShippingSection() {
    return _buildSectionCard(
      title: 'Livraison',
      icon: Icons.local_shipping_outlined,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Livraison gratuite
          SwitchListTile(
            value: _freeShipping,
            onChanged: (v) => setState(() => _freeShipping = v),
            title: const Text('Livraison gratuite'),
            subtitle: Text(
              _freeShipping
                  ? 'Les clients ne paieront pas de frais de livraison'
                  : 'Des frais de livraison seront appliqués',
            ),
            secondary: Icon(
              _freeShipping ? Icons.check_circle : Icons.payments_outlined,
              color: _freeShipping ? Colors.green : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (!_freeShipping) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _shippingCostC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Frais de livraison',
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Délais
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Délai minimum',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _shippingMinDays,
                      items: List.generate(14, (i) => i + 1).map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text('$d jour${d > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() {
                        _shippingMinDays = v ?? 1;
                        if (_shippingMaxDays < _shippingMinDays) {
                          _shippingMaxDays = _shippingMinDays;
                        }
                      }),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Délai maximum',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _shippingMaxDays,
                      items: List.generate(14, (i) => i + 1)
                          .where((d) => d >= _shippingMinDays)
                          .map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text('$d jour${d > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _shippingMaxDays = v ?? 7),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Suivi
          SwitchListTile(
            value: _trackingAvailable,
            onChanged: (v) => setState(() => _trackingAvailable = v),
            title: const Text('Suivi de livraison'),
            subtitle: const Text('Les clients peuvent suivre leur colis'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          // Villes
          const Text(
            'Villes de livraison',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCities.map((city) {
              final isSelected = _shippingCities.contains(city) ||
                  (_shippingCities.contains('all') && city == 'Toutes les villes');
              return FilterChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (city == 'Toutes les villes') {
                      if (selected) {
                        _shippingCities = ['all'];
                      } else {
                        _shippingCities = [];
                      }
                    } else {
                      _shippingCities.remove('all');
                      if (selected) {
                        _shippingCities.add(city);
                      } else {
                        _shippingCities.remove(city);
                      }
                    }
                  });
                },
                selectedColor: const Color(0xFF9B6DB8).withOpacity(0.2),
                checkmarkColor: const Color(0xFF9B6DB8),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF9B6DB8) : Colors.grey[700],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION GARANTIE ====================
  Widget _buildWarrantySection() {
    return _buildSectionCard(
      title: 'Garantie',
      icon: Icons.verified_user_outlined,
      iconColor: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durée
          DropdownButtonFormField<int>(
            value: _warrantyMonths,
            items: [0, 3, 6, 12, 24, 36].map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text(m == 0 ? 'Pas de garantie' : '$m mois'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _warrantyMonths = v ?? 12),
            decoration: InputDecoration(
              labelText: 'Durée de garantie',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.schedule),
            ),
          ),
          if (_warrantyMonths > 0) ...[
            const SizedBox(height: 16),
            // Type
            DropdownButtonFormField<String>(
              value: _warrantyType,
              items: const [
                DropdownMenuItem(value: 'constructeur', child: Text('Garantie constructeur')),
                DropdownMenuItem(value: 'revendeur', child: Text('Garantie revendeur')),
              ],
              onChanged: (v) => setState(() => _warrantyType = v ?? 'revendeur'),
              decoration: InputDecoration(
                labelText: 'Type de garantie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Couverture
            TextFormField(
              controller: _warrantyCoverageC,
              decoration: InputDecoration(
                labelText: 'Couverture',
                hintText: 'Ex: Défauts de fabrication, panne',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== SECTION RETOUR ====================
  Widget _buildReturnSection() {
    return _buildSectionCard(
      title: 'Politique de retour',
      icon: Icons.assignment_return_outlined,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jours
          DropdownButtonFormField<int>(
            value: _returnDays,
            items: [0, 3, 7, 14, 30].map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(d == 0 ? 'Pas de retour' : '$d jours'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _returnDays = v ?? 7),
            decoration: InputDecoration(
              labelText: 'Délai de retour',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.schedule),
            ),
          ),
          if (_returnDays > 0) ...[
            const SizedBox(height: 16),
            // Gratuit
            SwitchListTile(
              value: _freeReturn,
              onChanged: (v) => setState(() => _freeReturn = v),
              title: const Text('Retour gratuit'),
              subtitle: Text(
                _freeReturn
                    ? 'Aucun frais pour le retour'
                    : 'Le client paie les frais de retour',
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            // Conditions
            TextFormField(
              controller: _returnConditionsC,
              decoration: InputDecoration(
                labelText: 'Conditions de retour',
                hintText: 'Ex: Produit non ouvert, emballage intact',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.rule),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ==================== SECTION AUTHENTICITÉ ====================
  Widget _buildAuthenticitySection() {
    return _buildSectionCard(
      title: 'Authenticité',
      icon: Icons.verified_outlined,
      iconColor: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: _isVerified,
            onChanged: (v) => setState(() => _isVerified = v),
            title: const Text('Produit vérifié'),
            subtitle: const Text(
              'Ce produit est authentique et vérifié',
            ),
            secondary: Icon(
              _isVerified ? Icons.verified : Icons.help_outline,
              color: _isVerified ? Colors.green : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isVerified) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _authenticitySourceC,
              decoration: InputDecoration(
                labelText: 'Source / Distributeur',
                hintText: 'Ex: Distributeur officiel Apple',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.store),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== SECTION BADGES ====================
  Widget _buildBadgesSection() {
    return _buildSectionCard(
      title: 'Badges et mise en avant',
      icon: Icons.star_outline,
      iconColor: Colors.amber,
      child: Column(
        children: [
          // Nouveau
          CheckboxListTile(
            value: _isNew,
            onChanged: (v) => setState(() => _isNew = v ?? false),
            title: const Text('Nouveau produit'),
            subtitle: const Text('Affiche un badge "Nouveau"'),
            secondary: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Nouveau',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          // Best-seller
          CheckboxListTile(
            value: _isBestseller,
            onChanged: (v) => setState(() => _isBestseller = v ?? false),
            title: const Text('Best-seller'),
            subtitle: const Text('Affiche un badge "Best-seller"'),
            secondary: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Best-seller',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          // Mise en avant
          SwitchListTile(
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            title: const Text('Produit mis en avant'),
            subtitle: const Text(
              'Apparaît en priorité sur la page d\'accueil',
            ),
            secondary: Icon(
              Icons.push_pin,
              color: _isFeatured ? const Color(0xFF9B6DB8) : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ==================== SECTION HIGHLIGHTS ====================
  Widget _buildHighlightsSection() {
    return _buildSectionCard(
      title: 'Points forts',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF9B6DB8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajoutez les points forts du produit (3-5 recommandés)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // Liste des highlights
          if (_highlights.isNotEmpty) ...[
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _highlights.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _highlights.removeAt(oldIndex);
                  _highlights.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(_highlights[index]),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Color(0xFF9B6DB8)),
                    title: Text(_highlights[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() => _highlights.removeAt(index));
                      },
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 12, right: 4),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          // Ajouter un highlight
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _highlightC,
                  decoration: InputDecoration(
                    hintText: 'Ex: Autonomie exceptionnelle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addHighlight(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addHighlight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B6DB8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addHighlight() {
    final text = _highlightC.text.trim();
    if (text.isNotEmpty && !_highlights.contains(text)) {
      setState(() {
        _highlights.add(text);
        _highlightC.clear();
      });
    }
  }

  // ==================== SECTION DESCRIPTION COURTE ====================
  Widget _buildShortDescriptionSection() {
    return _buildSectionCard(
      title: 'Description courte',
      icon: Icons.short_text,
      iconColor: Colors.indigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _shortDescC,
            decoration: InputDecoration(
              hintText: 'Résumé accrocheur du produit (120 car. max)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '${_shortDescC.text.length}/120',
            ),
            maxLines: 3,
            maxLength: 120,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette description apparaît dans les listes de produits',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ==================== BOUTON SAUVEGARDER ====================
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9B6DB8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Enregistrer les modifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser ?'),
        content: const Text(
          'Voulez-vous remettre tous les champs à leurs valeurs par défaut ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _originalPriceC.clear();
                _shortDescC.clear();
                _highlights.clear();
                _freeShipping = false;
                _shippingMinDays = 3;
                _shippingMaxDays = 7;
                _trackingAvailable = true;
                _shippingCostC.clear();
                _shippingCities = ['Abidjan'];
                _warrantyMonths = 12;
                _warrantyType = 'revendeur';
                _warrantyCoverageC.text = 'Défauts de fabrication';
                _returnDays = 7;
                _freeReturn = true;
                _returnConditionsC.text = 'Produit non ouvert';
                _isVerified = false;
                _authenticitySourceC.clear();
                _isNew = false;
                _isBestseller = false;
                _isFeatured = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      // Construire les objets de signaux de confiance
      final shipping = ShippingInfo(
        isFree: _freeShipping,
        minDays: _shippingMinDays,
        maxDays: _shippingMaxDays,
        cities: _shippingCities.isEmpty ? ['Abidjan'] : _shippingCities,
        trackingAvailable: _trackingAvailable,
        cost: _freeShipping ? null : int.tryParse(_shippingCostC.text),
      );

      final warranty = WarrantyInfo(
        months: _warrantyMonths,
        type: _warrantyType,
        coverage: _warrantyCoverageC.text.isEmpty
            ? 'Défauts de fabrication'
            : _warrantyCoverageC.text,
      );

      final returnPolicy = ReturnPolicy(
        days: _returnDays,
        conditions: _returnConditionsC.text.isEmpty
            ? 'Produit non ouvert'
            : _returnConditionsC.text,
        freeReturn: _freeReturn,
      );

      final authenticity = AuthenticityInfo(
        verified: _isVerified,
        source: _authenticitySourceC.text,
      );

      // Construire les badges
      final badges = <ProductBadge>[];
      if (_isNew) badges.add(ProductBadge.newProduct);
      if (_isBestseller) badges.add(ProductBadge.bestSeller);
      if (_isVerified) badges.add(ProductBadge.verified);

      // Parser le prix original
      final originalPrice = _originalPriceC.text.isNotEmpty
          ? double.tryParse(_originalPriceC.text)
          : null;

      // Créer le produit enrichi avec copyWith
      final enrichedProduct = widget.product.copyWith(
        originalPrice: originalPrice,
        shipping: shipping,
        warranty: warranty,
        returnPolicy: returnPolicy,
        authenticity: authenticity,
        badges: badges,
        highlights: _highlights,
        shortDescription: _shortDescC.text.isEmpty ? null : _shortDescC.text,
        isFeatured: _isFeatured,
      );

      // Sauvegarder
      await _service.update(enrichedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Produit enrichi avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, enrichedProduct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
