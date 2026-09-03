// ignore_for_file: file_names

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../navigation/app_routes.dart';
import 'OrderApis.dart';
import 'OrderWidgets.dart';
import 'SpecificShopOrderListScreen.dart';

final OrderRepository sharedOrderRepository = OrderRepository();

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  static const String routeName = '/order_management';

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
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
  bool _isFilterExpanded = _savedFilterExpanded;

  bool get _hasActiveFilters =>
      _savedStatuses.isNotEmpty || _savedSort != OrderSortMode.newestFirst;

  @override
  void initState() {
    super.initState();
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

  List<OrderModel> get _shopOrders {
    final byShop = <String, List<OrderModel>>{};
    for (final order in _orders) {
      final key = order.retailer.id.isNotEmpty
          ? order.retailer.id
          : '${order.retailer.shopName}-${order.retailer.ownerName}';
      byShop.putIfAbsent(key, () => []).add(order);
    }
    final summaries = byShop.values.map((orders) {
      orders.sort(
        (a, b) =>
            (b.orderDate ?? DateTime(0)).compareTo(a.orderDate ?? DateTime(0)),
      );
      final latest = orders.first;
      return latest.copyWith(totalOrders: orders.length);
    }).toList();
    return _applyFilters(summaries, ownerSearch: true);
  }

  List<OrderModel> _applyFilters(
    List<OrderModel> source, {
    required bool ownerSearch,
  }) {
    var list = source.where((order) {
      final statusOk =
          _savedStatuses.isEmpty ||
          _savedStatuses.contains(normalizeOrderStatus(order.status));
      final searchOk = ownerSearch
          ? order.matchesOwner(_searchController.text)
          : order.matchesRetailer(_searchController.text);
      return statusOk && searchOk;
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
    final shops = _shopOrders;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Order Management',
      ),
      drawer: GlobalDrawer(selectedIndex: 4, onItemSelected: (_) {}),
      bottomNavigationBar: GlobalFooter(
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
                final isTablet = screenWidth >= 700;
                final pad = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
                final maxWidth = screenWidth >= 1100
                    ? 1040.0
                    : (screenWidth >= 700 ? 840.0 : screenWidth);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: CustomScrollView(
                      key: const PageStorageKey('owner-order-shops'),
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
                            isCompact ? 20 : 26,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              OrderSearchBar(
                                controller: _searchController,
                                hintText: isCompact
                                    ? 'Search shop or order'
                                    : 'Search shop, owner or order number',
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
                              SizedBox(height: isCompact ? 12 : 18),
                              if (_loading) ...const [
                                ShimmerCard(),
                                SizedBox(height: 16),
                                ShimmerCard(),
                              ] else if (_error != null)
                                OrderErrorWidget(
                                  message: _error!,
                                  onRetry: () => _load(forceRefresh: true),
                                )
                              else if (shops.isEmpty)
                                EmptyWidget(
                                  onRetry: () => _load(forceRefresh: true),
                                )
                              else
                                for (final shop in shops) ...[
                                  OrderCard(
                                    order: shop,
                                    shopCard: true,
                                    onTap: () => _openShop(shop),
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
      log('Message from Order');
      final orders = await sharedOrderRepository.fetchOwnerOrders(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _orders = orders);
      _savedOrders = List<OrderModel>.from(orders);
      for (final order in orders) {
        for (final image in order.images.take(2)) {
          precacheImage(NetworkImage(image), context);
        }
      }
    } catch (error) {
      log(error.toString());
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

  void _toggleStatus(String status) {
    setState(() {
      if (_savedStatuses.contains(status)) {
        _savedStatuses.remove(status);
      } else {
        _savedStatuses.add(status);
      }
    });
  }

  Future<void> _openShop(OrderModel shop) async {
    await Navigator.of(context).push<OrderModel>(
      MaterialPageRoute(
        builder: (_) => SpecificShopOrderListScreen(
          shop: shop,
          orders: _orders
              .where(
                (o) =>
                    o.retailer.id == shop.retailer.id ||
                    o.retailer.shopName == shop.retailer.shopName,
              )
              .toList(),
        ),
      ),
    );
    if (!mounted) return;
    try {
      final orders = await sharedOrderRepository.fetchOwnerOrders(
        forceRefresh: false,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _savedOrders = List<OrderModel>.from(orders);
      });
    } catch (_) {}
  }

  void _handleFooter(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.stockListing);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.addProduct);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.orderManagement);
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushNamed(AppRoutes.orderHistory);
      return;
    }
    setState(() => _footerIndex = index);
  }

  String _errorText(Object error) => error is ApiException
      ? error.message
      : error is SocketException
      ? 'Please check your internet connection.'
      : 'Something went wrong.';
  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
