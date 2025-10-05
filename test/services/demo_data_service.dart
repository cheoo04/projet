import 'package:pharrell_phone/models/product.dart';
import 'package:pharrell_phone/models/promotion.dart';
import 'package:pharrell_phone/models/order.dart';
import 'package:pharrell_phone/models/app_user.dart';
import 'package:pharrell_phone/models/category.dart';

class DemoDataService {
  static List<Product> getDemoProducts() {
    return [
      Product(
        id: '1',
        name: 'iPhone 15 Pro',
        description: 'Le dernier iPhone avec puce A17 Pro',
        price: 1229.0,
        brand: 'Apple',
        imageUrls: [
          'https://via.placeholder.com/400x400/007AFF/FFFFFF?text=iPhone+15+Pro',
        ],
        category: 'Smartphones',
        stock: 50,
        isInStock: true,
      ),
      Product(
        id: '2',
        name: 'Samsung Galaxy S24',
        description: 'Smartphone Android haut de gamme',
        price: 899.0,
        brand: 'Samsung',
        imageUrls: [
          'https://via.placeholder.com/400x400/1976D2/FFFFFF?text=Galaxy+S24',
        ],
        category: 'Smartphones',
        stock: 30,
        isInStock: true,
      ),
      Product(
        id: '3',
        name: 'AirPods Pro 2',
        description: 'Écouteurs sans fil avec réduction de bruit',
        price: 279.0,
        brand: 'Apple',
        imageUrls: [
          'https://via.placeholder.com/400x400/FF5722/FFFFFF?text=AirPods+Pro',
        ],
        category: 'Accessoires',
        stock: 100,
        isInStock: true,
      ),
    ];
  }

  static List<Promotion> getDemoPromotions() {
    return [
      Promotion(
        id: '1',
        name: 'Promo Rentrée',
        description: 'Réduction pour la rentrée scolaire',
        productIds: ['1', '2'],
        type: 'percentage',
        value: 15.0,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 23)),
        isActive: true,
      ),
      Promotion(
        id: '2',
        name: 'Black Friday',
        description: 'Offre spéciale Black Friday',
        productIds: ['1', '2', '3'],
        type: 'fixed',
        value: 100.0,
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 37)),
        isActive: false,
      ),
    ];
  }

  static List<Order> getDemoOrders() {
    return [
      Order(
        id: '1',
        customerName: 'John Doe',
        customerEmail: 'john.doe@example.com',
        customerPhone: '+33 1 23 45 67 89',
        deliveryAddress: '123 Rue de la Paix, 75001 Paris',
        items: [
          OrderItem(
            productId: '1',
            productName: 'iPhone 15 Pro',
            quantity: 1,
            unitPrice: 1229.0,
          ),
        ],
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Order(
        id: '2',
        customerName: 'Jane Smith',
        customerEmail: 'jane.smith@example.com',
        customerPhone: '+33 1 98 76 54 32',
        deliveryAddress: '456 Avenue des Champs-Élysées, 75008 Paris',
        items: [
          OrderItem(
            productId: '2',
            productName: 'Samsung Galaxy S24',
            quantity: 1,
            unitPrice: 899.0,
          ),
          OrderItem(
            productId: '3',
            productName: 'AirPods Pro 2',
            quantity: 2,
            unitPrice: 279.0,
          ),
        ],
        status: OrderStatus.shipped,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<AppUser> getDemoUsers() {
    return [
      AppUser(
        id: 'user1',
        email: 'john.doe@example.com',
        firstName: 'John',
        lastName: 'Doe',
        phone: '+33 1 23 45 67 89',
        address: '123 Rue de la Paix, 75001 Paris',
        role: UserRole.client,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'user2',
        email: 'jane.smith@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        phone: '+33 1 98 76 54 32',
        address: '456 Avenue des Champs-Élysées, 75008 Paris',
        role: UserRole.client,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      AppUser(
        id: 'admin1',
        email: 'admin@pharrellphone.com',
        firstName: 'Admin',
        lastName: 'User',
        phone: '+33 1 11 22 33 44',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      ),
    ];
  }

  static List<Category> getDemoCategories() {
    return [
      Category(
        id: '1',
        name: 'Smartphones',
        description: 'Téléphones intelligents de toutes marques',
        imageUrl:
            'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Smartphones',
        iconName: 'smartphone',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        productCount: 15,
      ),
      Category(
        id: '2',
        name: 'Accessoires',
        description: 'Accessoires pour téléphones',
        imageUrl:
            'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Accessoires',
        iconName: 'headphones',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        productCount: 8,
      ),
      Category(
        id: '3',
        name: 'Coques',
        description: 'Protections pour smartphones',
        imageUrl:
            'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Coques',
        iconName: 'phone_case',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        productCount: 5,
      ),
    ];
  }

  static Map<String, dynamic> getDemoAnalytics() {
    return {
      'totalRevenue': 15750.0,
      'totalOrders': 125,
      'totalProducts': 45,
      'activeUsers': 1250,
      'monthlyGrowth': 12.5,
      'topProducts': [
        {'name': 'iPhone 15 Pro', 'sales': 45},
        {'name': 'Samsung Galaxy S24', 'sales': 32},
        {'name': 'AirPods Pro 2', 'sales': 28},
      ],
      'recentOrders': getDemoOrders(),
      'salesByMonth': [
        {'month': 'Jan', 'sales': 12000},
        {'month': 'Fev', 'sales': 15000},
        {'month': 'Mar', 'sales': 18000},
        {'month': 'Avr', 'sales': 16000},
        {'month': 'Mai', 'sales': 20000},
        {'month': 'Jun', 'sales': 22000},
      ],
    };
  }

  static List<Map<String, dynamic>> getDemoNotifications() {
    return [
      {
        'id': '1',
        'title': 'Nouvelle commande',
        'message': 'Commande #1234 reçue',
        'type': 'order',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'isRead': false,
      },
      {
        'id': '2',
        'title': 'Stock faible',
        'message': 'iPhone 15 Pro - Stock: 5 unités',
        'type': 'stock',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
      },
      {
        'id': '3',
        'title': 'Nouvel avis client',
        'message': 'Avis 5⭐ sur Samsung Galaxy S24',
        'type': 'review',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'isRead': true,
      },
    ];
  }
}
