/// Wrappers pour les écrans admin.
/// Anciennement basé sur le deferred loading (code splitting),
/// maintenant en imports directs pour éviter DeferredLoadException au rechargement.
library;

import 'package:flutter/material.dart';
import 'modern_admin_screens.dart';
import 'modern_admin_navigation.dart';
import 'modern_admin_products_screen.dart';
import 'modern_stock_management_screen.dart';
import 'modern_order_management_screen.dart';
import 'modern_category_management_screen.dart';
import 'promotion_management_screen.dart';
import 'user_management_screen.dart';
import 'supplier_management_screen.dart';
import 'image_management_screen.dart';
import 'review_management_screen.dart';
import 'advanced_analytics_screen.dart';

/// Wrappers directs — anciennement deferred, maintenant imports directs
class DeferredAdminDashboard extends StatelessWidget {
  const DeferredAdminDashboard({super.key});
  @override
  Widget build(BuildContext context) => const ModernAdminDashboardScreen();
}

class DeferredAdminLogin extends StatelessWidget {
  const DeferredAdminLogin({super.key});
  @override
  Widget build(BuildContext context) => const ModernAdminLoginScreen();
}

class DeferredAdminNavigation extends StatelessWidget {
  const DeferredAdminNavigation({super.key});
  @override
  Widget build(BuildContext context) => const ModernAdminNavigation();
}

class DeferredAdminProducts extends StatelessWidget {
  const DeferredAdminProducts({super.key});
  @override
  Widget build(BuildContext context) => const ModernAdminProductsScreen();
}

class DeferredAdminStock extends StatelessWidget {
  const DeferredAdminStock({super.key});
  @override
  Widget build(BuildContext context) => const ModernStockManagementScreen();
}

class DeferredAdminOrders extends StatelessWidget {
  const DeferredAdminOrders({super.key});
  @override
  Widget build(BuildContext context) => const ModernOrderManagementScreen();
}

class DeferredAdminCategories extends StatelessWidget {
  const DeferredAdminCategories({super.key});
  @override
  Widget build(BuildContext context) => const ModernCategoryManagementScreen();
}

class DeferredAdminPromotions extends StatelessWidget {
  const DeferredAdminPromotions({super.key});
  @override
  Widget build(BuildContext context) => const PromotionManagementScreen();
}

class DeferredAdminUsers extends StatelessWidget {
  const DeferredAdminUsers({super.key});
  @override
  Widget build(BuildContext context) => const UserManagementScreen();
}

class DeferredAdminSuppliers extends StatelessWidget {
  const DeferredAdminSuppliers({super.key});
  @override
  Widget build(BuildContext context) => const SupplierManagementScreen();
}

class DeferredAdminImages extends StatelessWidget {
  const DeferredAdminImages({super.key});
  @override
  Widget build(BuildContext context) => const ImageManagementScreen();
}

class DeferredAdminReviews extends StatelessWidget {
  const DeferredAdminReviews({super.key});
  @override
  Widget build(BuildContext context) => const ReviewManagementScreen();
}

class DeferredAdminAnalytics extends StatelessWidget {
  const DeferredAdminAnalytics({super.key});
  @override
  Widget build(BuildContext context) => const AdvancedAnalyticsScreen();
}