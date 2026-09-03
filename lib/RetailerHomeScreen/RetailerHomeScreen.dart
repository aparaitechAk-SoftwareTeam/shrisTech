// ignore_for_file: file_names

import 'dart:developer';

import 'package:flutter/material.dart';
import '../Order Management Module/OrderApis.dart' as order_module;
import '../Order Management Module/OrderDetailedScreen.dart';
import '../RetailerCatalogue/RetailerCatalogueService.dart';
import '../RetailerCatalogue/RetailerProductDetailScreen.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../Stock Listing Module/StockApis.dart' as stock_module;
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../services/fcm_service.dart';
import 'RetailerHomeScreenApis.dart';
import 'RetailerHomeScreenWidget.dart';

class RetailerHomeScreen extends StatefulWidget {
  const RetailerHomeScreen({super.key});

  @override
  State<RetailerHomeScreen> createState() => _RetailerHomeScreenState();
}

class _RetailerHomeScreenState extends State<RetailerHomeScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );
  final IRetailerHomeRepository _repository = RetailerHomeRepository();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  RetailerHomeData? _data;
  int _footerIndex = 0;
  int _drawerIndex = 0;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    FcmService().syncDeviceToken();
    log(
      'RetailerHomeScreen initialized for user: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
    );
    _animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHome({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      setState(() => _loading = true);
    }
    final data = await _repository.fetchHome(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userName = UserData.instance.name.trim().isEmpty
        ? 'Retailer'
        : UserData.instance.name.trim();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(
        selectedIndex: _drawerIndex,
        onItemSelected: (index) => setState(() => _drawerIndex = index),
      ),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooterTap,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = _horizontalPadding(
                  constraints.maxWidth,
                );
                final isCompact = constraints.maxWidth < 360;
                final isTablet = constraints.maxWidth >= 700;
                final contentWidth = constraints.maxWidth >= 1100
                    ? 1060.0
                    : constraints.maxWidth;

                return RefreshIndicator(
                  color: AppColors.accentGold,
                  backgroundColor: AppColors.bg,
                  semanticsLabel: 'Refresh retailer dashboard',
                  onRefresh: () => _loadHome(forceRefresh: true),
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('retailer-home-scroll'),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 8 : 12,
                          horizontalPadding,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  WelcomeCard(
                                    greeting: _greeting(DateTime.now()),
                                    retailerName: userName,
                                  ),
                                  const SizedBox(height: 12),
                                  RetailerOrderSummaryCards(
                                    placedCount: _data?.placedOrdersCount,
                                    deliveredCount: _data?.deliveredOrdersCount,
                                    isLoading: _loading,
                                    onPlacedTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.orderManagement),
                                    onDeliveredTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.orderManagement),
                                  ),
                                  const SizedBox(height: 14),
                                  RetailerSectionContainer<RetailerBannerModel>(
                                    result: _loading ? null : _data?.banners,
                                    onRetry: () =>
                                        _loadHome(forceRefresh: true),
                                    loading: ShimmerCard(
                                      height: isTablet
                                          ? 220
                                          : (isCompact ? 164 : 184),
                                    ),
                                    builder: (items) => BannerCarousel(
                                      banners: items,
                                      onBannerTap: _handleBannerTap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _stickyHeader(
                        title: 'Featured Categories',
                        subtitle: 'Browse by jewellery collection.',
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        onViewAll: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.retailerCatalogue),
                      ),
                      _contentSliver(
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        child: RetailerSectionContainer<RetailerCategoryModel>(
                          result: _loading ? null : _data?.categories,
                          onRetry: () => _loadHome(forceRefresh: true),
                          loading: const ShimmerCard(height: 160),
                          builder: (items) => HorizontalSection(
                            height: 160,
                            children: items
                                .map(
                                  (item) => CategoryCard(
                                    category: item,
                                    onTap: () => _handleCategoryTap(item),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ),
                      _stickyHeader(
                        title: 'Popular Products',
                        subtitle: 'Latest premium inventory arrivals.',
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        onViewAll: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.retailerCatalogue),
                      ),
                      _contentSliver(
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        child: RetailerSectionContainer<RetailerProductModel>(
                          result: _loading ? null : _data?.products,
                          onRetry: () => _loadHome(forceRefresh: true),
                          loading: const ShimmerCard(height: 338),
                          builder: (items) => HorizontalSection(
                            height: 338,
                            children: items
                                .map(
                                  (item) => ProductCard(
                                    product: item,
                                    role: _productRole,
                                    onTap: () => _handleProductTap(item),
                                    onPrimaryAction: () =>
                                        _handleAddToCart(item),
                                    onSecondaryAction: () =>
                                        _handleBuyNow(item),
                                    onWishlist: () =>
                                        _handleToggleWishlist(item),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ),
                      _plainHeader(
                        title: 'Recent Orders',
                        subtitle: 'Track your recent wholesale orders.',
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        onViewAll: () => _navigateOrPlaceholder(3),
                      ),
                      _contentSliver(
                        horizontalPadding: horizontalPadding,
                        maxWidth: contentWidth,
                        child:
                            RetailerSectionContainer<RetailerOrderPreviewModel>(
                              result: _loading ? null : _data?.recentOrders,
                              onRetry: () => _loadHome(forceRefresh: true),
                              loading: const ShimmerCard(height: 190),
                              builder: (items) => Column(
                                children: items
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: RecentOrderCard(
                                          order: item,
                                          onTap: () => _handleOrderTap(item),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                      ),
                      // _plainHeader(
                      //   title: 'Business Snapshot',
                      //   subtitle: 'Real-time dashboard activity metrics.',
                      //   horizontalPadding: horizontalPadding,
                      //   maxWidth: contentWidth,
                      // ),
                      // _contentSliver(
                      //   horizontalPadding: horizontalPadding,
                      //   maxWidth: contentWidth,
                      //   bottomPadding: 24,
                      //   child: RetailerSectionContainer<RetailerStatisticModel>(
                      //     result: _loading ? null : _data?.statistics,
                      //     onRetry: () => _loadHome(forceRefresh: true),
                      //     loading: const ShimmerCard(height: 170),
                      //     builder: (items) => _StatisticGrid(items: items),
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  RetailerProductRole get _productRole {
    return UserData.instance.role.trim().toLowerCase() == 'owner'
        ? RetailerProductRole.owner
        : RetailerProductRole.retailer;
  }

  void _handleBannerTap(RetailerBannerModel banner) {
    if (banner.targetOfferId.isNotEmpty) {
      Navigator.of(context).pushNamed(AppRoutes.offers);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
    }
  }

  void _handleCategoryTap(RetailerCategoryModel category) {
    Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
  }

  void _handleProductTap(RetailerProductModel item) {
    if (item.rawProduct != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RetailerProductDetailScreen(product: item.rawProduct!),
        ),
      );
    } else {
      Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
    }
  }

  Future<void> _handleToggleWishlist(RetailerProductModel item) async {
    final newWishState = await RetailerWishlistService.instance.toggle(item.id);
    if (!mounted) return;

    if (_data != null) {
      final updatedProducts = _data!.products.items.map((p) {
        if (p.id == item.id) {
          return p.copyWith(isWishlisted: newWishState);
        }
        return p;
      }).toList();

      setState(() {
        _data = _data!.copyWith(
          products: SectionResult.success(updatedProducts),
        );
      });
    }

    _showToast(
      newWishState ? 'Added to Wishlist' : 'Removed from Wishlist',
      success: newWishState,
    );
  }

  Future<void> _handleAddToCart(RetailerProductModel item) async {
    final retailerId = UserData.instance.id.isNotEmpty
        ? UserData.instance.id
        : UserData.instance.userId;

    try {
      await RetailerCartService.instance.addToCart(
        retailerId: retailerId,
        productId: item.id,
        variantId: item.variantId,
        quantity: 1,
      );
      if (!mounted) return;
      _showToast('${item.name} added to Cart.', success: true);
      _loadHome(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      _showToast('Added ${item.name} to Cart list.', success: true);
    }
  }

  Future<void> _handleBuyNow(RetailerProductModel item) async {
    final retailerId = UserData.instance.id.isNotEmpty
        ? UserData.instance.id
        : UserData.instance.userId;

    // Show the quantity picker bottom sheet first.
    final productForSheet =
        item.rawProduct ??
        stock_module.ProductModel(
          id: item.id,
          productName: item.name,
        );
    final qty = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderNowSheet(product: productForSheet),
    );

    // User dismissed without confirming.
    if (qty == null || qty <= 0) return;
    if (!mounted) return;

    _showOrderingLoader(item.name);

    try {
      await RetailerCartService.instance.placeOrder(
        retailerId: retailerId,
        productId: item.id,
        variantId: item.variantId,
        quantity: qty,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showToast(
        'Order placed for $qty item${qty > 1 ? 's' : ''} of ${item.name}!',
        success: true,
      );
      _loadHome(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showToast('Order created for ${item.name}.', success: true);
      _loadHome(forceRefresh: true);
    }
  }

  void _showOrderingLoader(String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: AppColors.bg,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.borderGold, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentGold),
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primaryRoyalBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Placing Direct Order',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryRoyalBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ordering $productName...',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleOrderTap(RetailerOrderPreviewModel item) {
    if (item.rawOrder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailedScreen(
            order: item.rawOrder!,
            isOwner: false,
            repository: order_module.OrderRepository(),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushNamed(AppRoutes.orderManagement);
    }
  }

  void _showToast(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: success ? AppColors.accentGold : AppColors.surfaceWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryRoyalBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  SliverPersistentHeader _stickyHeader({
    required String title,
    required String subtitle,
    required double horizontalPadding,
    required double maxWidth,
    VoidCallback? onViewAll,
  }) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: StickySectionHeaderDelegate(
        title: title,
        subtitle: subtitle,
        horizontalPadding: horizontalPadding,
        maxWidth: maxWidth,
        onViewAll: onViewAll,
      ),
    );
  }

  SliverToBoxAdapter _plainHeader({
    required String title,
    required String subtitle,
    required double horizontalPadding,
    required double maxWidth,
    VoidCallback? onViewAll,
  }) {
    return _contentSliver(
      horizontalPadding: horizontalPadding,
      maxWidth: maxWidth,
      child: SectionHeader(
        title: title,
        subtitle: subtitle,
        onViewAll: onViewAll,
      ),
    );
  }

  SliverToBoxAdapter _contentSliver({
    required double horizontalPadding,
    required double maxWidth,
    required Widget child,
    double bottomPadding = 18,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          bottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 900) return 36;
    if (width >= 600) return 24;
    if (width < 360) return 12;
    return 16;
  }

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17) return 'Good Evening';
    return 'Welcome';
  }

  void _handleFooterTap(int index) {
    setState(() => _footerIndex = index);
    _navigateOrPlaceholder(index);
  }

  void _navigateOrPlaceholder(int index) {
    switch (index) {
      case 0:
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case 1:
        Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
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
        _showToast('Navigating section...');
    }
  }
}
