import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promotion.dart';
import '../models/product.dart';
import '../services/promotion_service.dart';
import '../services/product_service.dart';

class PromotionFormScreen extends StatefulWidget {
  final Promotion? promotion;
  const PromotionFormScreen({this.promotion, super.key});

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PromotionService _promotionService = PromotionService();
  final ProductService _productService = ProductService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TextEditingController _minimumAmountController;

  String _type = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isActive = true;
  List<String> _selectedProductIds = [];
  List<Product> _availableProducts = [];
  bool _isLoading = false;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProducts();
  }

  void _initializeControllers() {
    final promotion = widget.promotion;
    _nameController = TextEditingController(text: promotion?.name ?? '');
    _descriptionController = TextEditingController(
      text: promotion?.description ?? '',
    );
    _valueController = TextEditingController(
      text: promotion?.value.toString() ?? '',
    );
    _minimumAmountController = TextEditingController(
      text: promotion?.minimumAmount?.toString() ?? '',
    );

    if (promotion != null) {
      _type = promotion.type;
      _startDate = promotion.startDate;
      _endDate = promotion.endDate;
      _isActive = promotion.isActive;
      _selectedProductIds = List.from(promotion.productIds);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.fetchAll();
      if (mounted) {
        setState(() {
          _availableProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement produits: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minimumAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectProducts() async {
    if (_isLoadingProducts) return;

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _ProductSelectionDialog(
        availableProducts: _availableProducts,
        selectedProductIds: _selectedProductIds,
      ),
    );

    if (selected != null) {
      setState(() => _selectedProductIds = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un produit'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final promotion = Promotion(
        id:
            widget.promotion?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        productIds: _selectedProductIds,
        type: _type,
        value: double.parse(_valueController.text.trim()),
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
        minimumAmount: _minimumAmountController.text.isNotEmpty
            ? double.parse(_minimumAmountController.text.trim())
            : null,
      );

      if (widget.promotion == null) {
        await _promotionService.add(promotion);
      } else {
        await _promotionService.update(promotion);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promotion != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier promotion' : 'Nouvelle promotion'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'SAUVER',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom de la promotion
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la promotion *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_offer),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Type et valeur de remise
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type de remise',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Pourcentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Montant fixe (FCFA)'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: _type == 'percentage'
                          ? 'Valeur (%)'
                          : 'Valeur (FCFA)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requis';
                      }
                      final val = double.tryParse(value.trim());
                      if (val == null || val <= 0) {
                        return 'Valeur invalide';
                      }
                      if (_type == 'percentage' && val > 100) {
                        return 'Max 100%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Montant minimum d'achat
            TextFormField(
              controller: _minimumAmountController,
              decoration: const InputDecoration(
                labelText: 'Montant minimum d\'achat (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Optionnel',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final val = double.tryParse(value.trim());
                  if (val == null || val <= 0) {
                    return 'Montant invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date de début',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_startDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date de fin',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_endDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélection des produits
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Produits concernés'),
                subtitle: Text(
                  _selectedProductIds.isEmpty
                      ? 'Aucun produit sélectionné'
                      : '${_selectedProductIds.length} produit(s) sélectionné(s)',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectProducts,
              ),
            ),
            const SizedBox(height: 16),

            // Statut actif
            Card(
              child: SwitchListTile(
                title: const Text('Promotion active'),
                subtitle: Text(_isActive ? 'Activée' : 'Désactivée'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bouton de sauvegarde
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEditing ? Icons.save : Icons.add),
                label: Text(
                  _isLoading
                      ? 'Sauvegarde...'
                      : (isEditing
                            ? 'Modifier la promotion'
                            : 'Créer la promotion'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSelectionDialog extends StatefulWidget {
  final List<Product> availableProducts;
  final List<String> selectedProductIds;

  const _ProductSelectionDialog({
    required this.availableProducts,
    required this.selectedProductIds,
  });

  @override
  State<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedProductIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner les produits'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.availableProducts.length,
          itemBuilder: (context, index) {
            final product = widget.availableProducts[index];
            final isSelected = _selected.contains(product.id);

            return CheckboxListTile(
              title: Text(product.name),
              subtitle: Text('${product.price} FCFA • ${product.brand}'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selected.add(product.id);
                  } else {
                    _selected.remove(product.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Confirmer (${_selected.length})'),
        ),
      ],
    );
  }
}
