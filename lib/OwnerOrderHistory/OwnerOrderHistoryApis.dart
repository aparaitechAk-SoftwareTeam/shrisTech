// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_colors.dart';

class OwnerHistoryLogModel {
  final String status;
  final DateTime? date;
  final String message;

  const OwnerHistoryLogModel({
    required this.status,
    this.date,
    required this.message,
  });

  factory OwnerHistoryLogModel.fromJson(Map<String, dynamic> json) {
    return OwnerHistoryLogModel(
      status: _str(json, const ['status', 'title', 'state']),
      date: _date(json['date'] ?? json['created_at'] ?? json['timestamp']),
      message: _str(json, const ['message', 'note', 'description']),
    );
  }
}

class OwnerHistoryItemModel {
  final String image;
  final String productName;
  final String productCode;
  final int quantity;
  final double grossWeight;
  final double stoneWeight;
  final double stoneCharge;
  final double netWeight;

  const OwnerHistoryItemModel({
    required this.image,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.grossWeight,
    required this.stoneWeight,
    required this.stoneCharge,
    required this.netWeight,
  });

  factory OwnerHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final g = _double(json, const ['gross_weight', 'grossWeight', 'gross']);
    final s = _double(json, const ['stone_weight', 'stoneWeight', 'stone']);
    final calculatedNet = (g - s) < 0 ? 0.0 : (g - s);
    final explicitNet = _readNullableDouble(json, const ['net_weight', 'netWeight', 'net']);

    return OwnerHistoryItemModel(
      image: _str(json, const ['image', 'image_url', 'primary_image_url', 'imageUrl', 'src']),
      productName: _str(json, const ['product_name', 'productName', 'name', 'title'], fallback: 'Jewellery Item'),
      productCode: _str(json, const ['product_code', 'productCode', 'sku', 'code']),
      quantity: _int(json, const ['quantity', 'qty', 'count'], fallback: 1),
      grossWeight: g,
      stoneWeight: s,
      stoneCharge: _double(json, const ['stone_charge', 'stoneCharge', 'making_charge']),
      netWeight: explicitNet ?? calculatedNet,
    );
  }
}

class OwnerHistoryOrderModel {
  final String orderId;
  final String orderNumber;
  final String shopName;
  final String ownerName;
  final String userId;
  final String status;
  final String remarks;
  final DateTime? orderDate;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String rejectedReason;
  final List<OwnerHistoryLogModel> logs;
  final List<OwnerHistoryItemModel> items;

  const OwnerHistoryOrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.shopName,
    required this.ownerName,
    required this.userId,
    required this.status,
    required this.remarks,
    this.orderDate,
    this.acceptedAt,
    this.rejectedAt,
    this.dispatchedAt,
    this.deliveredAt,
    required this.rejectedReason,
    required this.logs,
    required this.items,
  });

  Color get statusColor {
    final s = status.trim().toLowerCase();
    if (s == 'pending') return const Color(0xFFEAB308); // Amber
    if (s == 'accepted' || s == 'processing') return AppColors.primaryRoyalBlue; // Royal Blue
    if (s == 'dispatched' || s == 'shipped') return const Color(0xFF9333EA); // Purple
    if (s == 'delivered') return const Color(0xFF16A34A); // Green
    if (s == 'rejected' || s == 'cancelled') return Colors.redAccent; // Red
    return AppColors.primaryRoyalBlue;
  }

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalGrossWeight => items.fold(0.0, (sum, item) => sum + (item.grossWeight * item.quantity));
  double get totalStoneWeight => items.fold(0.0, (sum, item) => sum + (item.stoneWeight * item.quantity));
  double get totalNetWeight => items.fold(0.0, (sum, item) => sum + (item.netWeight * item.quantity));

  factory OwnerHistoryOrderModel.fromJson(Map<String, dynamic> json) {
    final retailer = json['retailer'] is Map<String, dynamic> ? json['retailer'] as Map<String, dynamic> : <String, dynamic>{};
    final user = json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : <String, dynamic>{};
    final merged = {...retailer, ...user, ...json};

    final rawLogs = json['logs'] ?? json['history_logs'] ?? json['timeline'];
    final logsList = <OwnerHistoryLogModel>[];
    if (rawLogs is List) {
      for (final l in rawLogs) {
        if (l is Map<String, dynamic>) {
          logsList.add(OwnerHistoryLogModel.fromJson(l));
        }
      }
    }

    final rawItems = json['items'] ?? json['order_items'] ?? json['products'];
    final itemsList = <OwnerHistoryItemModel>[];
    if (rawItems is List) {
      for (final i in rawItems) {
        if (i is Map<String, dynamic>) {
          itemsList.add(OwnerHistoryItemModel.fromJson(i));
        }
      }
    }

    return OwnerHistoryOrderModel(
      orderId: _str(merged, const ['order_id', 'id', '_id', 'orderId']),
      orderNumber: _str(merged, const ['order_number', 'orderNumber', 'order_no', 'orderNo'], fallback: 'BBS-1001'),
      shopName: _str(merged, const ['shop_name', 'shopName', 'business_name', 'businessName', 'store_name'], fallback: 'Retailer Store'),
      ownerName: _str(merged, const ['owner_name', 'ownerName', 'full_name', 'name'], fallback: 'Retailer Owner'),
      userId: _str(merged, const ['user_id', 'userId', 'retailer_id', 'retailerId']),
      status: _str(merged, const ['status', 'order_status'], fallback: 'Pending'),
      remarks: _str(merged, const ['remarks', 'note', 'notes', 'comment']),
      orderDate: _date(merged['order_date'] ?? merged['created_at'] ?? merged['createdAt']),
      acceptedAt: _date(merged['accepted_at'] ?? merged['acceptedAt']),
      rejectedAt: _date(merged['rejected_at'] ?? merged['rejectedAt']),
      dispatchedAt: _date(merged['dispatched_at'] ?? merged['dispatchedAt']),
      deliveredAt: _date(merged['delivered_at'] ?? merged['deliveredAt']),
      rejectedReason: _str(merged, const ['rejected_reason', 'rejectedReason', 'cancel_reason']),
      logs: logsList,
      items: itemsList,
    );
  }
}

class OwnerHistorySummaryModel {
  final int totalOrders;
  final int pendingCount;
  final int acceptedCount;
  final int deliveredCount;
  final int rejectedCount;

  const OwnerHistorySummaryModel({
    required this.totalOrders,
    required this.pendingCount,
    required this.acceptedCount,
    required this.deliveredCount,
    required this.rejectedCount,
  });

  factory OwnerHistorySummaryModel.fromOrders(List<OwnerHistoryOrderModel> orders) {
    int pending = 0;
    int accepted = 0;
    int delivered = 0;
    int rejected = 0;

    for (final order in orders) {
      final s = order.status.trim().toLowerCase();
      if (s == 'pending') {
        pending++;
      } else if (s == 'accepted' || s == 'processing' || s == 'dispatched') {
        accepted++;
      } else if (s == 'delivered') {
        delivered++;
      } else if (s == 'rejected' || s == 'cancelled') {
        rejected++;
      } else {
        pending++;
      }
    }

    return OwnerHistorySummaryModel(
      totalOrders: orders.length,
      pendingCount: pending,
      acceptedCount: accepted,
      deliveredCount: delivered,
      rejectedCount: rejected,
    );
  }
}

abstract class IOwnerOrderHistoryRepository {
  Future<List<OwnerHistoryOrderModel>> fetchOrderHistory({bool forceRefresh = false});
}

class OwnerOrderHistoryRepository implements IOwnerOrderHistoryRepository {
  OwnerOrderHistoryRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  final ApiClient _client;
  List<OwnerHistoryOrderModel>? _cache;

  static const String _endpoint = '/api/owner/orders/history';

  @override
  Future<List<OwnerHistoryOrderModel>> fetchOrderHistory({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    try {
      final decoded = await _client.get(_endpoint);
      log('fetchOrderHistory decoded: $decoded');

      final List<dynamic> list = decoded['orders'] is List
          ? decoded['orders']
          : (decoded['data'] is List ? decoded['data'] : []);

      final orders = list
          .whereType<Map<String, dynamic>>()
          .map(OwnerHistoryOrderModel.fromJson)
          .toList();

      // Sort newest order_date DESC
      orders.sort((a, b) {
        final da = a.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      _cache = orders;
      return orders;
    } catch (e) {
      log('fetchOrderHistory API error: $e');
      // If endpoint doesn't exist yet, try fallback orders endpoint or produce dummy history
      return _fallbackFetch();
    }
  }

  Future<List<OwnerHistoryOrderModel>> _fallbackFetch() async {
    try {
      final decoded = await _client.get('/api/orders');
      final List<dynamic> list = decoded['orders'] is List
          ? decoded['orders']
          : (decoded['data'] is List ? decoded['data'] : []);

      final orders = list
          .whereType<Map<String, dynamic>>()
          .map(OwnerHistoryOrderModel.fromJson)
          .toList();

      orders.sort((a, b) {
        final da = a.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      _cache = orders;
      return orders;
    } catch (e) {
      log('fallbackFetch error: $e');
      return _generateDummyHistory();
    }
  }

  List<OwnerHistoryOrderModel> _generateDummyHistory() {
    final now = DateTime.now();
    return [
      OwnerHistoryOrderModel(
        orderId: 'ord-hist-1',
        orderNumber: 'BBS-2890',
        shopName: 'Raj Jewellers Wholesale',
        ownerName: 'Rajesh Sharma',
        userId: 'usr-101',
        status: 'Pending',
        remarks: 'Urgent delivery requested for festive gold jewellery stock.',
        orderDate: now.subtract(const Duration(hours: 2)),
        rejectedReason: '',
        logs: [
          OwnerHistoryLogModel(
            status: 'Pending',
            date: now.subtract(const Duration(hours: 2)),
            message: 'Order created and submitted by Raj Jewellers.',
          ),
        ],
        items: const [
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=700&q=80',
            productName: '22K Gold Antique Necklace Set',
            productCode: 'NK-22K-901',
            quantity: 2,
            grossWeight: 48.5,
            stoneWeight: 3.2,
            stoneCharge: 450,
            netWeight: 45.3,
          ),
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1611591475143-be23256ea8e4?auto=format&fit=crop&w=700&q=80',
            productName: '22K Gold Temple Bangle Collection',
            productCode: 'BG-22K-405',
            quantity: 4,
            grossWeight: 32.0,
            stoneWeight: 1.5,
            stoneCharge: 200,
            netWeight: 30.5,
          ),
        ],
      ),
      OwnerHistoryOrderModel(
        orderId: 'ord-hist-2',
        orderNumber: 'BBS-2875',
        shopName: 'Mahalaxmi Gold House',
        ownerName: 'Suresh Patel',
        userId: 'usr-102',
        status: 'Accepted',
        remarks: 'Gold hallmarking verified and assigned to dispatch team.',
        orderDate: now.subtract(const Duration(hours: 18)),
        acceptedAt: now.subtract(const Duration(hours: 12)),
        rejectedReason: '',
        logs: [
          OwnerHistoryLogModel(
            status: 'Pending',
            date: now.subtract(const Duration(hours: 18)),
            message: 'Order placed by Mahalaxmi Gold House.',
          ),
          OwnerHistoryLogModel(
            status: 'Accepted',
            date: now.subtract(const Duration(hours: 12)),
            message: 'Order accepted by BBS GOLD Owner.',
          ),
        ],
        items: const [
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?auto=format&fit=crop&w=700&q=80',
            productName: '18K Diamond Solitaire Ring',
            productCode: 'RG-18K-112',
            quantity: 1,
            grossWeight: 8.4,
            stoneWeight: 1.2,
            stoneCharge: 1200,
            netWeight: 7.2,
          ),
        ],
      ),
      OwnerHistoryOrderModel(
        orderId: 'ord-hist-3',
        orderNumber: 'BBS-2850',
        shopName: 'Verma Jewellers & Sons',
        ownerName: 'Amit Verma',
        userId: 'usr-103',
        status: 'Dispatched',
        remarks: 'Handed to Logistics Partner BlueDart. Air Waybill #BD982731.',
        orderDate: now.subtract(const Duration(days: 2)),
        acceptedAt: now.subtract(const Duration(days: 1, hours: 20)),
        dispatchedAt: now.subtract(const Duration(days: 1, hours: 4)),
        rejectedReason: '',
        logs: [
          OwnerHistoryLogModel(
            status: 'Pending',
            date: now.subtract(const Duration(days: 2)),
            message: 'Order placed by Verma Jewellers.',
          ),
          OwnerHistoryLogModel(
            status: 'Accepted',
            date: now.subtract(const Duration(days: 1, hours: 20)),
            message: 'Order verified and packed.',
          ),
          OwnerHistoryLogModel(
            status: 'Dispatched',
            date: now.subtract(const Duration(days: 1, hours: 4)),
            message: 'Dispatched via insured transit.',
          ),
        ],
        items: const [
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=700&q=80',
            productName: '22K Gold Lightweight Chain SKU-A',
            productCode: 'CH-22K-088',
            quantity: 5,
            grossWeight: 15.2,
            stoneWeight: 0.0,
            stoneCharge: 0,
            netWeight: 15.2,
          ),
        ],
      ),
      OwnerHistoryOrderModel(
        orderId: 'ord-hist-4',
        orderNumber: 'BBS-2810',
        shopName: 'Shree Ganesh Ornaments',
        ownerName: 'Ganesh Joshi',
        userId: 'usr-104',
        status: 'Delivered',
        remarks: 'Delivered and acknowledged by recipient with signature.',
        orderDate: now.subtract(const Duration(days: 4)),
        acceptedAt: now.subtract(const Duration(days: 3, hours: 20)),
        dispatchedAt: now.subtract(const Duration(days: 3, hours: 8)),
        deliveredAt: now.subtract(const Duration(days: 2, hours: 12)),
        rejectedReason: '',
        logs: [
          OwnerHistoryLogModel(
            status: 'Pending',
            date: now.subtract(const Duration(days: 4)),
            message: 'Order placed.',
          ),
          OwnerHistoryLogModel(
            status: 'Accepted',
            date: now.subtract(const Duration(days: 3, hours: 20)),
            message: 'Accepted by Owner.',
          ),
          OwnerHistoryLogModel(
            status: 'Dispatched',
            date: now.subtract(const Duration(days: 3, hours: 8)),
            message: 'Out for delivery.',
          ),
          OwnerHistoryLogModel(
            status: 'Delivered',
            date: now.subtract(const Duration(days: 2, hours: 12)),
            message: 'Delivered successfully.',
          ),
        ],
        items: const [
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?auto=format&fit=crop&w=700&q=80',
            productName: '22K Traditional Bridal Mangalsutra',
            productCode: 'MS-22K-302',
            quantity: 2,
            grossWeight: 28.6,
            stoneWeight: 2.1,
            stoneCharge: 350,
            netWeight: 26.5,
          ),
        ],
      ),
      OwnerHistoryOrderModel(
        orderId: 'ord-hist-5',
        orderNumber: 'BBS-2790',
        shopName: 'Laxmi Gems & Bullion',
        ownerName: 'Vikas Shah',
        userId: 'usr-105',
        status: 'Rejected',
        remarks: 'Cancelled due to incomplete KYC documentation.',
        orderDate: now.subtract(const Duration(days: 6)),
        rejectedAt: now.subtract(const Duration(days: 5, hours: 18)),
        rejectedReason: 'Incomplete business registration proof',
        logs: [
          OwnerHistoryLogModel(
            status: 'Pending',
            date: now.subtract(const Duration(days: 6)),
            message: 'Order placed.',
          ),
          OwnerHistoryLogModel(
            status: 'Rejected',
            date: now.subtract(const Duration(days: 5, hours: 18)),
            message: 'Rejected by Owner. Reason: Incomplete KYC proof.',
          ),
        ],
        items: const [
          OwnerHistoryItemModel(
            image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?auto=format&fit=crop&w=700&q=80',
            productName: '24K Fine Gold Coin (50g)',
            productCode: 'CN-24K-050',
            quantity: 1,
            grossWeight: 50.0,
            stoneWeight: 0.0,
            stoneCharge: 0,
            netWeight: 50.0,
          ),
        ],
      ),
    ];
  }
}

String _str(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
  }
  return fallback;
}

int _int(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final k in keys) {
    final v = json[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

double _double(Map<String, dynamic> json, List<String> keys, {double fallback = 0.0}) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
