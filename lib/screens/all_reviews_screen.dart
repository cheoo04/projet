import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/review.dart';
import '../models/product.dart';
import '../services/review_service.dart';
import '../widgets/trust_signal_card.dart';
import '../widgets/add_review_dialog.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/safe_network_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Écran affichant tous les avis d'un produit
class AllReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double? averageRating;
  final int? totalReviews;
  final Map<int, int>? distribution;

  const AllReviewsScreen({
    Key? key,
    required this.productId,
    required this.productName,
    this.averageRating,
    this.totalReviews,
    this.distribution,
  }) : super(key: key);

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'recent'; // 'recent', 'helpful', 'highRating', 'lowRating'
  int? _filterRating; // null = tous, 1-5 = filtrer par note

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await ReviewService.fetchProductReviews(
        widget.productId,
        limit: 100,
        approvedOnly: true,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Review> get _filteredAndSortedReviews {
    var result = List<Review>.from(_reviews);

    // Filtrer par note si sélectionné
    if (_filterRating != null) {
      result = result.where((r) => r.rating == _filterRating).toList();
    }

    // Trier
    switch (_sortBy) {
      case 'helpful':
        result.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
      case 'highRating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowRating':
        result.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'recent':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  Future<void> _openAddReviewDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text('Connectez-vous pour laisser un avis.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        Navigator.pushNamed(context, '/auth');
      }
      return;
    }

    final result = await AddReviewDialog.show(
      context,
      productId: widget.productId,
      productName: widget.productName,
      onReviewAdded: (review) {
        // L'avis sera visible après modération
      },
    );

    if (result == true) {
      // Rafraîchir la liste (même si le nouvel avis est en modération)
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.grey50,
      appBar: AppBar(
        title: Text('Avis clients'),
        backgroundColor: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filtrer et trier',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(theme, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReviewDialog,
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Écrire un avis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Erreur lors du chargement'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadReviews,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    final filteredReviews = _filteredAndSortedReviews;

    return CustomScrollView(
      slivers: [
        // En-tête avec résumé
        SliverToBoxAdapter(
          child: _buildSummaryHeader(theme, isDark),
        ),

        // Filtres actifs
        if (_filterRating != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('$_filterRating étoiles'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _filterRating = null),
                    backgroundColor: AppTheme.primaryViolet.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppTheme.primaryViolet),
                  ),
                ],
              ),
            ),
          ),

        // Message si aucun avis
        if (filteredReviews.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterRating != null
                        ? 'Aucun avis avec $_filterRating étoile${_filterRating! > 1 ? 's' : ''}'
                        : 'Aucun avis pour ce produit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier à donner votre avis !',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Liste des avis
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = filteredReviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildReviewCard(review, theme, isDark),
                  );
                },
                childCount: filteredReviews.length,
              ),
            ),
          ),

        // Espace pour le FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, bool isDark) {
    // Toujours calculer les vraies statistiques depuis les avis récupérés
    final distribution = _calculateDistribution();
    final totalReviews = _reviews.length;
    final avgRating = totalReviews > 0 
        ? _reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews 
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
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
        children: [
          // Nom du produit
          Text(
            widget.productName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note moyenne
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryViolet,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingStars(
                      rating: avgRating,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalReviews avis',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Distribution
              Expanded(
                flex: 3,
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = distribution[star] ?? 0;
                    final percentage = totalReviews > 0 
                        ? count / totalReviews 
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _filterRating = _filterRating == star ? null : star;
                        }),
                        child: Row(
                          children: [
                            Text(
                              '$star',
                              style: TextStyle(
                                fontSize: 12,
                                color: _filterRating == star 
                                    ? AppTheme.primaryViolet 
                                    : AppTheme.textSecondary,
                                fontWeight: _filterRating == star 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              size: 12,
                              color: _filterRating == star 
                                  ? AppTheme.primaryViolet 
                                  : Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: AppTheme.grey200,
                                  valueColor: AlwaysStoppedAnimation(
                                    _filterRating == star 
                                        ? AppTheme.primaryViolet 
                                        : Colors.amber,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<int, int> _calculateDistribution() {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in _reviews) {
      dist[review.rating] = (dist[review.rating] ?? 0) + 1;
    }
    return dist;
  }

  Widget _buildReviewCard(Review review, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              // Avatar
              SafeNetworkAvatar(
                imageUrl: review.userPhotoUrl,
                fallbackText: review.userName,
                radius: 20,
              ),
              const SizedBox(width: 12),

              // Nom et badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 10,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Vérifié',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Étoiles
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Commentaire
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium,
          ),

          // Images si présentes
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.imageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],

          // Réponse du vendeur
          if (review.response != null && review.response!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryViolet.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 16,
                        color: AppTheme.primaryViolet,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Réponse de Pharrell Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryViolet,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.response!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 12),
          Row(
            children: [
              // Bouton utile
              TextButton.icon(
                onPressed: () async {
                  await ReviewService.markHelpful(review.id);
                  CustomSnackBar.show(
                    context,
                    message: 'Merci pour votre retour !',
                    type: SnackBarType.success,
                  );
                },
                icon: const Icon(Icons.thumb_up_outlined, size: 18),
                label: Text(
                  review.helpfulCount > 0 
                      ? 'Utile (${review.helpfulCount})' 
                      : 'Utile',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.secondaryVioletDark 
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Trier par',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildSortOption('recent', 'Plus récents', Icons.schedule),
              _buildSortOption('helpful', 'Plus utiles', Icons.thumb_up),
              _buildSortOption('highRating', 'Meilleures notes', Icons.arrow_upward),
              _buildSortOption('lowRating', 'Notes les plus basses', Icons.arrow_downward),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryViolet : AppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryViolet : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.primaryViolet)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }
}
