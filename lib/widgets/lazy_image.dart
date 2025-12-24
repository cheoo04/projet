import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Widget d'image avec lazy loading et placeholder shimmer
/// 
/// Charge l'image uniquement quand elle devient visible dans le viewport
/// pour économiser la bande passante et améliorer les performances web.
class LazyImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final String? heroTag;
  final double visibilityThreshold;
  
  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.heroTag,
    this.visibilityThreshold = 0.1, // 10% visible pour déclencher le chargement
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _hasLoaded = false;
  late final AnimationController _shimmerController;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImageWidget();
    
    // Ajouter le Hero tag si présent
    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  Widget _buildImageWidget() {
    // Si l'image est nulle ou vide, afficher le placeholder d'erreur
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildErrorPlaceholder();
    }
    
    return VisibilityDetector(
      key: Key('lazy_image_${widget.imageUrl}'),
      onVisibilityChanged: (info) {
        if (!_isVisible && info.visibleFraction >= widget.visibilityThreshold) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _isVisible 
              ? _buildCachedImage() 
              : _buildShimmerPlaceholder(),
        ),
      ),
    );
  }
  
  Widget _buildCachedImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.width?.toInt(),
      memCacheHeight: widget.height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      imageBuilder: (context, imageProvider) {
        // Marquer comme chargé pour arrêter l'animation
        if (!_hasLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasLoaded = true;
              });
            }
          });
        }
        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }
  
  Widget _buildShimmerPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _shimmerController.value, 0.0),
              end: Alignment(-1.0 + 2.0 * _shimmerController.value + 1.0, 0.0),
              colors: [
                widget.placeholderColor ?? Colors.grey[300]!,
                widget.placeholderColor?.withValues(alpha: 0.5) ?? Colors.grey[100]!,
                widget.placeholderColor ?? Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (widget.height ?? 48) * 0.3,
        color: Colors.grey[500],
      ),
    );
  }
}

/// Grille d'images avec lazy loading optimisé
class LazyImageGrid extends StatelessWidget {
  final List<String?> imageUrls;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final BorderRadius? borderRadius;
  final void Function(int index)? onImageTap;
  
  const LazyImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.borderRadius,
    this.onImageTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: onImageTap != null ? () => onImageTap!(index) : null,
          child: LazyImage(
            imageUrl: imageUrls[index],
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Carrousel d'images avec lazy loading
class LazyImageCarousel extends StatefulWidget {
  final List<String?> imageUrls;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final void Function(int index)? onPageChanged;
  
  const LazyImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.onPageChanged,
  });
  
  @override
  State<LazyImageCarousel> createState() => _LazyImageCarouselState();
}

class _LazyImageCarouselState extends State<LazyImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.autoPlay && widget.imageUrls.length > 1) {
      _startAutoPlay();
    }
  }
  
  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted && widget.autoPlay) {
        final nextPage = (_currentPage + 1) % widget.imageUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              return LazyImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
              );
            },
          ),
          
          // Indicateurs de page
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
