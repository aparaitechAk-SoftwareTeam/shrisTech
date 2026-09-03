// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';

import '../ApprovalRequest/approved_retailer_apis.dart';
import '../OffersModule/OffersApis.dart' hide ProductModel;
import '../Order Management Module/OrderApis.dart';
import '../Stock Listing Module/StockApis.dart';

enum OwnerSectionStatus { loading, success, empty, error }

class OwnerDashboardSummary {
  final int pendingApprovalsCount;
  final int totalProductsCount;
  final int pendingOrdersCount;
  final int activeOffersCount;
  final double totalNetWeightGold; // Total net weight in grams across all orders
  final double avgWeightPerOrder;  // Average gold net weight per order
  final double fulfillmentRate;    // Delivery success percentage
  final Map<String, double> weightByStatus; // Status -> Net Weight (g)
  final Map<String, int> ordersByStatus;    // Status -> Count

  const OwnerDashboardSummary({
    required this.pendingApprovalsCount,
    required this.totalProductsCount,
    required this.pendingOrdersCount,
    required this.activeOffersCount,
    required this.totalNetWeightGold,
    required this.avgWeightPerOrder,
    required this.fulfillmentRate,
    required this.weightByStatus,
    required this.ordersByStatus,
  });

  factory OwnerDashboardSummary.empty() {
    return const OwnerDashboardSummary(
      pendingApprovalsCount: 0,
      totalProductsCount: 0,
      pendingOrdersCount: 0,
      activeOffersCount: 0,
      totalNetWeightGold: 0,
      avgWeightPerOrder: 0,
      fulfillmentRate: 0,
      weightByStatus: {},
      ordersByStatus: {},
    );
  }
}

class OwnerRecentActivityModel {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const OwnerRecentActivityModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class OwnerHomeData {
  final OwnerDashboardSummary summary;
  final List<OrderModel> pendingOrders;
  final List<PendingRequestModel> pendingApprovals;
  final List<OwnerRecentActivityModel> recentActivities;

  const OwnerHomeData({
    required this.summary,
    required this.pendingOrders,
    required this.pendingApprovals,
    required this.recentActivities,
  });
}

abstract class IOwnerHomeRepository {
  Future<OwnerHomeData> fetchHomeData({bool forceRefresh = false});
}

class OwnerHomeRepository implements IOwnerHomeRepository {
  OwnerHomeRepository({
    OrderRepository? orderRepository,
    StockRepository? stockRepository,
    OffersRepository? offersRepository,
    ApprovedRetailerApis? retailerApis,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _stockRepository = stockRepository ?? StockRepository.instance,
        _offersRepository = offersRepository ?? OffersRepository(),
        _retailerApis = retailerApis ?? ApprovedRetailerApis();

  final OrderRepository _orderRepository;
  final StockRepository _stockRepository;
  final OffersRepository _offersRepository;
  final ApprovedRetailerApis _retailerApis;

  OwnerHomeData? _cache;

  @override
  Future<OwnerHomeData> fetchHomeData({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    final results = await Future.wait([
      _safeFetchOrders(forceRefresh: forceRefresh),
      _safeFetchProducts(forceRefresh: forceRefresh),
      _safeFetchOffers(forceRefresh: forceRefresh),
      _safeFetchApprovals(),
    ]);

    final orders = results[0] as List<OrderModel>;
    final products = results[1] as List<ProductModel>;
    final offers = results[2] as List<OfferModel>;
    final approvals = results[3] as List<PendingRequestModel>;

    // Compute Gold Wholesaler Order Analytics & Metrics
    double totalWeight = 0;
    int pendingOrdersCount = 0;
    int deliveredOrdersCount = 0;
    final weightByStatus = <String, double>{
      'Pending': 0,
      'Accepted': 0,
      'Dispatched': 0,
      'Delivered': 0,
      'Rejected': 0,
    };
    final ordersByStatus = <String, int>{
      'Pending': 0,
      'Accepted': 0,
      'Dispatched': 0,
      'Delivered': 0,
      'Rejected': 0,
    };

    final pendingOrdersList = <OrderModel>[];

    for (final order in orders) {
      final statusKey = _normalizeStatusKey(order.status);
      ordersByStatus[statusKey] = (ordersByStatus[statusKey] ?? 0) + 1;

      if (statusKey == 'Pending') {
        pendingOrdersCount++;
        pendingOrdersList.add(order);
      } else if (statusKey == 'Delivered') {
        deliveredOrdersCount++;
      }

      // Sum net weight across order items
      double orderNetWeight = 0;
      for (final item in order.items) {
        if (item.netWeight != null && item.netWeight! > 0) {
          orderNetWeight += item.netWeight! * item.quantity;
        } else if (item.grossWeight != null && item.grossWeight! > 0) {
          final stone = item.stoneWeight ?? 0;
          orderNetWeight += (item.grossWeight! - stone) * item.quantity;
        }
      }
      totalWeight += orderNetWeight;
      weightByStatus[statusKey] = (weightByStatus[statusKey] ?? 0) + orderNetWeight;
    }

    final avgWeight = orders.isNotEmpty ? (totalWeight / orders.length) : 0.0;
    final fulfillment = orders.isNotEmpty
        ? ((deliveredOrdersCount + (ordersByStatus['Accepted'] ?? 0) + (ordersByStatus['Dispatched'] ?? 0)) / orders.length * 100)
        : 100.0;

    final summary = OwnerDashboardSummary(
      pendingApprovalsCount: approvals.length,
      totalProductsCount: products.length,
      pendingOrdersCount: pendingOrdersCount,
      activeOffersCount: offers.length,
      totalNetWeightGold: totalWeight,
      avgWeightPerOrder: avgWeight,
      fulfillmentRate: fulfillment,
      weightByStatus: weightByStatus,
      ordersByStatus: ordersByStatus,
    );

    // Compute Activity Feed
    final activities = _computeActivities(orders, approvals, products);

    final data = OwnerHomeData(
      summary: summary,
      pendingOrders: pendingOrdersList,
      pendingApprovals: approvals,
      recentActivities: activities,
    );

    _cache = data;
    return data;
  }

  Future<List<OrderModel>> _safeFetchOrders({bool forceRefresh = false}) async {
    try {
      return await _orderRepository.fetchOwnerOrders(forceRefresh: forceRefresh);
    } catch (e) {
      log('OwnerHomeRepository fetchOwnerOrders error: $e');
      return const [];
    }
  }

  Future<List<ProductModel>> _safeFetchProducts({bool forceRefresh = false}) async {
    try {
      return await _stockRepository.fetchProducts(forceRefresh: forceRefresh);
    } catch (e) {
      log('OwnerHomeRepository fetchProducts error: $e');
      return const [];
    }
  }

  Future<List<OfferModel>> _safeFetchOffers({bool forceRefresh = false}) async {
    try {
      return await _offersRepository.fetchOffers(forceRefresh: forceRefresh);
    } catch (e) {
      log('OwnerHomeRepository fetchOffers error: $e');
      return const [];
    }
  }

  Future<List<PendingRequestModel>> _safeFetchApprovals() async {
    try {
      return await _retailerApis.fetchPendingRequests();
    } catch (e) {
      log('OwnerHomeRepository fetchPendingRequests error: $e');
      return const [];
    }
  }

  String _normalizeStatusKey(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'pending') return 'Pending';
    if (s == 'accepted' || s == 'processing') return 'Accepted';
    if (s == 'dispatched' || s == 'shipped') return 'Dispatched';
    if (s == 'delivered') return 'Delivered';
    if (s == 'rejected' || s == 'cancelled') return 'Rejected';
    return 'Pending';
  }

  List<OwnerRecentActivityModel> _computeActivities(
    List<OrderModel> orders,
    List<PendingRequestModel> approvals,
    List<ProductModel> products,
  ) {
    final list = <OwnerRecentActivityModel>[];

    for (final app in approvals.take(2)) {
      list.add(
        OwnerRecentActivityModel(
          id: 'act-app-${app.requestId}',
          icon: Icons.person_add_alt_1_rounded,
          title: 'Retailer approval request',
          subtitle: '${app.businessName.isNotEmpty ? app.businessName : app.ownerName} submitted registration.',
          time: 'Pending',
        ),
      );
    }

    for (final order in orders.take(3)) {
      list.add(
        OwnerRecentActivityModel(
          id: 'act-ord-${order.id}',
          icon: Icons.receipt_long_rounded,
          title: 'Wholesale order #${order.orderNumber}',
          subtitle: 'Status: ${order.status} • Shop: ${order.retailer.shopName}',
          time: _formatTime(order.orderDate),
        ),
      );
    }

    if (products.isNotEmpty) {
      final p = products.first;
      list.add(
        OwnerRecentActivityModel(
          id: 'act-prd-${p.id}',
          icon: Icons.inventory_2_rounded,
          title: 'Stock inventory updated',
          subtitle: '${p.productName} updated in catalogue.',
          time: 'Catalog',
        ),
      );
    }

    return list.take(5).toList();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
