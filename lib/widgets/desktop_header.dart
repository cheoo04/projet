import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../web_config/navigation_helper.dart';

/// Header de navigation pour desktop web
/// Affiche : Logo, liens de navigation, recherche, panier, compte
class DesktopHeader extends StatefulWidget implements PreferredSizeWidget {
  final bool displaySearchBar;
  final VoidCallback? onSearchTap;

  const DesktopHeader({
    super.key,
    this.displaySearchBar = true,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);
  
  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(BuildContext context) {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Naviguer vers le catalogue avec la recherche
      context.push('/catalog', extra: {'searchQuery': query});
      _searchController.clear();
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Breakpoints simplifiés
    final showNavLinks = screenWidth >= 1300;
    final showLogoText = screenWidth >= 1150;
    final showActionLabels = screenWidth >= 1050;
    final showSearch = screenWidth >= 800;
    
    final horizontalPadding = screenWidth < 900 ? 12.0 : 24.0;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo - toujours visible
          _buildLogo(context, isDark, showText: showLogoText),
          
          const SizedBox(width: 16),
          
          // Navigation links - seulement sur grands écrans
          if (showNavLinks) 
            _buildNavLinks(context, isDark, compact: false),
          
          const Spacer(),
          
          // Search bar - flexible pour s'adapter
          if (widget.displaySearchBar && showSearch) 
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280, minWidth: 100),
                child: _buildSearchBarFlexible(context, isDark),
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Actions (panier, compte)
          _buildActions(context, isDark, showLabels: showActionLabels),
        ],
      ),
    );
  }
  
  /// Search bar flexible qui s'adapte à l'espace disponible
  Widget _buildSearchBarFlexible(BuildContext context, bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(context),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark, {bool showText = true}) {
    return InkWell(
      onTap: () => context.go('/'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryViolet,
                    AppTheme.primaryViolet.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.phone_android,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharrell Phone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                  Text(
                    'Qualité supérieure',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavLinks(BuildContext context, bool isDark, {bool compact = false}) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    
    final links = [
      {'label': 'Accueil', 'path': '/', 'icon': Icons.home_outlined},
      {'label': 'Catalogue', 'path': '/catalog', 'icon': Icons.grid_view_outlined},
      {'label': 'Promotions', 'path': '/catalog', 'extra': {'category': 'Promotions'}, 'icon': Icons.local_offer_outlined},
      {'label': 'Nouveautés', 'path': '/catalog', 'extra': {'category': 'Nouveautés'}, 'icon': Icons.fiber_new_outlined},
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: links.map((link) {
        final isActive = currentPath == link['path'] && link['extra'] == null;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
          child: TextButton(
            onPressed: () {
              if (link['extra'] != null) {
                context.push(link['path'] as String, extra: link['extra']);
              } else {
                context.go(link['path'] as String);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16, 
                vertical: compact ? 8 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: isActive 
                  ? AppTheme.primaryViolet.withOpacity(0.1) 
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  link['icon'] as IconData,
                  size: 18,
                  color: isActive 
                      ? AppTheme.primaryViolet 
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    link['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive 
                          ? AppTheme.primaryViolet 
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, {double width = 280}) {
    return Container(
      width: width,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(context),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, {bool showLabels = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panier
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return _ActionButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Panier',
              badge: cart.itemCount,
              isDark: isDark,
              showLabel: showLabels,
              onTap: () => AppNavigator.push(context, AppNavigator.cartRoute),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // Compte
        _ActionButton(
          icon: Icons.person_outline,
          label: 'Compte',
          isDark: isDark,
          showLabel: showLabels,
          onTap: () => context.push('/account'),
        ),
      ],
    );
  }
}

/// Bouton d'action avec icône et badge optionnel
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool isDark;
  final bool showLabel;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.isDark,
    this.showLabel = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
