import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({this.product, super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();
  final ImagePicker _picker = ImagePicker();

  // Catégories prédéfinies
  static const List<String> _predefinedCategories = [
    'phone',
    'accessory',
    'screen',
    'pc',
    'tablet',
    'headphones',
    'charger',
    'case',
    'other',
  ];

  late TextEditingController _nameC;
  late TextEditingController _brandC;
  late TextEditingController _priceC;
  late TextEditingController _stockC;
  late TextEditingController _supplierRefC;
  late TextEditingController _descriptionC;
  late TextEditingController _imageUrlC;
  final Map<String, TextEditingController> _specControllers = {};
  final List<String> _imageUrls = [];
  String? _selectedCategory;
  DateTime _createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameC = TextEditingController(text: p?.name ?? '');
    _brandC = TextEditingController(text: p?.brand ?? '');
    _priceC = TextEditingController(text: p?.price.toString() ?? '');
    _stockC = TextEditingController(text: p?.stock.toString() ?? '');
    _supplierRefC = TextEditingController(text: p?.supplierReference ?? '');
    _descriptionC = TextEditingController(text: p?.description ?? '');
    _imageUrlC = TextEditingController();
    _imageUrls.addAll(p?.imageUrls ?? []);
    _selectedCategory = p?.category;
    _createdAt = p?.createdAt ?? DateTime.now();

    (p?.specs ?? {}).forEach((k, v) {
      _specControllers[k] = TextEditingController(text: v);
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _brandC.dispose();
    _priceC.dispose();
    _stockC.dispose();
    _supplierRefC.dispose();
    _descriptionC.dispose();
    _imageUrlC.dispose();
    for (var controller in _specControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final name = _nameC.text.trim();
    final brand = _brandC.text.trim();
    final price = double.parse(_priceC.text.trim());
    final stock = int.parse(_stockC.text.trim());
    final category = _selectedCategory ?? '';
    final description = _descriptionC.text.trim();
    final supplierRef = _supplierRefC.text.trim();

    final specs = <String, String>{};
    for (var entry in _specControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        specs[entry.key] = value;
      }
    }

    final prod = Product(
      id: id,
      name: name,
      brand: brand,
      category: category,
      price: price,
      description: description,
      imageUrls: List.from(_imageUrls),
      isInStock: stock > 0,
      stock: stock,
      supplierReference: supplierRef,
      specs: specs,
      createdAt: _createdAt,
    );

    try {
      if (widget.product == null) {
        await _service.add(prod);
      } else {
        await _service.update(prod);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // Validation d'URL d'image
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (url.toLowerCase().endsWith('.jpg') ||
            url.toLowerCase().endsWith('.jpeg') ||
            url.toLowerCase().endsWith('.png') ||
            url.toLowerCase().endsWith('.gif') ||
            url.toLowerCase().endsWith('.webp'));
  }

  // Sélecteur d'images
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _imageUrls.add(image.path);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image ajoutée avec succès')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la sélection: $e')),
          );
        }
      }
    }
  }

  // Ajouter une nouvelle spécification technique
  void _addNewSpec() {
    final specKeyController = TextEditingController();
    final specValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle spécification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: specKeyController,
              decoration: const InputDecoration(
                labelText: 'Nom de la spécification',
                hintText: 'Ex: Poids, Dimensions, Couleur...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: specValueController,
              decoration: const InputDecoration(
                labelText: 'Valeur',
                hintText: 'Ex: 200g, 15x8x0.8cm, Noir...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final key = specKeyController.text.trim();
              final value = specValueController.text.trim();
              if (key.isNotEmpty && !_specControllers.containsKey(key)) {
                setState(() {
                  _specControllers[key] = TextEditingController(text: value);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier produit' : 'Ajouter produit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de base
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations générales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameC,
                          decoration: const InputDecoration(
                            labelText: 'Nom du produit *',
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Nom requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _brandC,
                          decoration: const InputDecoration(
                            labelText: 'Marque *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Marque requise' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie *',
                            prefixIcon: Icon(Icons.category),
                            helperText: 'Sélectionnez une catégorie',
                          ),
                          items: _predefinedCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (v) => v == null || v.isEmpty
                              ? 'Catégorie requise'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionC,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Prix et stock
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prix et stock',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceC,
                                decoration: const InputDecoration(
                                  labelText: 'Prix (FCFA) *',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Prix requis';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Prix invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stockC,
                                decoration: const InputDecoration(
                                  labelText: 'Stock *',
                                  prefixIcon: Icon(Icons.inventory_2),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Stock requis';
                                  }
                                  if (int.tryParse(v) == null) {
                                    return 'Stock invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _supplierRefC,
                          decoration: const InputDecoration(
                            labelText: 'Référence fournisseur',
                            prefixIcon: Icon(Icons.qr_code),
                            helperText: 'GTIN, MPN, ou référence interne',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Images
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlC,
                                decoration: const InputDecoration(
                                  labelText: 'URL de l\'image',
                                  prefixIcon: Icon(Icons.link),
                                ),
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      !_isValidImageUrl(value)) {
                                    return 'URL d\'image invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final url = _imageUrlC.text.trim();
                                if (url.isNotEmpty &&
                                    _isValidImageUrl(url) &&
                                    !_imageUrls.contains(url)) {
                                  setState(() {
                                    _imageUrls.add(url);
                                    _imageUrlC.clear();
                                  });
                                } else if (url.isNotEmpty &&
                                    !_isValidImageUrl(url)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('URL d\'image invalide'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add),
                              tooltip: 'Ajouter URL',
                            ),
                            IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt),
                              tooltip: 'Prendre photo',
                            ),
                          ],
                        ),
                        if (_imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Images ajoutées (${_imageUrls.length}):'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _imageUrls.map((url) {
                              final isValid = _isValidImageUrl(url);
                              return Chip(
                                avatar: Icon(
                                  isValid ? Icons.check_circle : Icons.error,
                                  color: isValid ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                label: Text(
                                  url.length > 25
                                      ? '${url.substring(0, 25)}...'
                                      : url,
                                  style: TextStyle(
                                    color: isValid ? null : Colors.red,
                                  ),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => _imageUrls.remove(url));
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Spécifications techniques
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Spécifications techniques',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addNewSpec,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ajouter'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_specControllers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Aucune spécification ajoutée',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        ..._specControllers.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: e.value,
                                    decoration: InputDecoration(
                                      labelText: e.key,
                                      prefixIcon: const Icon(
                                        Icons.info_outline,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      e.value.dispose();
                                      _specControllers.remove(e.key);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date et actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            'Date de création: ${DateFormat.yMd().format(_createdAt)}',
                          ),
                          onPressed: () async {
                            DateTime? d = await showDatePicker(
                              context: context,
                              initialDate: _createdAt,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _createdAt = d);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: Icon(isEdit ? Icons.save : Icons.add),
                            label: Text(
                              isEdit ? 'Mettre à jour' : 'Créer le produit',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
