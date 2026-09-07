// ignore_for_file: file_names

import 'dart:developer';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class CartItemModel {
  final String cartItemId;
  final String productId;
  final String variantId;
  final String productName;
  final String imageUrl;
  final int quantity;

  const CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.variantId,
    required this.productName,
    this.imageUrl = '',
    this.quantity = 1,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: _str(json, const ['id', 'cart_item_id', 'cartItemId']),
      productId: _str(json, const ['product_id', 'productId']),
      variantId: _str(json, const ['variant_id', 'variantId']),
      productName: _str(json, const ['product_name', 'productName', 'name']),
      imageUrl: _str(json, const ['image_url', 'imageUrl', 'image']),
      quantity: _int(json, const ['quantity', 'qty']),
    );
  }

  CartItemModel copyWith({int? quantity}) => CartItemModel(
    cartItemId: cartItemId,
    productId: productId,
    variantId: variantId,
    productName: productName,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
  );
}

class CartModel {
  final String cartId;
  final int totalItems;
  final List<CartItemModel> items;

  const CartModel({required this.cartId, this.totalItems = 0, this.items = const []});

  factory CartModel.empty() => const CartModel(cartId: '');

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawItems = data['items'];
    final items = <CartItemModel>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) items.add(CartItemModel.fromJson(item));
      }
    }

    final countFromField = _int(data, const ['total_items', 'totalItems', 'count']);
    return CartModel(
      cartId: _str(data, const ['cart_id', 'cartId', 'id']),
      totalItems: countFromField > 0 ? countFromField : items.length,
      items: List.unmodifiable(items),
    );
  }
}

// ---------------------------------------------------------------------------
// API class
// ---------------------------------------------------------------------------

class RetailerCatalogueApis {
  RetailerCatalogueApis({ApiClient? client}) : _client = client ?? ApiClient();

  static const String _cartEndpoint = '/api/retailer/cart';
  static const String _ordersEndpoint = '/api/retailer/orders';

  final ApiClient _client;

  Future<CartModel> fetchCart(String retailerId) async {
    if (retailerId.trim().isEmpty) return CartModel.empty();
    final decoded = await _client.get('$_cartEndpoint?retailer_id=$retailerId');
    log('fetchCart: $decoded');
    _throwIfFailed(decoded);
    return CartModel.fromJson(decoded);
  }

  Future<CartItemModel> addToCart({
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
    log('addToCart: $decoded');
    _throwIfFailed(decoded);
    final data = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;
    return CartItemModel.fromJson(data);
  }

  Future<void> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final decoded = await _client.patch(
      '$_cartEndpoint/$cartItemId',
      body: {'quantity': quantity},
    );
    log('updateCartItem: $decoded');
    _throwIfFailed(decoded);
  }

  Future<void> removeCartItem(String cartItemId) async {
    final decoded = await _client.delete('$_cartEndpoint/$cartItemId');
    log('removeCartItem: $decoded');
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
          {'product_id': productId, 'variant_id': variantId, 'quantity': quantity},
        ],
      },
    );
    log('placeOrder: $decoded');
    _throwIfFailed(decoded);
  }

  void _throwIfFailed(Map<String, dynamic> decoded) {
    if (decoded['success'] != false) return;
    final message = decoded['message'] ?? decoded['error'];
    throw ApiException(
      message is String && message.trim().isNotEmpty ? message : 'Something went wrong.',
    );
  }
}

String _str(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null) return v.toString().trim();
  }
  return '';
}

int _int(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final p = int.tryParse(v?.toString() ?? '');
    if (p != null) return p;
  }
  return 0;
}
