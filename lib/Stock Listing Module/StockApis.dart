// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

abstract class StockStrings {
  static const String title = 'Stock Listing';
  static const String noProducts = 'No Products Found';
  static const String retry = 'Retry';
  static const String unavailable = 'N/A';
}

class ImageModel {
  final String id;
  final String url;
  final String altText;
  final int sortOrder;

  const ImageModel({
    required this.id,
    required this.url,
    this.altText = '',
    this.sortOrder = 0,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = _readString(json, const ['url', 'image_url', 'src', 'path']);
    final cleanUrl = _looksLikeUrl(rawUrl) ? rawUrl : '';
    return ImageModel(
      id: _readString(json, const ['id', 'image_id', 'public_id']),
      url: cleanUrl,
      altText: _readString(json, const ['alt', 'alt_text', 'name']),
      sortOrder: _readInt(json, const ['sort_order', 'position', 'order']),
    );
  }

  factory ImageModel.fromValue(Object? value, int index) {
    if (value is Map<String, dynamic>) return ImageModel.fromJson(value);
    final rawUrl = value?.toString().trim() ?? '';
    final cleanUrl = _looksLikeUrl(rawUrl) ? rawUrl : '';
    return ImageModel(
      id: 'image-$index-$cleanUrl',
      url: cleanUrl,
      sortOrder: index,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'alt_text': altText,
    'sort_order': sortOrder,
  };

  ImageModel copyWith({
    String? id,
    String? url,
    String? altText,
    int? sortOrder,
  }) {
    return ImageModel(
      id: id ?? this.id,
      url: url ?? this.url,
      altText: altText ?? this.altText,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? parentId;

  const CategoryModel({required this.id, required this.name, this.parentId});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final parent = json['parent_id'] ?? json['parentId'];
    final parentText = parent?.toString().trim();
    return CategoryModel(
      id: _readString(json, const ['id', 'category_id', 'sub_category_id']),
      name: _readString(json, const [
        'name',
        'category_name',
        'sub_category_name',
      ]),
      parentId: parentText == null || parentText.isEmpty ? null : parentText,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
  };

  CategoryModel copyWith({String? id, String? name, String? parentId}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }
}

class WeightModel {
  final double grossWeight;
  final double stoneWeight;
  final double stoneCharge;
  final double netWeight;

  const WeightModel({
    this.grossWeight = 0,
    this.stoneWeight = 0,
    this.stoneCharge = 0,
    this.netWeight = 0,
  });

  factory WeightModel.fromJson(Map<String, dynamic> json) {
    final gross = _readDouble(json, const ['gross_weight', 'grossWeight']);
    final stone = _readDouble(json, const ['stone_weight', 'stoneWeight']);
    final net = _readNullableDouble(json, const ['net_weight', 'netWeight']);
    return WeightModel(
      grossWeight: gross,
      stoneWeight: stone,
      stoneCharge: _readDouble(json, const ['stone_charge', 'stoneCharge']),
      netWeight: net ?? _safeNetWeight(gross, stone),
    );
  }

  Map<String, dynamic> toJson() => {
    'gross_weight': grossWeight,
    'stone_weight': stoneWeight,
    'stone_charge': stoneCharge,
    'net_weight': netWeight,
  };

  WeightModel copyWith({
    double? grossWeight,
    double? stoneWeight,
    double? stoneCharge,
    double? netWeight,
  }) {
    return WeightModel(
      grossWeight: grossWeight ?? this.grossWeight,
      stoneWeight: stoneWeight ?? this.stoneWeight,
      stoneCharge: stoneCharge ?? this.stoneCharge,
      netWeight: netWeight ?? this.netWeight,
    );
  }
}

class ProductModel {
  final String id;
  final String productName;
  final String productCode;
  final String description;
  final WeightModel weights;
  final int availableQuantity;
  final int minimumOrderQuantity;
  final List<ImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawJson;

  const ProductModel({
    required this.id,
    required this.productName,
    this.productCode = '',
    this.description = '',
    this.weights = const WeightModel(),
    this.availableQuantity = 0,
    this.minimumOrderQuantity = 1,
    this.images = const <ImageModel>[],
    this.createdAt,
    this.updatedAt,
    this.rawJson = const <String, dynamic>{},
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final weightsJson =
        _nestedMap(json['weights']) ??
        _nestedMap(json['weight']) ??
        _firstMap(json['weights']);

    return ProductModel(
      id: _readString(json, const ['id', 'product_id', '_id']),
      productName: _readString(json, const [
        'product_name',
        'productName',
        'name',
        'title',
      ]),
      productCode: _readString(json, const [
        'product_code',
        'productCode',
        'code',
      ]),
      description: _readString(json, const [
        'description',
        'narration',
        'details',
      ]),
      weights: weightsJson == null
          ? WeightModel.fromJson(json)
          : WeightModel.fromJson(weightsJson),
      availableQuantity: _readInt(json, const [
        'available_quantity',
        'availableQuantity',
        'quantity',
        'qty',
      ]),
      minimumOrderQuantity: _readInt(json, const [
        'minimum_order_quantity',
        'minimumOrderQuantity',
        'moq',
      ], fallback: 1),
      images: _readImages(json),
      createdAt: _readDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDateTime(json['updated_at'] ?? json['updatedAt']),
      rawJson: Map<String, dynamic>.unmodifiable(json),
    );
  }

  String get displayName => productName.trim().isEmpty
      ? StockStrings.unavailable
      : productName.trim();

  String get heroTag => 'stock-product-$id-${primaryImageUrl.hashCode}';

  String get primaryImageUrl {
    for (final image in images) {
      if (_looksLikeUrl(image.url)) return image.url;
    }
    return '';
  }

  bool matchesProductName(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return productName.toLowerCase().contains(normalized);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'product_code': productCode,
    'description': description,
    'weights': weights.toJson(),
    'available_quantity': availableQuantity,
    'minimum_order_quantity': minimumOrderQuantity,
    'images': images.map((image) => image.toJson()).toList(growable: false),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  ProductModel copyWith({
    String? id,
    String? productName,
    String? productCode,
    String? description,
    WeightModel? weights,
    int? availableQuantity,
    int? minimumOrderQuantity,
    List<ImageModel>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? rawJson,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      description: description ?? this.description,
      weights: weights ?? this.weights,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawJson: rawJson ?? this.rawJson,
    );
  }
}

class ProductNameGroup {
  final String productName;
  final List<ProductModel> products;

  const ProductNameGroup({required this.productName, required this.products});

  int get count => products.length;
  String get imageUrl => products.isEmpty ? '' : products.first.primaryImageUrl;
}

class StockWeightRange {
  final double min;
  final double? max;

  const StockWeightRange(this.min, this.max);

  String get id => max == null
      ? '${min.toStringAsFixed(0)}+'
      : '${min.toStringAsFixed(0)}-${max!.toStringAsFixed(0)}';

  String get label => max == null
      ? '${min.toStringAsFixed(0)} gm+'
      : '${min.toStringAsFixed(0)} gm - ${max!.toStringAsFixed(0)} gm';

  bool contains(double value) {
    if (max == null) return value >= min;
    return value >= min && value < max!;
  }
}

class StockWeightGroup {
  final StockWeightRange range;
  final List<ProductModel> products;

  const StockWeightGroup({required this.range, required this.products});

  int get count => products.length;
}

enum StockSortOption { none, netWeightAsc, netWeightDesc, newest, oldest }

extension StockSortOptionLabel on StockSortOption {
  String get label {
    switch (this) {
      case StockSortOption.netWeightAsc:
        return 'Net Weight up';
      case StockSortOption.netWeightDesc:
        return 'Net Weight down';
      case StockSortOption.newest:
        return 'New to Old';
      case StockSortOption.oldest:
        return 'Old to New';
      case StockSortOption.none:
        return 'Default';
    }
  }
}

abstract class IStockRepository {
  Future<List<ProductModel>> fetchProducts({bool forceRefresh = false});
  Future<ProductModel> fetchSingleProduct(String productId);
  Future<ProductModel> updateProduct({
    required String productId,
    required double grossWeight,
    required double stoneWeight,
  });
  List<ProductNameGroup> groupByProductName(List<ProductModel> products);
  List<StockWeightGroup> groupByWeight(List<ProductModel> products);
  List<ProductModel> cachedProducts();
  void clearCache();
}

class StockRepository implements IStockRepository {
  StockRepository._({StockApis? apis}) : _apis = apis ?? StockApis();

  static final StockRepository instance = StockRepository._();

  final StockApis _apis;
  List<ProductModel>? _cache;
  final Map<String, List<ProductNameGroup>> _nameGroupCache = {};
  final Map<String, List<StockWeightGroup>> _weightGroupCache = {};

  @override
  Future<List<ProductModel>> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return List<ProductModel>.unmodifiable(_cache!);
    }
    final products = await _apis.fetchProducts();
    _cache = products;
    _clearComputedCaches();
    return List<ProductModel>.unmodifiable(products);
  }

  @override
  Future<ProductModel> fetchSingleProduct(String productId) async {
    final product = await _apis.fetchSingleProduct(productId);
    _replaceCachedProduct(product);
    return product;
  }

  @override
  Future<ProductModel> updateProduct({
    required String productId,
    required double grossWeight,
    required double stoneWeight,
  }) async {
    final optimistic = _cachedById(productId)?.copyWith(
      weights: (_cachedById(productId)?.weights ?? const WeightModel())
          .copyWith(
            grossWeight: grossWeight,
            stoneWeight: stoneWeight,
            netWeight: _safeNetWeight(grossWeight, stoneWeight),
          ),
    );
    if (optimistic != null) _replaceCachedProduct(optimistic);

    final updated = await _apis.updateProduct(
      productId: productId,
      grossWeight: grossWeight,
      stoneWeight: stoneWeight,
    );
    _replaceCachedProduct(updated);
    return updated;
  }

  @override
  List<ProductNameGroup> groupByProductName(List<ProductModel> products) {
    final key = _cacheKey(products, 'names');
    final cached = _nameGroupCache[key];
    if (cached != null) return cached;

    final map = <String, List<ProductModel>>{};
    for (final product in products) {
      final name = product.displayName;
      map.putIfAbsent(name, () => <ProductModel>[]).add(product);
    }
    final groups =
        map.entries
            .map(
              (entry) => ProductNameGroup(
                productName: entry.key,
                products: List<ProductModel>.unmodifiable(entry.value),
              ),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.productName.toLowerCase().compareTo(
              b.productName.toLowerCase(),
            ),
          );
    _nameGroupCache[key] = List<ProductNameGroup>.unmodifiable(groups);
    return _nameGroupCache[key]!;
  }

  @override
  List<StockWeightGroup> groupByWeight(List<ProductModel> products) {
    final key = _cacheKey(products, 'weights');
    final cached = _weightGroupCache[key];
    if (cached != null) return cached;

    final groups = <StockWeightGroup>[];
    for (final range in StockApis.weightRanges) {
      final items = products
          .where((product) => range.contains(product.weights.netWeight))
          .toList(growable: false);
      if (items.isNotEmpty) {
        groups.add(
          StockWeightGroup(
            range: range,
            products: List<ProductModel>.unmodifiable(items),
          ),
        );
      }
    }
    _weightGroupCache[key] = List<StockWeightGroup>.unmodifiable(groups);
    return _weightGroupCache[key]!;
  }

  @override
  List<ProductModel> cachedProducts() {
    return List<ProductModel>.unmodifiable(_cache ?? const <ProductModel>[]);
  }

  @override
  void clearCache() {
    _cache = null;
    _clearComputedCaches();
  }

  ProductModel? _cachedById(String productId) {
    final cache = _cache;
    if (cache == null) return null;
    for (final product in cache) {
      if (product.id == productId) return product;
    }
    return null;
  }

  void _replaceCachedProduct(ProductModel product) {
    final cache = _cache;
    if (cache == null || product.id.isEmpty) return;
    var replaced = false;
    final next = cache
        .map((item) {
          if (item.id != product.id) return item;
          replaced = true;
          return product;
        })
        .toList(growable: true);
    if (!replaced) next.add(product);
    _cache = List<ProductModel>.unmodifiable(next);
    _clearComputedCaches();
  }

  void _clearComputedCaches() {
    _nameGroupCache.clear();
    _weightGroupCache.clear();
  }

  String _cacheKey(List<ProductModel> products, String scope) {
    final ids = products.map((product) => product.id).join(',');
    final latest = products
        .map((product) => product.updatedAt?.millisecondsSinceEpoch ?? 0)
        .fold<int>(0, (previous, value) => value > previous ? value : previous);
    return '$scope:${products.length}:$latest:$ids';
  }
}

class StockApis {
  StockApis({ApiClient? client}) : _client = client ?? ApiClient();

  static const String productsEndpoint = '/api/products';
  static const String ownerProductsEndpoint = '/api/owner/products';
  static const List<StockWeightRange> weightRanges = [
    StockWeightRange(0, 5),
    StockWeightRange(5, 10),
    StockWeightRange(10, 15),
    StockWeightRange(15, 20),
    StockWeightRange(20, 25),
    StockWeightRange(25, 30),
    StockWeightRange(30, 35),
    StockWeightRange(35, 40),
    StockWeightRange(40, 45),
    StockWeightRange(45, 50),
    StockWeightRange(50, 55),
    StockWeightRange(55, 60),
    StockWeightRange(60, 65),
    StockWeightRange(65, 70),
    StockWeightRange(70, 75),
    StockWeightRange(75, 80),
    StockWeightRange(80, 85),
    StockWeightRange(85, 90),
    StockWeightRange(90, null),
  ];

  final ApiClient _client;

  Future<List<ProductModel>> fetchProducts() async {
    final decoded = await _client.get(productsEndpoint);
    _throwIfApiFailed(decoded);
    final list = _extractList(decoded, const [
      'products',
      'data',
      'items',
      'results',
    ]);
    return _parseProducts(list);
  }

  Future<ProductModel> fetchSingleProduct(String productId) async {
    if (productId.trim().isEmpty) {
      throw const ApiException('Product details are unavailable.');
    }
    final decoded = await _client.get('$productsEndpoint/$productId');
    log('Stock fetchSingleProduct APIs: ${decoded.toString()}');
    _throwIfApiFailed(decoded);
    final productJson = _extractObject(decoded, const [
      'product',
      'data',
      'item',
      'result',
    ]);
    if (productJson == null) {
      return ProductModel.fromJson(decoded);
    }
    return ProductModel.fromJson(productJson);
  }

  Future<ProductModel> updateProduct({
    required String productId,
    required double grossWeight,
    required double stoneWeight,
  }) async {
    if (productId.trim().isEmpty) {
      throw const ApiException('Product details are unavailable.');
    }
    final decoded = await _client.patch(
      '$ownerProductsEndpoint/$productId',
      body: {'gross_weight': grossWeight, 'stone_weight': stoneWeight},
    );
    _throwIfApiFailed(decoded);
    final productJson = _extractObject(decoded, const [
      'product',
      'data',
      'item',
      'result',
    ]);
    if (productJson == null) {
      return ProductModel.fromJson(decoded);
    }
    return ProductModel.fromJson(productJson);
  }

  List<ProductModel> _parseProducts(List<Object?> values) {
    return values
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .where(
          (product) => product.id.isNotEmpty || product.productName.isNotEmpty,
        )
        .toList(growable: false);
  }

  void _throwIfApiFailed(Map<String, dynamic> decoded) {
    if (decoded['success'] != false) return;
    final message = decoded['message'] ?? decoded['error'];
    throw ApiException(
      message is String && message.trim().isNotEmpty
          ? message
          : 'Something went wrong.',
    );
  }
}

List<Object?> _extractList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final nested = _extractList(value, keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const <Object?>[];
}

Map<String, dynamic>? _extractObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
  }
  return null;
}

Map<String, dynamic>? _nestedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return null;
}

Map<String, dynamic>? _firstMap(Object? value) {
  if (value is List) {
    for (final item in value) {
      if (item is Map<String, dynamic>) return item;
    }
  }
  return null;
}

List<ImageModel> _readImages(Map<String, dynamic> json) {
  final value =
      json['images'] ??
      json['product_images'] ??
      json['image_urls'] ??
      json['image'];
  if (value is List) {
    final images = <ImageModel>[];
    for (var index = 0; index < value.length; index++) {
      final image = ImageModel.fromValue(value[index], index);
      if (image.url.trim().isNotEmpty) images.add(image);
    }
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List<ImageModel>.unmodifiable(images);
  }
  if (value is Map<String, dynamic>) return [ImageModel.fromJson(value)];
  final url = value?.toString().trim() ?? '';
  return url.isEmpty
      ? const <ImageModel>[]
      : [ImageModel(id: 'image-0-$url', url: url)];
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  return _readNullableDouble(json, keys) ?? 0;
}

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double _safeNetWeight(double grossWeight, double stoneWeight) {
  final net = grossWeight - stoneWeight;
  return net < 0 ? 0 : net;
}

bool _looksLikeUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('data:image')) return true;
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  if (host.contains('provider.com') ||
      host.contains('example.com') ||
      host == 'localhost' ||
      host == '127.0.0.1') {
    return false;
  }
  return true;
}
