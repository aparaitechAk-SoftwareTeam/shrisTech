// ignore_for_file: file_names

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'StockApis.dart';
import 'StockProductDetailedScreen.dart';
import 'StockWidget.dart';

class StockProductListScreen extends StatefulWidget {
  final String productName;
  final StockWeightRange range;
  final List<ProductModel> products;

  const StockProductListScreen({
    super.key,
    required this.productName,
    required this.range,
    required this.products,
  });

  @override
  State<StockProductListScreen> createState() => _StockProductListScreenState();
}

class _StockProductListScreenState extends State<StockProductListScreen>
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
  void didUpdateWidget(covariant StockProductListScreen oldWidget) {
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
            final horizontalPadding =
                isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
            final maxWidth =
                screenWidth >= 1100
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
                        isCompact ? 10 : 14,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StockSearchBar(
                                  controller: _searchController,
                                  hintText: isCompact
                                      ? 'Search weight group'
                                      : 'Search within this weight group',
                                  onClear: _clearSearch,
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: isCompact ? 48 : 52,
                                width: isCompact ? 48 : 52,
                                child: IconButton.filled(
                                  tooltip: 'Add Product',
                                  onPressed: _openAddProduct,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryRoyalBlue,
                                    foregroundColor: AppColors.accentGold,
                                  ),
                                  icon: Icon(
                                    Icons.add_rounded,
                                    size: isCompact ? 22 : 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          _FilterSortPanel(
                            expanded: _filterExpanded,
                            sortOption: _sortOption,
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
                    Expanded(
                      child: _buildList(
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

  Widget _buildList({
    required double horizontalPadding,
    required bool isCompact,
  }) {
    if (_refreshing) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isCompact ? 10 : 14,
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
        onRefresh: _refreshAfterExternalChange,
        child: StockEmptyWidget(
          message: _query.isEmpty
              ? 'No products exist in ${widget.range.label}.'
              : 'No products match your current search or filters.',
          onRetry: _refreshAfterExternalChange,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      onRefresh: _refreshAfterExternalChange,
      child: ListView.separated(
        key: PageStorageKey<String>(
          'stock-products-${widget.productName}-${widget.range.id}',
        ),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isCompact ? 10 : 14,
          horizontalPadding,
          isCompact ? 20 : 24,
        ),
        itemCount: _visibleProducts.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 14),
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
        .where((product) {
          if (!widget.range.contains(product.weights.netWeight)) return false;
          if (!_matchesSearch(product)) return false;
          return true;
        })
        .toList(growable: false);

    items = _sortProducts(items);

    if (!mounted) return;
    setState(() {
      _visibleProducts = items;
    });
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
    _debounce = Timer(const Duration(milliseconds: 320), () {
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

  Future<void> _openAddProduct() async {
    final changed = await Navigator.of(context).pushNamed(AppRoutes.addProduct);
    if (changed != null || mounted) {
      await _refreshAfterExternalChange();
    }
  }

  Future<void> _refreshAfterExternalChange() async {
    if (mounted) setState(() => _refreshing = true);
    final allProducts = await _repository.fetchProducts(forceRefresh: true);
    final next = allProducts
        .where((product) {
          return product.productName.toLowerCase() ==
                  widget.productName.toLowerCase() &&
              widget.range.contains(product.weights.netWeight);
        })
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _sourceProducts = List<ProductModel>.unmodifiable(next);
      _refreshing = false;
    });
    _recomputeFiltersAndSort();
  }

  void _openDetails(ProductModel product) {
    Navigator.of(context)
        .push(
          PageRouteBuilder<ProductModel>(
            pageBuilder: (context, animation, secondaryAnimation) {
              return StockProductDetailedScreen(product: product);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
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
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((updated) {
          if (updated is ProductModel) {
            setState(() {
              _sourceProducts = _sourceProducts
                  .map((item) => item.id == updated.id ? updated : item)
                  .where(
                    (item) => widget.range.contains(item.weights.netWeight),
                  )
                  .toList(growable: false);
            });
            _recomputeFiltersAndSort();
          }
        });
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

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) return;
    if (index == 2) {
      _openAddProduct();
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
  }
}

class _StickyWeightHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StickyWeightHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Selected weight range $title',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: Container(
          key: ValueKey(title),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.primaryRoyalBlue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            border: Border(
              bottom: BorderSide(color: AppColors.accentGold, width: 1.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPrimaryGlow,
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSortPanel extends StatelessWidget {
  final bool expanded;
  final StockSortOption sortOption;
  final VoidCallback onToggle;
  final ValueChanged<StockSortOption> onSortSelected;
  final VoidCallback onClear;

  const _FilterSortPanel({
    required this.expanded,
    required this.sortOption,
    required this.onToggle,
    required this.onSortSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = sortOption != StockSortOption.none;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryRoyalBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Filter & Sort',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasFilters)
                      ProductBadge(
                        label: 'Active',
                        compact: true,
                        semanticsLabel: 'Filters active',
                      ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 12),
                  Text(
                    'Sort',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in StockSortOption.values)
                        StockWeightChip(
                          label: option.label,
                          selected: sortOption == option,
                          onSelected: () => onSortSelected(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: hasFilters ? onClear : null,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: const Text('Clear Filter'),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
