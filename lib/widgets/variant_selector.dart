import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product_extensions.dart';

/// Sélecteur de variantes de produit (couleur, stockage, taille)
class VariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onVariantSelected;
  final String variantType; // "color" | "storage" | "size"

  const VariantSelector({
    Key? key,
    required this.variants,
    required this.selectedVariant,
    required this.onVariantSelected,
    required this.variantType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrer les variantes par type
    final filteredVariants = variants.where((v) => v.type == variantType).toList();
    
    if (filteredVariants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTitle(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: filteredVariants.map((variant) {
            final isSelected = selectedVariant?.id == variant.id;
            final isAvailable = variant.stock > 0;
            
            return variantType == 'color'
                ? _buildColorChip(context, variant, isSelected, isAvailable)
                : _buildTextChip(context, variant, isSelected, isAvailable);
          }).toList(),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (variantType) {
      case 'color':
        return 'Couleur';
      case 'storage':
        return 'Stockage';
      case 'size':
        return 'Taille';
      default:
        return 'Options';
    }
  }

  /// Chip pour les couleurs (avec cercle de couleur)
  Widget _buildColorChip(
    BuildContext context,
    ProductVariant variant,
    bool isSelected,
    bool isAvailable,
  ) {
    final color = _parseColor(variant.value);
    
    return GestureDetector(
      onTap: isAvailable ? () => onVariantSelected(variant) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryViolet.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryViolet 
                : isAvailable 
                    ? AppTheme.grey300 
                    : AppTheme.grey200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cercle de couleur
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == Colors.white 
                        ? AppTheme.grey300 
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: _getContrastColor(color),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Nom de la couleur
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isAvailable 
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : AppTheme.textSecondary,
                    ),
                  ),
                  if (!isAvailable)
                    Text(
                      'Rupture',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade400,
                      ),
                    ),
                  if (isAvailable && variant.stock <= 5)
                    Text(
                      'Plus que ${variant.stock}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip pour texte (stockage, taille)
  Widget _buildTextChip(
    BuildContext context,
    ProductVariant variant,
    bool isSelected,
    bool isAvailable,
  ) {
    final hasPriceAdjustment = variant.priceAdjustment != null && variant.priceAdjustment != 0;
    
    return GestureDetector(
      onTap: isAvailable ? () => onVariantSelected(variant) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryViolet
              : isAvailable 
                  ? Colors.transparent
                  : AppTheme.grey100,
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryViolet 
                : isAvailable 
                    ? AppTheme.grey300 
                    : AppTheme.grey200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Column(
            children: [
              Text(
                variant.value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (hasPriceAdjustment) ...[
                const SizedBox(height: 4),
                Text(
                  variant.priceAdjustment! > 0 
                      ? '+${_formatPrice(variant.priceAdjustment!)}' 
                      : _formatPrice(variant.priceAdjustment!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.9) 
                        : variant.priceAdjustment! > 0 
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                  ),
                ),
              ],
              if (!isAvailable) ...[
                const SizedBox(height: 4),
                Text(
                  'Rupture',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.red.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Formater le prix
  String _formatPrice(int price) {
    return '${price.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} FCFA';
  }

  /// Convertir un nom de couleur en Color
  Color _parseColor(String colorName) {
    final colorMap = {
      'noir': Colors.black,
      'black': Colors.black,
      'blanc': Colors.white,
      'white': Colors.white,
      'bleu': Colors.blue,
      'blue': Colors.blue,
      'rouge': Colors.red,
      'red': Colors.red,
      'vert': Colors.green,
      'green': Colors.green,
      'jaune': Colors.yellow,
      'yellow': Colors.yellow,
      'rose': Colors.pink,
      'pink': Colors.pink,
      'violet': AppTheme.primaryViolet,
      'purple': Colors.purple,
      'gris': Colors.grey,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'or': const Color(0xFFFFD700),
      'gold': const Color(0xFFFFD700),
      'argent': const Color(0xFFC0C0C0),
      'silver': const Color(0xFFC0C0C0),
      'titane': const Color(0xFF878681),
      'titanium': const Color(0xFF878681),
      'noir titane': const Color(0xFF3D3D3D),
      'bleu titane': const Color(0xFF4A5568),
      'naturel': const Color(0xFFE8E4DF),
      'minuit': const Color(0xFF1C1C1E),
      'midnight': const Color(0xFF1C1C1E),
      'starlight': const Color(0xFFF5F5DC),
      'lumière stellaire': const Color(0xFFF5F5DC),
      'vert alpin': const Color(0xFF3C6E47),
      'violet profond': const Color(0xFF5D3FD3),
      'deep purple': const Color(0xFF5D3FD3),
    };
    
    final normalized = colorName.toLowerCase().trim();
    return colorMap[normalized] ?? Colors.grey;
  }

  /// Obtenir la couleur de contraste pour le check
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Widget combiné pour afficher tous les types de variantes
class ProductVariantsSelector extends StatefulWidget {
  final List<ProductVariant> variants;
  final ValueChanged<Map<String, ProductVariant?>>? onSelectionChanged;
  final ValueChanged<int>? onPriceAdjustmentChanged;

  const ProductVariantsSelector({
    Key? key,
    required this.variants,
    this.onSelectionChanged,
    this.onPriceAdjustmentChanged,
  }) : super(key: key);

  @override
  State<ProductVariantsSelector> createState() => _ProductVariantsSelectorState();
}

class _ProductVariantsSelectorState extends State<ProductVariantsSelector> {
  final Map<String, ProductVariant?> _selectedVariants = {};

  @override
  void initState() {
    super.initState();
    // Sélectionner la première variante disponible de chaque type
    _initializeDefaultSelections();
  }

  void _initializeDefaultSelections() {
    final types = widget.variants.map((v) => v.type).toSet();
    
    for (final type in types) {
      final variantsOfType = widget.variants.where((v) => v.type == type).toList();
      // Sélectionner la première variante en stock, sinon la première
      final defaultVariant = variantsOfType.firstWhere(
        (v) => v.stock > 0,
        orElse: () => variantsOfType.first,
      );
      _selectedVariants[type] = defaultVariant;
    }
    
    _notifyChanges();
  }

  void _onVariantSelected(String type, ProductVariant variant) {
    setState(() {
      _selectedVariants[type] = variant;
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    // Calculer l'ajustement de prix total
    int totalAdjustment = 0;
    for (final variant in _selectedVariants.values) {
      if (variant?.priceAdjustment != null) {
        totalAdjustment += variant!.priceAdjustment!;
      }
    }
    
    widget.onSelectionChanged?.call(_selectedVariants);
    widget.onPriceAdjustmentChanged?.call(totalAdjustment);
  }

  @override
  Widget build(BuildContext context) {
    // Grouper les variantes par type
    final types = widget.variants.map((v) => v.type).toSet().toList();
    
    // Trier pour avoir un ordre cohérent (couleur d'abord, puis stockage)
    types.sort((a, b) {
      const order = ['color', 'storage', 'size'];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });

    if (types.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < types.length; i++) ...[
          VariantSelector(
            variants: widget.variants,
            selectedVariant: _selectedVariants[types[i]],
            onVariantSelected: (v) => _onVariantSelected(types[i], v),
            variantType: types[i],
          ),
          if (i < types.length - 1) const SizedBox(height: 20),
        ],
      ],
    );
  }
}
