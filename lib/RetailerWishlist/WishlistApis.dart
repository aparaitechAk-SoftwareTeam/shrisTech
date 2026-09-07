// ignore_for_file: file_names

import '../Stock Listing Module/StockApis.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class WishlistItemModel {
  final String wishlistId;
  final String retailerId;
  final String productId;
  final String variantId;
  final ProductModel product;

  const WishlistItemModel({
    required this.wishlistId,
    required this.retailerId,
    required this.productId,
    required this.variantId,
    required this.product,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final productJson =
        _asMap(json['product']) ??
        _asMap(json['products']) ??
        _asMap(json['item']) ??
        json;
    final product = ProductModel.fromJson({
      ...productJson,
      ..._productFallbacks(json),
    });
    final productId = _readString(json, const ['product_id', 'productId']);
    final variantId = _readString(json, const [
      'variant_id',
      'variantId',
      'product_variant_id',
      'productVariantId',
    ]);
    return WishlistItemModel(
      wishlistId: _readString(json, const ['wishlist_id', 'wishlistId', 'id']),
      retailerId: _readString(json, const ['retailer_id', 'retailerId']),
      productId: productId.isNotEmpty ? productId : product.id,
      variantId: variantId.isNotEmpty ? variantId : productVariantId(product),
      product: product,
    );
  }

  WishlistItemModel copyWith({ProductModel? product}) {
    return WishlistItemModel(
      wishlistId: wishlistId,
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      product: product ?? this.product,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return product.productName.toLowerCase().contains(normalized) ||
        product.productCode.toLowerCase().contains(normalized);
  }
}

abstract class IWishlistRepository {
  Future<List<WishlistItemModel>> fetchWishlist(String retailerId);
  Future<WishlistItemModel?> addWishlist({
    required String retailerId,
    required String productId,
    required String variantId,
  });
  Future<void> removeWishlist({
    required String retailerId,
    required String wishlistId,
  });
  Future<void> placeOrder({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity,
    String remarks,
  });
}

class WishlistRepository implements IWishlistRepository {
  WishlistRepository({WishlistApis? apis}) : _apis = apis ?? WishlistApis();

  final WishlistApis _apis;

  @override
  Future<List<WishlistItemModel>> fetchWishlist(String retailerId) {
    return _apis.fetchWishlist(retailerId);
  }

  @override
  Future<WishlistItemModel?> addWishlist({
    required String retailerId,
    required String productId,
    required String variantId,
  }) {
    return _apis.addWishlist(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
    );
  }

  @override
  Future<void> removeWishlist({
    required String retailerId,
    required String wishlistId,
  }) {
    return _apis.removeWishlist(retailerId: retailerId, wishlistId: wishlistId);
  }

  @override
  Future<void> placeOrder({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
    String remarks = '',
  }) {
    return _apis.placeOrder(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
      remarks: remarks,
    );
  }
}

class WishlistApis {
  WishlistApis({ApiClient? client}) : _client = client ?? ApiClient();

  static const String _wishlistEndpoint = '/api/wishlist';
  static const String _ordersEndpoint = '/api/retailer/orders';

  final ApiClient _client;

  Future<List<WishlistItemModel>> fetchWishlist(String retailerId) async {
    if (retailerId.trim().isEmpty) return const [];
    final decoded = await _client.get(
      '$_wishlistEndpoint?retailer_id=$retailerId',
    );
    _throwIfFailed(decoded);
    return _extractList(decoded)
        .whereType<Map<String, dynamic>>()
        .map(WishlistItemModel.fromJson)
        .where(
          (item) => item.productId.isNotEmpty || item.product.id.isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<WishlistItemModel?> addWishlist({
    required String retailerId,
    required String productId,
    required String variantId,
  }) async {
    final decoded = await _client.post(
      _wishlistEndpoint,
      body: {
        'retailer_id': retailerId,
        'product_id': productId,
        'variant_id': variantId,
      },
    );
    _throwIfFailed(decoded);
    final data = _extractObject(decoded);
    return data == null ? null : WishlistItemModel.fromJson(data);
  }

  Future<void> removeWishlist({
    required String retailerId,
    required String wishlistId,
  }) async {
    final decoded = await _client.delete(
      '$_wishlistEndpoint/$wishlistId',
      body: {'retailer_id': retailerId},
    );
    _throwIfFailed(decoded);
  }

  Future<void> placeOrder({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
    String remarks = '',
  }) async {
    final decoded = await _client.post(
      _ordersEndpoint,
      body: {
        'retailer_id': retailerId,
        'remarks': remarks,
        'items': [
          {
            'product_id': productId,
            'variant_id': variantId,
            'quantity': quantity,
          },
        ],
      },
    );
    _throwIfFailed(decoded);
  }

  void _throwIfFailed(Map<String, dynamic> decoded) {
    if (decoded['success'] != false) return;
    final message = decoded['message'] ?? decoded['error'];
    throw ApiException(
      message is String && message.trim().isNotEmpty
          ? message
          : 'Something went wrong. Please try again.',
    );
  }
}

String productVariantId(ProductModel product) {
  final raw = product.rawJson;
  final direct = _readString(raw, const [
    'variant_id',
    'variantId',
    'product_variant_id',
    'productVariantId',
  ]);
  if (direct.isNotEmpty) return direct;

  final weights = raw['weights'] ?? raw['weight'];
  final fromWeights = _readNestedString(weights, const [
    'id',
    'variant_id',
    'variantId',
    'product_variant_id',
  ]);
  if (fromWeights.isNotEmpty) return fromWeights;

  final variants = raw['variants'] ?? raw['product_variants'];
  final fromVariants = _readNestedString(variants, const [
    'id',
    'variant_id',
    'variantId',
    'product_variant_id',
  ]);
  return fromVariants.isNotEmpty ? fromVariants : product.id;
}

List<Object?> _extractList(Map<String, dynamic> json) {
  for (final key in const [
    'wishlist',
    'wishlists',
    'items',
    'products',
    'data',
    'results',
  ]) {
    final value = json[key];
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final nested = _extractList(value);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

Map<String, dynamic>? _extractObject(Map<String, dynamic> json) {
  for (final key in const ['wishlist', 'item', 'data', 'result']) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
  }
  return json.isEmpty ? null : json;
}

Map<String, dynamic> _productFallbacks(Map<String, dynamic> json) {
  return {
    if (json['product_id'] != null) 'id': json['product_id'],
    if (json['product_name'] != null) 'product_name': json['product_name'],
    if (json['product_code'] != null) 'product_code': json['product_code'],
    if (json['images'] != null) 'images': json['images'],
    if (json['image_url'] != null) 'image': json['image_url'],
    if (json['weights'] != null) 'weights': json['weights'],
  };
}

Map<String, dynamic>? _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : null;
}

String _readNestedString(Object? value, List<String> keys) {
  if (value is Map<String, dynamic>) return _readString(value, keys);
  if (value is List) {
    for (final item in value) {
      final result = _readNestedString(item, keys);
      if (result.isNotEmpty) return result;
    }
  }
  return '';
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
