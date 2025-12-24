import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../data/cote_ivoire_locations.dart';

/// Écran de gestion des adresses de livraison
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresses de livraison'),
        actions: [
          IconButton(
            onPressed: () => _showAddAddressDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une adresse',
          ),
        ],
      ),
      body: user == null
          ? _buildNotLoggedIn(context)
          : _buildAddressesList(context, user.uid),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(context),
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nouvelle adresse'),
      ),
    );
  }
  
  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Connectez-vous pour gérer vos adresses'),
        ],
      ),
    );
  }
  
  Widget _buildAddressesList(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final addresses = snapshot.data?.docs ?? [];
        
        if (addresses.isEmpty) {
          return _buildEmptyAddresses(context);
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final address = addresses[index].data() as Map<String, dynamic>;
            return _buildAddressCard(context, addresses[index].id, address, userId);
          },
        );
      },
    );
  }
  
  Widget _buildEmptyAddresses(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune adresse enregistrée',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une adresse pour faciliter vos livraisons',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Ajouter une adresse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressCard(BuildContext context, String addressId, Map<String, dynamic> address, String userId) {
    final isDefault = address['isDefault'] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDefault 
            ? const BorderSide(color: AppTheme.primaryViolet, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    address['type'] == 'work' ? Icons.work_outline : Icons.home_outlined,
                    color: AppTheme.primaryViolet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address['label'] ?? 'Adresse',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Par défaut',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address['name'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'default':
                        _setDefaultAddress(userId, addressId);
                        break;
                      case 'edit':
                        _showEditAddressDialog(context, addressId, address, userId);
                        break;
                      case 'delete':
                        _deleteAddress(userId, addressId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline),
                            SizedBox(width: 8),
                            Text('Définir par défaut'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppTheme.error),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address['address'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (address['city'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${address['city']}${address['commune'] != null ? ', ${address['commune']}' : ''}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (address['phone'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    address['phone'],
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showAddAddressDialog(BuildContext context) {
    _showAddressDialog(context, null, null, null);
  }
  
  void _showEditAddressDialog(BuildContext context, String addressId, Map<String, dynamic> address, String userId) {
    _showAddressDialog(context, addressId, address, userId);
  }
  
  void _showAddressDialog(BuildContext context, String? addressId, Map<String, dynamic>? existingAddress, String? userId) {
    final labelController = TextEditingController(text: existingAddress?['label'] ?? '');
    final nameController = TextEditingController(text: existingAddress?['name'] ?? '');
    final addressController = TextEditingController(text: existingAddress?['address'] ?? '');
    final phoneController = TextEditingController(text: existingAddress?['phone'] ?? '');
    String type = existingAddress?['type'] ?? 'home';
    String selectedVille = existingAddress?['city'] ?? 'Abidjan';
    String selectedCommune = existingAddress?['commune'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Text(
                  addressId == null ? 'Nouvelle adresse' : 'Modifier l\'adresse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Type selection
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeChip(
                        label: 'Domicile',
                        icon: Icons.home_outlined,
                        isSelected: type == 'home',
                        onTap: () => setModalState(() => type = 'home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeChip(
                        label: 'Travail',
                        icon: Icons.work_outline,
                        isSelected: type == 'work',
                        onTap: () => setModalState(() => type = 'work'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Fields
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'adresse',
                    hintText: 'Ex: Maison, Bureau...',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du destinataire',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse complète',
                    hintText: 'Rue, quartier, repères...',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                // Ville selector
                _buildLocationSelector(
                  context: context,
                  label: 'Ville',
                  value: selectedVille,
                  icon: Icons.location_city,
                  onTap: () async {
                    final ville = await _showVilleSelector(context, selectedVille);
                    if (ville != null) {
                      setModalState(() {
                        selectedVille = ville;
                        // Reset commune when ville changes
                        selectedCommune = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Commune selector
                _buildLocationSelector(
                  context: context,
                  label: 'Commune',
                  value: selectedCommune.isEmpty ? 'Sélectionner une commune' : selectedCommune,
                  icon: Icons.map_outlined,
                  onTap: () async {
                    final commune = await _showCommuneSelector(context, selectedVille, selectedCommune);
                    if (commune != null) {
                      setModalState(() => selectedCommune = commune);
                    }
                  },
                ),
                
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+225 07 00 00 00 00',
                  ),
                ),
                const SizedBox(height: 32),
                
                // Boutons harmonisés - même taille
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryViolet),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryViolet,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _saveAddress(
                            context,
                            addressId,
                            {
                              'label': labelController.text,
                              'name': nameController.text,
                              'address': addressController.text,
                              'city': selectedVille,
                              'commune': selectedCommune,
                              'phone': phoneController.text,
                              'type': type,
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryViolet : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveAddress(BuildContext context, String? addressId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Validation du numéro de téléphone
    final phone = data['phone'] as String? ?? '';
    if (phone.isNotEmpty) {
      // Vérifier le format: + suivi de 8 à 15 chiffres
      final phoneRegex = RegExp(r'^\+?\d{8,15}$');
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (!phoneRegex.hasMatch(cleanPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Numéro de téléphone invalide (8-15 chiffres)')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      // Nettoyer le numéro
      data['phone'] = cleanPhone.startsWith('+') ? cleanPhone : '+$cleanPhone';
    }
    
    try {
      final addressesRef = _firestore.collection('users').doc(user.uid).collection('addresses');
      
      if (addressId == null) {
        // Check if this is the first address
        final existing = await addressesRef.limit(1).get();
        data['isDefault'] = existing.docs.isEmpty;
        data['createdAt'] = FieldValue.serverTimestamp();
        await addressesRef.add(data);
      } else {
        await addressesRef.doc(addressId).update(data);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Adresse enregistrée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  
  Future<void> _setDefaultAddress(String userId, String addressId) async {
    try {
      // Remove default from all
      final batch = _firestore.batch();
      final addresses = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();
      
      for (var doc in addresses.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == addressId});
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Adresse par défaut mise à jour'),
              ],
            ),
            backgroundColor: AppTheme.primaryViolet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting default address: $e');
    }
  }
  
  Future<void> _deleteAddress(String userId, String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'adresse ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Adresse supprimée'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
  
  /// Widget pour afficher un sélecteur de localisation
  Widget _buildLocationSelector({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.contains('Sélectionner') 
                          ? Colors.grey.shade500 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
  
  /// Afficher le sélecteur de ville
  Future<String?> _showVilleSelector(BuildContext context, String currentVille) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSelectorSheet(
        title: 'Sélectionner une ville',
        items: CoteIvoireLocations.villes,
        selectedItem: currentVille,
        searchHint: 'Rechercher une ville...',
      ),
    );
  }
  
  /// Afficher le sélecteur de commune
  Future<String?> _showCommuneSelector(BuildContext context, String ville, String currentCommune) async {
    final communes = CoteIvoireLocations.getCommunesPourVille(ville);
    
    if (communes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Aucune commune disponible pour cette ville'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return null;
    }
    
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSelectorSheet(
        title: 'Commune à $ville',
        items: communes,
        selectedItem: currentCommune,
        searchHint: 'Rechercher une commune...',
      ),
    );
  }
}

/// Widget pour afficher une liste de sélection avec recherche
class _LocationSelectorSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selectedItem;
  final String searchHint;
  
  const _LocationSelectorSheet({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.searchHint,
  });
  
  @override
  State<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<_LocationSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  
  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }
  
  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun résultat',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedItem;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                              ? AppTheme.primaryViolet 
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryViolet : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.primaryViolet)
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
