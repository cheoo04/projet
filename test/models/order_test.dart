import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pharrell_phone/models/order.dart';

void main() {
  group('OrderItem', () {
    test('calcule totalPrice = unitPrice * quantity', () {
      final item = OrderItem(
        productId: 'p1',
        productName: 'iPhone 13',
        unitPrice: 150000,
        quantity: 2,
      );
      expect(item.totalPrice, 300000);
    });

    test('round-trip toMap/fromMap conserve les valeurs', () {
      final item = OrderItem(
        productId: 'p1',
        productName: 'iPhone 13',
        unitPrice: 150000,
        quantity: 2,
      );
      final restored = OrderItem.fromMap(item.toMap());
      expect(restored.productId, 'p1');
      expect(restored.productName, 'iPhone 13');
      expect(restored.unitPrice, 150000);
      expect(restored.quantity, 2);
      expect(restored.totalPrice, 300000);
    });
  });

  group('OrderStatusEntry', () {
    test('round-trip toMap/fromMap conserve statut et date', () {
      final entry = OrderStatusEntry(
        status: OrderStatus.shipped,
        timestamp: DateTime(2026, 6, 17, 10, 30),
      );
      final restored = OrderStatusEntry.fromMap(entry.toMap());
      expect(restored.status, OrderStatus.shipped);
      expect(restored.timestamp, DateTime(2026, 6, 17, 10, 30));
    });

    test('fromMap accepte un Timestamp Firestore', () {
      final map = {
        'status': 'delivered',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 18)),
      };
      final entry = OrderStatusEntry.fromMap(map);
      expect(entry.status, OrderStatus.delivered);
      expect(entry.timestamp, DateTime(2026, 6, 18));
    });

    test('fromMap retombe sur "pending" si le statut est inconnu', () {
      final entry = OrderStatusEntry.fromMap({
        'status': 'inexistant',
        'timestamp': DateTime(2026, 1, 1),
      });
      expect(entry.status, OrderStatus.pending);
    });
  });

  group('Order', () {
    OrderItem sampleItem() => OrderItem(
      productId: 'p1',
      productName: 'iPhone 13',
      unitPrice: 100000,
      quantity: 1,
    );

    test('totalAmount est calculé à partir des items', () {
      final order = Order(
        id: 'o1',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem(), sampleItem()],
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 6, 19),
      );
      expect(order.totalAmount, 200000);
    });

    test('statusHistory est vide par défaut si non fourni', () {
      final order = Order(
        id: 'o1',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem()],
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 6, 19),
      );
      expect(order.statusHistory, isEmpty);
    });

    test('round-trip toMap/fromMap conserve userId et statusHistory', () {
      final order = Order(
        id: 'o1',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem()],
        status: OrderStatus.shipped,
        createdAt: DateTime(2026, 6, 19),
        statusHistory: [
          OrderStatusEntry(
            status: OrderStatus.pending,
            timestamp: DateTime(2026, 6, 19),
          ),
          OrderStatusEntry(
            status: OrderStatus.shipped,
            timestamp: DateTime(2026, 6, 20),
          ),
        ],
      );

      final restored = Order.fromMap(order.toMap(), order.id);

      expect(restored.userId, 'u1');
      expect(restored.statusHistory.length, 2);
      expect(restored.statusHistory.first.status, OrderStatus.pending);
      expect(restored.statusHistory.last.status, OrderStatus.shipped);
    });

    test('fromMap utilise "" comme userId par défaut si absent (anciennes données)', () {
      final map = {
        'customerName': 'Client',
        'customerEmail': 'a@b.ci',
        'customerPhone': '0700000000',
        'deliveryAddress': 'Abidjan',
        'items': [],
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      final order = Order.fromMap(map, 'legacy1');
      expect(order.userId, '');
      expect(order.statusHistory, isEmpty);
    });

    test('copyWith ne change pas userId si non précisé', () {
      final order = Order(
        id: 'o1',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem()],
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 6, 19),
      );
      final updated = order.copyWith(status: OrderStatus.confirmed);
      expect(updated.userId, 'u1');
      expect(updated.status, OrderStatus.confirmed);
    });

    test('round-trip toMap/fromMap conserve les champs de fidélité', () {
      final order = Order(
        id: 'o1',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem()],
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 6, 19),
        pointsRedeemed: 50,
      );
      final restored = Order.fromMap(order.toMap(), order.id);
      expect(restored.pointsRedeemed, 50);
      expect(restored.pointsCredited, false);
      expect(restored.pointsEarned, null);
    });

    test('pointsCredited et pointsEarned par défaut à false/null', () {
      final order = Order(
        id: 'o2',
        userId: 'u1',
        customerName: 'Client Test',
        customerEmail: 'client@test.ci',
        customerPhone: '0700000000',
        deliveryAddress: 'Abidjan',
        items: [sampleItem()],
        status: OrderStatus.delivered,
        createdAt: DateTime(2026, 6, 19),
      );
      expect(order.pointsCredited, false);
      expect(order.pointsEarned, null);
      expect(order.pointsRedeemed, 0);
    });
  });
}