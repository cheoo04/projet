import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdvancedAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtient les statistiques par catégorie pour une période donnée
  Future<Map<String, dynamic>> getCategoryStats({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryFilter,
  }) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get()
          .timeout(const Duration(seconds: 10));

      if (ordersSnapshot.docs.isEmpty) {
        return _getEmptyCategoryStats(startDate, endDate);
      }

      Map<String, Map<String, dynamic>> categoryStats = {};
      double totalRevenue = 0;
      int totalOrders = ordersSnapshot.docs.length;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        double orderTotal = (data['total'] ?? 0).toDouble();
        totalRevenue += orderTotal;

        // Traiter les items de la commande
        List<dynamic> items = data['items'] ?? [];
        for (var item in items) {
          String categoryName = item['categoryName'] ?? 'Sans catégorie';

          // Filtrer par catégorie si nécessaire
          if (categoryFilter != null && categoryName != categoryFilter) {
            continue;
          }

          if (!categoryStats.containsKey(categoryName)) {
            categoryStats[categoryName] = {
              'totalRevenue': 0.0,
              'totalQuantitySold': 0,
              'totalOrders': 0,
              'averageOrderValue': 0.0,
            };
          }

          double itemPrice = (item['price'] ?? 0).toDouble();
          int itemQuantity = (item['quantity'] ?? 1);

          categoryStats[categoryName]!['totalRevenue'] =
              (categoryStats[categoryName]!['totalRevenue'] as double) +
              (itemPrice * itemQuantity);
          categoryStats[categoryName]!['totalQuantitySold'] =
              (categoryStats[categoryName]!['totalQuantitySold'] as int) +
              itemQuantity;
          categoryStats[categoryName]!['totalOrders'] =
              (categoryStats[categoryName]!['totalOrders'] as int) + 1;
        }
      }

      // Calculer les moyennes
      categoryStats.forEach((category, stats) {
        if ((stats['totalOrders'] as int) > 0) {
          stats['averageOrderValue'] =
              (stats['totalRevenue'] as double) / (stats['totalOrders'] as int);
        }
      });

      return {
        'period': {'startDate': startDate, 'endDate': endDate},
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      return _getEmptyCategoryStats(startDate, endDate);
    }
  }

  /// Obtient les statistiques temporelles (évolution dans le temps)
  Future<Map<String, dynamic>> getTimeSeriesStats({
    required DateTime startDate,
    required DateTime endDate,
    required String granularity,
    String? categoryFilter,
  }) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt')
          .get()
          .timeout(const Duration(seconds: 10));

      Map<String, Map<String, dynamic>> periodData = {};

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
        double orderTotal = (data['total'] ?? 0).toDouble();

        // Filtrer par catégorie si nécessaire
        if (categoryFilter != null) {
          List<dynamic> items = data['items'] ?? [];
          bool hasCategory = items.any(
            (item) => item['categoryName'] == categoryFilter,
          );
          if (!hasCategory) continue;
        }

        String periodKey = _getPeriodKey(createdAt, granularity);

        if (!periodData.containsKey(periodKey)) {
          periodData[periodKey] = {
            'date': periodKey,
            'revenue': 0.0,
            'orders': 0,
            'items': 0,
          };
        }

        periodData[periodKey]!['revenue'] =
            (periodData[periodKey]!['revenue'] as double) + orderTotal;
        periodData[periodKey]!['orders'] =
            (periodData[periodKey]!['orders'] as int) + 1;
        periodData[periodKey]!['items'] =
            (periodData[periodKey]!['items'] as int) +
            (data['items'] as List).length;
      }

      List<Map<String, dynamic>> timeSeries = periodData.values.toList();
      timeSeries.sort((a, b) => a['date'].compareTo(b['date']));

      double totalRevenue = timeSeries.fold(
        0.0,
        (total, period) => total + (period['revenue'] as double),
      );
      int totalOrders = timeSeries.fold(
        0,
        (total, period) => total + (period['orders'] as int),
      );
      int periodsWithSales = timeSeries
          .where((period) => (period['revenue'] as double) > 0)
          .length;

      return {
        'timeSeries': timeSeries,
        'summary': {
          'totalRevenue': totalRevenue,
          'totalOrders': totalOrders,
          'periodsWithSales': periodsWithSales,
          'averageRevenuePerPeriod': periodsWithSales > 0
              ? totalRevenue / periodsWithSales
              : 0.0,
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

  /// Analyse des tendances avec régression linéaire simple
  Future<Map<String, dynamic>> getTrendAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryFilter,
  }) async {
    try {
      final timeSeriesData = await getTimeSeriesStats(
        startDate: startDate,
        endDate: endDate,
        granularity: 'day',
        categoryFilter: categoryFilter,
      );

      List<Map<String, dynamic>> timeSeries = timeSeriesData['timeSeries'];

      if (timeSeries.length < 2) {
        return _getEmptyTrendAnalysis();
      }

      List<double> revenues = timeSeries
          .map((period) => period['revenue'] as double)
          .toList();
      Map<String, dynamic> trendAnalysis = _calculateLinearRegression(revenues);
      Map<String, dynamic> volatilityAnalysis = _calculateVolatility(revenues);
      Map<String, dynamic> peaksAndValleys = _findPeaksAndValleys(timeSeries);

      return {
        'trend': trendAnalysis,
        'volatility': volatilityAnalysis,
        'peaks': peaksAndValleys['peaks'],
        'valleys': peaksAndValleys['valleys'],
        'summary': {
          'averageRevenue': revenues.isNotEmpty
              ? revenues.reduce((a, b) => a + b) / revenues.length
              : 0.0,
          'bestPeriod': peaksAndValleys['bestPeriod'],
          'worstPeriod': peaksAndValleys['worstPeriod'],
        },
      };
    } catch (e) {
      // Erreur dans getTrendAnalysis: $e
      return _getEmptyTrendAnalysis();
    }
  }

  // Méthodes utilitaires

  Map<String, dynamic> getEmptyCategoryStats(
    DateTime startDate,
    DateTime endDate,
  ) {
    return {
      'period': {'startDate': startDate, 'endDate': endDate},
      'totalRevenue': 0.0,
      'totalOrders': 0,
      'categoryStats': <String, Map<String, dynamic>>{},
    };
  }

  Map<String, dynamic> getEmptyTrendAnalysis() {
    return {
      'trend': {'direction': 'stable', 'strength': 'none'},
      'volatility': {'level': 'none'},
      'peaks': [],
      'valleys': [],
      'summary': {
        'averageRevenue': 0.0,
        'bestPeriod': null,
        'worstPeriod': null,
      },
    };
  }

  Map<String, dynamic> _getEmptyCategoryStats(
    DateTime startDate,
    DateTime endDate,
  ) {
    return getEmptyCategoryStats(startDate, endDate);
  }

  Map<String, dynamic> _getEmptyTrendAnalysis() {
    return getEmptyTrendAnalysis();
  }

  String _getPeriodKey(DateTime date, String granularity) {
    switch (granularity) {
      case 'day':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'week':
        int weekOfYear =
            ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor() +
            1;
        return '${date.year}-W${weekOfYear.toString().padLeft(2, '0')}';
      case 'month':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      default:
        return date.toIso8601String().split('T')[0];
    }
  }

  Map<String, dynamic> _calculateLinearRegression(List<double> values) {
    if (values.length < 2) {
      return {'direction': 'stable', 'strength': 'none', 'slope': 0.0};
    }

    double n = values.length.toDouble();
    List<double> x = List.generate(values.length, (index) => index.toDouble());

    double sumX = x.reduce((a, b) => a + b);
    double sumY = values.reduce((a, b) => a + b);
    double sumXY = 0.0;
    double sumX2 = 0.0;

    for (int i = 0; i < values.length; i++) {
      sumXY += x[i] * values[i];
      sumX2 += x[i] * x[i];
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

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

  Map<String, dynamic> _calculateVolatility(List<double> values) {
    if (values.length < 2) {
      return {'level': 'none', 'coefficient': 0.0};
    }

    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance =
        values
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        values.length;

    double standardDeviation = variance > 0
        ? values
              .map((value) => (value - mean).abs())
              .reduce((a, b) => a > b ? a : b)
        : 0.0;

    double coefficientOfVariation = mean > 0 ? standardDeviation / mean : 0.0;

    String level = 'low';
    if (coefficientOfVariation > 0.5) {
      level = 'high';
    } else if (coefficientOfVariation > 0.2) {
      level = 'moderate';
    }

    return {'level': level, 'coefficient': coefficientOfVariation};
  }

  Map<String, dynamic> _findPeaksAndValleys(
    List<Map<String, dynamic>> timeSeries,
  ) {
    if (timeSeries.length < 3) {
      return {
        'peaks': [],
        'valleys': [],
        'bestPeriod': null,
        'worstPeriod': null,
      };
    }

    List<Map<String, dynamic>> peaks = [];
    List<Map<String, dynamic>> valleys = [];

    Map<String, dynamic>? bestPeriod;
    Map<String, dynamic>? worstPeriod;
    double maxRevenue = -1;
    double minRevenue = double.infinity;

    for (int i = 1; i < timeSeries.length - 1; i++) {
      double prev = timeSeries[i - 1]['revenue'] as double;
      double current = timeSeries[i]['revenue'] as double;
      double next = timeSeries[i + 1]['revenue'] as double;

      if (current > prev && current > next) {
        peaks.add(timeSeries[i]);
      }

      if (current < prev && current < next) {
        valleys.add(timeSeries[i]);
      }

      if (current > maxRevenue) {
        maxRevenue = current;
        bestPeriod = timeSeries[i];
      }

      if (current < minRevenue && current > 0) {
        minRevenue = current;
        worstPeriod = timeSeries[i];
      }
    }

    return {
      'peaks': peaks,
      'valleys': valleys,
      'bestPeriod': bestPeriod,
      'worstPeriod': worstPeriod,
    };
  }
}
