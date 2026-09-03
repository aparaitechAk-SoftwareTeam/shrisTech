// ignore_for_file: file_names

import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import 'RetailerCatalogueApis.dart';

// ---------------------------------------------------------------------------
// Wishlist Service (in-memory + SharedPreferences persistence)
// ---------------------------------------------------------------------------

class RetailerWishlistService {
  RetailerWishlistService._();
  static final RetailerWishlistService instance = RetailerWishlistService._();

  static const String _prefKey = 'retailer_wishlist_ids';

  final Set<String> _wishlistIds = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw);
        if (list is List) {
          _wishlistIds.addAll(list.map((e) => e.toString()));
        }
      }
    } catch (e) {
      log('WishlistService load error: $e');
    }
    _loaded = true;
  }

  bool isWishlisted(String productId) => _wishlistIds.contains(productId);

  Future<bool> toggle(String productId) async {
    await ensureLoaded();
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    await _persist();
    return _wishlistIds.contains(productId);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_wishlistIds.toList()));
    } catch (e) {
      log('WishlistService save error: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Cart Service (in-memory cache; syncs with backend on demand)
// ---------------------------------------------------------------------------

class RetailerCartService {
  RetailerCartService._();
  static final RetailerCartService instance = RetailerCartService._();

  final RetailerCatalogueApis _apis = RetailerCatalogueApis();
  CartModel? _cache;

  int get itemCount => _cache?.totalItems ?? 0;
  CartModel get cart => _cache ?? CartModel.empty();

  Future<CartModel> fetchCart(String retailerId) async {
    final result = await _apis.fetchCart(retailerId);
    _cache = result;
    return result;
  }

  Future<void> addToCart({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
  }) async {
    await _apis.addToCart(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );
    // Invalidate cache so next fetch is fresh
    _cache = null;
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    await _apis.updateCartItemQuantity(cartItemId: cartItemId, quantity: quantity);
    _cache = null;
  }

  Future<void> removeItem(String cartItemId) async {
    await _apis.removeCartItem(cartItemId);
    _cache = null;
  }

  Future<void> placeOrder({
    required String retailerId,
    required String productId,
    required String variantId,
    int quantity = 1,
    String remarks = '',
  }) async {
    await _apis.placeOrder(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
      remarks: remarks,
    );
  }

  void clear() => _cache = null;
}
