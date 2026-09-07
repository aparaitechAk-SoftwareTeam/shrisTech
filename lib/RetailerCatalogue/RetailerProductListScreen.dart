// ignore_for_file: file_names

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../Stock Listing Module/StockApis.dart';
import '../Stock Listing Module/StockWidget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'RetailerProductDetailScreen.dart';

class RetailerProductListScreen extends StatefulWidget {
  final String productName;
  final StockWeightRange range;
  final List<ProductModel> products;

  const RetailerProductListScreen({
    super.key,
    required this.productName,
    required this.range,
    required this.products,
  });

  @override
  State<RetailerProductListScreen> createState() =>
      _RetailerProductListScreenState();
}

class _RetailerProductListScreenState extends State<RetailerProductListScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IStockRepository _repository = StockRepository.instance;

  Timer? _debounce;
  late List<ProductModel> _sourceProducts;
  List<ProductModel> _visibleProducts = const [];
  String _query = '';
  StockSortOption _sortOption = StockSortOption.none;
  bool _filterExpanded = false;
  bool _refreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sourceProducts = List<ProductModel>.unmodifiable(widget.products);
    _recomputeFiltersAndSort();
  }

  @override
  void didUpdateWidget(covariant RetailerProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products ||
        oldWidget.range.id != widget.range.id) {
      _sourceProducts = List<ProductModel>.unmodifiable(widget.products);
      _recomputeFiltersAndSort();
    }
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
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(selectedIndex: 1, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: 1,
        onTap: _handleFooterTap,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 650;
            final horizontalPadding = isTablet
                ? 28.0
                : (isCompact ? 12.0 : 16.0);
            final maxWidth = screenWidth >= 1100
                ? 1040.0
                : (screenWidth >= 700 ? 820.0 : screenWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 10 : 14,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        children: [
                          StockSearchBar(
                            controller: _searchController,
                            hintText: 'Search in this weight group...',
                            onClear: _clearSearch,
                            onChanged: _onSearchChanged,
                            isFilterExpanded: _filterExpanded,
                            hasActiveFilters:
                                _sortOption != StockSortOption.none,
                            onToggleFilter: () => setState(
                              () => _filterExpanded = !_filterExpanded,
                            ),
                          ),
                          _FilterSortPanel(
                            expanded: _filterExpanded,
                            sortOption: _sortOption,
                            isCompact: isCompact,
                            onToggle: () => setState(
                              () => _filterExpanded = !_filterExpanded,
                            ),
                            onSortSelected: (value) {
                              setState(() => _sortOption = value);
                              _recomputeFiltersAndSort();
                            },
                            onClear: _clearFilters,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(child: _buildList(horizontalPadding, isCompact)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(double horizontalPadding, bool isCompact) {
    if (_refreshing) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          6,
          horizontalPadding,
          24,
        ),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 14),
        itemBuilder: (context, index) => const StockShimmerCard(),
      );
    }

    if (_visibleProducts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        backgroundColor: AppColors.bg,
        onRefresh: _refreshAfterExternalChange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            24,
          ),
          child: StockEmptyWidget(
            message: _query.isEmpty
                ? 'No products exist in ${widget.range.label}.'
                : 'No products match your current search or filters.',
            onRetry: _refreshAfterExternalChange,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      backgroundColor: AppColors.bg,
      onRefresh: _refreshAfterExternalChange,
      child: ListView.separated(
        key: PageStorageKey<String>(
          'retailer-products-${widget.productName}-${widget.range.id}',
        ),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          4,
          horizontalPadding,
          28,
        ),
        itemCount: _visibleProducts.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 12),
        itemBuilder: (context, index) {
          final product = _visibleProducts[index];
          _precacheVisibleImages(index);
          return StockProductCard(
            product: product,
            onTap: () => _openDetails(product),
          );
        },
      ),
    );
  }

  void _recomputeFiltersAndSort() {
    var items = _sourceProducts
        .where((p) {
          if (!widget.range.contains(p.weights.netWeight)) return false;
          if (!_matchesSearch(p)) return false;
          return true;
        })
        .toList(growable: false);
    items = _sortProducts(items);
    if (!mounted) return;
    setState(() => _visibleProducts = items);
  }

  List<ProductModel> _sortProducts(List<ProductModel> items) {
    final sorted = List<ProductModel>.from(items);
    switch (_sortOption) {
      case StockSortOption.netWeightAsc:
        sorted.sort(
          (a, b) => a.weights.netWeight.compareTo(b.weights.netWeight),
        );
      case StockSortOption.netWeightDesc:
        sorted.sort(
          (a, b) => b.weights.netWeight.compareTo(a.weights.netWeight),
        );
      case StockSortOption.newest:
        sorted.sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      case StockSortOption.oldest:
        sorted.sort(
          (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      case StockSortOption.none:
        break;
    }
    return List<ProductModel>.unmodifiable(sorted);
  }

  bool _matchesSearch(ProductModel product) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return product.productName.toLowerCase().contains(query);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _query = value;
      _recomputeFiltersAndSort();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _recomputeFiltersAndSort();
  }

  void _clearFilters() {
    setState(() => _sortOption = StockSortOption.none);
    _recomputeFiltersAndSort();
  }

  Future<void> _refreshAfterExternalChange() async {
    if (mounted) setState(() => _refreshing = true);
    final allProducts = await _repository.fetchProducts(forceRefresh: true);
    final next = allProducts
        .where(
          (p) =>
              p.productName.toLowerCase() == widget.productName.toLowerCase() &&
              widget.range.contains(p.weights.netWeight),
        )
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _sourceProducts = List<ProductModel>.unmodifiable(next);
      _refreshing = false;
    });
    _recomputeFiltersAndSort();
  }

  void _openDetails(ProductModel product) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RetailerProductDetailScreen(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
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
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _precacheVisibleImages(int index) {
    for (final nextIndex in [index + 1, index + 2]) {
      if (nextIndex >= _visibleProducts.length) continue;
      final url = _visibleProducts[nextIndex].primaryImageUrl;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        continue;
      }
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  void _handleFooterTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 1:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.retailerCatalogue,
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.offers);
        break;
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.orderManagement);
        break;
      case 4:
        Navigator.of(context).pushNamed(AppRoutes.retailerCart);
        break;
      default:
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT LIST HEADER STRIP (Weight Range & Result Metrics)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListHeaderStrip extends StatelessWidget {
  final String productName;
  final String rangeLabel;
  final int visibleCount;
  final int totalCount;
  final bool isCompact;
  final bool hasFilter;
  final VoidCallback onClearFilter;

  const _ProductListHeaderStrip({
    required this.productName,
    required this.rangeLabel,
    required this.visibleCount,
    required this.totalCount,
    required this.isCompact,
    required this.hasFilter,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLightBlue,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.scale_rounded,
                size: 13,
                color: AppColors.primaryRoyalBlue,
              ),
              const SizedBox(width: 5),
              Text(
                rangeLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 7 : 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentGoldSubtle,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.5),
              width: 0.6,
            ),
          ),
          child: Text(
            '$visibleCount product${visibleCount == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(
              color: AppColors.accentGoldDark,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 10 : 11.5,
            ),
          ),
        ),
        const Spacer(),
        if (hasFilter)
          InkWell(
            onTap: onClearFilter,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Reset Sort',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 10.5 : 11.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER / SORT PANEL (Responsive chips, high contrast, smooth expand)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSortPanel extends StatelessWidget {
  final bool expanded;
  final StockSortOption sortOption;
  final bool isCompact;
  final VoidCallback onToggle;
  final ValueChanged<StockSortOption> onSortSelected;
  final VoidCallback onClear;

  const _FilterSortPanel({
    required this.expanded,
    required this.sortOption,
    required this.isCompact,
    required this.onToggle,
    required this.onSortSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = sortOption != StockSortOption.none;
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: expanded
          ? Container(
              margin: const EdgeInsets.only(top: 10),
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                border: Border.all(
                  color: AppColors.borderGold.withValues(alpha: 0.8),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.accentGoldGlow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primaryRoyalBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort Products',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                      const Spacer(),
                      if (hasFilters)
                        TextButton(
                          onPressed: onClear,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 11.5 : 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: isCompact ? 6 : 8,
                    runSpacing: isCompact ? 6 : 8,
                    children: [
                      for (final option in StockSortOption.values)
                        StockWeightChip(
                          label: option.label,
                          selected: sortOption == option,
                          onSelected: () => onSortSelected(option),
                        ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
