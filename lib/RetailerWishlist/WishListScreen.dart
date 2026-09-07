// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../RetailerCart/CartApis.dart' as cart;
import '../RetailerCatalogue/RetailerProductDetailScreen.dart'
    show OrderNowSheet;
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../screens/home/owner_home_screen.dart';
import 'WishlistApis.dart';
import 'WishlistProductDetailScreen.dart';
import 'WishlistWidgets.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen>
    with AutomaticKeepAliveClientMixin {
  static String _savedQuery = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IWishlistRepository _repository = WishlistRepository();
  final cart.ICartRepository _cartRepository = cart.CartRepository();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  Timer? _debounce;
  List<WishlistItemModel> _items = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyIds = {};

  @override
  bool get wantKeepAlive => true;

  List<WishlistItemModel> get _visibleItems {
    final query = _savedQuery.trim();
    if (query.isEmpty) return _items;
    return _items.where((item) => item.matches(query)).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    log(
      'WishListScreen initialized for product: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
    );
    _searchController = TextEditingController(text: _savedQuery);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _savedQuery = _searchController.text;
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isOwner) return const OwnerHomeScreen();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(selectedIndex: 2, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: -1,
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
                        isCompact ? 6 : 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RetailerProductSearchBar(
                            controller: _searchController,
                            hintText: 'Search wishlist products...',
                            onChanged: _onSearchChanged,
                            onClear: _clearSearch,
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
      return RetailerProductShimmerList(horizontalPadding: horizontalPadding);
    }
    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        backgroundColor: AppColors.bg,
        onRefresh: () => _load(forceRefresh: true),
        child: RetailerModuleState(
          icon: Icons.cloud_off_rounded,
          title: 'Something Went Wrong',
          message: _error!,
          actionLabel: 'Retry',
          onAction: () => _load(forceRefresh: true),
        ),
      );
    }
    final visible = _visibleItems;
    if (visible.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryRoyalBlue,
        backgroundColor: AppColors.bg,
        onRefresh: () => _load(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: RetailerModuleState(
            icon: Icons.favorite_border_rounded,
            title: 'No Wishlist Products',
            message: _savedQuery.trim().isEmpty
                ? 'Products you save will appear here.'
                : 'No wishlist products match your search.',
            actionLabel: 'Browse Products',
            onAction: () =>
                Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      backgroundColor: AppColors.bg,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView.separated(
        key: const PageStorageKey<String>('retailer-wishlist-list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          4,
          horizontalPadding,
          24,
        ),
        itemCount: visible.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 12),
        itemBuilder: (context, index) {
          final item = visible[index];
          final busy = _busyIds.contains(item.wishlistId);
          return RetailerProductActionCard(
            product: item.product,
            onTap: () => _openDetail(item),
            busy: busy,
            onRemove: () => _remove(item),
            actionArea: WishlistCardActions(
              busy: busy,
              onAddToCart: () => _addToCart(item),
              onOrder: () => _order(item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _repository.fetchWishlist(_retailerId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(error);
        _loading = false;
      });
    }
  }

  Future<void> _remove(WishlistItemModel item) async {
    if (_busyIds.contains(item.wishlistId)) return;
    final previous = List<WishlistItemModel>.from(_items);
    setState(() {
      _busyIds.add(item.wishlistId);
      _items = _items
          .where((value) => value.wishlistId != item.wishlistId)
          .toList();
    });
    try {
      await _repository.removeWishlist(
        retailerId: _retailerId,
        wishlistId: item.wishlistId,
      );
      if (!mounted) return;
      _snack('Removed from wishlist.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.wishlistId));
    }
  }

  Future<void> _addToCart(WishlistItemModel item) async {
    if (_busyIds.contains(item.wishlistId)) return;
    setState(() => _busyIds.add(item.wishlistId));
    try {
      final currentCart = await _cartRepository.fetchCart(_retailerId);
      cart.CartItemModel? existing;
      for (final cartItem in currentCart.items) {
        if (cartItem.productId == item.productId &&
            cartItem.variantId == item.variantId) {
          existing = cartItem;
          break;
        }
      }
      if (existing == null) {
        await _cartRepository.addToCart(
          retailerId: _retailerId,
          productId: item.productId,
          variantId: item.variantId,
          quantity: 1,
        );
      } else {
        await _cartRepository.updateQuantity(
          cartItemId: existing.cartItemId,
          quantity: existing.quantity + 1,
        );
      }
      if (!mounted) return;
      _snack('Added to cart.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.wishlistId));
    }
  }

  Future<void> _order(WishlistItemModel item) async {
    if (_busyIds.contains(item.wishlistId)) return;

    // Show the quantity picker bottom sheet before touching the API.
    final qty = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderNowSheet(product: item.product),
    );

    // User dismissed without confirming.
    if (qty == null || qty <= 0) return;
    if (!mounted) return;

    setState(() => _busyIds.add(item.wishlistId));
    try {
      await _repository.placeOrder(
        retailerId: _retailerId,
        productId: item.productId,
        variantId: item.variantId,
        quantity: qty,
      );
      if (!mounted) return;
      _snack('Order placed for $qty item${qty > 1 ? 's' : ''} successfully.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.wishlistId));
    }
  }

  Future<void> _openDetail(WishlistItemModel item) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WishlistProductDetailScreen(item: item),
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _savedQuery = value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _savedQuery = '');
  }

  void _handleFooterTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
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
    }
  }

  String get _retailerId {
    final user = UserData.instance;
    return user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
  }

  bool get _isOwner => UserData.instance.role.trim().toLowerCase() == 'owner';

  void _snack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Colors.redAccent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 2200),
        elevation: 6,
      ),
    );
  }

  String _errorText(Object error) {
    return error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';
  }
}
