import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/cloudinary_service.dart';
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
  final CategoryService _categoryService = CategoryService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  // Catégories chargées depuis Firebase
  List<models.Category> _categories = [];
  bool _isLoadingCategories = true;

  late TextEditingController _nameC;
  late TextEditingController _brandC;
  late TextEditingController _priceC;
  late TextEditingController _stockC;
  late TextEditingController _supplierRefC;
  late TextEditingController _descriptionC;
  late TextEditingController _imageUrlC;
  final Map<String, TextEditingController> _specControllers = {};
  final List<String> _imageUrls = [];
  final List<String> _videoUrls = [];
  bool _isUploadingVideo = false;
  String? _selectedCategory;
  DateTime _createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    final p = widget.product;
    _nameC = TextEditingController(text: p?.name ?? '');
    _brandC = TextEditingController(text: p?.brand ?? '');
    _priceC = TextEditingController(text: p?.price.toString() ?? '');
    _stockC = TextEditingController(text: p?.stock.toString() ?? '');
    _supplierRefC = TextEditingController(text: p?.supplierReference ?? '');
    _descriptionC = TextEditingController(text: p?.description ?? '');
    _imageUrlC = TextEditingController();
    _imageUrls.addAll(p?.imageUrls ?? []);
    _videoUrls.addAll(p?.videoUrls ?? []);
    
    // Garder la catégorie existante du produit
    _selectedCategory = p?.category;
    _createdAt = p?.createdAt ?? DateTime.now();

    (p?.specs ?? {}).forEach((k, v) {
      _specControllers[k] = TextEditingController(text: v);
    });
  }
  
  /// Charge les catégories depuis Firebase
  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
          
          // Vérifier si la catégorie sélectionnée existe dans la liste
          if (_selectedCategory != null) {
            final exists = _categories.any((c) => c.id == _selectedCategory || c.name == _selectedCategory);
            if (!exists) {
              _selectedCategory = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
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

    // Construire l'objet produit en préservant les champs existants si
    // nous sommes en mode édition (utiliser copyWith pour ne pas écraser
    // les données enrichies non modifiées).
    final prod = widget.product == null
        ? Product(
            id: id,
            name: name,
            brand: brand,
            category: category,
            price: price,
            description: description,
            imageUrls: List.from(_imageUrls),
            videoUrls: List.from(_videoUrls),
            isInStock: stock > 0,
            stock: stock,
            supplierReference: supplierRef,
            specs: specs,
            createdAt: _createdAt,
          )
        : widget.product!.copyWith(
            name: name,
            brand: brand,
            category: category,
            price: price,
            description: description,
            imageUrls: List.from(_imageUrls),
            videoUrls: List.from(_videoUrls),
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
        _showSuccessDialog(prod.id, widget.product == null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  /// Affiche un dialogue de succès avec option de voir le produit sur la boutique
  void _showSuccessDialog(String productId, bool isNew) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
        ),
        title: Text(isNew ? 'Produit ajouté !' : 'Produit modifié !'),
        content: Text(
          isNew 
            ? 'Le produit a été ajouté avec succès à votre catalogue.'
            : 'Les modifications ont été enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(this.context, true); // Retourner à la liste
            },
            child: const Text('Retour à la liste'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(this.context, true); // Retourner à la liste
              // Naviguer vers la boutique avec le produit
              this.context.go('/product/$productId');
            },
            icon: const Icon(Icons.storefront),
            label: const Text('Voir sur la boutique'),
          ),
        ],
      ),
    );
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

  // Sélecteur d'images avec upload Cloudinary
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb) // Caméra non disponible sur web
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
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        
        if (image != null) {
          await _uploadImageToCloudinary(image);
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

  /// Upload l'image sélectionnée vers Cloudinary
  Future<void> _uploadImageToCloudinary(XFile image) async {
    setState(() => _isUploadingImage = true);
    
    try {
      // Lire les bytes de l'image
      final bytes = await image.readAsBytes();
      
      // Générer un ID unique pour l'image
      final productName = _nameC.text.trim().isNotEmpty 
          ? _nameC.text.trim().replaceAll(' ', '_').toLowerCase()
          : 'product';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${productName}_$timestamp';
      
      // Upload vers Cloudinary
      final url = await _cloudinaryService.uploadImageUnsigned(
        bytes,
        folder: 'products',
        publicId: publicId,
      );
      
      if (url != null) {
        setState(() {
          _imageUrls.add(url);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Image uploadée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('URL de retour nulle');
      }
    } catch (e) {
      debugPrint('❌ Erreur upload Cloudinary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  /// Sélectionne une vidéo depuis la galerie, vérifie sa durée (≤ 30s) et
  /// sa taille avant de l'uploader. Maximum [Product.maxVideos] vidéos.
  Future<void> _pickVideo() async {
    if (_videoUrls.length >= Product.maxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${Product.maxVideos} vidéos par produit'),
        ),
      );
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      // Vérifier la durée avant tout upload — évite de gaspiller de la
      // bande passante et des crédits Cloudinary sur une vidéo refusée.
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(video.path))
          : VideoPlayerController.file(File(video.path));

      Duration duration = Duration.zero;
      try {
        await controller.initialize();
        duration = controller.value.duration;
      } finally {
        await controller.dispose();
      }

      if (duration.inSeconds > Product.maxVideoDurationSeconds) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vidéo trop longue (${duration.inSeconds}s) — '
                'max ${Product.maxVideoDurationSeconds}s autorisées',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final bytes = await video.readAsBytes();

      if (bytes.length > Product.maxVideoSizeBytes) {
        final maxMb = (Product.maxVideoSizeBytes / (1024 * 1024)).round();
        final fileMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vidéo trop volumineuse ($fileMb Mo) — max $maxMb Mo. '
                'Compressez-la avant de réessayer.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _uploadVideoToCloudinary(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  /// Upload la vidéo validée vers Cloudinary
  Future<void> _uploadVideoToCloudinary(Uint8List bytes) async {
    setState(() => _isUploadingVideo = true);

    try {
      final productName = _nameC.text.trim().isNotEmpty
          ? _nameC.text.trim().replaceAll(' ', '_').toLowerCase()
          : 'product';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${productName}_video_$timestamp';

      final url = await _cloudinaryService.uploadVideoSigned(
        bytes,
        folder: 'products/videos',
        publicId: publicId,
      );

      if (url != null) {
        setState(() => _videoUrls.add(url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Vidéo uploadée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('URL de retour nulle');
      }
    } catch (e) {
      debugPrint('❌ Erreur upload vidéo Cloudinary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload vidéo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
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
                        _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie *',
                                prefixIcon: Icon(Icons.category),
                                helperText: 'Sélectionnez une catégorie',
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
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
                            _isUploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.upload_file),
                                    tooltip: 'Uploader depuis l\'appareil',
                                  ),
                          ],
                        ),
                        if (_isUploadingImage)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Upload en cours vers Cloudinary...',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
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

                // Section vidéos produit
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Vidéos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_videoUrls.length}/${Product.maxVideos})',
                              style: TextStyle(
                                color: _videoUrls.length >= Product.maxVideos
                                    ? Colors.red
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max ${Product.maxVideos} vidéos, '
                          '${Product.maxVideoDurationSeconds}s chacune. '
                          'Elles s\'affichent après les images dans la galerie '
                          'et jouent automatiquement au glissement.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (_isUploadingVideo ||
                                        _videoUrls.length >=
                                            Product.maxVideos)
                                    ? null
                                    : _pickVideo,
                                icon: const Icon(Icons.videocam),
                                label: Text(
                                  _videoUrls.length >= Product.maxVideos
                                      ? 'Limite atteinte'
                                      : 'Ajouter une vidéo',
                                ),
                              ),
                            ),
                            if (_isUploadingVideo) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        if (_isUploadingVideo)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Vérification (durée/taille) puis upload vers Cloudinary...',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ),
                        if (_videoUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Vidéos ajoutées (${_videoUrls.length}):'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _videoUrls.map((url) {
                              return Chip(
                                avatar: const Icon(Icons.videocam,
                                    size: 16, color: Colors.blue),
                                label: Text(
                                  url.length > 25
                                      ? '${url.substring(0, 25)}...'
                                      : url,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => _videoUrls.remove(url));
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
                            Expanded(
                              child: Text(
                                'Spécifications techniques',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
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