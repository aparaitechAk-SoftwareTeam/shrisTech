// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import 'OrderApis.dart';
import 'OrderDetailedScreen.dart';
import 'OrderListScreen.dart';
import 'OrderWidgets.dart';

class SpecificShopOrderListScreen extends StatefulWidget {
  final OrderModel shop;
  final List<OrderModel> orders;

  const SpecificShopOrderListScreen({
    super.key,
    required this.shop,
    required this.orders,
  });

  @override
  State<SpecificShopOrderListScreen> createState() =>
      _SpecificShopOrderListScreenState();
}

class _SpecificShopOrderListScreenState
    extends State<SpecificShopOrderListScreen> {
  static String _savedSearch = '';
  static final Set<String> _savedStatuses = {};
  static OrderSortMode _savedSort = OrderSortMode.newestFirst;
  static double _savedOffset = 0;
  static bool _savedFilterExpanded = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late List<OrderModel> _orders;
  String? _busyOrderId;
  bool _isFilterExpanded = _savedFilterExpanded;

  bool get _hasActiveFilters =>
      _savedStatuses.isNotEmpty || _savedSort != OrderSortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    _orders = List<OrderModel>.from(widget.orders);
    _scrollController = ScrollController(initialScrollOffset: _savedOffset);
    _searchController = TextEditingController(text: _savedSearch);
  }

  @override
  void dispose() {
    _savedOffset = _scrollController.hasClients
        ? _scrollController.offset
        : _savedOffset;
    _savedSearch = _searchController.text;
    _savedFilterExpanded = _isFilterExpanded;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> get _filtered {
    final list = _orders.where((order) {
      return (_savedStatuses.isEmpty ||
              _savedStatuses.contains(normalizeOrderStatus(order.status))) &&
          order.matchesOwner(_searchController.text);
    }).toList();
    list.sort((a, b) {
      final compare = (b.orderDate ?? DateTime(0)).compareTo(
        a.orderDate ?? DateTime(0),
      );
      return _savedSort == OrderSortMode.newestFirst ? compare : -compare;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: widget.shop.retailer.shopName,
      ),
      drawer: GlobalDrawer(selectedIndex: 4, onItemSelected: (_) {}),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isCompact = screenWidth < 360;
              final isTablet = screenWidth >= 700;
              final pad = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
              final maxWidth = screenWidth >= 1100
                  ? 1040.0
                  : (screenWidth >= 700 ? 840.0 : screenWidth);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          isCompact ? 10 : 14,
                          pad,
                          isCompact ? 20 : 28,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            OrderSearchBar(
                              controller: _searchController,
                              hintText: isCompact
                                  ? 'Search order'
                                  : 'Search order number or product',
                              onChanged: (_) => setState(() {}),
                              onClear: () => setState(() {}),
                              isFilterExpanded: _isFilterExpanded,
                              hasActiveFilters: _hasActiveFilters,
                              onToggleFilter: () => setState(
                                () => _isFilterExpanded = !_isFilterExpanded,
                              ),
                            ),
                            FilterPanel(
                              isExpanded: _isFilterExpanded,
                              selectedStatuses: _savedStatuses,
                              sortMode: _savedSort,
                              onStatusToggled: _toggleStatus,
                              onSortChanged: (mode) =>
                                  setState(() => _savedSort = mode),
                              onClearAllFilters: () {
                                setState(() {
                                  _savedStatuses.clear();
                                  _savedSort = OrderSortMode.newestFirst;
                                });
                              },
                            ),
                            SizedBox(height: isCompact ? 12 : 18),
                            if (filtered.isEmpty)
                              EmptyWidget(onRetry: _refresh)
                            else
                              for (final order in filtered) ...[
                                OrderCard(
                                  order: order,
                                  onTap: () => _openDetail(order),
                                  actionArea: ActionButtons(
                                    order: order,
                                    isOwner: true,
                                    loading: _busyOrderId == order.id,
                                    onStatusSelected: (status) =>
                                        _confirmAndUpdate(order, status),
                                  ),
                                ),
                                SizedBox(height: isCompact ? 12 : 16),
                              ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final orders = await sharedOrderRepository.fetchOwnerOrders(
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _orders = orders
          .where(
            (o) =>
                o.retailer.id == widget.shop.retailer.id ||
                o.retailer.shopName == widget.shop.retailer.shopName,
          )
          .toList();
    });
  }

  Future<void> _openDetail(OrderModel order) async {
    final result = await Navigator.of(context).push<OrderModel>(
      MaterialPageRoute(
        builder: (_) => OrderDetailedScreen(
          order: order,
          isOwner: true,
          repository: sharedOrderRepository,
        ),
      ),
    );
    if (!mounted) return;
    try {
      final cached = await sharedOrderRepository.fetchOwnerOrderDetails(
        order.id,
        forceRefresh: false,
      );
      if (mounted) {
        _replace(cached, popResult: false);
      }
    } catch (_) {
      if (result != null && mounted) {
        _replace(result, popResult: false);
      }
    }
  }

  Future<void> _confirmAndUpdate(OrderModel order, String status) async {
    if (!canOwnerTransition(order.status, status) || _busyOrderId != null) {
      return;
    }
    final reason = status == 'Rejected' ? await _reasonDialog() : null;
    if (status == 'Rejected' && reason == null) return;
    final confirmed = status == 'Rejected'
        ? true
        : await _confirmDialog(status);
    if (confirmed != true) return;
    final previous = order;
    final optimistic = order.copyWith(
      status: status,
      rejectedReason: reason ?? order.rejectedReason,
    );
    _replace(optimistic, popResult: false);
    setState(() => _busyOrderId = order.id);
    try {
      final updated = await sharedOrderRepository.updateOwnerOrderStatus(
        order.id,
        status,
        rejectedReason: reason,
      );
      if (!mounted) return;
      _replace(updated.id.isEmpty ? optimistic : updated, popResult: false);
      _snack(
        'Order status updated to ${normalizeOrderStatus(status)}.',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;
      _replace(previous, popResult: false);
      _snack(
        error is ApiException
            ? error.message
            : 'Unable to update order status.',
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  void _replace(OrderModel order, {required bool popResult}) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    OrderModel merged = order;
    setState(() {
      if (index == -1) {
        _orders = [order, ..._orders];
      } else {
        final existing = _orders[index];
        final isSparse =
            order.orderNumber == 'N/A' ||
            order.primaryItem.productName == 'N/A';
        merged = isSparse
            ? existing.copyWith(
                status: order.status,
                rejectedReason: order.rejectedReason.isNotEmpty
                    ? order.rejectedReason
                    : existing.rejectedReason,
                cancelledReason: order.cancelledReason.isNotEmpty
                    ? order.cancelledReason
                    : existing.cancelledReason,
                history: order.history.isNotEmpty
                    ? order.history
                    : existing.history,
              )
            : order;
        _orders = List<OrderModel>.from(_orders)..[index] = merged;
      }
    });
    if (popResult) Navigator.of(context).pop(merged);
  }

  void _toggleStatus(String status) {
    setState(
      () => _savedStatuses.contains(status)
          ? _savedStatuses.remove(status)
          : _savedStatuses.add(status),
    );
  }

  Future<bool?> _confirmDialog(String status) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${status == 'Dispatched' ? 'Dispatch' : status} Order?'),
      content: Text(
        'This will move the order to ${normalizeOrderStatus(status)}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  Future<String?> _reasonDialog() {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
