import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../config/app_theme.dart';

/// Type de toast
enum ToastType { success, error, warning, info }

/// Système de toast positionné en HAUT de l'écran.
/// - Ne bloque jamais la navigation bas
/// - File d'attente automatique (max 3 simultanés)
/// - Auto-dismiss configurable
/// - S'utilise depuis n'importe où sans BuildContext grâce à la clé globale
///
/// Usage :
///   AppToast.show(context, 'Ajouté aux favoris ❤️');
///   AppToast.success(context, 'Commande passée !');
///   AppToast.error(context, 'Connexion impossible');
class AppToast {
  static final _queue = <_ToastEntry>[];
  static bool _isShowing = false;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final entry = _ToastEntry(
      context: context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    _queue.add(entry);
    if (!_isShowing) _showNext();
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message, type: ToastType.success, actionLabel: actionLabel, onAction: onAction);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error, duration: const Duration(seconds: 4));

  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning, duration: const Duration(seconds: 3));

  static void info(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message, type: ToastType.info, actionLabel: actionLabel, onAction: onAction);

  static void _showNext() {
    if (_queue.isEmpty) { _isShowing = false; return; }
    _isShowing = true;
    final entry = _queue.removeAt(0);
    _displayToast(entry);
  }

  static void _displayToast(_ToastEntry entry) {
    if (!entry.context.mounted) { _showNext(); return; }

    late OverlayEntry overlayEntry;
    final controller = AnimationController(
      vsync: _TickerProviderImpl(),
      duration: const Duration(milliseconds: 280),
    );
    final anim = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);

    overlayEntry = OverlayEntry(
      builder: (_) => _ToastWidget(
        entry: entry,
        animation: anim,
        onDismiss: () {
          controller.reverse().then((_) {
            overlayEntry.remove();
            controller.dispose();
            Future.delayed(const Duration(milliseconds: 80), _showNext);
          });
        },
      ),
    );

    final overlay = Overlay.of(entry.context);
    overlay.insert(overlayEntry);
    controller.forward();

    Timer(entry.duration, () {
      if (overlayEntry.mounted) {
        controller.reverse().then((_) {
          if (overlayEntry.mounted) overlayEntry.remove();
          controller.dispose();
          Future.delayed(const Duration(milliseconds: 80), _showNext);
        });
      }
    });
  }
}

class _ToastEntry {
  final BuildContext context;
  final String message;
  final ToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  _ToastEntry({
    required this.context, required this.message, required this.type,
    required this.duration, this.actionLabel, this.onAction,
  });
}

class _ToastWidget extends StatelessWidget {
  final _ToastEntry entry;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  const _ToastWidget({required this.entry, required this.animation, required this.onDismiss});

  Color get _bg {
    switch (entry.type) {
      case ToastType.success: return const Color(0xFF2E7D32);
      case ToastType.error:   return const Color(0xFFC62828);
      case ToastType.warning: return const Color(0xFFEF6C00);
      case ToastType.info:    return AppTheme.primaryViolet;
    }
  }

  IconData get _icon {
    switch (entry.type) {
      case ToastType.success: return Icons.check_circle_rounded;
      case ToastType.error:   return Icons.error_rounded;
      case ToastType.warning: return Icons.warning_rounded;
      case ToastType.info:    return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
              .animate(animation),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _bg.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Icon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.message,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  if (entry.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () { entry.onAction?.call(); onDismiss(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(entry.actionLabel!,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// TickerProvider minimal pour les animations hors-widget
class _TickerProviderImpl extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}