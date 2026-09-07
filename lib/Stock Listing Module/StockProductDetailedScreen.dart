// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../Product Module/AddProductFormScreen.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/safe_network_image.dart';
import 'StockApis.dart';
import 'StockWidget.dart';

class StockProductDetailedScreen extends StatefulWidget {
  final ProductModel product;
  final bool isOwner;

  const StockProductDetailedScreen({
    super.key,
    required this.product,
    this.isOwner = true,
  });

  @override
  State<StockProductDetailedScreen> createState() =>
      _StockProductDetailedScreenState();
}

class _StockProductDetailedScreenState extends State<StockProductDetailedScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IStockRepository _repository = StockRepository.instance;
  late final PageController _pageController;

  late ProductModel _product;
  int _imageIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _pageController = PageController();
    _loadLatestProduct();
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
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: StockStrings.title,
      ),
      drawer: GlobalDrawer(selectedIndex: 3, onItemSelected: (_) {}),
      bottomNavigationBar: _RoleAwareBottomBar(
        isOwner: widget.isOwner,
        onBack: () => Navigator.of(context).pop(_product),
        onEdit: _openEditProduct,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _loading
              ? const _DetailShimmer(key: ValueKey('detail-loading'))
              : _error != null
              ? StockErrorWidget(
                  key: const ValueKey('detail-error'),
                  message: _error!,
                  onRetry: _loadLatestProduct,
                )
              : _DetailBody(
                  key: ValueKey('${_product.id}-${_product.images.length}-${_product.primaryImageUrl.hashCode}-${_product.weights.grossWeight}'),
                  product: _product,
                  imageIndex: _imageIndex,
                  pageController: _pageController,
                  onImageChanged: _onImageChanged,
                  onPrevious: _previousImage,
                  onNext: _nextImage,
                  onImageTap: _openZoom,
                ),
        ),
      ),
    );
  }

  Future<void> _loadLatestProduct() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final targetId = _product.id.isNotEmpty ? _product.id : widget.product.id;
      final latest = await _repository.fetchSingleProduct(targetId);
      if (!mounted) return;
      setState(() {
        _product = latest;
        _imageIndex = 0;
        _loading = false;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _preloadNeighborImages();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
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

  void _openZoom() {
    openStockImageZoom(
      context,
      product: _product,
      initialIndex: _imageIndex,
      onPageChanged: (index) {
        if (mounted && index != _imageIndex) {
          setState(() => _imageIndex = index);
          if (_pageController.hasClients) {
            _pageController.jumpToPage(index);
          }
          _preloadNeighborImages();
        }
      },
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
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (e, s) {},
      );
    }
  }

  Future<void> _openEditProduct() async {
    final updated = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute<ProductModel>(
        builder: (context) => AddProductScreen.edit(
          initialProductData: _product,
          onProductUpdated: (product) {
            if (mounted) {
              setState(() {
                _product = product;
                _imageIndex = 0;
              });
            }
          },
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _product = updated;
        _imageIndex = 0;
      });
    }
    await _loadLatestProduct();
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}

class _DetailBody extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onImageTap;

  const _DetailBody({
    super.key,
    required this.product,
    required this.imageIndex,
    required this.pageController,
    required this.onImageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 700;
        final horizontalPadding = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
        final maxWidth = screenWidth >= 1100
            ? 760.0
            : (screenWidth >= 700 ? 680.0 : screenWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isCompact ? 10 : 14,
                    horizontalPadding,
                    isCompact ? 18 : 26,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ImageGallery(
                        product: product,
                        imageIndex: imageIndex,
                        pageController: pageController,
                        onImageChanged: onImageChanged,
                        onPrevious: onPrevious,
                        onNext: onNext,
                        onImageTap: onImageTap,
                        isCompact: isCompact,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
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

class _ImageGallery extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onImageTap;
  final bool isCompact;
  final bool isTablet;

  const _ImageGallery({
    required this.product,
    required this.imageIndex,
    required this.pageController,
    required this.onImageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onImageTap,
    required this.isCompact,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.images;
    final hasImages = images.isNotEmpty;
    final aspectRatio = isTablet ? (16 / 9) : (isCompact ? 1.15 : 1.05);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!hasImages)
                GestureDetector(
                  onTap: onImageTap,
                  child: Hero(
                    tag: product.heroTag,
                    child: const ColoredBox(
                      color: AppColors.primaryLightBlue,
                      child: StockImagePlaceholder(),
                    ),
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
                      onTap: onImageTap,
                      child: Hero(
                        tag: index == 0
                            ? product.heroTag
                            : '${product.heroTag}-$index',
                        child: SafeNetworkImage(
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
                    );
                  },
                ),
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
                  bottom: isCompact ? 8 : 12,
                  child: _PageIndicator(
                    count: images.length,
                    index: imageIndex,
                    isCompact: isCompact,
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
  final VoidCallback? onPressed;
  final bool isCompact;

  const _GalleryButton({
    required this.icon,
    required this.onPressed,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 38.0 : 46.0;
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryRoyalBlue.withValues(alpha: 0.88),
        foregroundColor: AppColors.accentGold,
        disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.35),
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
  final bool isCompact;

  const _PageIndicator({
    required this.count,
    required this.index,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (itemIndex) {
        final selected = itemIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? (isCompact ? 14 : 18) : (isCompact ? 6 : 7),
          height: isCompact ? 6 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGold : AppColors.borderLight,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

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
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StockSectionHeader(
            title: 'Product Details',
            subtitle: 'Latest catalogue data from backend',
            icon: Icons.diamond_rounded,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          _DetailRow(
            label: 'Product Name',
            value: product.displayName,
            isCompact: isCompact,
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
            isLast: true,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;
  final bool isLast;
  final bool isCompact;

  const _DetailRow({
    required this.label,
    required this.value,
    this.multiLine = false,
    this.isLast = false,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
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
            width: isCompact ? 104 : 128,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 12 : 13,
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
                fontSize: isCompact ? 13.5 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleAwareBottomBar extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _RoleAwareBottomBar({
    required this.isOwner,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 16,
              isCompact ? 8 : 10,
              isCompact ? 12 : 16,
              bottom > 0 ? (isCompact ? 8 : 10) : (isCompact ? 12 : 16),
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
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: isCompact ? 18 : 20,
                    ),
                    label: Text(
                      isOwner ? 'Back' : 'Add To Cart',
                      style: TextStyle(fontSize: isCompact ? 13.5 : 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, isCompact ? 46 : 52),
                      foregroundColor: AppColors.primaryRoyalBlue,
                      side: const BorderSide(color: AppColors.borderGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isCompact ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isOwner ? onEdit : () {},
                    icon: Icon(
                      isOwner ? Icons.edit_rounded : Icons.flash_on_rounded,
                      size: isCompact ? 18 : 20,
                    ),
                    label: Text(
                      isOwner ? 'Edit Product' : 'Buy Now',
                      style: TextStyle(fontSize: isCompact ? 13.5 : 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, isCompact ? 46 : 52),
                      backgroundColor: AppColors.primaryRoyalBlue,
                      foregroundColor: AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isCompact ? 14 : 16,
                        ),
                      ),
                    ),
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

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 700;
        final horizontalPadding = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
        final maxWidth = screenWidth >= 1100
            ? 760.0
            : (screenWidth >= 700 ? 680.0 : screenWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 10 : 14,
                horizontalPadding,
                isCompact ? 18 : 26,
              ),
              children: [
                const StockShimmerCard(),
                SizedBox(height: isCompact ? 12 : 16),
                const StockShimmerCard(compact: true),
                SizedBox(height: isCompact ? 12 : 16),
                const StockShimmerCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}
