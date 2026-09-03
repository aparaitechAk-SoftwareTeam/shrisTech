// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../Stock Listing Module/StockApis.dart';
import '../Stock Listing Module/StockWidget.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import 'RetailerProductWeightScreen.dart';

class RetailerProductNameListScreen extends StatefulWidget {
  const RetailerProductNameListScreen({super.key});

  static const String routeName = AppRoutes.retailerCatalogue;

  @override
  State<RetailerProductNameListScreen> createState() =>
      _RetailerProductNameListScreenState();
}

class _RetailerProductNameListScreenState
    extends State<RetailerProductNameListScreen>
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
    log(
      'RetailerProductNameListScreen initialized for user: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
    );
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 10 : 14,
                        horizontalPadding,
                        isCompact ? 8 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StockSearchBar(
                            controller: _searchController,
                            hintText: 'Search product name...',
                            onClear: _clearSearch,
                            onChanged: _onSearchChanged,
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildBody(horizontalPadding, isCompact)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(double horizontalPadding, bool isCompact) {
    if (_loading) {
      return ListView.separated(
        key: const PageStorageKey<String>('retailer-catalogue-loading'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          4,
          horizontalPadding,
          24,
        ),
        itemCount: 6,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 12),
        itemBuilder: (context, index) =>
            _CatalogueShimmerCard(isCompact: isCompact),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        backgroundColor: AppColors.bg,
        onRefresh: () => _loadProducts(forceRefresh: true),
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
          child: StockErrorWidget(
            message: _error!,
            onRetry: () => _loadProducts(forceRefresh: true),
          ),
        ),
      );
    }

    if (_visibleGroups.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        backgroundColor: AppColors.bg,
        onRefresh: () => _loadProducts(forceRefresh: true),
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
            message: _query.trim().isEmpty
                ? 'Product catalogue is currently empty.'
                : 'No products match your search.',
            onRetry: () => _loadProducts(forceRefresh: true),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      backgroundColor: AppColors.bg,
      onRefresh: () => _loadProducts(forceRefresh: true),
      child: ListView.separated(
        key: const PageStorageKey<String>('retailer-catalogue-list'),
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
        itemCount: _visibleGroups.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 12),
        itemBuilder: (context, index) {
          final group = _visibleGroups[index];
          _precacheNextImage(index);
          return _RetailerProductNameCard(
            group: group,
            isCompact: isCompact,
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
        _error = _errorMsg(error);
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
        .where((g) {
          if (query.isEmpty) return true;
          return g.productName.toLowerCase().contains(query);
        })
        .toList(growable: false);
    if (!mounted) return;
    setState(() => _visibleGroups = visible);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            RetailerProductWeightScreen(
              productName: group.productName,
              products: group.products,
            ),
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

  void _precacheNextImage(int index) {
    if (index + 1 >= _visibleGroups.length) return;
    final url = _visibleGroups[index + 1].imageUrl;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;
    precacheImage(CachedNetworkImageProvider(url), context);
  }

  void _handleFooterTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 1:
        // Already here
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

  String _errorMsg(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETAILER PRODUCT NAME CARD (Responsive, High Contrast, SaaS Polish)
// ─────────────────────────────────────────────────────────────────────────────

class _RetailerProductNameCard extends StatefulWidget {
  final ProductNameGroup group;
  final bool isCompact;
  final VoidCallback onTap;

  const _RetailerProductNameCard({
    required this.group,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_RetailerProductNameCard> createState() =>
      _RetailerProductNameCardState();
}

class _RetailerProductNameCardState extends State<_RetailerProductNameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isCompact = widget.isCompact;
    final imageSize = isCompact ? 64.0 : 74.0;
    final hasImage =
        group.imageUrl.isNotEmpty &&
        (Uri.tryParse(group.imageUrl)?.hasAbsolutePath ?? false);

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.98 : 1.0,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: AppColors.accentGoldGlow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              color: AppColors.surfaceWhite,
            ),
            child: Row(
              children: [
                // ── Thumbnail ───────────────────────────────────────────────
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: group.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const StockImageShimmer(),
                          errorWidget: (context, url, error) =>
                              const StockImagePlaceholder(),
                        )
                      : const StockImagePlaceholder(),
                ),
                SizedBox(width: isCompact ? 10 : 14),

                // ── Details ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 14 : 15.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 8 : 10,
                              vertical: isCompact ? 2.5 : 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLightBlue,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.borderGold.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.layers_rounded,
                                  size: isCompact ? 11 : 12.5,
                                  color: AppColors.primaryRoyalBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.count} Product${group.count == 1 ? '' : 's'}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryRoyalBlue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 10.5 : 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Trailing Arrow Action ────────────────────────────────────
                const SizedBox(width: 6),
                Container(
                  width: isCompact ? 30 : 34,
                  height: isCompact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentGoldDark,
                    size: isCompact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATALOGUE SHIMMER SKELETON
// ─────────────────────────────────────────────────────────────────────────────

class _CatalogueShimmerCard extends StatelessWidget {
  final bool isCompact;

  const _CatalogueShimmerCard({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final imageSize = isCompact ? 64.0 : 74.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Row(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(width: isCompact ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: isCompact ? 30 : 34,
              height: isCompact ? 30 : 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
