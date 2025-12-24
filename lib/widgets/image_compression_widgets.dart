import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/image_compression_service.dart';

/// Widget de progression de compression d'image
class ImageCompressionProgress extends StatelessWidget {
  final int current;
  final int total;
  final CompressionResult? lastResult;
  final bool isCompressing;

  const ImageCompressionProgress({
    super.key,
    required this.current,
    required this.total,
    this.lastResult,
    this.isCompressing = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryVioletDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryViolet.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              if (isCompressing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryViolet,
                  ),
                )
              else
                Icon(
                  current == total && total > 0
                      ? Icons.check_circle
                      : Icons.compress,
                  color: current == total && total > 0
                      ? Colors.green
                      : AppTheme.primaryViolet,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Text(
                isCompressing
                    ? 'Compression en cours...'
                    : current == total && total > 0
                        ? 'Compression terminée'
                        : 'Prêt à compresser',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '$current / $total',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          if (total > 0) ...[
            const SizedBox(height: 12),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? Colors.green : AppTheme.primaryViolet,
                ),
                minHeight: 6,
              ),
            ),
          ],

          // Résultat de la dernière compression
          if (lastResult != null && lastResult!.success) ...[
            const SizedBox(height: 12),
            _buildResultRow(
              'Original',
              lastResult!.originalSizeFormatted,
              Icons.image,
            ),
            const SizedBox(height: 4),
            _buildResultRow(
              'Compressé',
              lastResult!.compressedSizeFormatted,
              Icons.compress,
            ),
            const SizedBox(height: 4),
            _buildResultRow(
              'Économie',
              '${lastResult!.reductionPercent.toStringAsFixed(1)}%',
              Icons.savings,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? Colors.green : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}

/// Widget de sélection du niveau de compression
class CompressionLevelSelector extends StatelessWidget {
  final CompressionLevel selectedLevel;
  final ValueChanged<CompressionLevel> onChanged;

  const CompressionLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Niveau de compression',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: CompressionLevel.values.map((level) {
            final isSelected = level == selectedLevel;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildLevelChip(level, isSelected),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getLevelDescription(selectedLevel),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(CompressionLevel level, bool isSelected) {
    return InkWell(
      onTap: () => onChanged(level),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryViolet
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryViolet
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getLevelIcon(level),
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              _getLevelLabel(level),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelLabel(CompressionLevel level) {
    return switch (level) {
      CompressionLevel.high => 'Haute',
      CompressionLevel.medium => 'Moyenne',
      CompressionLevel.low => 'Basse',
      CompressionLevel.thumbnail => 'Mini',
    };
  }

  IconData _getLevelIcon(CompressionLevel level) {
    return switch (level) {
      CompressionLevel.high => Icons.hd,
      CompressionLevel.medium => Icons.sd,
      CompressionLevel.low => Icons.photo_size_select_small,
      CompressionLevel.thumbnail => Icons.photo_size_select_actual,
    };
  }

  String _getLevelDescription(CompressionLevel level) {
    return switch (level) {
      CompressionLevel.high =>
        'Qualité 90% • Max 2048px • Recommandé pour images principales',
      CompressionLevel.medium =>
        'Qualité 75% • Max 1200px • Bon équilibre qualité/taille',
      CompressionLevel.low =>
        'Qualité 60% • Max 800px • Upload rapide, taille réduite',
      CompressionLevel.thumbnail =>
        'Qualité 50% • Max 400px • Miniatures et aperçus',
    };
  }
}

/// Prévisualisation avant/après compression
class CompressionPreview extends StatelessWidget {
  final File? originalFile;
  final CompressionResult? result;
  final bool showComparison;

  const CompressionPreview({
    super.key,
    this.originalFile,
    this.result,
    this.showComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    if (originalFile == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Aucune image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: kIsWeb
                ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  )
                : Image.file(
                    result?.compressedFile ?? originalFile!,
                    fit: BoxFit.cover,
                  ),
          ),

          // Stats
          if (result != null && result!.success)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Avant',
                    result!.originalSizeFormatted,
                    '${result!.originalWidth}x${result!.originalHeight}',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-${result!.reductionPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _buildStat(
                    'Après',
                    result!.compressedSizeFormatted,
                    '${result!.compressedWidth}x${result!.compressedHeight}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String size, String dimensions) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          size,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          dimensions,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

/// Résumé de compression pour plusieurs images
class CompressionSummary extends StatelessWidget {
  final List<CompressionResult> results;

  const CompressionSummary({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    final successCount = results.where((r) => r.success).length;
    final totalOriginal = results.fold<int>(0, (sum, r) => sum + r.originalSize);
    final totalCompressed =
        results.fold<int>(0, (sum, r) => sum + r.compressedSize);
    final totalSavings = totalOriginal - totalCompressed;
    final avgReduction = totalOriginal > 0
        ? (1 - totalCompressed / totalOriginal) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            AppTheme.primaryViolet.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '$successCount/${results.length} images compressées',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total économisé',
                _formatSize(totalSavings),
                Icons.savings,
                Colors.green,
              ),
              _buildSummaryItem(
                'Réduction moyenne',
                '${avgReduction.toStringAsFixed(1)}%',
                Icons.trending_down,
                AppTheme.primaryViolet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
