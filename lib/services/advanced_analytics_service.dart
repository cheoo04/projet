import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order;
import '../models/order.dart';

/// Service d'analytics avancées basé sur les vraies commandes Firestore.
/// Utilise les vrais noms de champs du modèle Order :
///   - totalAmount (pas "total")
///   - unitPrice (pas "price")
///   - productName (pas de "categoryName" dans OrderItem)
///   - createdAt stocké en Timestamp
class AdvancedAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Charge les commandes d'une période depuis Firestore.
  Future<List<Order>> _fetchOrders({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snap = await _firestore
        .collection('orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt')
        .get()
        .timeout(const Duration(seconds: 15));

    return snap.docs
        .map((doc) => Order.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stats globales + par statut pour une période.
  Future<Map<String, dynamic>> getCategoryStats({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryFilter,
  }) async {
    try {
      final orders = await _fetchOrders(
          startDate: startDate, endDate: endDate);

      if (orders.isEmpty) return _emptyCategoryStats(startDate, endDate);

      double totalRevenue = 0;
      int totalOrders = orders.length;
      // On regroupe par statut puisqu'il n'y a pas de category dans OrderItem
      Map<String, Map<String, dynamic>> statusStats = {};

      for (final order in orders) {
        totalRevenue += order.totalAmount;
        final key = order.status.displayName;

        statusStats.putIfAbsent(key, () => {
          'totalRevenue': 0.0,
          'totalQuantitySold': 0,
          'totalOrders': 0,
          'averageOrderValue': 0.0,
        });

        statusStats[key]!['totalRevenue'] =
            (statusStats[key]!['totalRevenue'] as double) + order.totalAmount;
        statusStats[key]!['totalOrders'] =
            (statusStats[key]!['totalOrders'] as int) + 1;

        for (final item in order.items) {
          statusStats[key]!['totalQuantitySold'] =
              (statusStats[key]!['totalQuantitySold'] as int) + item.quantity;
        }
      }

      // Calculer moyennes
      for (final stats in statusStats.values) {
        final n = stats['totalOrders'] as int;
        if (n > 0) {
          stats['averageOrderValue'] =
              (stats['totalRevenue'] as double) / n;
        }
      }

      return {
        'period': {'startDate': startDate, 'endDate': endDate},
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'categoryStats': statusStats,
      };
    } catch (e) {
      return _emptyCategoryStats(startDate, endDate);
    }
  }

  /// Évolution des revenus et commandes dans le temps.
  Future<Map<String, dynamic>> getTimeSeriesStats({
    required DateTime startDate,
    required DateTime endDate,
    required String granularity,
    String? categoryFilter,
  }) async {
    try {
      final orders = await _fetchOrders(
          startDate: startDate, endDate: endDate);

      final Map<String, Map<String, dynamic>> periodData = {};

      for (final order in orders) {
        final key = _periodKey(order.createdAt, granularity);

        periodData.putIfAbsent(key, () => {
          'date': key,
          'revenue': 0.0,
          'orders': 0,
          'items': 0,
        });

        periodData[key]!['revenue'] =
            (periodData[key]!['revenue'] as double) + order.totalAmount;
        periodData[key]!['orders'] =
            (periodData[key]!['orders'] as int) + 1;
        periodData[key]!['items'] =
            (periodData[key]!['items'] as int) + order.items.length;
      }

      final timeSeries = periodData.values.toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      final totalRevenue = timeSeries.fold(
          0.0, (t, p) => t + (p['revenue'] as double));
      final totalOrders = timeSeries.fold(
          0, (t, p) => t + (p['orders'] as int));
      final periodsWithSales =
          timeSeries.where((p) => (p['revenue'] as double) > 0).length;

      return {
        'timeSeries': timeSeries,
        'summary': {
          'totalRevenue': totalRevenue,
          'totalOrders': totalOrders,
          'periodsWithSales': periodsWithSales,
          'averageRevenuePerPeriod':
              periodsWithSales > 0 ? totalRevenue / periodsWithSales : 0.0,
        },
      };
    } catch (e) {
      return {
        'timeSeries': [],
        'summary': {
          'totalRevenue': 0.0,
          'totalOrders': 0,
          'periodsWithSales': 0,
          'averageRevenuePerPeriod': 0.0,
        },
      };
    }
  }

  /// Analyse des tendances avec régression linéaire simple.
  Future<Map<String, dynamic>> getTrendAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryFilter,
  }) async {
    try {
      final tsData = await getTimeSeriesStats(
        startDate: startDate,
        endDate: endDate,
        granularity: 'day',
      );

      final List<Map<String, dynamic>> timeSeries =
          List<Map<String, dynamic>>.from(tsData['timeSeries'] as List);

      if (timeSeries.length < 2) return _emptyTrendAnalysis();

      final revenues =
          timeSeries.map((p) => p['revenue'] as double).toList();

      return {
        'trend': _linearRegression(revenues),
        'volatility': _volatility(revenues),
        ..._peaksAndValleys(timeSeries),
        'summary': {
          'averageRevenue': revenues.isNotEmpty
              ? revenues.reduce((a, b) => a + b) / revenues.length
              : 0.0,
        },
      };
    } catch (e) {
      return _emptyTrendAnalysis();
    }
  }

  // ── Helpers publics pour le dashboard ─────────────────────────────────

  /// Charge les stats globales pour le dashboard admin (rapide).
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final allSnap = await _firestore
          .collection('orders')
          .get()
          .timeout(const Duration(seconds: 10));

      final monthSnap = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get()
          .timeout(const Duration(seconds: 10));

      final allOrders = allSnap.docs
          .map((d) => Order.fromMap(d.data(), d.id))
          .toList();
      final monthOrders = monthSnap.docs
          .map((d) => Order.fromMap(d.data(), d.id))
          .toList();

      double totalRevenue =
          allOrders.fold(0.0, (t, o) => t + o.totalAmount);
      double monthRevenue =
          monthOrders.fold(0.0, (t, o) => t + o.totalAmount);

      final pending = allOrders
          .where((o) => o.status == OrderStatus.pending)
          .length;

      return {
        'totalOrders': allOrders.length,
        'monthOrders': monthOrders.length,
        'totalRevenue': totalRevenue,
        'monthRevenue': monthRevenue,
        'pendingOrders': pending,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'monthOrders': 0,
        'totalRevenue': 0.0,
        'monthRevenue': 0.0,
        'pendingOrders': 0,
      };
    }
  }

  // ── Méthodes utilitaires ───────────────────────────────────────────────

  Map<String, dynamic> getEmptyCategoryStats(DateTime s, DateTime e) =>
      _emptyCategoryStats(s, e);
  Map<String, dynamic> getEmptyTrendAnalysis() => _emptyTrendAnalysis();

  Map<String, dynamic> _emptyCategoryStats(DateTime s, DateTime e) => {
        'period': {'startDate': s, 'endDate': e},
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'categoryStats': <String, Map<String, dynamic>>{},
      };

  Map<String, dynamic> _emptyTrendAnalysis() => {
        'trend': {'direction': 'stable', 'strength': 'none', 'slope': 0.0},
        'volatility': {'level': 'none', 'coefficient': 0.0},
        'peaks': <dynamic>[],
        'valleys': <dynamic>[],
        'summary': {
          'averageRevenue': 0.0,
          'bestPeriod': null,
          'worstPeriod': null,
        },
      };

  String _periodKey(DateTime date, String granularity) {
    switch (granularity) {
      case 'week':
        final week =
            ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7)
                    .floor() +
                1;
        return '${date.year}-W${week.toString().padLeft(2, '0')}';
      case 'month':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      default: // day
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> _linearRegression(List<double> values) {
    if (values.length < 2) {
      return {'direction': 'stable', 'strength': 'none', 'slope': 0.0};
    }
    final n = values.length.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < values.length; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i.toDouble();
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    String direction = 'stable';
    String strength = 'none';
    if (slope > 0.1) {
      direction = 'ascending';
      strength = slope > 1.0 ? 'strong' : 'moderate';
    } else if (slope < -0.1) {
      direction = 'descending';
      strength = slope < -1.0 ? 'strong' : 'moderate';
    }
    return {'direction': direction, 'strength': strength, 'slope': slope};
  }

  Map<String, dynamic> _volatility(List<double> values) {
    if (values.length < 2) {
      return {'level': 'none', 'coefficient': 0.0};
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    final maxDev = values.map((v) => (v - mean).abs()).reduce((a, b) => a > b ? a : b);
    final cv = mean > 0 ? maxDev / mean : 0.0;
    String level = cv > 0.5 ? 'high' : cv > 0.2 ? 'moderate' : 'low';
    return {'level': level, 'coefficient': cv};
  }

  Map<String, dynamic> _peaksAndValleys(
      List<Map<String, dynamic>> series) {
    if (series.length < 3) {
      return {
        'peaks': <dynamic>[],
        'valleys': <dynamic>[],
        'summary': {'bestPeriod': null, 'worstPeriod': null},
      };
    }
    final peaks = <Map<String, dynamic>>[];
    final valleys = <Map<String, dynamic>>[];
    Map<String, dynamic>? best, worst;
    double maxR = -1, minR = double.infinity;

    for (int i = 1; i < series.length - 1; i++) {
      final prev = series[i - 1]['revenue'] as double;
      final cur = series[i]['revenue'] as double;
      final next = series[i + 1]['revenue'] as double;
      if (cur > prev && cur > next) peaks.add(series[i]);
      if (cur < prev && cur < next) valleys.add(series[i]);
      if (cur > maxR) { maxR = cur; best = series[i]; }
      if (cur < minR && cur > 0) { minR = cur; worst = series[i]; }
    }
    return {
      'peaks': peaks,
      'valleys': valleys,
      'summary': {'bestPeriod': best, 'worstPeriod': worst},
    };
  }
}