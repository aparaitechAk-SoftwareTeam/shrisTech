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
      orderNumber: _str(merged, const ['order_number', 'orderNumber', 'order_no', 'orderNo'], fallback: 'ORD-${merged['order_id'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
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
      return const [];
    }
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
