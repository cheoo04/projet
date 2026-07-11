import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Une page de la galerie produit qui joue une vidéo.
///
/// Comportement :
/// - Démarre MUETTE (obligatoire pour l'autoplay sur navigateur web — les
///   navigateurs bloquent la lecture automatique avec son sans interaction
///   utilisateur) puis boucle tant que la page est visible.
/// - Se met en lecture/pause automatiquement selon [isActive], qui reflète
///   si cette page est la page actuellement affichée dans le PageView
///   (l'utilisateur a swipé jusqu'à elle).
/// - Un tap sur la vidéo bascule le son (comme Instagram/TikTok).
class ProductVideoPage extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const ProductVideoPage({
    super.key,
    required this.videoUrl,
    required this.isActive,
  });

  @override
  State<ProductVideoPage> createState() => _ProductVideoPageState();
}

class _ProductVideoPageState extends State<ProductVideoPage> {
  VideoPlayerController? _controller;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      // Muet par défaut : requis pour que l'autoplay fonctionne sur web.
      await controller.setVolume(0);
      if (!mounted) return;
      setState(() {});
      if (widget.isActive) {
        controller.play();
      }
    } catch (e) {
      debugPrint('❌ Erreur lecture vidéo produit: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant ProductVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (widget.isActive && !oldWidget.isActive) {
      // La page devient visible : on rejoue depuis le début.
      controller.seekTo(Duration.zero);
      controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      // La page n'est plus visible : on met en pause pour économiser
      // les ressources et éviter du son en arrière-plan.
      controller.pause();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_hasError) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white54, size: 40),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            // Badge "vidéo" en haut à gauche pour distinguer des photos
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Vidéo',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton son
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}