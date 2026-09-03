// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../RetailerWishlist/WishlistWidgets.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../screens/home/owner_home_screen.dart';
import 'CartApis.dart';
import 'CartProductDetailScreen.dart';
import 'CartWidgets.dart';

class CartListScreen extends StatefulWidget {
  const CartListScreen({super.key});

  @override
  State<CartListScreen> createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen>
    with AutomaticKeepAliveClientMixin {
  static String _savedQuery = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ICartRepository _repository = CartRepository();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  Timer? _debounce;
  CartModel _cart = const CartModel.empty();
  bool _loading = true;
  String? _error;
  final Set<String> _busyIds = {};

  @override
  bool get wantKeepAlive => true;

  List<CartItemModel> get _visibleItems {
    final query = _savedQuery.trim();
    if (query.isEmpty) return _cart.items;
    return _cart.items
        .where((item) => item.matches(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
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
      drawer: RetailerGlobalDrawer(selectedIndex: -1, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: 4,
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
                        isCompact ? 12 : 16,
                        horizontalPadding,
                        isCompact ? 6 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RetailerProductSearchBar(
                            controller: _searchController,
                            hintText: 'Search cart products...',
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
        onRefresh: () => _load(forceRefresh: true),
        child: RetailerModuleState(
          icon: Icons.shopping_cart_outlined,
          title: 'Cart is Empty',
          message: _savedQuery.trim().isEmpty
              ? 'Add products to cart before placing an order.'
              : 'No cart products match your search.',
          actionLabel: 'Continue Shopping',
          onAction: () =>
              Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView.separated(
        key: const PageStorageKey<String>('retailer-cart-list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          6,
          horizontalPadding,
          isCompact ? 18 : 24,
        ),
        itemCount: visible.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isCompact ? 10 : 14),
        itemBuilder: (context, index) {
          final item = visible[index];
          final busy = _busyIds.contains(item.cartItemId);
          return RetailerProductActionCard(
            product: item.product,
            quantity: item.quantity,
            onTap: () => _openDetail(item),
            actionArea: CartCardActions(
              quantity: item.quantity,
              busy: busy,
              isCompact: isCompact,
              onDecrease: () => _updateQuantity(item, item.quantity - 1),
              onIncrease: () => _updateQuantity(item, item.quantity + 1),
              onRemove: () => _remove(item),
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
      final cart = await _repository.fetchCart(_retailerId);
      if (!mounted) return;
      setState(() {
        _cart = cart;
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

  Future<void> _updateQuantity(CartItemModel item, int quantity) async {
    if (_busyIds.contains(item.cartItemId) || quantity < 1) return;
    final previous = _cart;
    setState(() {
      _busyIds.add(item.cartItemId);
      _cart = _cartWithItem(item.copyWith(quantity: quantity));
    });
    try {
      await _repository.updateQuantity(
        cartItemId: item.cartItemId,
        quantity: quantity,
      );
      if (!mounted) return;
      _snack('Quantity updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _cart = previous);
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.cartItemId));
    }
  }

  Future<void> _remove(CartItemModel item) async {
    if (_busyIds.contains(item.cartItemId)) return;
    final previous = _cart;
    setState(() {
      _busyIds.add(item.cartItemId);
      _cart = _cartWithoutItem(item.cartItemId);
    });
    try {
      await _repository.removeItem(item.cartItemId);
      if (!mounted) return;
      _snack('Removed from cart.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _cart = previous);
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.cartItemId));
    }
  }

  Future<void> _order(CartItemModel item) async {
    if (_busyIds.contains(item.cartItemId)) return;
    setState(() => _busyIds.add(item.cartItemId));
    try {
      await _repository.placeOrder(
        retailerId: _retailerId,
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
      );
      if (!mounted) return;
      _snack('Order placed successfully.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.cartItemId));
    }
  }

  Future<void> _openDetail(CartItemModel item) async {
    final result = await Navigator.of(context).push<CartItemModel?>(
      MaterialPageRoute(builder: (_) => CartProductDetailScreen(item: item)),
    );
    if (!mounted) return;
    if (result == null) {
      await _load(forceRefresh: true);
    }
  }

  CartModel _cartWithItem(CartItemModel item) {
    final items = _cart.items
        .map(
          (current) => current.cartItemId == item.cartItemId ? item : current,
        )
        .toList(growable: false);
    return CartModel(
      cartId: _cart.cartId,
      totalItems: items.fold<int>(0, (sum, value) => sum + value.quantity),
      items: items,
    );
  }

  CartModel _cartWithoutItem(String cartItemId) {
    final items = _cart.items
        .where((current) => current.cartItemId != cartItemId)
        .toList(growable: false);
    return CartModel(
      cartId: _cart.cartId,
      totalItems: items.fold<int>(0, (sum, value) => sum + value.quantity),
      items: items,
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _errorText(Object error) {
    return error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';
  }
}
