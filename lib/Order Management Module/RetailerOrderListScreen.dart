// ignore_for_file: file_names

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import 'OrderApis.dart';
import 'OrderDetailedScreen.dart';
import 'OrderListScreen.dart';
import 'OrderWidgets.dart';

class RetailerOrderListScreen extends StatefulWidget {
  const RetailerOrderListScreen({super.key});

  @override
  State<RetailerOrderListScreen> createState() =>
      _RetailerOrderListScreenState();
}

class _RetailerOrderListScreenState extends State<RetailerOrderListScreen>
    with SingleTickerProviderStateMixin {
  static double _savedOffset = 0;
  static String _savedSearch = '';
  static final Set<String> _savedStatuses = {};
  static OrderSortMode _savedSort = OrderSortMode.newestFirst;
  static List<OrderModel> _savedOrders = const [];
  static bool _savedFilterExpanded = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  List<OrderModel> _orders = const [];
  bool _loading = false;
  int _footerIndex = 3;
  String? _error;
  String? _busyOrderId;
  bool _isFilterExpanded = _savedFilterExpanded;

  bool get _hasActiveFilters =>
      _savedStatuses.isNotEmpty || _savedSort != OrderSortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    log(
      'RetailerOrderListScreen initialized: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
    );
    _orders = List<OrderModel>.from(_savedOrders);
    _scrollController = ScrollController(initialScrollOffset: _savedOffset);
    _searchController = TextEditingController(text: _savedSearch);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    if (_orders.isEmpty) _load();
    if (_orders.isNotEmpty) _hydratePreservedOrders();
  }

  @override
  void dispose() {
    _savedOffset = _scrollController.hasClients
        ? _scrollController.offset
        : _savedOffset;
    _savedSearch = _searchController.text;
    _savedOrders = List<OrderModel>.from(_orders);
    _savedFilterExpanded = _isFilterExpanded;
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> get _filtered {
    final list = _orders.where((order) {
      return (_savedStatuses.isEmpty ||
              _savedStatuses.contains(normalizeOrderStatus(order.status))) &&
          order.matchesRetailer(_searchController.text);
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
    final orders = _filtered;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(selectedIndex: 3, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooter,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _load(forceRefresh: true),
          child: FadeTransition(
            opacity: _fade,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isCompact = screenWidth < 360;
                final isTablet = screenWidth >= 650;
                final pad = isTablet ? 28.0 : (isCompact ? 12.0 : 16.0);
                final maxWidth = screenWidth >= 1100
                    ? 1040.0
                    : (screenWidth >= 700 ? 820.0 : screenWidth);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: CustomScrollView(
                      key: const PageStorageKey('retailer-orders'),
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
                            26,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              OrderSearchBar(
                                controller: _searchController,
                                hintText: 'Search order number or product...',
                                onChanged: (_) {
                                  _savedSearch = _searchController.text;
                                  setState(() {});
                                },
                                onClear: () {
                                  _savedSearch = '';
                                  setState(() {});
                                },
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

                              const SizedBox(height: 8),
                              if (_loading) ...const [
                                ShimmerCard(),
                                SizedBox(height: 14),
                                ShimmerCard(),
                              ] else if (_error != null)
                                OrderErrorWidget(
                                  message: _error!,
                                  onRetry: () => _load(forceRefresh: true),
                                )
                              else if (orders.isEmpty)
                                EmptyWidget(
                                  onRetry: () => _load(forceRefresh: true),
                                )
                              else
                                for (final order in orders) ...[
                                  OrderCard(
                                    order: order,
                                    onTap: () => _openDetail(order),
                                    actionArea: ActionButtons(
                                      order: order,
                                      isOwner: false,
                                      loading: _busyOrderId == order.id,
                                      onStatusSelected: (status) =>
                                          _confirmAndUpdate(order, status),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 10 : 14),
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
      ),
    );
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = _orders.isEmpty;
      _error = null;
    });
    try {
      final orders = await sharedOrderRepository.fetchRetailerOrders(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _orders = orders);
      _savedOrders = List<OrderModel>.from(orders);
      for (final order in orders) {
        for (final image in order.images.take(2)) {
          final uri = Uri.tryParse(image);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            precacheImage(NetworkImage(image), context);
          }
        }
      }
    } catch (error) {
      if (!mounted) return;
      if (_orders.isEmpty) {
        setState(() => _error = _errorText(error));
      } else {
        _snack(_errorText(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hydratePreservedOrders() async {
    try {
      final orders = await sharedOrderRepository.hydrateOrdersProducts(_orders);
      if (!mounted) return;
      setState(() => _orders = orders);
      _savedOrders = List<OrderModel>.from(orders);
    } catch (_) {
      // Preserve the existing list if product hydration is unavailable.
    }
  }

  Future<void> _openDetail(OrderModel order) async {
    final result = await Navigator.of(context).push<OrderModel>(
      MaterialPageRoute(
        builder: (_) => OrderDetailedScreen(
          order: order,
          isOwner: false,
          repository: sharedOrderRepository,
        ),
      ),
    );
    if (!mounted) return;
    try {
      final cached = await sharedOrderRepository.fetchRetailerOrderDetails(
        order.id,
        forceRefresh: false,
      );
      if (mounted) {
        _replace(cached);
      }
    } catch (_) {
      if (result != null && mounted) _replace(result);
    }
  }

  Future<void> _confirmAndUpdate(OrderModel order, String status) async {
    if (!canRetailerTransition(order.status, status) || _busyOrderId != null) {
      return;
    }
    final confirmed = await _confirmDialog(status);
    if (confirmed != true) return;
    final previous = order;
    final optimistic = order.copyWith(status: status);
    _replace(optimistic);
    setState(() => _busyOrderId = order.id);
    try {
      final updated = status == 'Cancelled'
          ? await sharedOrderRepository.cancelRetailerOrder(order.id)
          : await sharedOrderRepository.markRetailerDelivered(order.id);
      if (!mounted) return;
      _replace(updated.id.isEmpty ? optimistic : updated);
      _snack(
        'Order status updated to ${normalizeOrderStatus(status)}.',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;
      _replace(previous);
      _snack(_errorText(error));
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  void _replace(OrderModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    setState(() {
      if (index == -1) {
        _orders = [order, ..._orders];
      } else {
        final existing = _orders[index];
        final isSparse =
            order.orderNumber == 'N/A' ||
            order.primaryItem.productName == 'N/A';
        final merged = isSparse
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
    _savedOrders = List<OrderModel>.from(_orders);
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
      title: Text('${status == 'Cancelled' ? 'Cancel' : status} Order?'),
      content: Text(
        'This will move the order to ${normalizeOrderStatus(status)}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  void _handleFooter(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
      return;
    }
    if (index == 1) {
      setState(() => _footerIndex = index);
      Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.offers);
      return;
    }
    if (index == 3) {
      setState(() => _footerIndex = 3);
      return;
    }
    setState(() => _footerIndex = index);
    Navigator.of(context).pushNamed(AppRoutes.retailerCart);
  }

  String _errorText(Object error) => error is ApiException
      ? error.message
      : error is SocketException
      ? 'Please check your internet connection.'
      : 'Something went wrong.';
  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
