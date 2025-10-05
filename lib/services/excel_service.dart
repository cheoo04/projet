import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'stock_service.dart';

class ExcelService {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final StockService _stockService = StockService();
  static bool _localeInitialized = false;

  // Exporter toutes les commandes
  Future<String> exportAllOrders() async {
    final orders = await _orderService.fetchAll();
    return _createExcelFile(orders, 'commandes_toutes');
  }

  // Exporter les commandes par statut
  Future<String> exportOrdersByStatus(OrderStatus status) async {
    final orders = await _orderService.fetchByStatus(status);
    final fileName = 'commandes_${status.name}';
    return _createExcelFile(orders, fileName);
  }

  // Exporter les commandes par période
  Future<String> exportOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final orders = await _orderService.fetchByDateRange(startDate, endDate);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final fileName =
        'commandes_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}';
    return _createExcelFile(orders, fileName);
  }

  // Exporter le rapport mensuel - VERSION OPTIMISÉE
  Future<String> exportMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final orders = await _orderService.fetchByDateRange(startDate, endDate);

    if (!_localeInitialized) {
      try {
        await initializeDateFormatting('fr');
        _localeInitialized = true;
      } catch (_) {
        /* fallback silent */
      }
    }

    String monthName;
    try {
      monthName = DateFormat('MMMM_yyyy', 'fr').format(startDate);
    } catch (_) {
      monthName = DateFormat('MMMM_yyyy').format(startDate);
    }

    return _createMonthlyReportExcel(orders, 'rapport_$monthName');
  }

  // Créer le fichier Excel standard
  Future<String> _createExcelFile(List<Order> orders, String fileName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Commandes'];

    // Headers
    final headers = [
      'ID Commande',
      'Date',
      'Client',
      'Email',
      'Téléphone',
      'Adresse',
      'Statut',
      'Nb Articles',
      'Montant Total',
      'Notes',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      final rowIndex = i + 1;

      final rowValues = [
        order.id,
        dateFormat.format(order.createdAt),
        order.customerName,
        order.customerEmail,
        order.customerPhone,
        order.deliveryAddress,
        order.status.displayName,
        order.items.length,
        order.totalAmount,
        order.notes ?? '',
      ];

      for (int j = 0; j < rowValues.length; j++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: j,
                    rowIndex: rowIndex,
                  ),
                )
                .value =
            rowValues[j];
      }

      if (i % 2 == 1) {
        final rowStyle = CellStyle(backgroundColorHex: '#ECEFF1');
        for (int j = 0; j < headers.length; j++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: j,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              rowStyle;
        }
      }
    }

    // Ajouter une feuille détaillée des articles
    _addDetailedItemsSheet(excel, orders);

    // Sauvegarder le fichier
    return await _saveExcelFile(excel, fileName);
  }

  // Créer le rapport mensuel avec statistiques - VERSION OPTIMISÉE
  Future<String> _createMonthlyReportExcel(
    List<Order> orders,
    String fileName,
  ) async {
    final excel = Excel.createExcel();

    // Feuille principale avec résumé
    _createSummarySheet(excel, orders);

    // Pause pour permettre à l'UI de respirer
    await Future.delayed(const Duration(milliseconds: 50));

    // Feuille détaillée des commandes - version optimisée
    await _createOrdersSheetOptimized(excel, orders);

    // Pause pour permettre à l'UI de respirer
    await Future.delayed(const Duration(milliseconds: 50));

    // Feuille des produits les plus vendus - version optimisée
    await _createTopProductsSheetOptimized(excel, orders);

    return await _saveExcelFile(excel, fileName);
  }

  void _createSummarySheet(Excel excel, List<Order> orders) {
    final sheet = excel['Résumé'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#2196F3',
      fontColorHex: '#FFFFFF',
    );

    // Statistiques générales
    sheet.cell(CellIndex.indexByString('A1')).value =
        'RAPPORT MENSUEL - RÉSUMÉ';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

    final stats = _calculateStats(orders);
    int row = 3;

    stats.forEach((key, value) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
              .value =
          key;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
              .value =
          value;
      row++;
    });

    // Répartition par statut
    sheet.cell(CellIndex.indexByString('D1')).value = 'RÉPARTITION PAR STATUT';
    sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByString('D2')).value = 'Statut';
    sheet.cell(CellIndex.indexByString('E2')).value = 'Nombre';

    row = 3;
    for (final status in OrderStatus.values) {
      final count = orders.where((o) => o.status == status).length;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
              .value =
          status.displayName;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value =
          count;
      row++;
    }
  }

  // Version optimisée de _createOrdersSheet avec pauses
  Future<void> _createOrdersSheetOptimized(
    Excel excel,
    List<Order> orders,
  ) async {
    const sheetName = 'Commandes Détaillées';
    if (excel.sheets.containsKey('Sheet1')) {
      try {
        excel.rename('Sheet1', sheetName);
      } catch (_) {
        // Si le renommage échoue, on continue
      }
    }
    final sheet = excel[sheetName];

    final headers = [
      'ID',
      'Date',
      'Client',
      'Email',
      'Téléphone',
      'Adresse',
      'Statut',
      'Nb Articles',
      'Montant Total',
      'Notes',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Traiter les commandes par lots pour éviter de bloquer l'UI
    const batchSize = 25;
    for (int start = 0; start < orders.length; start += batchSize) {
      final end = (start + batchSize < orders.length)
          ? start + batchSize
          : orders.length;
      final batch = orders.sublist(start, end);

      for (int i = 0; i < batch.length; i++) {
        final order = batch[i];
        final row = start + i + 1;

        final rowValues = [
          order.id,
          dateFormat.format(order.createdAt),
          order.customerName,
          order.customerEmail,
          order.customerPhone,
          order.deliveryAddress,
          order.status.displayName,
          order.items.length,
          order.totalAmount,
          order.notes ?? '',
        ];

        for (int c = 0; c < rowValues.length; c++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
                  )
                  .value =
              rowValues[c];
        }

        if (row % 2 == 1) {
          final alt = CellStyle(backgroundColorHex: '#ECEFF1');
          for (int c = 0; c < headers.length; c++) {
            sheet
                    .cell(
                      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
                    )
                    .cellStyle =
                alt;
          }
        }
      }

      // Pause après chaque lot pour permettre à l'UI de se mettre à jour
      if (start + batchSize < orders.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  // Version optimisée de _createTopProductsSheet avec pauses
  Future<void> _createTopProductsSheetOptimized(
    Excel excel,
    List<Order> orders,
  ) async {
    final sheet = excel['Top Produits'];

    // Calculer les produits les plus vendus de manière optimisée
    final productStats = <String, Map<String, dynamic>>{};

    // Traiter les commandes par lots
    const batchSize = 30;
    for (int start = 0; start < orders.length; start += batchSize) {
      final end = (start + batchSize < orders.length)
          ? start + batchSize
          : orders.length;
      final batch = orders.sublist(start, end);

      for (final order in batch) {
        for (final item in order.items) {
          if (productStats.containsKey(item.productId)) {
            productStats[item.productId]!['quantity'] += item.quantity;
            productStats[item.productId]!['revenue'] += item.totalPrice;
          } else {
            productStats[item.productId] = {
              'name': item.productName,
              'quantity': item.quantity,
              'revenue': item.totalPrice,
            };
          }
        }
      }

      // Pause après chaque lot
      if (start + batchSize < orders.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // Trier par quantité vendue
    final sortedProducts = productStats.entries.toList()
      ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

    // Headers
    final headers = ['Produit', 'Quantité Vendue', 'Chiffre d\'Affaires'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#FF9800',
        fontColorHex: '#FFFFFF',
      );
    }

    // Données (top 20)
    for (int i = 0; i < sortedProducts.length && i < 20; i++) {
      final product = sortedProducts[i];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
              .value =
          product.value['name'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
              .value =
          product.value['quantity'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
              .value =
          product.value['revenue'];
    }
  }

  void _addDetailedItemsSheet(Excel excel, List<Order> orders) {
    final sheet = excel['Détail Articles'];

    final headers = [
      'ID Commande',
      'Date',
      'Client',
      'Produit',
      'Prix Unitaire',
      'Quantité',
      'Total',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#9C27B0',
        fontColorHex: '#FFFFFF',
      );
    }

    int rowIndex = 1;
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final order in orders) {
      for (final item in order.items) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = order
            .id;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = dateFormat.format(
          order.createdAt,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = order
            .customerName;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = item
            .productName;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = item
            .unitPrice;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = item
            .quantity;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = item
            .totalPrice;
        rowIndex++;
      }
    }
  }

  Map<String, dynamic> _calculateStats(List<Order> orders) {
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    final totalItems = orders.fold<int>(
      0,
      (sum, order) => sum + order.items.length,
    );

    return {
      'Nombre total de commandes': totalOrders,
      'Chiffre d\'affaires total': '${totalRevenue.toStringAsFixed(2)} FCFA',
      'Valeur moyenne par commande':
          '${averageOrderValue.toStringAsFixed(2)} FCFA',
      'Nombre total d\'articles': totalItems,
    };
  }

  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${fileName}_$timestamp.xlsx');

    final bytes = excel.encode()!;
    await file.writeAsBytes(bytes);

    return file.path;
  }

  // ========== GESTION DES PRODUITS ==========

  /// Exporter tous les produits avec leurs stocks
  Future<String> exportAllProducts() async {
    try {
      final products = await _productService.fetchAll();
      return await _createProductsExcelFile(products, 'produits_complet');
    } catch (e) {
      throw Exception('Erreur lors de l\'export des produits: $e');
    }
  }

  /// Exporter les produits avec stock faible
  Future<String> exportLowStockProducts() async {
    try {
      final products = await _productService.getLowStockProducts();
      return await _createProductsExcelFile(products, 'produits_stock_faible');
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'export des produits à stock faible: $e',
      );
    }
  }

  /// Exporter les produits en rupture de stock
  Future<String> exportOutOfStockProducts() async {
    try {
      final products = await _productService.getOutOfStockProducts();
      return await _createProductsExcelFile(products, 'produits_rupture_stock');
    } catch (e) {
      throw Exception('Erreur lors de l\'export des produits en rupture: $e');
    }
  }

  /// Exporter l'historique des mouvements de stock
  Future<String> exportStockMovements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<StockMovement> movements;

      if (startDate != null && endDate != null) {
        movements = await _stockService.getMovementsByDateRange(
          startDate,
          endDate,
        );
      } else {
        // Récupérer les mouvements des 30 derniers jours par défaut
        final end = DateTime.now();
        final start = end.subtract(const Duration(days: 30));
        movements = await _stockService.getMovementsByDateRange(start, end);
      }

      return await _createStockMovementsExcelFile(
        movements,
        'mouvements_stock',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'export des mouvements de stock: $e');
    }
  }

  /// Créer le fichier Excel pour les produits
  Future<String> _createProductsExcelFile(
    List<Product> products,
    String fileName,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Produits'];

    // Headers pour les produits
    final headers = [
      'ID',
      'Nom',
      'Catégorie',
      'Marque',
      'Prix (FCFA)',
      'Stock',
      'En Stock',
      'Description',
      'Référence Fournisseur',
      'Date Création',
      'Spécifications',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#2196F3',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final rowIndex = i + 1;

      // Convertir les spécifications en chaîne
      final specsString = product.specs.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('; ');

      final rowValues = [
        product.id,
        product.name,
        product.category,
        product.brand,
        product.price,
        product.stock,
        product.isInStock ? 'Oui' : 'Non',
        product.description,
        product.supplierReference,
        dateFormat.format(product.createdAt),
        specsString,
      ];

      for (int j = 0; j < rowValues.length; j++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
        );
        cell.value = rowValues[j];

        // Style des lignes alternées
        if (i % 2 == 1) {
          cell.cellStyle = CellStyle(backgroundColorHex: '#F5F5F5');
        }
      }
    }

    // Ajouter une feuille avec les statistiques de stock
    _addStockStatsSheet(excel, products);

    return await _saveExcelFile(excel, fileName);
  }

  /// Créer le fichier Excel pour les mouvements de stock
  Future<String> _createStockMovementsExcelFile(
    List<StockMovement> movements,
    String fileName,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Mouvements Stock'];

    // Headers pour les mouvements
    final headers = [
      'ID',
      'Date',
      'Produit',
      'Type',
      'Quantité',
      'Stock Avant',
      'Stock Après',
      'Raison',
      'Utilisateur',
      'ID Commande',
      'ID Fournisseur',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#FF9800',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (int i = 0; i < movements.length; i++) {
      final movement = movements[i];
      final rowIndex = i + 1;

      final rowValues = [
        movement.id,
        dateFormat.format(movement.createdAt),
        movement.productName,
        movement.typeDisplayName,
        movement.quantity,
        movement.stockBefore,
        movement.stockAfter,
        movement.reason,
        movement.userName,
        movement.orderId ?? '',
        movement.supplierId ?? '',
      ];

      for (int j = 0; j < rowValues.length; j++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
        );
        cell.value = rowValues[j];

        // Style selon le type de mouvement
        if (movement.isEntry) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: '#E8F5E8',
          ); // Vert clair
        } else if (movement.isExit) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: '#FFF2F2',
          ); // Rouge clair
        } else {
          cell.cellStyle = CellStyle(
            backgroundColorHex: '#F5F5F5',
          ); // Gris clair
        }
      }
    }

    // Ajouter une feuille avec résumé des mouvements
    _addMovementsSummarySheet(excel, movements);

    return await _saveExcelFile(excel, fileName);
  }

  /// Ajouter une feuille avec les statistiques de stock
  void _addStockStatsSheet(Excel excel, List<Product> products) {
    final sheet = excel['Statistiques Stock'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );

    // Titre
    sheet.cell(CellIndex.indexByString('A1')).value = 'STATISTIQUES DE STOCK';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

    int totalProducts = products.length;
    int inStock = products
        .where((p) => p.stock > ProductService.defaultLowStockThreshold)
        .length;
    int lowStock = products
        .where(
          (p) =>
              p.stock > 0 && p.stock <= ProductService.defaultLowStockThreshold,
        )
        .length;
    int outOfStock = products.where((p) => p.stock == 0).length;
    double totalStockValue = products.fold(
      0,
      (sum, p) => sum + (p.stock * p.price),
    );

    final stats = {
      'Nombre total de produits': totalProducts,
      'Produits en stock normal': inStock,
      'Produits en stock faible': lowStock,
      'Produits en rupture': outOfStock,
      'Valeur totale du stock': '${totalStockValue.toStringAsFixed(0)} FCFA',
      'Pourcentage stock faible':
          '${(lowStock / totalProducts * 100).toStringAsFixed(1)}%',
      'Pourcentage rupture':
          '${(outOfStock / totalProducts * 100).toStringAsFixed(1)}%',
    };

    int row = 3;
    stats.forEach((key, value) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
              .value =
          key;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
              .value =
          value;
      row++;
    });

    // Répartition par catégorie
    sheet.cell(CellIndex.indexByString('D1')).value =
        'RÉPARTITION PAR CATÉGORIE';
    sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;

    final categoryStats = <String, Map<String, dynamic>>{};
    for (final product in products) {
      if (!categoryStats.containsKey(product.category)) {
        categoryStats[product.category] = {
          'count': 0,
          'totalStock': 0,
          'totalValue': 0.0,
        };
      }
      categoryStats[product.category]!['count']++;
      categoryStats[product.category]!['totalStock'] += product.stock;
      categoryStats[product.category]!['totalValue'] +=
          product.stock * product.price;
    }

    sheet.cell(CellIndex.indexByString('D2')).value = 'Catégorie';
    sheet.cell(CellIndex.indexByString('E2')).value = 'Nb Produits';
    sheet.cell(CellIndex.indexByString('F2')).value = 'Stock Total';
    sheet.cell(CellIndex.indexByString('G2')).value = 'Valeur (FCFA)';

    row = 3;
    categoryStats.forEach((category, stats) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
              .value =
          category;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value =
          stats['count'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
              .value =
          stats['totalStock'];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = (stats['totalValue'] as double).toStringAsFixed(
        0,
      );
      row++;
    });
  }

  /// Ajouter une feuille avec résumé des mouvements
  void _addMovementsSummarySheet(Excel excel, List<StockMovement> movements) {
    final sheet = excel['Résumé Mouvements'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#FF9800',
      fontColorHex: '#FFFFFF',
    );

    sheet.cell(CellIndex.indexByString('A1')).value =
        'RÉSUMÉ DES MOUVEMENTS DE STOCK';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

    // Statistiques par type
    final typeStats = <StockMovementType, Map<String, int>>{};
    for (final movement in movements) {
      if (!typeStats.containsKey(movement.type)) {
        typeStats[movement.type] = {'count': 0, 'totalQuantity': 0};
      }
      typeStats[movement.type]!['count'] =
          typeStats[movement.type]!['count']! + 1;
      typeStats[movement.type]!['totalQuantity'] =
          typeStats[movement.type]!['totalQuantity']! +
          movement.absoluteQuantity;
    }

    sheet.cell(CellIndex.indexByString('A3')).value = 'Type de mouvement';
    sheet.cell(CellIndex.indexByString('B3')).value = 'Nombre';
    sheet.cell(CellIndex.indexByString('C3')).value = 'Quantité totale';

    int row = 4;
    typeStats.forEach((type, stats) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = type
          .toString()
          .split('.')
          .last;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
              .value =
          stats['count'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
              .value =
          stats['totalQuantity'];
      row++;
    });

    // Top produits par mouvements
    final productMovements = <String, Map<String, dynamic>>{};
    for (final movement in movements) {
      if (!productMovements.containsKey(movement.productId)) {
        productMovements[movement.productId] = {
          'name': movement.productName,
          'count': 0,
          'totalQuantity': 0,
        };
      }
      productMovements[movement.productId]!['count']++;
      productMovements[movement.productId]!['totalQuantity'] +=
          movement.absoluteQuantity;
    }

    final sortedProducts = productMovements.entries.toList()
      ..sort((a, b) => b.value['count'].compareTo(a.value['count']));

    sheet.cell(CellIndex.indexByString('E1')).value =
        'TOP PRODUITS (MOUVEMENTS)';
    sheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByString('E3')).value = 'Produit';
    sheet.cell(CellIndex.indexByString('F3')).value = 'Nb Mouvements';
    sheet.cell(CellIndex.indexByString('G3')).value = 'Quantité totale';

    row = 4;
    for (int i = 0; i < sortedProducts.length && i < 10; i++) {
      final product = sortedProducts[i];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value =
          product.value['name'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
              .value =
          product.value['count'];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
              .value =
          product.value['totalQuantity'];
      row++;
    }
  }

  /// Importer des produits depuis un fichier Excel
  Future<Map<String, dynamic>> importProductsFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier non trouvé: $filePath');
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.sheets.isEmpty) {
        throw Exception('Le fichier Excel est vide');
      }

      final sheet = excel.sheets.values.first;

      int imported = 0;
      int errors = 0;
      List<String> errorMessages = [];

      // Ignorer la première ligne (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        try {
          final row = sheet.row(i);
          if (row.isEmpty || row.length < 6) continue;

          // Extraire les données de la ligne
          final id = row[0]?.value?.toString() ?? '';
          final name = row[1]?.value?.toString() ?? '';
          final category = row[2]?.value?.toString() ?? '';
          final brand = row[3]?.value?.toString() ?? '';
          final priceStr = row[4]?.value?.toString() ?? '0';
          final stockStr = row[5]?.value?.toString() ?? '0';

          if (name.isEmpty || category.isEmpty || brand.isEmpty) {
            errorMessages.add(
              'Ligne ${i + 1}: Données manquantes (nom, catégorie ou marque)',
            );
            errors++;
            continue;
          }

          final price = double.tryParse(priceStr) ?? 0.0;
          final stock = int.tryParse(stockStr) ?? 0;

          final product = Product(
            id: id.isEmpty
                ? DateTime.now().millisecondsSinceEpoch.toString()
                : id,
            name: name,
            category: category,
            brand: brand,
            price: price,
            description: row.length > 7
                ? (row[7]?.value?.toString() ?? '')
                : '',
            imageUrls: [],
            stock: stock,
            isInStock: stock > 0,
            supplierReference: row.length > 8
                ? (row[8]?.value?.toString() ?? '')
                : '',
          );

          await _productService.add(product);
          imported++;
        } catch (e) {
          errorMessages.add('Ligne ${i + 1}: $e');
          errors++;
        }
      }

      return {
        'success': true,
        'imported': imported,
        'errors': errors,
        'errorMessages': errorMessages,
        'message':
            'Import terminé: $imported produits importés, $errors erreurs',
      };
    } catch (e) {
      return {
        'success': false,
        'imported': 0,
        'errors': 1,
        'errorMessages': [e.toString()],
        'message': 'Erreur lors de l\'import: $e',
      };
    }
  }

  /// Créer un modèle Excel pour l'import de produits
  Future<String> createProductImportTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Produits'];

    final headers = [
      'ID (optionnel)',
      'Nom*',
      'Catégorie*',
      'Marque*',
      'Prix (FCFA)*',
      'Stock*',
      'En Stock (Oui/Non)',
      'Description',
      'Référence Fournisseur',
      'Spécifications',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    // Ajouter des exemples
    final examples = [
      [
        '',
        'iPhone 14',
        'phone',
        'Apple',
        '800000',
        '10',
        'Oui',
        'Smartphone haut de gamme',
        'IPH14-128GB',
        'Écran: 6.1 pouces; Stockage: 128GB',
      ],
      [
        '',
        'Galaxy S23',
        'phone',
        'Samsung',
        '750000',
        '5',
        'Oui',
        'Smartphone Android',
        'GAL-S23-256',
        'Écran: 6.6 pouces; Stockage: 256GB',
      ],
      [
        '',
        'MacBook Pro',
        'pc',
        'Apple',
        '1500000',
        '0',
        'Non',
        'Ordinateur portable',
        'MBP-M2-512',
        'Processeur: M2; RAM: 8GB; SSD: 512GB',
      ],
    ];

    for (int i = 0; i < examples.length; i++) {
      final example = examples[i];
      for (int j = 0; j < example.length; j++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                )
                .value =
            example[j];
      }
    }

    return await _saveExcelFile(excel, 'template_import_produits');
  }
}
