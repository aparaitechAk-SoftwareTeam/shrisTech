// ignore_for_file: file_names

import '../RetailerWishlist/WishlistApis.dart';
import '../Stock Listing Module/StockApis.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class CartItemModel {
  final String cartId;
  final String cartItemId;
  final String retailerId;
  final String productId;
  final String variantId;
  final int quantity;
  final ProductModel product;

  const CartItemModel({
    required this.cartId,
    required this.cartItemId,
    required this.retailerId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
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
    final quantity = _readInt(json, const ['quantity', 'qty'], fallback: 1);
    return CartItemModel(
      cartId: _readString(json, const ['cart_id', 'cartId']),
      cartItemId: _readString(json, const ['cart_item_id', 'cartItemId', 'id']),
      retailerId: _readString(json, const ['retailer_id', 'retailerId']),
      productId: productId.isNotEmpty ? productId : product.id,
      variantId: variantId.isNotEmpty ? variantId : productVariantId(product),
      quantity: quantity < 1 ? 1 : quantity,
      product: product,
    );
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      cartId: cartId,
      cartItemId: cartItemId,
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      quantity: quantity ?? this.quantity,
      product: product,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return product.productName.toLowerCase().contains(normalized) ||
        product.productCode.toLowerCase().contains(normalized);
  }
}

class CartModel {
  final String cartId;
  final int totalItems;
  final List<CartItemModel> items;

  const CartModel({
    required this.cartId,
    required this.totalItems,
    required this.items,
  });

  const CartModel.empty() : cartId = '', totalItems = 0, items = const [];

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawItems = data['items'] ?? data['cart_items'] ?? data['products'];
    final items = <CartItemModel>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(CartItemModel.fromJson(item));
        }
      }
    }
    final total = _readInt(data, const ['total_items', 'totalItems', 'count']);
    return CartModel(
      cartId: _readString(data, const ['cart_id', 'cartId', 'id']),
      totalItems: total > 0
          ? total
          : items.fold<int>(0, (sum, item) => sum + item.quantity),
      items: List.unmodifiable(items),
    );
  }
}

abstract class ICartRepository {
  Future<CartModel> fetchCart(String retailerId);
  Future<CartItemModel?> addToCart({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity,
  });
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  });
  Future<void> removeItem(String cartItemId);
  Future<void> placeOrder({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity,
    String remarks,
  });
}

class CartRepository implements ICartRepository {
  CartRepository({CartApis? apis}) : _apis = apis ?? CartApis();

  final CartApis _apis;

  @override
  Future<CartModel> fetchCart(String retailerId) => _apis.fetchCart(retailerId);

  @override
  Future<CartItemModel?> addToCart({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
  }) {
    return _apis.addToCart(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );
  }

  @override
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) {
    return _apis.updateQuantity(cartItemId: cartItemId, quantity: quantity);
  }

  @override
  Future<void> removeItem(String cartItemId) => _apis.removeItem(cartItemId);

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

class CartApis {
  CartApis({ApiClient? client}) : _client = client ?? ApiClient();

  static const String _cartEndpoint = '/api/retailer/cart';
  static const String _ordersEndpoint = '/api/retailer/orders';

  final ApiClient _client;

  Future<CartModel> fetchCart(String retailerId) async {
    if (retailerId.trim().isEmpty) return const CartModel.empty();
    final decoded = await _client.get('$_cartEndpoint?retailer_id=$retailerId');
    _throwIfFailed(decoded);
    return CartModel.fromJson(decoded);
  }

  Future<CartItemModel?> addToCart({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
  }) async {
    final decoded = await _client.post(
      _cartEndpoint,
      body: {
        'retailer_id': retailerId,
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      },
    );
    _throwIfFailed(decoded);
    final data = _extractObject(decoded);
    return data == null ? null : CartItemModel.fromJson(data);
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final decoded = await _client.patch(
      '$_cartEndpoint/$cartItemId',
      body: {'quantity': quantity},
    );
    _throwIfFailed(decoded);
  }

  Future<void> removeItem(String cartItemId) async {
    final decoded = await _client.delete('$_cartEndpoint/$cartItemId');
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

Map<String, dynamic>? _extractObject(Map<String, dynamic> json) {
  for (final key in const ['cart_item', 'item', 'data', 'result']) {
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

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
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
