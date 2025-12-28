import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import 'package:intl/intl.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final AuthService _authService = AuthService();

  String? _selectedStatusFilter; // 'pending', 'approved', 'rejected'
  int? _selectedRatingFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getReviewStatus(Review review) {
    if (!review.isModerated) return 'pending';
    return review.isApproved ? 'approved' : 'rejected';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des avis clients'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersSection(),

          // Liste des avis
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final reviews = snapshot.data?.docs ?? [];
                final filteredReviews = _filterReviews(reviews);

                if (filteredReviews.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun avis trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    final reviewDoc = filteredReviews[index];
                    final reviewData = reviewDoc.data() as Map<String, dynamic>;
                    reviewData['id'] = reviewDoc.id;
                    final review = Review.fromMap(reviewData);

                    return _buildReviewCard(review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par utilisateur ou commentaire...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 12),

          // Filtre par statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statut:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusFilter(null, 'Tous'),
                    _buildStatusFilter('pending', 'En attente'),
                    _buildStatusFilter('approved', 'Approuvé'),
                    _buildStatusFilter('rejected', 'Rejeté'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filtre par note
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRatingFilter(null, 'Toutes'),
                    ...List.generate(
                      5,
                      (i) => _buildRatingFilter(i + 1, '${i + 1}⭐'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(String? status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatusFilter = selected ? status : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildRatingFilter(int? rating, String label) {
    final isSelected = _selectedRatingFilter == rating;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRatingFilter = selected ? rating : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterReviews(
    List<QueryDocumentSnapshot> reviews,
  ) {
    return reviews.where((doc) {
      final reviewData = doc.data() as Map<String, dynamic>;
      reviewData['id'] = doc.id;
      final review = Review.fromMap(reviewData);

      // Filtre par statut
      if (_selectedStatusFilter != null &&
          _getReviewStatus(review) != _selectedStatusFilter) {
        return false;
      }

      // Filtre par note
      if (_selectedRatingFilter != null &&
          review.rating != _selectedRatingFilter) {
        return false;
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return review.userName.toLowerCase().contains(query) ||
            review.comment.toLowerCase().contains(query) ||
            review.productId.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Widget _buildReviewCard(Review review) {
    final status = _getReviewStatus(review);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec utilisateur et note
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Vérifié',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Produit: ${review.productId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      // Nom du produit
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('products').doc(review.productId).get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final productData = snapshot.data!.data() as Map<String, dynamic>;
                            final productName = productData['name'] ?? 'Produit inconnu';
                            return Text(
                              productName,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Commentaire
            if (review.comment.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.comment,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            // Images si présentes
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.imageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Note de modération si présente
            if (review.moderatorNote?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note de modération: ${review.moderatorNote}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Statut et actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatusChip(status),
                if (status == 'pending') ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _showModerationDialog(review, true),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Approuver', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _showModerationDialog(review, false),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ] else if (status == 'approved') ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _showModerationDialog(review, false),
                      icon: const Icon(Icons.block, size: 14),
                      label: const Text('Masquer', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ] else if (status == 'rejected') ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _showModerationDialog(review, true),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text('Afficher', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    onPressed: () => _showDeleteConfirmation(review),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    tooltip: 'Supprimer',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approuvé';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showModerationDialog(Review review, bool isApproving) {
    final noteController = TextEditingController(
      text: review.moderatorNote ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproving ? 'Approuver l\'avis' : 'Rejeter l\'avis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApproving
                  ? 'Voulez-vous approuver cet avis pour qu\'il soit visible publiquement ?'
                  : 'Voulez-vous rejeter cet avis ? Il ne sera plus visible publiquement.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note de modération (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              _updateReviewModeration(review, isApproving, noteController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproving ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproving ? 'Approuver' : 'Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReviewModeration(
    Review review,
    bool isApproving,
    String moderatorNote,
  ) async {
    try {
      String adminId = 'unknown_admin';
      String adminName = 'Admin';
      
      try {
        final currentUser = await _authService.getCurrentUserData();
        if (currentUser != null) {
          adminId = currentUser.id ?? 'unknown_admin';
          adminName = currentUser.fullName ?? 'Admin';
        }
      } catch (e) {
        // Ignorer l'erreur d'auth, utiliser les valeurs par défaut
      }
      
      await _firestore.collection('reviews').doc(review.id).update({
        'isModerated': true,
        'isApproved': isApproving,
        'moderatorId': adminId,
        'moderatorNote': moderatorNote.isNotEmpty ? moderatorNote : null,
        'moderatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Mettre à jour le compteur de rating du produit
      if (review.productId.isNotEmpty) {
        await ReviewService.updateProductRating(review.productId);
      }

      try {
        await _auditService.log(
          userId: adminId,
          userName: adminName,
          action: 'moderate_review',
          entityType: 'review',
          entityId: review.id ?? '',
          oldValues: {'status': _getReviewStatus(review)},
          newValues: {
            'status': isApproving ? 'approved' : 'rejected',
            'note': moderatorNote,
          },
        );
      } catch (e) {
        // Ignorer l'erreur d'audit
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Avis ${isApproving ? 'approuvé' : 'rejeté'} avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmation(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'avis de "${review.userName}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(review);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(Review review) async {
    try {
      String adminId = 'unknown_admin';
      String adminName = 'Admin';
      
      try {
        final currentUser = await _authService.getCurrentUserData();
        if (currentUser != null) {
          adminId = currentUser.id ?? 'unknown_admin';
          adminName = currentUser.fullName ?? 'Admin';
        }
      } catch (e) {
        // Ignorer l'erreur d'auth
      }
      
      await _firestore.collection('reviews').doc(review.id).delete();

      try {
        await _auditService.log(
          userId: adminId,
          userName: adminName,
          action: 'delete_review',
          entityType: 'review',
          entityId: review.id ?? '',
          oldValues: {
            'review':
                '${review.userName} - Produit ${review.productId} (${review.rating}⭐)',
          },
        );
      } catch (e) {
        // Ignorer l'erreur d'audit
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
