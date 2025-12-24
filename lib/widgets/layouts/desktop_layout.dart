import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../web_config/responsive_config.dart';
import '../../config/app_theme.dart';

/// Layout desktop avec sidebar de navigation
/// Utilisé automatiquement quand l'écran est >= 1200px
class DesktopLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;

  const DesktopLayout({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  bool _isExpanded = true;

  // Items de navigation principale
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Accueil',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Catalogue',
      route: '/catalog',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'Panier',
      route: '/cart',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Compte',
      route: '/account',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Commandes',
      route: '/my-orders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 260 : 72,
            child: _buildSidebar(isDark),
          ),
          
          // Divider vertical
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Header desktop
                if (widget.title != null) _buildHeader(isDark),
                
                // Contenu
                Expanded(
                  child: ResponsiveContainer(
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        children: [
          // Logo / Header
          _buildSidebarHeader(isDark),
          
          const SizedBox(height: 8),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildNavItem(_navItems[i], i, isDark),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
          
          // Footer avec boutons utilitaires
          _buildSidebarFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDark) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryViolet,
                  AppTheme.primaryViolet.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pharrell Phone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Toggle sidebar
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            tooltip: _isExpanded ? 'Réduire' : 'Agrandir',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index, bool isDark) {
    final isSelected = widget.selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go(item.route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryViolet.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppTheme.primaryViolet
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  size: 24,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primaryViolet
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Aide
          _buildFooterButton(
            icon: Icons.help_outline,
            label: 'Aide',
            onTap: () => context.go('/help'),
            isDark: isDark,
          ),
          
          const SizedBox(height: 8),
          
          // Paramètres
          _buildFooterButton(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            onTap: () => context.go('/security'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 12 : 0,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: _isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          
          Text(
            widget.title ?? '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          
          const Spacer(),
          
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }
}

/// Wrapper qui applique automatiquement le layout desktop ou mobile
class AdaptiveLayout extends StatelessWidget {
  final Widget child;
  final Widget? mobileAppBar;
  final int selectedIndex;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AdaptiveLayout({
    super.key,
    required this.child,
    this.mobileAppBar,
    this.selectedIndex = 0,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      // Version mobile avec AppBar et BottomNav
      mobile: Scaffold(
        appBar: mobileAppBar != null ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: mobileAppBar!,
        ) : null,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
      
      // Version desktop avec sidebar
      desktop: DesktopLayout(
        selectedIndex: selectedIndex,
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }
}

/// Item de navigation pour la sidebar
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
