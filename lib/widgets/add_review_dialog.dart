import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../widgets/custom_snackbar.dart';

/// Dialog pour ajouter un avis sur un produit
class AddReviewDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Function(Review)? onReviewAdded;

  const AddReviewDialog({
    Key? key,
    required this.productId,
    required this.productName,
    this.onReviewAdded,
  }) : super(key: key);

  /// Afficher le dialog
  static Future<bool?> show(
    BuildContext context, {
    required String productId,
    required String productName,
    Function(Review)? onReviewAdded,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReviewDialog(
        productId: productId,
        productName: productName,
        onReviewAdded: onReviewAdded,
      ),
    );
  }

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _hasAlreadyReviewed = false;
  bool _isVerifiedPurchase = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasReviewed = await ReviewService.hasUserReviewed(
      widget.productId,
      user.uid,
    );

    final hasPurchased = await ReviewService.hasUserPurchased(
      widget.productId,
      user.uid,
    );

    if (mounted) {
      setState(() {
        _hasAlreadyReviewed = hasReviewed;
        _isVerifiedPurchase = hasPurchased;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      CustomSnackBar.show(
        context,
        message: 'Veuillez donner une note',
        type: SnackBarType.warning,
      );
      return;
    }

    if (_commentController.text.trim().length < 10) {
      CustomSnackBar.show(
        context,
        message: 'Votre avis doit contenir au moins 10 caractères',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    String? errorMessage;
    bool success = false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final reviewId = await ReviewService.addReview(
        productId: widget.productId,
        userId: user.uid,
        userName: user.displayName ?? 'Client',
        userPhotoUrl: user.photoURL,
        rating: _rating,
        comment: _commentController.text.trim(),
        isVerifiedPurchase: _isVerifiedPurchase,
      );

      // Créer l'objet Review pour le callback
      final newReview = Review(
        id: reviewId,
        productId: widget.productId,
        userId: user.uid,
        userName: user.displayName ?? 'Client',
        userPhotoUrl: user.photoURL,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        isVerifiedPurchase: _isVerifiedPurchase,
      );

      widget.onReviewAdded?.call(newReview);
      success = true;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Fermer le dialog dans tous les cas
    if (mounted) {
      Navigator.pop(context, success);
      
      // Attendre que le dialog soit fermé avant d'afficher le message
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (context.mounted) {
        if (success) {
          CustomSnackBar.show(
            context,
            message: 'Merci pour votre avis ! Il sera publié après modération.',
            type: SnackBarType.success,
          );
        } else if (errorMessage != null) {
          CustomSnackBar.error(context, 'Erreur: $errorMessage');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.rate_review_outlined,
                      color: AppTheme.primaryViolet,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Donner votre avis',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Message si déjà avis
              if (_hasAlreadyReviewed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous avez déjà laissé un avis pour ce produit.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Badge achat vérifié
              if (_isVerifiedPurchase) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Achat vérifié',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Sélection de la note
              Text(
                'Votre note',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildRatingSelector(),

              const SizedBox(height: 24),

              // Commentaire
              Text(
                'Votre avis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience avec ce produit...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryViolet, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _hasAlreadyReviewed || _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_rounded),
                            SizedBox(width: 10),
                            Text(
                              'Publier mon avis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Note informative
              Text(
                'Votre avis sera publié après vérification par notre équipe.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélecteur d'étoiles animé
  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= _rating;

        return GestureDetector(
          onTap: () => setState(() => _rating = starNumber),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            child: AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: isSelected ? Colors.amber : AppTheme.grey400,
              ),
            ),
          ),
        );
      }),
    );
  }
}
