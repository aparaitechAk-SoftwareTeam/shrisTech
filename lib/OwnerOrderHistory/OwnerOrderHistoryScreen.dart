// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../navigation/app_routes.dart';
import 'OwnerOrderHistoryApis.dart';
import 'OwnerOrderHistoryDetailScreen.dart';
import 'OwnerOrderHistoryWidgets.dart';

class OwnerOrderHistoryScreen extends StatefulWidget {
  const OwnerOrderHistoryScreen({super.key});

  @override
  State<OwnerOrderHistoryScreen> createState() =>
      _OwnerOrderHistoryScreenState();
}

class _OwnerOrderHistoryScreenState extends State<OwnerOrderHistoryScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOwnerOrderHistoryRepository _repository =
      OwnerOrderHistoryRepository();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  int _footerIndex = 4;
  int _drawerIndex = 5;

  bool _isLoading = true;
  String _errorMessage = '';
  List<OwnerHistoryOrderModel> _allOrders = [];

  // Filter States
  bool _isFilterExpanded = false;
  String _selectedStatus = 'All';
  String _selectedSort = 'Newest First';
  String _shopNameFilter = '';
  String _productNameFilter = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _loadOrderHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderHistory({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orders = await _repository.fetchOrderHistory(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e, stack) {
      log('OwnerOrderHistoryScreen _loadOrderHistory error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load order history. Please try again.';
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = 'All';
      _selectedSort = 'Newest First';
      _shopNameFilter = '';
      _productNameFilter = '';
      _searchController.clear();
    });
  }

  List<OwnerHistoryOrderModel> _computeFilteredOrders() {
    final query = _searchController.text.trim().toLowerCase();

    return _allOrders.where((order) {
      // 1. Search Query filter (Order Number, Shop Name, Owner Name, Product Name)
      if (query.isNotEmpty) {
        final matchesOrderNo = order.orderNumber.toLowerCase().contains(query);
        final matchesShop = order.shopName.toLowerCase().contains(query);
        final matchesOwner = order.ownerName.toLowerCase().contains(query);
        final matchesProducts = order.items.any(
          (item) =>
              item.productName.toLowerCase().contains(query) ||
              item.productCode.toLowerCase().contains(query),
        );

        if (!matchesOrderNo &&
            !matchesShop &&
            !matchesOwner &&
            !matchesProducts) {
          return false;
        }
      }

      // 2. Status filter
      if (_selectedStatus != 'All') {
        final s = order.status.trim().toLowerCase();
        final sel = _selectedStatus.trim().toLowerCase();
        if (sel == 'accepted' && !(s == 'accepted' || s == 'processing')) {
          return false;
        } else if (sel == 'dispatched' &&
            !(s == 'dispatched' || s == 'shipped')) {
          return false;
        } else if (sel == 'rejected' &&
            !(s == 'rejected' || s == 'cancelled')) {
          return false;
        } else if (sel != 'accepted' &&
            sel != 'dispatched' &&
            sel != 'rejected' &&
            s != sel) {
          return false;
        }
      }

      // 3. Shop Name Filter
      if (_shopNameFilter.trim().isNotEmpty) {
        if (!order.shopName.toLowerCase().contains(
          _shopNameFilter.trim().toLowerCase(),
        )) {
          return false;
        }
      }

      // 4. Product Name Filter
      if (_productNameFilter.trim().isNotEmpty) {
        final matchPrd = order.items.any(
          (i) => i.productName.toLowerCase().contains(
            _productNameFilter.trim().toLowerCase(),
          ),
        );
        if (!matchPrd) return false;
      }

      return true;
    }).toList()..sort((a, b) {
      final da = a.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.orderDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _selectedSort == 'Oldest First'
          ? da.compareTo(db)
          : db.compareTo(da);
    });
  }

  Map<String, List<OwnerHistoryOrderModel>> _groupOrdersByDate(
    List<OwnerHistoryOrderModel> orders,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));

    final groups = <String, List<OwnerHistoryOrderModel>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Older': [],
    };

    for (final order in orders) {
      if (order.orderDate == null) {
        groups['Older']!.add(order);
        continue;
      }

      final d = DateTime(
        order.orderDate!.year,
        order.orderDate!.month,
        order.orderDate!.day,
      );

      if (d.isAtSameMomentAs(today)) {
        groups['Today']!.add(order);
      } else if (d.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(order);
      } else if (d.isAfter(thisWeekStart)) {
        groups['This Week']!.add(order);
      } else {
        groups['Older']!.add(order);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  bool get _hasActiveFilters =>
      _selectedStatus != 'All' ||
      _selectedSort != 'Newest First' ||
      _shopNameFilter.isNotEmpty ||
      _productNameFilter.isNotEmpty ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filteredOrders = _computeFilteredOrders();
    final groupedOrders = _groupOrdersByDate(filteredOrders);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Order History Dashboard',
      ),
      drawer: GlobalDrawer(
        selectedIndex: _drawerIndex,
        onItemSelected: (index) => setState(() => _drawerIndex = index),
      ),
      bottomNavigationBar: GlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _loadOrderHistory(forceRefresh: true),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isCompact = screenWidth < 360;
                final isTablet = screenWidth >= 700;
                final horizontalPadding =
                    isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
                final contentWidth = screenWidth >= 1100
                    ? 1040.0
                    : (screenWidth >= 700 ? 840.0 : screenWidth);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: CustomScrollView(
                        key: const PageStorageKey<String>(
                          'owner-history-scroll',
                        ),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          // 1. Search & Filter Header Section
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: isCompact ? 12 : 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OrderHistorySearchBar(
                                    controller: _searchController,
                                    hintText: isCompact
                                        ? 'Search history...'
                                        : 'Search order, shop, owner, product...',
                                    onChanged: _onSearchChanged,
                                    onClear: _clearSearch,
                                    isFilterExpanded: _isFilterExpanded,
                                    hasActiveFilters: _hasActiveFilters,
                                    onToggleFilter: () => setState(
                                      () => _isFilterExpanded =
                                          !_isFilterExpanded,
                                    ),
                                  ),
                                  ExpandableFilterPanel(
                                    isExpanded: _isFilterExpanded,
                                    selectedStatus: _selectedStatus,
                                    selectedSort: _selectedSort,
                                    shopNameQuery: _shopNameFilter,
                                    productNameQuery: _productNameFilter,
                                    onStatusChanged: (s) =>
                                        setState(() => _selectedStatus = s),
                                    onSortChanged: (s) =>
                                        setState(() => _selectedSort = s),
                                    onShopNameChanged: (s) =>
                                        setState(() => _shopNameFilter = s),
                                    onProductNameChanged: (s) =>
                                        setState(() => _productNameFilter = s),
                                    onClearAllFilters: _clearAllFilters,
                                  ),
                                  SizedBox(height: isCompact ? 6 : 8),
                                ],
                              ),
                            ),
                          ),

                          // 2. Loading State
                          if (_isLoading)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    const OwnerHistoryShimmerCard(),
                                childCount: 5,
                              ),
                            )
                          // 3. Error State
                          else if (_errorMessage.isNotEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: OwnerHistoryErrorState(
                                message: _errorMessage,
                                onRetry: () =>
                                    _loadOrderHistory(forceRefresh: true),
                              ),
                            )
                          // 4. Empty State
                          else if (filteredOrders.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: OwnerHistoryEmptyState(
                                onRetry: () =>
                                    _loadOrderHistory(forceRefresh: true),
                              ),
                            )
                          // 5. Grouped Sticky Date Headers & Order Cards
                          else
                            ...groupedOrders.entries.expand((entry) {
                              final groupTitle = entry.key;
                              final ordersInGroup = entry.value;

                              return [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: StickyDateHeaderDelegate(
                                    title: groupTitle,
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    top: isCompact ? 8 : 10,
                                    bottom: isCompact ? 10 : 14,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final order = ordersInGroup[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: isCompact ? 10 : 14,
                                        ),
                                        child: OwnerHistoryOrderCard(
                                          order: order,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OwnerOrderHistoryDetailScreen(
                                                      order: order,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }, childCount: ordersInGroup.length),
                                  ),
                                ),
                              ];
                            }),
                        ],
                      ),
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


  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushNamed(AppRoutes.ownerHome);
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
      setState(() => _footerIndex = 4);
      return;
    }
  }
}
