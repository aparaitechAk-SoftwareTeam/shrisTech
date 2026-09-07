// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/userdata.dart';
import '../Stock Listing Module/StockApis.dart' as stock;

typedef OrderStatusChanged = void Function(OrderModel order);

enum OrderSortMode { newestFirst, oldestFirst }

class StatusModel {
  final String value;
  final DateTime? changedAt;
  final String remarks;

  const StatusModel({required this.value, this.changedAt, this.remarks = ''});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      value: normalizeOrderStatus(_readString(json, const ['status', 'value'])),
      changedAt: _readDateTime(
        _readObject(json, const ['changed_at', 'changedAt', 'created_at']),
      ),
      remarks: _readString(json, const ['remarks', 'reason', 'note']),
    );
  }

  StatusModel copyWith({String? value, DateTime? changedAt, String? remarks}) {
    return StatusModel(
      value: value ?? this.value,
      changedAt: changedAt ?? this.changedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': value,
    'changed_at': changedAt?.toUtc().toIso8601String(),
    'remarks': remarks,
  };
}

class RetailerModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String mobileNumber;
  final String email;
  final Map<String, dynamic> rawJson;

  const RetailerModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    this.mobileNumber = '',
    this.email = '',
    this.rawJson = const <String, dynamic>{},
  });

  factory RetailerModel.fromJson(Map<String, dynamic> json) {
    return RetailerModel(
      id: _readString(json, const [
        'id',
        '_id',
        'retailer_id',
        'retailerId',
        'user_id',
      ]),
      shopName: _readString(json, const [
        'shop_name',
        'shopName',
        'shop',
        'business_name',
        'businessName',
      ], fallback: 'N/A'),
      ownerName: _readString(json, const [
        'owner_name',
        'ownerName',
        'name',
        'retailer_name',
        'retailerName',
      ], fallback: 'N/A'),
      mobileNumber: _readString(json, const ['mobile_no', 'mobile', 'phone']),
      email: _readString(json, const ['email']),
      rawJson: json,
    );
  }

  RetailerModel copyWith({
    String? id,
    String? shopName,
    String? ownerName,
    String? mobileNumber,
    String? email,
  }) {
    return RetailerModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      rawJson: rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_name': shopName,
    'owner_name': ownerName,
    'mobile_no': mobileNumber,
    'email': email,
  };
}

class OrderItemModel {
  final String id;
  final String productId;
  final String variantId;
  final String productName;
  final String imageUrl;
  final List<String> images;
  final int quantity;
  final double? grossWeight;
  final double? stoneWeight;
  final double? stoneCharge;
  final double? netWeight;
  final Map<String, dynamic> rawJson;

  const OrderItemModel({
    required this.id,
    required this.productId,
    this.variantId = '',
    required this.productName,
    required this.imageUrl,
    required this.images,
    required this.quantity,
    this.grossWeight,
    this.stoneWeight,
    this.stoneCharge,
    this.netWeight,
    this.rawJson = const <String, dynamic>{},
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = _readFirstMap(json, const [
      'product',
      'product_details',
      'productDetails',
    ]);
    final weights = _readFirstMap(json, const ['weights', 'weight']);
    final merged = <String, dynamic>{...product, ...weights, ...json};
    final images = _readStringList(merged, const [
      'images',
      'product_images',
      'productImages',
    ]);
    final singleImage = _readString(merged, const [
      'image',
      'image_url',
      'imageUrl',
      'product_image',
      'productImage',
    ]);
    final allImages = {
      if (singleImage.isNotEmpty) singleImage,
      ...images,
    }.toList(growable: false);
    return OrderItemModel(
      id: _readString(merged, const [
        'item_id',
        'itemId',
        'id',
        '_id',
        'order_item_id',
      ]),
      productId: _readString(merged, const [
        'product_id',
        'productId',
        'id',
        '_id',
      ]),
      variantId: _readString(merged, const [
        'variant_id',
        'variantId',
        'product_variant_id',
        'productVariantId',
      ]),
      productName: _readString(merged, const [
        'product_name',
        'productName',
        'name',
        'title',
      ], fallback: 'N/A'),
      imageUrl: allImages.isEmpty ? '' : allImages.first,
      images: allImages,
      quantity: _readInt(
        _readObject(merged, const ['quantity', 'qty']),
        fallback: 0,
      ),
      grossWeight: _readDouble(
        _readObject(merged, const ['gross_weight', 'grossWeight', 'gw']),
      ),
      stoneWeight: _readDouble(
        _readObject(merged, const ['stone_weight', 'stoneWeight', 'sw']),
      ),
      stoneCharge: _readDouble(
        _readObject(merged, const ['stone_charge', 'stoneCharge']),
      ),
      netWeight: _readDouble(
        _readObject(merged, const ['net_weight', 'netWeight', 'nw']),
      ),
      rawJson: json,
    );
  }

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? variantId,
    String? productName,
    String? imageUrl,
    List<String>? images,
    int? quantity,
    double? grossWeight,
    double? stoneWeight,
    double? stoneCharge,
    double? netWeight,
    Map<String, dynamic>? rawJson,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      grossWeight: grossWeight ?? this.grossWeight,
      stoneWeight: stoneWeight ?? this.stoneWeight,
      stoneCharge: stoneCharge ?? this.stoneCharge,
      netWeight: netWeight ?? this.netWeight,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'variant_id': variantId,
    'product_name': productName,
    'image_url': imageUrl,
    'images': images,
    'quantity': quantity,
    'gross_weight': grossWeight,
    'stone_weight': stoneWeight,
    'stone_charge': stoneCharge,
    'net_weight': netWeight,
  };
}

class PlaceOrderItemRequest {
  final String productId;
  final String variantId;
  final int quantity;

  const PlaceOrderItemRequest({
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'variant_id': variantId,
    'quantity': quantity,
  };
}

class PlaceRetailerOrderRequest {
  final String retailerId;
  final String remarks;
  final List<PlaceOrderItemRequest> items;

  const PlaceRetailerOrderRequest({
    required this.retailerId,
    this.remarks = '',
    required this.items,
  });

  PlaceRetailerOrderRequest copyWith({
    String? retailerId,
    String? remarks,
    List<PlaceOrderItemRequest>? items,
  }) {
    return PlaceRetailerOrderRequest(
      retailerId: retailerId ?? this.retailerId,
      remarks: remarks ?? this.remarks,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'retailer_id': retailerId,
    'remarks': remarks,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class OrderModel {
  final String id;
  final String orderNumber;
  final RetailerModel retailer;
  final List<OrderItemModel> items;
  final DateTime? orderDate;
  final String status;
  final String rejectedReason;
  final String cancelledReason;
  final String remarks;
  final List<StatusModel> history;
  final int totalOrders;
  final Map<String, dynamic> rawJson;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.retailer,
    required this.items,
    required this.orderDate,
    required this.status,
    this.rejectedReason = '',
    this.cancelledReason = '',
    this.remarks = '',
    this.history = const [],
    this.totalOrders = 1,
    this.rawJson = const <String, dynamic>{},
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final retailerMap = _readFirstMap(json, const [
      'retailer',
      'shop',
      'retailer_details',
      'retailerDetails',
    ]);
    final items = _readItems(json);
    final fallbackItem = items.isEmpty
        ? [OrderItemModel.fromJson(json)]
        : items;
    final status = normalizeOrderStatus(
      _readString(json, const [
        'status',
        'current_status',
        'currentStatus',
      ], fallback: 'Pending'),
    );
    return OrderModel(
      id: _readString(json, const ['order_id', 'orderId', 'id', '_id']),
      orderNumber: _readString(json, const [
        'order_number',
        'orderNumber',
        'order_no',
        'orderNo',
        'invoice_no',
      ], fallback: 'N/A'),
      retailer: RetailerModel.fromJson(
        retailerMap.isEmpty ? json : retailerMap,
      ),
      items: fallbackItem,
      orderDate: _readDateTime(
        _readObject(json, const [
          'order_date',
          'orderDate',
          'created_at',
          'createdAt',
          'date',
        ]),
      ),
      status: status,
      rejectedReason: _readString(json, const [
        'rejected_reason',
        'rejectedReason',
      ]),
      cancelledReason: _readString(json, const [
        'cancelled_reason',
        'cancelledReason',
      ]),
      remarks: _readString(json, const ['remarks', 'note', 'message']),
      history: _readHistory(json, status),
      totalOrders: _readInt(
        _readObject(json, const [
          'total_orders',
          'totalOrders',
          'orders_count',
          'ordersCount',
        ]),
        fallback: 1,
      ),
      rawJson: json,
    );
  }

  OrderItemModel get primaryItem =>
      items.isEmpty ? OrderItemModel.fromJson(const {}) : items.first;
  List<String> get images => items
      .expand((item) => item.images)
      .where((image) => image.trim().isNotEmpty)
      .toSet()
      .toList(growable: false);

  bool matchesOwner(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return retailer.shopName.toLowerCase().contains(q) ||
        retailer.ownerName.toLowerCase().contains(q) ||
        orderNumber.toLowerCase().contains(q) ||
        items.any((item) => item.productName.toLowerCase().contains(q));
  }

  bool matchesRetailer(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return orderNumber.toLowerCase().contains(q) ||
        items.any((item) => item.productName.toLowerCase().contains(q));
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    RetailerModel? retailer,
    List<OrderItemModel>? items,
    DateTime? orderDate,
    String? status,
    String? rejectedReason,
    String? cancelledReason,
    String? remarks,
    List<StatusModel>? history,
    int? totalOrders,
    Map<String, dynamic>? rawJson,
  }) {
    final nextStatus = status == null
        ? this.status
        : normalizeOrderStatus(status);
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      retailer: retailer ?? this.retailer,
      items: items ?? this.items,
      orderDate: orderDate ?? this.orderDate,
      status: nextStatus,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      remarks: remarks ?? this.remarks,
      history: history ?? this.history,
      totalOrders: totalOrders ?? this.totalOrders,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'retailer': retailer.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'order_date': orderDate?.toUtc().toIso8601String(),
    'status': status,
    'rejected_reason': rejectedReason,
    'cancelled_reason': cancelledReason,
    'remarks': remarks,
    'status_history': history.map((item) => item.toJson()).toList(),
    'total_orders': totalOrders,
  };
}

abstract class IOrderRepository {
  Future<List<OrderModel>> fetchOwnerOrders({bool forceRefresh = false});
  Future<OrderModel> fetchOwnerOrderDetails(
    String orderId, {
    bool forceRefresh = false,
  });
  Future<OrderModel> updateOwnerOrderStatus(
    String orderId,
    String status, {
    String? rejectedReason,
  });
  Future<List<OrderModel>> fetchRetailerOrders({bool forceRefresh = false});
  Future<OrderModel> placeRetailerOrder(PlaceRetailerOrderRequest request);
  Future<OrderModel> fetchRetailerOrderDetails(
    String orderId, {
    bool forceRefresh = false,
  });
  Future<OrderModel> cancelRetailerOrder(String orderId);
  Future<OrderModel> markRetailerDelivered(String orderId);
  Future<OrderModel> hydrateOrderProducts(OrderModel order);
  Future<List<OrderModel>> hydrateOrdersProducts(List<OrderModel> orders);
  void updateCachedOrder(OrderModel order);
}

class OrderRepository implements IOrderRepository {
  OrderRepository({OrderApis? apis}) : _apis = apis ?? OrderApis();

  final OrderApis _apis;
  List<OrderModel>? _ownerOrders;
  List<OrderModel>? _retailerOrders;
  final Map<String, OrderModel> _details = {};

  @override
  Future<List<OrderModel>> fetchOwnerOrders({bool forceRefresh = false}) async {
    _ensureOwner();
    if (!forceRefresh && _ownerOrders != null) {
      return List.unmodifiable(_ownerOrders!);
    }
    final orders = await hydrateOrdersProducts(await _apis.fetchOwnerOrders());
    _ownerOrders = orders;
    return List.unmodifiable(orders);
  }

  @override
  Future<OrderModel> fetchOwnerOrderDetails(
    String orderId, {
    bool forceRefresh = false,
  }) async {
    _ensureOwner();
    if (!forceRefresh && _details[orderId] != null) return _details[orderId]!;
    final order = await hydrateOrderProducts(
      await _apis.fetchOwnerOrderDetails(orderId),
    );
    _details[order.id] = order;
    updateCachedOrder(order);
    return order;
  }

  @override
  Future<OrderModel> updateOwnerOrderStatus(
    String orderId,
    String status, {
    String? rejectedReason,
  }) async {
    _ensureOwner();
    final order = await _apis.updateOwnerOrderStatus(
      orderId,
      status,
      rejectedReason: rejectedReason,
    );
    updateCachedOrder(order);
    return order;
  }

  @override
  Future<List<OrderModel>> fetchRetailerOrders({
    bool forceRefresh = false,
  }) async {
    _ensureRetailer();
    if (!forceRefresh && _retailerOrders != null) {
      return List.unmodifiable(_retailerOrders!);
    }
    final orders = await hydrateOrdersProducts(
      await _apis.fetchRetailerOrders(),
    );
    _retailerOrders = orders;
    return List.unmodifiable(orders);
  }

  @override
  Future<OrderModel> fetchRetailerOrderDetails(
    String orderId, {
    bool forceRefresh = false,
  }) async {
    _ensureRetailer();
    if (!forceRefresh && _details[orderId] != null) return _details[orderId]!;
    final order = await hydrateOrderProducts(
      await _apis.fetchRetailerOrderDetails(orderId),
    );
    _details[order.id] = order;
    updateCachedOrder(order);
    return order;
  }

  @override
  Future<OrderModel> placeRetailerOrder(
    PlaceRetailerOrderRequest request,
  ) async {
    _ensureRetailer();
    final order = await _apis.placeRetailerOrder(
      request.copyWith(retailerId: _currentUserId()),
    );
    _retailerOrders = [order, ...?_retailerOrders];
    _details[order.id] = order;
    return order;
  }

  @override
  Future<OrderModel> cancelRetailerOrder(String orderId) async {
    _ensureRetailer();
    final order = await _apis.cancelRetailerOrder(orderId);
    updateCachedOrder(order);
    return order;
  }

  @override
  Future<OrderModel> markRetailerDelivered(String orderId) async {
    _ensureRetailer();
    final order = await _apis.markRetailerDelivered(orderId);
    updateCachedOrder(order);
    return order;
  }

  @override
  Future<List<OrderModel>> hydrateOrdersProducts(
    List<OrderModel> orders,
  ) async {
    final hydrated = await Future.wait(orders.map(hydrateOrderProducts));
    return hydrated;
  }

  @override
  Future<OrderModel> hydrateOrderProducts(OrderModel order) async {
    final items = await Future.wait(order.items.map(_hydrateItem));
    final hydrated = order.copyWith(items: items);
    updateCachedOrder(hydrated);
    return hydrated;
  }

  Future<OrderItemModel> _hydrateItem(OrderItemModel item) async {
    if (item.productId.trim().isEmpty) return item;
    try {
      final product = await stock.StockRepository.instance.fetchSingleProduct(
        item.productId,
      );
      final images = product.images
          .map((image) => image.url)
          .where((url) => url.trim().isNotEmpty)
          .toList(growable: false);
      return item.copyWith(
        productId: product.id.isNotEmpty ? product.id : item.productId,
        variantId: _productVariantId(product, fallback: item.variantId),
        productName: product.productName.trim().isNotEmpty
            ? product.productName
            : item.productName,
        imageUrl: images.isNotEmpty ? images.first : item.imageUrl,
        images: images.isNotEmpty ? images : item.images,
        grossWeight: product.weights.grossWeight > 0
            ? product.weights.grossWeight
            : item.grossWeight,
        stoneWeight: product.weights.stoneWeight > 0
            ? product.weights.stoneWeight
            : item.stoneWeight,
        stoneCharge: product.weights.stoneCharge > 0
            ? product.weights.stoneCharge
            : item.stoneCharge,
        netWeight: product.weights.netWeight > 0
            ? product.weights.netWeight
            : item.netWeight,
        rawJson: {...item.rawJson, 'product': product.toJson()},
      );
    } catch (_) {
      return item;
    }
  }

  @override
  void updateCachedOrder(OrderModel order) {
    _details[order.id] = order;
    _ownerOrders = _replaceOrder(_ownerOrders, order);
    _retailerOrders = _replaceOrder(_retailerOrders, order);
  }

  List<OrderModel>? _replaceOrder(List<OrderModel>? source, OrderModel order) {
    if (source == null) return null;
    final index = source.indexWhere((item) => item.id == order.id);
    if (index == -1) return source;
    return List<OrderModel>.from(source)..[index] = order;
  }

  void _ensureOwner() {
    if (UserData.instance.role.trim().toLowerCase() != 'owner') {
      throw const ApiException('Owner access is required for this order API.');
    }
  }

  void _ensureRetailer() {
    if (UserData.instance.role.trim().toLowerCase() != 'retailer') {
      throw const ApiException(
        'Retailer access is required for this order API.',
      );
    }
  }

  String _currentUserId() {
    final user = UserData.instance;
    final id = user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
    if (id.isEmpty) {
      throw const ApiException('User id was not found in the session.');
    }
    return id;
  }
}

String _productVariantId(stock.ProductModel product, {String fallback = ''}) {
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
  return fallback.isNotEmpty ? fallback : product.id;
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

class OrderApis {
  OrderApis({http.Client? client}) : _client = client ?? http.Client();

  static const String ownerOrdersEndpoint = '/api/owner/orders';
  static const String retailerOrdersEndpoint = '/api/retailer/orders';

  final http.Client _client;

  Future<List<OrderModel>> fetchOwnerOrders() =>
      _fetchOrders(ownerOrdersEndpoint);
  Future<List<OrderModel>> fetchRetailerOrders() => _fetchOrders(
    retailerOrdersEndpoint,
    queryParameters: {'retailer_id': _currentRetailerId()},
  );

  Future<OrderModel> placeRetailerOrder(PlaceRetailerOrderRequest request) {
    return _createOrder(retailerOrdersEndpoint, request.toJson());
  }

  Future<OrderModel> fetchOwnerOrderDetails(String orderId) =>
      _fetchOrder('$ownerOrdersEndpoint/${Uri.encodeComponent(orderId)}');
  Future<OrderModel> fetchRetailerOrderDetails(String orderId) =>
      _fetchOrder('$retailerOrdersEndpoint/${Uri.encodeComponent(orderId)}');

  Future<OrderModel> updateOwnerOrderStatus(
    String orderId,
    String status, {
    String? rejectedReason,
  }) {
    final body = <String, dynamic>{'status': normalizeOrderStatus(status)};
    if (rejectedReason != null) body['rejected_reason'] = rejectedReason.trim();
    return _updateStatus(
      '$ownerOrdersEndpoint/${Uri.encodeComponent(orderId)}/status',
      body,
      orderId,
      status,
    );
  }

  Future<OrderModel> cancelRetailerOrder(String orderId) {
    return _updateStatus(
      '$retailerOrdersEndpoint/${Uri.encodeComponent(orderId)}/status',
      {'retailer_id': _currentRetailerId(), 'status': 'Cancelled'},
      orderId,
      'Cancelled',
    );
  }

  Future<OrderModel> markRetailerDelivered(String orderId) {
    return _updateStatus(
      '$retailerOrdersEndpoint/${Uri.encodeComponent(orderId)}/status',
      {'retailer_id': _currentRetailerId(), 'status': 'Delivered'},
      orderId,
      'Delivered',
    );
  }

  Future<List<OrderModel>> _fetchOrders(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUri(endpoint, queryParameters: queryParameters),
            headers: _headers(),
          )
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final list = _readResponseList(decoded, const [
        'orders',
        'data',
        'items',
        'results',
      ]);
      final orders = list
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .where((order) => order.id.isNotEmpty)
          .toList(growable: false);
      orders.sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
      return orders;
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<OrderModel> _fetchOrder(String endpoint) async {
    try {
      final response = await _client
          .get(_buildUri(endpoint), headers: _headers())
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final map = _readFirstMap(decoded, const ['order', 'data', 'item']);
      return OrderModel.fromJson(map.isEmpty ? decoded : map);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<OrderModel> _createOrder(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            _buildUri(endpoint),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final map = _readFirstMap(decoded, const ['order', 'data', 'item']);
      return OrderModel.fromJson(map.isEmpty ? decoded : map);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<OrderModel> _updateStatus(
    String endpoint,
    Map<String, dynamic> body,
    String orderId,
    String fallbackStatus,
  ) async {
    try {
      final response = await _client
          .put(_buildUri(endpoint), headers: _headers(), body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final map = _readFirstMap(decoded, const ['order', 'data', 'item']);
      if (map.isEmpty) {
        return OrderModel.fromJson({'id': orderId, 'status': fallbackStatus});
      }
      return OrderModel.fromJson(map);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Uri _buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    final separator =
        ApiConstants.activeBaseUrl.endsWith('/') || endpoint.startsWith('/')
        ? ''
        : '/';
    final uri = Uri.parse('${ApiConstants.activeBaseUrl}$separator$endpoint');
    final filteredQuery = <String, String>{
      ...uri.queryParameters,
      for (final entry in (queryParameters ?? {}).entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };
    return uri.replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }

  Map<String, String> _headers() {
    final token = UserData.instance.token.trim();
    return {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      if (token.isNotEmpty) ApiConstants.headerAuthorization: 'Bearer $token',
    };
  }

  String _currentRetailerId() {
    final user = UserData.instance;
    final id = user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
    if (id.isEmpty) {
      throw const ApiException('Retailer id was not found in the session.');
    }
    return id;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const {'success': true};
      }
      throw ApiException(
        _fallbackMessageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid response received from server.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final message = decoded['message'] ?? decoded['error'];
    throw ApiException(
      message is String && message.trim().isNotEmpty
          ? message
          : _fallbackMessageForStatus(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _fallbackMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Please check the order details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to manage this order.';
      case 404:
        return 'Order data was not found.';
      case 409:
        return 'This order status has already changed.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong.';
    }
  }
}

String normalizeOrderStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'accepted') return 'Accepted';
  if (normalized == 'rejected') return 'Rejected';
  if (normalized == 'dispatched' || normalized == 'dispatch') {
    return 'Dispatched';
  }
  if (normalized == 'delivered') return 'Delivered';
  if (normalized == 'cancelled' || normalized == 'canceled') return 'Cancelled';
  return 'Pending';
}

bool canOwnerTransition(String from, String to) {
  final current = normalizeOrderStatus(from);
  final next = normalizeOrderStatus(to);
  return (current == 'Pending' && (next == 'Accepted' || next == 'Rejected')) ||
      (current == 'Accepted' && next == 'Dispatched') ||
      (current == 'Dispatched' && next == 'Delivered');
}

bool canRetailerTransition(String from, String to) {
  final current = normalizeOrderStatus(from);
  final next = normalizeOrderStatus(to);
  return (current == 'Pending' && next == 'Cancelled') ||
      (current == 'Dispatched' && next == 'Delivered');
}

DateTime _sortDate(OrderModel order) =>
    order.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);

List<OrderItemModel> _readItems(Map<String, dynamic> json) {
  final list = _readResponseList(json, const [
    'items',
    'order_items',
    'orderItems',
    'products',
  ]);
  return list
      .whereType<Map<String, dynamic>>()
      .map(OrderItemModel.fromJson)
      .toList(growable: false);
}

List<StatusModel> _readHistory(Map<String, dynamic> json, String status) {
  final list = _readResponseList(json, const [
    'status_history',
    'statusHistory',
    'timeline',
    'history',
  ]);
  final history = list
      .whereType<Map<String, dynamic>>()
      .map(StatusModel.fromJson)
      .toList(growable: false);
  if (history.isNotEmpty) return history;
  return [
    StatusModel(
      value: status,
      changedAt: _readDateTime(
        _readObject(json, const ['updated_at', 'updatedAt', 'created_at']),
      ),
    ),
  ];
}

List<dynamic> _readResponseList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final nested = _readResponseList(value, keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

Map<String, dynamic> _readFirstMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

Object? _readObject(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
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

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _readString(item, const [
                'url',
                'image_url',
                'image',
                'secure_url',
              ]);
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '');
}

DateTime? _readDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString().trim())?.toLocal();
}

void _throwIfApiFailed(Map<String, dynamic> decoded, int statusCode) {
  if (decoded['success'] != false) return;
  final message = decoded['message'] ?? decoded['error'];
  throw ApiException(
    message is String && message.trim().isNotEmpty
        ? message
        : 'Something went wrong.',
    statusCode: statusCode,
  );
}
