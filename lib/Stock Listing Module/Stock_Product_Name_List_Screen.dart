// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../navigation/app_routes.dart';
import 'StockApis.dart';
import 'StockWeight.dart';
import 'StockWidget.dart';

class StockProductNameListScreen extends StatefulWidget {
  const StockProductNameListScreen({super.key});

  static const String routeName = AppRoutes.stockListing;

  @override
  State<StockProductNameListScreen> createState() =>
      _StockProductNameListScreenState();
}

class _StockProductNameListScreenState extends State<StockProductNameListScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IStockRepository _repository = StockRepository.instance;

  Timer? _debounce;
  List<ProductModel> _products = const [];
  List<ProductNameGroup> _groups = const [];
  List<ProductNameGroup> _visibleGroups = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: StockStrings.title,
      ),
      drawer: GlobalDrawer(selectedIndex: 3, onItemSelected: (_) {}),
      bottomNavigationBar: GlobalFooter(
        currentIndex: 1,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 700;
            final horizontalPadding = isTablet
                ? 34.0
                : (isCompact ? 12.0 : 18.0);
            final maxWidth = screenWidth >= 1100
                ? 1040.0
                : (screenWidth >= 700 ? 840.0 : screenWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 12 : 18,
                        horizontalPadding,
                        isCompact ? 8 : 10,
                      ),
                      child: StockSearchBar(
                        controller: _searchController,
                        hintText: isCompact
                            ? 'Search product'
                            : 'Search product name',
                        onClear: _clearSearch,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(
                      child: _buildBody(
                        horizontalPadding: horizontalPadding,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required double horizontalPadding,
    required bool isCompact,
  }) {
    if (_loading) {
      return ListView.separated(
        key: const PageStorageKey<String>('stock-name-loading'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isCompact ? 4 : 6,
          horizontalPadding,
          24,
        ),
        itemCount: 7,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 14),
        itemBuilder: (context, index) => const StockShimmerCard(compact: true),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        onRefresh: () => _loadProducts(forceRefresh: true),
        child: StockErrorWidget(
          message: _error!,
          onRetry: () => _loadProducts(forceRefresh: true),
        ),
      );
    }

    if (_visibleGroups.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        onRefresh: () => _loadProducts(forceRefresh: true),
        child: StockEmptyWidget(
          message: _query.trim().isEmpty
              ? 'Your product catalogue is empty.'
              : 'No product names match your search.',
          onRetry: () => _loadProducts(forceRefresh: true),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      onRefresh: () => _loadProducts(forceRefresh: true),
      child: ListView.separated(
        key: const PageStorageKey<String>('stock-name-list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isCompact ? 4 : 6,
          horizontalPadding,
          isCompact ? 20 : 24,
        ),
        itemCount: _visibleGroups.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 14),
        itemBuilder: (context, index) {
          final group = _visibleGroups[index];
          _precacheNextImage(index);
          return StockProductNameCard(
            group: group,
            onTap: () => _openWeightScreen(group),
          );
        },
      ),
    );
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final products = await _repository.fetchProducts(
        forceRefresh: forceRefresh,
      );
      final groups = _repository.groupByProductName(products);
      if (!mounted) return;
      setState(() {
        _products = products;
        _groups = groups;
        _loading = false;
      });
      _applySearch();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
        _products = _repository.cachedProducts();
        _groups = _repository.groupByProductName(_products);
      });
      _applySearch();
    }
  }

  void _applySearch() {
    final query = _query.trim().toLowerCase();
    final visible = _groups
        .where((group) {
          if (query.isEmpty) return true;
          return group.productName.toLowerCase().contains(query);
        })
        .toList(growable: false);
    if (!mounted) return;
    setState(() => _visibleGroups = visible);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _query = value;
      _applySearch();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _applySearch();
  }

  void _openWeightScreen(ProductNameGroup group) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return StockWeightScreen(
            productName: group.productName,
            products: group.products,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _precacheNextImage(int index) {
    if (index + 1 >= _visibleGroups.length) return;
    final url = _visibleGroups[index + 1].imageUrl;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return;
    }
    precacheImage(NetworkImage(url), context);
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) return;
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.addProduct).then((_) {
        _loadProducts(forceRefresh: true);
      });
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
    setState(() {});
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
