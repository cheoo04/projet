import 'package:flutter/material.dart';
import '../web_config/responsive_config.dart';

/// Wrapper responsive pour les écrans de l'app.
/// 
/// Le DesktopHeader est géré par AppShell (StatefulShellRoute) — 
/// ResponsiveScaffold ne l'affiche plus pour éviter les doublons.
/// Sur desktop, le contenu est centré avec maxWidth.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  // Conservé pour compatibilité avec les appels existants, mais ignoré
  // ignore: unused_field
  final bool showDesktopHeader;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showDesktopHeader = true, // ignoré — AppShell gère le header
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      // Sur desktop : centrer le contenu avec maxWidth, sans header (AppShell s'en charge)
      return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.maxContentWidth(context),
            ),
            child: body,
          ),
        ),
      );
    }

    // Sur mobile/tablette : scaffold standard
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}