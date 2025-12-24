import 'package:flutter/material.dart';
import '../web_config/responsive_config.dart';
import 'desktop_header.dart';

/// Wrapper qui ajoute automatiquement le DesktopHeader sur desktop
/// et garde le contenu tel quel sur mobile/tablette
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showDesktopHeader;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showDesktopHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    // Sur desktop, ajouter le DesktopHeader
    if (isDesktop && showDesktopHeader) {
      return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        // Affiche aussi la barre d'actions en bas sur desktop
        bottomNavigationBar: bottomNavigationBar,
        body: Column(
          children: [
            const DesktopHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.maxContentWidth(context),
                  ),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sur mobile/tablette, utiliser le scaffold normal
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
