import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_products_screen.dart';
import 'promotion_management_screen.dart';
import 'order_management_screen.dart';
import 'user_management_screen.dart';
import 'category_management_screen.dart';
import 'supplier_management_screen.dart';
import 'review_management_screen.dart';
import 'notification_management_screen.dart';
import 'advanced_analytics_screen.dart';
import 'image_management_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminProductsScreen(),
    const PromotionManagementScreen(),
    const OrderManagementScreen(),
    const UserManagementScreen(),
    const CategoryManagementScreen(),
    const SupplierManagementScreen(),
    const ReviewManagementScreen(),
    const NotificationManagementScreen(),
    const AdvancedAnalyticsScreen(),
    const ImageManagementScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard),
      label: 'Tableau de bord',
    ),
    const NavigationDestination(icon: Icon(Icons.inventory), label: 'Produits'),
    const NavigationDestination(
      icon: Icon(Icons.local_offer),
      label: 'Promotions',
    ),
    const NavigationDestination(
      icon: Icon(Icons.shopping_cart),
      label: 'Commandes',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people),
      label: 'Utilisateurs',
    ),
    const NavigationDestination(
      icon: Icon(Icons.category),
      label: 'Catégories',
    ),
    const NavigationDestination(
      icon: Icon(Icons.business),
      label: 'Fournisseurs',
    ),
    const NavigationDestination(icon: Icon(Icons.star), label: 'Avis'),
    const NavigationDestination(
      icon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const NavigationDestination(icon: Icon(Icons.image), label: 'Images'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MediaQuery.of(context).size.width < 800 ? _buildDrawer() : null,
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _destinations.take(5).toList(),
            )
          : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 800)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              extended: MediaQuery.of(context).size.width > 1200,
              destinations: _destinations
                  .map(
                    (dest) => NavigationRailDestination(
                      icon: dest.icon,
                      label: Text(dest.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pharrell Phone',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ..._destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final destination = entry.value;
            return ListTile(
              leading: destination.icon,
              title: Text(destination.label),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
