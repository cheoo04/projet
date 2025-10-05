import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_management_service.dart';

class ImageManagementScreen extends StatefulWidget {
  final String? productId;
  final String? categoryId;
  final List<String>? existingImages;
  final Function(List<String>)? onImagesUpdated;

  const ImageManagementScreen({
    super.key,
    this.productId,
    this.categoryId,
    this.existingImages,
    this.onImagesUpdated,
  });

  @override
  State<ImageManagementScreen> createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen> {
  final ImageManagementService _imageService = ImageManagementService();
  final ImagePicker _picker = ImagePicker();

  List<ImageItem> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingImages();
  }

  void _loadExistingImages() {
    if (widget.existingImages != null) {
      setState(() {
        _images = widget.existingImages!
            .asMap()
            .entries
            .map(
              (entry) => ImageItem(
                id: entry.key.toString(),
                url: entry.value,
                order: entry.key,
                isUploaded: true,
              ),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des images'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _showAddImageDialog,
          ),
          if (_images.isNotEmpty)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
          ? _buildEmptyState()
          : _buildImageGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddImageDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune image ajoutée',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton + pour ajouter des images',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddImageDialog,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Ajouter des images'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Instructions de réorganisation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maintenez et glissez pour réorganiser les images',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grille d'images réorganisable
          Expanded(
            child: ReorderableGridView(
              itemCount: _images.length,
              onReorder: _reorderImages,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: _images.map((image) => _buildImageCard(image)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(ImageItem image) {
    return Card(
      key: ValueKey(image.id),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image principale
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: image.bytes != null
                  ? DecorationImage(
                      image: MemoryImage(image.bytes!),
                      fit: BoxFit.cover,
                    )
                  : DecorationImage(
                      image: NetworkImage(image.url!),
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // Overlay avec actions
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Actions du haut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicateur d'ordre
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${image.order + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Statut d'upload
                      if (!image.isUploaded)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_upload,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),

                  // Actions du bas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.crop,
                        'Recadrer',
                        () => _cropImage(image),
                      ),
                      _buildActionButton(
                        Icons.edit,
                        'Éditer',
                        () => _editImage(image),
                      ),
                      _buildActionButton(
                        Icons.delete,
                        'Supprimer',
                        () => _deleteImage(image),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de glisser-déposer
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showAddImageDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter des images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAddImageOption(
                    Icons.camera_alt,
                    'Appareil photo',
                    () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAddImageOption(
                    Icons.photo_library,
                    'Galerie',
                    () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // Fermer le bottom sheet

      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // Valider l'image
      final validation = await _imageService.validateImage(
        imageBytes,
        maxWidth: 2048,
        maxHeight: 2048,
        maxSizeInBytes: 5 * 1024 * 1024, // 5MB
        allowedFormats: ['JPEG', 'PNG'],
      );

      if (!validation.isValid) {
        _showValidationErrors(validation.errors);
        return;
      }

      // Optimiser pour le web
      final optimizedBytes = await _imageService.optimizeForWeb(imageBytes);
      if (optimizedBytes == null) {
        _showError('Erreur lors de l\'optimisation de l\'image');
        return;
      }

      // Ajouter à la liste
      setState(() {
        _images.add(
          ImageItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            bytes: optimizedBytes,
            order: _images.length,
            isUploaded: false,
          ),
        );
      });
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final ImageItem item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);

      // Mettre à jour les ordres
      for (int i = 0; i < _images.length; i++) {
        _images[i].order = i;
      }
    });
  }

  void _cropImage(ImageItem image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropScreen(
          imageBytes: image.bytes!,
          onCropped: (croppedBytes) {
            setState(() {
              image.bytes = croppedBytes;
              image.isUploaded = false;
            });
          },
        ),
      ),
    );
  }

  void _editImage(ImageItem image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditScreen(
          imageBytes: image.bytes!,
          onEdited: (editedBytes) {
            setState(() {
              image.bytes = editedBytes;
              image.isUploaded = false;
            });
          },
        ),
      ),
    );
  }

  void _deleteImage(ImageItem image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette image ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _images.remove(image);
                // Réorganiser les ordres
                for (int i = 0; i < _images.length; i++) {
                  _images[i].order = i;
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_images.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<String> uploadedUrls = [];

      for (ImageItem image in _images) {
        if (!image.isUploaded && image.bytes != null) {
          // Upload de la nouvelle image
          String path = widget.productId != null
              ? 'products/${widget.productId}/images/${image.id}'
              : 'categories/${widget.categoryId}/images/${image.id}';

          Map<String, String> uploadResults = await _imageService
              .uploadImageWithThumbnails(
                image.bytes!,
                path,
                metadata: {'order': image.order.toString()},
              );

          uploadedUrls.add(uploadResults['original']!);
          image.isUploaded = true;
          image.url = uploadResults['original'];
        } else if (image.url != null) {
          uploadedUrls.add(image.url!);
        }
      }

      // Notifier le parent
      if (widget.onImagesUpdated != null) {
        widget.onImagesUpdated!(uploadedUrls);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images sauvegardées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image non valide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((error) => Text('• $error')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

class ImageItem {
  String id;
  String? url;
  Uint8List? bytes;
  int order;
  bool isUploaded;

  ImageItem({
    required this.id,
    this.url,
    this.bytes,
    required this.order,
    required this.isUploaded,
  });
}

// Widget simplifié pour la grille réorganisable
class ReorderableGridView extends StatelessWidget {
  final int itemCount;
  final Function(int oldIndex, int newIndex) onReorder;
  final SliverGridDelegate gridDelegate;
  final List<Widget> children;

  const ReorderableGridView({
    super.key,
    required this.itemCount,
    required this.onReorder,
    required this.gridDelegate,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: onReorder,
      scrollDirection: Axis.vertical,
      children: children,
    );
  }
}

// Écrans de recadrage et d'édition (versions simplifiées)
class ImageCropScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onCropped;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.onCropped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recadrer l\'image'),
        actions: [
          TextButton(
            onPressed: () {
              // Pour l'instant, retourner l'image telle quelle
              onCropped(imageBytes);
              Navigator.pop(context);
            },
            child: const Text('Terminé'),
          ),
        ],
      ),
      body: Center(child: Image.memory(imageBytes)),
    );
  }
}

class ImageEditScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onEdited;

  const ImageEditScreen({
    super.key,
    required this.imageBytes,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer l\'image'),
        actions: [
          TextButton(
            onPressed: () {
              // Pour l'instant, retourner l'image telle quelle
              onEdited(imageBytes);
              Navigator.pop(context);
            },
            child: const Text('Terminé'),
          ),
        ],
      ),
      body: Center(child: Image.memory(imageBytes)),
    );
  }
}
