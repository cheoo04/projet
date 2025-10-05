// Service d'optimisation des performances
// Gère la pagination, le cache d'images et les optimisations

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import '../services/logging_service.dart';

// Classe pour gérer les données paginées
class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoading;

  PaginatedData({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.isLoading = false,
  });

  PaginatedData<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    bool? isLoading,
  }) {
    return PaginatedData<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Contrôleur de pagination
class PaginationController<T> extends ChangeNotifier {
  PaginatedData<T> _data = PaginatedData<T>(
    items: [],
    currentPage: 1,
    totalPages: 1,
    totalItems: 0,
    hasNextPage: false,
    hasPreviousPage: false,
  );

  PaginatedData<T> get data => _data;

  final Future<List<T>> Function(int page, int pageSize) _fetchFunction;
  final int _pageSize;

  PaginationController({
    required Future<List<T>> Function(int page, int pageSize) fetchFunction,
    int pageSize = PerformanceOptimizationService.defaultPageSize,
  }) : _fetchFunction = fetchFunction,
       _pageSize = pageSize;

  // Charger la première page
  Future<void> loadFirstPage() async {
    _data = _data.copyWith(isLoading: true);
    notifyListeners();

    try {
      final items = await _fetchFunction(1, _pageSize);
      _updateData(items, 1);
    } catch (e) {
      LoggingService.error('Erreur chargement première page: $e');
      _data = _data.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Charger la page suivante
  Future<void> loadNextPage() async {
    if (!_data.hasNextPage || _data.isLoading) return;

    final nextPage = _data.currentPage + 1;
    _data = _data.copyWith(isLoading: true);
    notifyListeners();

    try {
      final items = await _fetchFunction(nextPage, _pageSize);
      final allItems = [..._data.items, ...items];
      _updateData(allItems, nextPage);
    } catch (e) {
      LoggingService.error('Erreur chargement page suivante: $e');
      _data = _data.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Actualiser les données
  Future<void> refresh() async {
    await loadFirstPage();
  }

  void _updateData(List<T> items, int page) {
    _data = PaginatedData<T>(
      items: items,
      currentPage: page,
      totalPages: (items.length / _pageSize).ceil(),
      totalItems: items.length,
      hasNextPage: items.length >= _pageSize,
      hasPreviousPage: page > 1,
      isLoading: false,
    );
    notifyListeners();
  }
}

// Classe Debouncer pour optimiser les recherches
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  late Dio _dio;
  late CacheOptions _cacheOptions;
  bool _isInitialized = false;

  // Configuration de pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration de Dio
      _dio = Dio();

      // Configuration du cache uniquement sur les plateformes supportées
      if (!kIsWeb) {
        try {
          // Obtenir le répertoire de cache
          final cacheDir = await getTemporaryDirectory();
          final cacheStore = HiveCacheStore(cacheDir.path);

          // Configuration du cache
          _cacheOptions = CacheOptions(
            store: cacheStore,
            policy: CachePolicy.request,
            hitCacheOnErrorExcept: [401, 403],
            maxStale: const Duration(days: 7),
            priority: CachePriority.normal,
            cipher: null,
            keyBuilder: CacheOptions.defaultCacheKeyBuilder,
            allowPostMethod: false,
          );

          // Ajouter l'intercepteur de cache
          _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
          LoggingService.info('Cache HTTP activé');
        } catch (e) {
          LoggingService.warning('Cache HTTP non disponible: $e');
          // Créer une configuration de cache par défaut avec store mémoire
          _cacheOptions = CacheOptions(
            store: MemCacheStore(),
            policy: CachePolicy.noCache,
            hitCacheOnErrorExcept: [401, 403],
            maxStale: const Duration(hours: 1),
            priority: CachePriority.normal,
          );
        }
      } else {
        // Sur le web, utiliser un store en mémoire
        LoggingService.info('Plateforme web détectée - cache mémoire activé');
        _cacheOptions = CacheOptions(
          store: MemCacheStore(),
          policy: CachePolicy.request,
          hitCacheOnErrorExcept: [401, 403],
          maxStale: const Duration(hours: 1),
          priority: CachePriority.normal,
        );
      }

      _isInitialized = true;
      LoggingService.info('Service d\'optimisation initialisé');
    } catch (e) {
      LoggingService.error('Erreur initialisation optimisation: $e');
      // Continuer avec une configuration basique
      _dio = Dio();
      _cacheOptions = CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.noCache,
      );
      _isInitialized = true;
    }
  }

  // MÉTHODES DE PAGINATION

  // Créer un contrôleur de pagination
  PaginationController<T> createPaginationController<T>({
    required Future<List<T>> Function(int page, int pageSize) fetchFunction,
    int pageSize = defaultPageSize,
  }) {
    return PaginationController<T>(
      fetchFunction: fetchFunction,
      pageSize: pageSize,
    );
  }

  // GESTION DU CACHE

  // Récupérer des données avec cache
  Future<Response<T>> getCachedData<T>(
    String url, {
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    await _ensureInitialized();

    final options = _cacheOptions.copyWith(
      maxStale: Nullable(maxAge ?? const Duration(hours: 1)),
      policy: forceRefresh ? CachePolicy.refresh : CachePolicy.request,
    );

    return await _dio.get<T>(url, options: Options(extra: options.toExtra()));
  }

  // Vider le cache HTTP
  Future<void> clearHttpCache() async {
    await _ensureInitialized();
    try {
      await _cacheOptions.store?.clean();
      LoggingService.info('Cache HTTP vidé');
    } catch (e) {
      LoggingService.error('Erreur vidage cache HTTP: $e');
    }
  }

  // Vider le cache d'images
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      LoggingService.info('Cache d\'images vidé');
    } catch (e) {
      LoggingService.error('Erreur vidage cache images: $e');
    }
  }

  // MESURE DE PERFORMANCE

  /// Mesure le temps d'exécution d'une fonction asynchrone
  static Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    LoggingService.info('Début mesure: $operationName');
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      LoggingService.info('$operationName terminé en ${duration}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      LoggingService.error('$operationName échoué après ${duration}ms: $e');
      rethrow;
    }
  }

  /// Mesure le temps d'exécution d'une fonction synchrone
  static T measureExecutionTimeSync<T>(
    String operationName,
    T Function() operation,
  ) {
    LoggingService.info('Début mesure: $operationName');
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      LoggingService.info('$operationName terminé en ${duration}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      LoggingService.error('$operationName échoué après ${duration}ms: $e');
      rethrow;
    }
  }

  // Vérifier l'initialisation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
