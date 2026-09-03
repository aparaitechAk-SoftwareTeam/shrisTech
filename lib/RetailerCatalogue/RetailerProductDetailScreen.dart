// ignore_for_file: file_names
import 'dart:developer';

import 'package:bbs_gold/RetailerGlobalCode/RetailerGlobalAppbar.dart';
import 'package:bbs_gold/RetailerGlobalCode/RetailerGlobalDrawer.dart';
import 'package:bbs_gold/core/network/api_exception.dart';
import 'package:bbs_gold/core/theme/app_colors.dart';
import 'package:bbs_gold/core/theme/app_typography.dart';
import '../core/userdata.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bbs_gold/RetailerCatalogue/RetailerCatalogueApis.dart';
import 'package:bbs_gold/RetailerWishlist/WishlistApis.dart';
import '../Stock Listing Module/StockApis.dart';
import '../Stock Listing Module/StockWidget.dart';
import 'package:bbs_gold/RetailerCatalogue/RetailerCatalogueService.dart';

class RetailerProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final Widget? bottomNavigationBar;
  final bool showWishlistButton;

  const RetailerProductDetailScreen({
    super.key,
    required this.product,
    this.bottomNavigationBar,
    this.showWishlistButton = true,
  });

  @override
  State<RetailerProductDetailScreen> createState() =>
      _RetailerProductDetailScreenState();
}

class _RetailerProductDetailScreenState
    extends State<RetailerProductDetailScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RetailerCartService _cartService = RetailerCartService.instance;
  final IWishlistRepository _wishlistRepository = WishlistRepository();
  late final PageController _pageController;

  late ProductModel _product;
  int _imageIndex = 0;
  bool _wishlisted = false;
  bool _loadingWishlist = true;
  bool _wishlistPending = false;
  bool _loadingProduct = false;
  bool _addingToCart = false;
  bool _ordering = false;
  String? _wishlistId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    log(
      'RetailerProductDetailScreen initialized for product: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
    );
    _product = widget.product;
    _pageController = PageController();
    _loadLatestProduct();
    _loadWishlistState();
    _warmCart();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      bottomNavigationBar:
          widget.bottomNavigationBar ??
          _RetailerActionBar(
            addingToCart: _addingToCart,
            ordering: _ordering,
            onAddToCart: _addToCart,
            onOrderNow: _orderNow,
          ),
      body: SafeArea(
        child: _DetailBody(
          product: _product,
          imageIndex: _imageIndex,
          pageController: _pageController,
          wishlisted: _wishlisted,
          loadingWishlist: _loadingWishlist,
          loadingProduct: _loadingProduct,
          showWishlistButton: widget.showWishlistButton,
          onImageChanged: _onImageChanged,
          onPrevious: _previousImage,
          onNext: _nextImage,
          onWishlist: _toggleWishlist,
          onOpenFullscreen: _openFullscreenGallery,
        ),
      ),
    );
  }

  void _openFullscreenGallery(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            RetailerProductImageViewer(
              product: _product,
              initialIndex: initialIndex,
              onPageChanged: (index) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(index);
                }
                setState(() => _imageIndex = index);
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  Future<void> _loadWishlistState() async {
    final retailerId = _retailerId;
    if (retailerId.isEmpty || !widget.showWishlistButton) {
      if (mounted) setState(() => _loadingWishlist = false);
      return;
    }
    try {
      final wishlist = await _wishlistRepository.fetchWishlist(retailerId);
      WishlistItemModel? matched;
      for (final item in wishlist) {
        if (item.productId == _product.id) {
          matched = item;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _wishlisted = matched != null;
        _wishlistId = matched?.wishlistId;
        _loadingWishlist = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWishlist = false);
    }
  }

  Future<void> _warmCart() async {
    final retailerId = _retailerId;
    if (retailerId.isEmpty) return;
    try {
      await _cartService.fetchCart(retailerId);
    } catch (_) {
      // Cart can still be created by the add-to-cart call.
    }
  }

  Future<void> _loadLatestProduct() async {
    if (_product.id.trim().isEmpty) return;
    setState(() => _loadingProduct = true);
    try {
      final latest = await StockRepository.instance.fetchSingleProduct(
        _product.id,
      );
      if (!mounted) return;
      setState(() => _product = latest);
      _preloadNeighborImages();
    } catch (_) {
      // Keep the navigation payload if the detail endpoint is temporarily unavailable.
    } finally {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  void _onImageChanged(int index) {
    setState(() => _imageIndex = index);
    _preloadNeighborImages();
  }

  void _previousImage() {
    if (_imageIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextImage() {
    if (_imageIndex >= _product.images.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _preloadNeighborImages() {
    for (final index in [_imageIndex - 1, _imageIndex + 1]) {
      if (index < 0 || index >= _product.images.length) continue;
      final url = _product.images[index].url;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        continue;
      }
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  /// Optimistic wishlist toggle:
  ///  1. Flip the heart icon & show SnackBar instantly (zero perceived lag).
  ///  2. Fire the API call in the background.
  ///  3. Rollback state + show error SnackBar only if the API fails.
  Future<void> _toggleWishlist() async {
    if (_loadingWishlist) return;
    if (_wishlistPending) return;

    final ids = _requestIds();
    if (ids == null) return;

    final previousWishlisted = _wishlisted;
    final previousWishlistId = _wishlistId;
    final next = !_wishlisted;

    // ── Step 1: Instant optimistic update ───────────────────────────────────
    setState(() {
      _wishlisted = next;
      _wishlistPending = true;
    });
    _snack(next ? 'Added to wishlist.' : 'Removed from wishlist.');

    // ── Step 2: Background API call ─────────────────────────────────────────
    try {
      if (next) {
        final item = await _wishlistRepository.addWishlist(
          retailerId: ids.retailerId,
          productId: ids.productId,
          variantId: ids.variantId,
        );
        if (mounted) setState(() => _wishlistId = item?.wishlistId);
      } else {
        final wishlistId = previousWishlistId;
        if (wishlistId == null || wishlistId.isEmpty) {
          if (mounted) setState(() => _wishlisted = previousWishlisted);
          await _loadWishlistState();
          return;
        }
        await _wishlistRepository.removeWishlist(
          retailerId: ids.retailerId,
          wishlistId: wishlistId,
        );
        if (mounted) setState(() => _wishlistId = null);
      }
    } catch (error) {
      // ── Step 3: Rollback on failure ────────────────────────────────────────
      if (!mounted) return;
      setState(() {
        _wishlisted = previousWishlisted;
        _wishlistId = previousWishlistId;
      });
      _snack(_errorMessage(error), success: false);
    } finally {
      if (mounted) setState(() => _wishlistPending = false);
    }
  }

  Future<void> _addToCart() async {
    if (_addingToCart || _ordering) return;
    final ids = _requestIds();
    if (ids == null) return;

    setState(() => _addingToCart = true);
    try {
      final cart = _cartService.cart.items.isEmpty
          ? await _cartService.fetchCart(ids.retailerId)
          : _cartService.cart;
      final existing = _findCartItem(cart, ids);
      if (existing == null) {
        await _cartService.addToCart(
          retailerId: ids.retailerId,
          productId: ids.productId,
          variantId: ids.variantId,
          quantity: 1,
        );
      } else {
        await _cartService.updateQuantity(
          cartItemId: existing.cartItemId,
          quantity: existing.quantity + 1,
        );
      }
      await _cartService.fetchCart(ids.retailerId);
      if (!mounted) return;
      _snack('Product added to cart.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorMessage(error), success: false);
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _orderNow() async {
    if (_addingToCart || _ordering) return;
    final ids = _requestIds();
    if (ids == null) return;

    // Show the quantity picker bottom sheet first.
    final qty = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderNowSheet(product: _product),
    );

    // User dismissed without confirming.
    if (qty == null || qty <= 0) return;
    if (!mounted) return;

    setState(() => _ordering = true);
    try {
      await _cartService.placeOrder(
        retailerId: ids.retailerId,
        productId: ids.productId,
        variantId: ids.variantId,
        quantity: qty,
      );
      if (!mounted) return;
      _snack('Order placed successfully for $qty item${qty > 1 ? 's' : ''}.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorMessage(error), success: false);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  CartItemModel? _findCartItem(CartModel cart, _RetailerProductRequest ids) {
    for (final item in cart.items) {
      if (item.productId == ids.productId && item.variantId == ids.variantId) {
        return item;
      }
    }
    return null;
  }

  _RetailerProductRequest? _requestIds() {
    final retailerId = _retailerId;
    final productId = _product.id.trim();
    final variantId = _variantId(_product);
    if (retailerId.isEmpty) {
      log(
        'Retailer: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
      );
      _snack(
        'Retailer session is unavailable. Please sign in again.',
        success: false,
      );
      return null;
    }
    if (productId.isEmpty || variantId.isEmpty) {
      _snack('Product details are unavailable.', success: false);
      return null;
    }
    return _RetailerProductRequest(
      retailerId: retailerId,
      productId: productId,
      variantId: variantId,
    );
  }

  String get _retailerId {
    final user = UserData.instance;
    return user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
  }

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
        duration: const Duration(milliseconds: 2000),
        elevation: 6,
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BODY (Responsive Layout & Scroll Presentation)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final PageController pageController;
  final bool wishlisted;
  final bool loadingWishlist;
  final bool loadingProduct;
  final bool showWishlistButton;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onWishlist;
  final ValueChanged<int> onOpenFullscreen;

  const _DetailBody({
    required this.product,
    required this.imageIndex,
    required this.pageController,
    required this.wishlisted,
    required this.loadingWishlist,
    required this.loadingProduct,
    required this.showWishlistButton,
    required this.onImageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onWishlist,
    required this.onOpenFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 650;
        final horizontalPadding = isTablet ? 28.0 : (isCompact ? 12.0 : 16.0);
        final maxWidth = screenWidth >= 1100
            ? 1040.0
            : (screenWidth >= 700 ? 820.0 : screenWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isCompact ? 12 : 16,
                    horizontalPadding,
                    28,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ImageGallery(
                        product: product,
                        imageIndex: imageIndex,
                        pageController: pageController,
                        wishlisted: wishlisted,
                        loadingWishlist: loadingWishlist,
                        showWishlistButton: showWishlistButton,
                        isCompact: isCompact,
                        onImageChanged: onImageChanged,
                        onPrevious: onPrevious,
                        onNext: onNext,
                        onWishlist: onWishlist,
                        onOpenFullscreen: onOpenFullscreen,
                      ),
                      if (loadingProduct) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.accentGold,
                          backgroundColor: AppColors.primaryLightBlue,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _DetailSection(product: product, isCompact: isCompact),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE GALLERY (Interactive Zoom, Fullscreen Tap, Forward/Backward Actions)
// ─────────────────────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final PageController pageController;
  final bool wishlisted;
  final bool loadingWishlist;
  final bool showWishlistButton;
  final bool isCompact;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onWishlist;
  final ValueChanged<int> onOpenFullscreen;

  const _ImageGallery({
    required this.product,
    required this.imageIndex,
    required this.pageController,
    required this.wishlisted,
    required this.loadingWishlist,
    required this.showWishlistButton,
    required this.isCompact,
    required this.onImageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onWishlist,
    required this.onOpenFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.images;
    final hasImages = images.isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;
    final aspectRatio = isTablet ? 16 / 9 : (isCompact ? 1.05 : 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.accentGoldGlow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!hasImages)
                Hero(
                  tag: product.heroTag,
                  child: const ColoredBox(
                    color: AppColors.primaryLightBlue,
                    child: StockImagePlaceholder(),
                  ),
                )
              else
                PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: onImageChanged,
                  itemBuilder: (context, index) {
                    final url = images[index].url;
                    return GestureDetector(
                      onTap: () => onOpenFullscreen(index),
                      child: Hero(
                        tag: index == 0
                            ? product.heroTag
                            : '${product.heroTag}-$index',
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            memCacheWidth:
                                (MediaQuery.sizeOf(context).width *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            placeholder: (context, url) =>
                                const StockImageShimmer(),
                            errorWidget: (context, url, error) =>
                                const StockBrokenImage(),
                            fadeInDuration: const Duration(milliseconds: 220),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // ── Fullscreen Expand Icon Badge (Top Left) ───────────────────
              // if (hasImages)
              //   Positioned(
              //     top: isCompact ? 10 : 12,
              //     left: isCompact ? 10 : 12,
              //     child: Material(
              //       color: AppColors.surfaceWhite.withValues(alpha: 0.92),
              //       shape: const CircleBorder(),
              //       elevation: 3,
              //       child: InkWell(
              //         customBorder: const CircleBorder(),
              //         onTap: () => onOpenFullscreen(imageIndex),
              //         child: Padding(
              //           padding: EdgeInsets.all(isCompact ? 8 : 10),
              //           child: Icon(
              //             Icons.fullscreen_rounded,
              //             color: AppColors.primaryRoyalBlue,
              //             size: isCompact ? 20 : 23,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),

              // ── Wishlist Heart Badge (Top Right) ──────────────────────────
              if (showWishlistButton)
                Positioned(
                  top: isCompact ? 10 : 12,
                  right: isCompact ? 10 : 12,
                  child: Material(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: loadingWishlist ? null : onWishlist,
                      child: Padding(
                        padding: EdgeInsets.all(isCompact ? 8 : 10),
                        child: Icon(
                          wishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: wishlisted
                              ? Colors.redAccent
                              : AppColors.textMuted,
                          size: isCompact ? 20 : 23,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Previous & Next Image Buttons (Forward / Backward) ────────
              if (images.length > 1) ...[
                Positioned(
                  left: isCompact ? 8 : 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryButton(
                      icon: Icons.chevron_left_rounded,
                      isCompact: isCompact,
                      onPressed: imageIndex == 0 ? null : onPrevious,
                    ),
                  ),
                ),
                Positioned(
                  right: isCompact ? 8 : 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryButton(
                      icon: Icons.chevron_right_rounded,
                      isCompact: isCompact,
                      onPressed: imageIndex == images.length - 1
                          ? null
                          : onNext,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: isCompact ? 10 : 12,
                  child: _PageIndicator(
                    count: images.length,
                    index: imageIndex,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final IconData icon;
  final bool isCompact;
  final VoidCallback? onPressed;

  const _GalleryButton({
    required this.icon,
    required this.isCompact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 38.0 : 44.0;
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryRoyalBlue.withValues(alpha: 0.88),
        foregroundColor: AppColors.accentGold,
        disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.30),
        minimumSize: Size(size, size),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: isCompact ? 22 : 26),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int index;

  const _PageIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (itemIndex) {
        final selected = itemIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGold : AppColors.borderLight,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN IMAGE LIGHTBOX VIEWER (Pinch-to-zoom, Double Tap, Forward/Backward)
// ─────────────────────────────────────────────────────────────────────────────

class RetailerProductImageViewer extends StatefulWidget {
  final ProductModel product;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  const RetailerProductImageViewer({
    super.key,
    required this.product,
    this.initialIndex = 0,
    this.onPageChanged,
  });

  @override
  State<RetailerProductImageViewer> createState() =>
      _RetailerProductImageViewerState();
}

class _RetailerProductImageViewerState
    extends State<RetailerProductImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getController(int index) {
    return _controllers.putIfAbsent(index, () => TransformationController());
  }

  void _handleDoubleTap(int index, TapDownDetails details) {
    final controller = _getController(index);
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      controller.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-position.dx * 1.5, -position.dy * 1.5, 0.0);
    }
  }

  void _previousImage() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextImage() {
    final images = widget.product.images;
    if (_currentIndex >= images.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;
    final hasImages = images.isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main PageView with Pinch-to-zoom ───────────────────────────
            Positioned.fill(
              child: hasImages
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        widget.onPageChanged?.call(index);
                      },
                      itemBuilder: (context, index) {
                        final url = images[index].url;
                        final tag = index == 0
                            ? widget.product.heroTag
                            : '${widget.product.heroTag}-$index';
                        final controller = _getController(index);

                        return GestureDetector(
                          onDoubleTapDown: (details) =>
                              _handleDoubleTap(index, details),
                          onDoubleTap: () {},
                          child: Center(
                            child: Hero(
                              tag: tag,
                              child: InteractiveViewer(
                                transformationController: controller,
                                minScale: 0.8,
                                maxScale: 5.0,
                                clipBehavior: Clip.none,
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const StockImageShimmer(),
                                  errorWidget: (context, url, error) =>
                                      const StockBrokenImage(),
                                  fadeInDuration: const Duration(
                                    milliseconds: 180,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: StockImagePlaceholder()),
            ),

            // ── Top Header Navigation Bar ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    // Close button
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.all(isCompact ? 8 : 10),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Name & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isCompact ? 14 : 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                size: 12,
                                color: AppColors.accentGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _extractCategory(widget.product),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isCompact ? 10.5 : 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Counter badge
                    if (images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.borderGold.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Backward Navigation Button (Left Side) ─────────────────────
            if (images.length > 1)
              Positioned(
                left: isCompact ? 10 : 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: _currentIndex == 0
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.22),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _currentIndex == 0 ? null : _previousImage,
                      child: Padding(
                        padding: EdgeInsets.all(isCompact ? 10 : 12),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _currentIndex == 0
                              ? Colors.white30
                              : AppColors.accentGold,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Forward Navigation Button (Right Side) ─────────────────────
            if (images.length > 1)
              Positioned(
                right: isCompact ? 10 : 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: _currentIndex >= images.length - 1
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.22),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _currentIndex >= images.length - 1
                          ? null
                          : _nextImage,
                      child: Padding(
                        padding: EdgeInsets.all(isCompact ? 10 : 12),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _currentIndex >= images.length - 1
                              ? Colors.white30
                              : AppColors.accentGold,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Bottom Thumbnail Strip & Zoom Helper ───────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Helper hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pinch_rounded,
                          size: 13,
                          color: AppColors.accentGold,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Pinch or double tap to zoom',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 10),
                    // Thumbnail Carousel
                    SizedBox(
                      height: isCompact ? 46 : 54,
                      child: Center(
                        child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: images.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final selected = index == _currentIndex;
                            final thumbUrl = images[index].url;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isCompact ? 46 : 54,
                                height: isCompact ? 46 : 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.accentGold
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: selected ? 2.2 : 0.8,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          const BoxShadow(
                                            color: AppColors.accentGoldGlow,
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: thumbUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const StockImageShimmer(),
                                    errorWidget: (context, url, error) =>
                                        const StockBrokenImage(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SECTION (Responsive Data Table)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final ProductModel product;
  final bool isCompact;

  const _DetailSection({required this.product, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StockSectionHeader(
            title: 'Product Details',
            subtitle: 'Catalogue data from stock listing',
            icon: Icons.diamond_rounded,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Product Name',
            value: product.displayName,
            isCompact: isCompact,
            multiLine: true,
          ),
          _DetailRow(
            label: 'Gross Weight',
            value: stockFormatGram(product.weights.grossWeight),
            isCompact: isCompact,
          ),
          _DetailRow(
            label: 'Stone Weight',
            value: stockFormatGram(product.weights.stoneWeight),
            isCompact: isCompact,
          ),
          _DetailRow(
            label: 'Stone Charge',
            value: stockFormatMoney(product.weights.stoneCharge),
            isCompact: isCompact,
          ),
          _DetailRow(
            label: 'Net Weight',
            value: stockFormatGram(product.weights.netWeight),
            isCompact: isCompact,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCompact;
  final bool multiLine;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isCompact,
    this.multiLine = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidth = isCompact ? 104.0 : 124.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : (isCompact ? 10 : 12),
        top: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 11.5 : 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.trim().isEmpty ? StockStrings.unavailable : value,
              maxLines: multiLine ? 6 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETAILER ACTION BAR (Bottom Dual Actions)
// ─────────────────────────────────────────────────────────────────────────────

class _RetailerActionBar extends StatelessWidget {
  final bool addingToCart;
  final bool ordering;
  final VoidCallback onAddToCart;
  final VoidCallback onOrderNow;

  const _RetailerActionBar({
    required this.addingToCart,
    required this.ordering,
    required this.onAddToCart,
    required this.onOrderNow,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final busy = addingToCart || ordering;
    final buttonHeight = isCompact ? 48.0 : 52.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 16,
          8,
          isCompact ? 12 : 16,
          bottom > 0 ? 8 : 14,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onAddToCart,
                icon: addingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.shopping_cart_rounded,
                        size: isCompact ? 18 : 20,
                      ),
                label: Text(
                  'Add To Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 12.5 : 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, buttonHeight),
                  foregroundColor: AppColors.primaryRoyalBlue,
                  side: const BorderSide(
                    color: AppColors.borderGold,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy ? null : onOrderNow,
                icon: ordering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surfaceWhite,
                        ),
                      )
                    : Icon(Icons.flash_on_rounded, size: isCompact ? 18 : 20),
                label: Text(
                  'Order Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 12.5 : 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(0, buttonHeight),
                  backgroundColor: AppColors.primaryRoyalBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  elevation: 3,
                  shadowColor: AppColors.shadowPrimaryGlow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetailerProductRequest {
  final String retailerId;
  final String productId;
  final String variantId;

  const _RetailerProductRequest({
    required this.retailerId,
    required this.productId,
    required this.variantId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER NOW — QUANTITY PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

/// A reusable bottom sheet that lets the user pick a quantity before ordering.
/// Returns the selected [int] quantity via [Navigator.pop], or null if dismissed.
class OrderNowSheet extends StatefulWidget {
  final ProductModel product;
  const OrderNowSheet({super.key, required this.product});

  @override
  State<OrderNowSheet> createState() => _OrderNowSheetState();
}

class _OrderNowSheetState extends State<OrderNowSheet> {
  int _quantity = 1;
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocus = FocusNode();
  static const int _min = 1;
  static const int _max = 999;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  void _setQty(int value) {
    final clamped = value.clamp(_min, _max);
    setState(() => _quantity = clamped);
    _qtyController.text = clamped.toString();
    _qtyController.selection = TextSelection.collapsed(
      offset: _qtyController.text.length,
    );
  }

  void _onFieldChanged(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed != null && parsed >= _min && parsed <= _max) {
      setState(() => _quantity = parsed);
    }
  }

  void _onFieldSubmitted(String raw) {
    final parsed = int.tryParse(raw) ?? _min;
    _setQty(parsed);
    _qtyFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 700;
    final hPad = isTablet ? 32.0 : (isCompact ? 16.0 : 20.0);

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 18),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // ── Header row ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightBlue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.borderGold.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.primaryRoyalBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Place Order',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: isCompact ? 16 : 18,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.product.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: isCompact ? 11.5 : 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      backgroundColor: AppColors.bg,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Divider ──────────────────────────────────────────────────
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.borderGold.withValues(alpha: 0),
                      AppColors.borderGold,
                      AppColors.borderGold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Quantity label ───────────────────────────────────────────
              Text(
                'Select Quantity',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 12 : 13,
                ),
              ),
              const SizedBox(height: 12),

              // ── Stepper row ──────────────────────────────────────────────
              Row(
                children: [
                  OrderNowStepButton(
                    icon: Icons.remove_rounded,
                    enabled: _quantity > _min,
                    onTap: () => _setQty(_quantity - 1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: _onFieldChanged,
                      onSubmitted: _onFieldSubmitted,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 19 : 22,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderGold,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderGold,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primaryRoyalBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OrderNowStepButton(
                    icon: Icons.add_rounded,
                    enabled: _quantity < _max,
                    onTap: () => _setQty(_quantity + 1),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Confirm button ───────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(_quantity),
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(
                  'Confirm Order  •  Qty: $_quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 13.5 : 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(0, isCompact ? 50 : 54),
                  backgroundColor: AppColors.primaryRoyalBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  elevation: 4,
                  shadowColor: AppColors.shadowPrimaryGlow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated increment/decrement button used inside [OrderNowSheet].
class OrderNowStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const OrderNowStepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primaryRoyalBlue.withValues(alpha: 0.09)
            : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.primaryRoyalBlue : AppColors.borderSubtle,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.primaryRoyalBlue : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

String _variantId(ProductModel product) {
  final raw = product.rawJson;
  final direct = _readString(raw, const [
    'variant_id',
    'variantId',
    'product_variant_id',
    'productVariantId',
  ]);
  if (direct.isNotEmpty) return direct;

  final weights = raw['weights'] ?? raw['weight'];
  final fromWeights = _readNestedString(weights, const [
    'id',
    'variant_id',
    'variantId',
    'product_variant_id',
  ]);
  if (fromWeights.isNotEmpty) return fromWeights;

  final variants = raw['variants'] ?? raw['product_variants'];
  final fromVariants = _readNestedString(variants, const [
    'id',
    'variant_id',
    'variantId',
    'product_variant_id',
  ]);
  return fromVariants.isNotEmpty ? fromVariants : product.id;
}

String _readNestedString(Object? value, List<String> keys) {
  if (value is Map<String, dynamic>) return _readString(value, keys);
  if (value is List) {
    for (final item in value) {
      final result = _readNestedString(item, keys);
      if (result.isNotEmpty) return result;
    }
  }
  return '';
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _extractCategory(ProductModel product) {
  final direct = _readString(product.rawJson, const [
    'category',
    'category_name',
    'categoryName',
    'sub_category_name',
    'subcategory_name',
  ]);
  if (direct.isNotEmpty) return direct;
  return 'Jewellery';
}
