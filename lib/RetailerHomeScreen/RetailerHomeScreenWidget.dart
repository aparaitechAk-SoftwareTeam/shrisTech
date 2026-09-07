// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/safe_network_image.dart';
import 'RetailerHomeScreenApis.dart';

class RetailerHomeText {
  static const discoverCollections = 'Discover premium jewellery collections.';
  static const viewAll = 'View All';
  static const retry = 'Retry';
  static const sectionUnavailable = 'Section unavailable';
  static const noData = 'No data available yet.';
  static const addToCart = 'Add To Cart';
  static const buyNow = 'Buy Now';
  static const editProduct = 'Edit Product';
  static const analytics = 'Analytics';
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME CARD (Responsive & Dynamic SaaS Banner)
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeCard extends StatelessWidget {
  final String greeting;
  final String retailerName;

  const WelcomeCard({
    super.key,
    required this.greeting,
    required this.retailerName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 650;
        final cardPadding = isTablet ? 26.0 : (isCompact ? 14.0 : 18.0);
        final illustrationSize = isTablet ? 120.0 : (isCompact ? 72.0 : 96.0);
        final rightOffset = isTablet ? 24.0 : (isCompact ? 6.0 : 12.0);

        return Semantics(
          label: '$greeting $retailerName',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1E4C),
                  AppColors.primaryDarkBlue,
                  AppColors.primaryRoyalBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowPrimaryGlow,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _GoldLinePainter()),
                ),
                Positioned(
                  right: -24,
                  top: -28,
                  child: _DecorativeCircle(size: isCompact ? 80 : 115),
                ),
                Positioned(
                  right: rightOffset,
                  bottom: isCompact ? -4 : 0,
                  top: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _JewelleryIllustration(size: illustrationSize),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: illustrationSize + (isCompact ? 10 : 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 10,
                          vertical: isCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.borderGold.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: isCompact ? 12 : 14,
                              color: AppColors.accentGold,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                greeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isCompact ? 10.5 : 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 6 : 8),
                      Text(
                        retailerName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          fontSize: isTablet ? 28 : (isCompact ? 18 : 22),
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        RetailerHomeText.discoverCollections,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.88),
                          height: 1.3,
                          fontSize: isCompact ? 11.5 : 13,
                        ),
                      ),
                    ],
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
// RETAILER ORDER SUMMARY CARDS (Placed & Delivered Counts)
// ─────────────────────────────────────────────────────────────────────────────

class RetailerOrderSummaryCards extends StatelessWidget {
  final int? placedCount;
  final int? deliveredCount;
  final bool isLoading;
  final VoidCallback? onPlacedTap;
  final VoidCallback? onDeliveredTap;

  const RetailerOrderSummaryCards({
    super.key,
    this.placedCount,
    this.deliveredCount,
    this.isLoading = false,
    this.onPlacedTap,
    this.onDeliveredTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;

        if (isLoading) {
          return Row(
            children: [
              Expanded(child: ShimmerCard(height: isCompact ? 72 : 82)),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(child: ShimmerCard(height: isCompact ? 72 : 82)),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _OrderMetricCard(
                title: 'Placed Orders',
                count: placedCount ?? 0,
                subtitle: 'Total Placed',
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primaryRoyalBlue,
                iconBgColor: AppColors.primaryLightBlue,
                borderColor: AppColors.borderGold.withValues(alpha: 0.5),
                badgeColor: AppColors.primaryLightBlue,
                badgeTextColor: AppColors.primaryRoyalBlue,
                isCompact: isCompact,
                onTap: onPlacedTap,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: _OrderMetricCard(
                title: 'Delivered Orders',
                count: deliveredCount ?? 0,
                subtitle: 'Fulfilled',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFD1FAE5),
                borderColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                badgeColor: const Color(0xFFD1FAE5),
                badgeTextColor: const Color(0xFF047857),
                isCompact: isCompact,
                onTap: onDeliveredTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderMetricCard extends StatefulWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final bool isCompact;
  final VoidCallback? onTap;

  const _OrderMetricCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.isCompact,
    this.onTap,
  });

  @override
  State<_OrderMetricCard> createState() => _OrderMetricCardState();
}

class _OrderMetricCardState extends State<_OrderMetricCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _pressed ? 0.97 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 14,
              vertical: widget.isCompact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
              border: Border.all(color: widget.borderColor, width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: widget.isCompact ? 36 : 42,
                  height: widget.isCompact ? 36 : 42,
                  decoration: BoxDecoration(
                    color: widget.iconBgColor,
                    borderRadius: BorderRadius.circular(
                      widget.isCompact ? 10 : 12,
                    ),
                    border: Border.all(
                      color: widget.iconColor.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: widget.isCompact ? 18 : 22,
                  ),
                ),
                SizedBox(width: widget.isCompact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.count.toString().padLeft(2, '0'),
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: widget.isCompact ? 17 : 21,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: widget.badgeTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: widget.isCompact ? 9 : 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: widget.isCompact ? 10.5 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: widget.isCompact ? 10 : 12,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
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
// BANNER CAROUSEL (Responsive Aspect Ratio & Legible Typography)
// ─────────────────────────────────────────────────────────────────────────────

class BannerCarousel extends StatefulWidget {
  final List<RetailerBannerModel> banners;
  final ValueChanged<RetailerBannerModel>? onBannerTap;

  const BannerCarousel({super.key, required this.banners, this.onBannerTap});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel>
    with AutomaticKeepAliveClientMixin {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = 0;
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 650;
        final bannerHeight = isTablet ? 220.0 : (isCompact ? 164.0 : 184.0);

        return Column(
          children: [
            SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                key: const PageStorageKey<String>('retailer-banner-carousel'),
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final banner = widget.banners[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _BannerCard(
                      banner: banner,
                      isCompact: isCompact,
                      onTap: () => widget.onBannerTap?.call(banner),
                    ),
                  );
                },
              ),
            ),
            if (widget.banners.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (index) {
                  final selected = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentGold
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION CARD & GRID
// ─────────────────────────────────────────────────────────────────────────────

class QuickActionCard extends StatefulWidget {
  final RetailerQuickActionModel action;
  final VoidCallback onTap;

  const QuickActionCard({super.key, required this.action, required this.onTap});

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 160;

        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _pressed ? 0.98 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(20),
              child: _PremiumCard(
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                child: Semantics(
                  button: true,
                  label: widget.action.title,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _IconBox(
                            icon: widget.action.icon,
                            isCompact: isCompact,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.accentGoldDark,
                            size: isCompact ? 13 : 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.action.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 13.5 : 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.action.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.25,
                          fontSize: isCompact ? 10.5 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveQuickActionGrid extends StatelessWidget {
  final List<RetailerQuickActionModel> actions;
  final ValueChanged<RetailerQuickActionModel> onTap;

  const ResponsiveQuickActionGrid({
    super.key,
    required this.actions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 820
            ? 4
            : width >= 520
            ? 3
            : 2;
        final childAspect = width < 360 ? 1.05 : (width < 420 ? 1.15 : 1.25);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspect,
          ),
          itemBuilder: (context, index) => QuickActionCard(
            action: actions[index],
            onTap: () => onTap(actions[index]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CARD (Responsive width & clear non-cramped label)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryCard extends StatelessWidget {
  final RetailerCategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: 156,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: _PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.38,
                        child: _NetworkImage(
                          url: category.imageUrl,
                          semanticLabel: category.title,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            category.icon,
                            color: AppColors.accentGoldDark,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              category.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD (Adaptive width, badges, dual action buttons)
// ─────────────────────────────────────────────────────────────────────────────

class ProductCard extends StatelessWidget {
  final RetailerProductModel product;
  final RetailerProductRole role;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onWishlist;

  const ProductCard({
    super.key,
    required this.product,
    required this.role,
    required this.onTap,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == RetailerProductRole.owner;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: 236,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: _PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: 'retailer-product-${product.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.28,
                              child: _NetworkImage(
                                url: product.imageUrl,
                                semanticLabel: product.name,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: _CircleIconButton(
                            icon: product.isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            onTap: onWishlist,
                            semanticLabel: 'Wishlist ${product.name}',
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldSubtle,
                              borderRadius: BorderRadius.circular(999),
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
                                const Icon(
                                  Icons.scale_rounded,
                                  size: 12,
                                  color: AppColors.accentGoldDark,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Net Wt ${product.netWeight}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.accentGoldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniButton(
                                  label: isOwner
                                      ? RetailerHomeText.editProduct
                                      : RetailerHomeText.addToCart,
                                  icon: isOwner
                                      ? Icons.edit_rounded
                                      : Icons.shopping_cart_rounded,
                                  onTap: onPrimaryAction,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _MiniButton(
                                  label: isOwner
                                      ? RetailerHomeText.analytics
                                      : RetailerHomeText.buyNow,
                                  icon: isOwner
                                      ? Icons.analytics_rounded
                                      : Icons.flash_on_rounded,
                                  onTap: onSecondaryAction,
                                  filled: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFER CARD
// ─────────────────────────────────────────────────────────────────────────────

class OfferCard extends StatelessWidget {
  final RetailerOfferModel offer;
  final VoidCallback onTap;

  const OfferCard({super.key, required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: _PremiumCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: _NetworkImage(
                    url: offer.imageUrl,
                    semanticLabel: offer.title,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.accentGoldDark,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT ORDER CARD (Responsive Row / Tag)
// ─────────────────────────────────────────────────────────────────────────────

class RecentOrderCard extends StatelessWidget {
  final RetailerOrderPreviewModel order;
  final VoidCallback onTap;

  const RecentOrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _IconBox(
                    icon: Icons.receipt_long_rounded,
                    isCompact: isCompact,
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: isCompact ? 13 : 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: isCompact ? 10.5 : 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: isCompact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: order.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: order.statusColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      order.status,
                      style: AppTypography.caption.copyWith(
                        color: order.statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 10 : 11.5,
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// STATISTIC CARD (Responsive, Non-Clipping Metrics)
// ─────────────────────────────────────────────────────────────────────────────

class StatisticCard extends StatelessWidget {
  final RetailerStatisticModel statistic;

  const StatisticCard({super.key, required this.statistic});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;

        return _PremiumCard(
          padding: EdgeInsets.all(isCompact ? 10 : 14),
          child: Row(
            children: [
              _IconBox(icon: statistic.icon, gold: true, isCompact: isCompact),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        statistic.value,
                        maxLines: 1,
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 18 : 22,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statistic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 10.5 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER (Fixed Truncation with Adaptive Typography)
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          color: AppColors.surfaceWhite,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primaryRoyalBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 17 : 19,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: isCompact ? 36 : 44,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isCompact ? 11 : 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onViewAll != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          RetailerHomeText.viewAll,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentGoldDark,
                            fontWeight: FontWeight.w900,
                            fontSize: isCompact ? 11.5 : 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.accentGoldDark,
                          size: isCompact ? 10 : 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON / SHIMMER & STATE CARDS
// ─────────────────────────────────────────────────────────────────────────────

class EmptyWidget extends StatelessWidget {
  final String message;

  const EmptyWidget({super.key, this.message = RetailerHomeText.noData});

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.inbox_rounded,
      title: RetailerHomeText.noData,
      message: message,
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.error_outline_rounded,
      title: RetailerHomeText.sectionUnavailable,
      message: message,
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(RetailerHomeText.retry),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerCard({
    super.key,
    this.height = 132,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY DELEGATE & CONTAINERS
// ─────────────────────────────────────────────────────────────────────────────

class StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final double horizontalPadding;
  final double maxWidth;
  final VoidCallback? onViewAll;

  const StickySectionHeaderDelegate({
    required this.title,
    required this.horizontalPadding,
    required this.maxWidth,
    this.subtitle,
    this.onViewAll,
  });

  @override
  double get minExtent => subtitle == null ? 58 : 74;

  @override
  double get maxExtent => subtitle == null ? 64 : 82;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: overlapsContent
            ? const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SectionHeader(
              title: title,
              subtitle: subtitle,
              onViewAll: onViewAll,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        horizontalPadding != oldDelegate.horizontalPadding ||
        maxWidth != oldDelegate.maxWidth;
  }
}

class RetailerSectionContainer<T> extends StatelessWidget {
  final SectionResult<T>? result;
  final VoidCallback onRetry;
  final Widget Function(List<T> items) builder;
  final Widget loading;
  final Widget? emptyWidget;
  final bool hideWhenEmpty;

  const RetailerSectionContainer({
    super.key,
    required this.result,
    required this.onRetry,
    required this.builder,
    this.loading = const ShimmerCard(),
    this.emptyWidget,
    this.hideWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = result;
    if (value == null) return loading;
    switch (value.status) {
      case RetailerSectionStatus.loading:
        return loading;
      case RetailerSectionStatus.empty:
        if (hideWhenEmpty) return const SizedBox.shrink();
        return emptyWidget ??
            EmptyWidget(message: value.message ?? RetailerHomeText.noData);
      case RetailerSectionStatus.error:
        if (hideWhenEmpty) return const SizedBox.shrink();
        return ErrorWidget(
          message: value.message ?? RetailerHomeText.sectionUnavailable,
          onRetry: onRetry,
        );
      case RetailerSectionStatus.success:
        if (value.items.isEmpty) {
          if (hideWhenEmpty) return const SizedBox.shrink();
          return emptyWidget ??
              EmptyWidget(message: value.message ?? RetailerHomeText.noData);
        }
        return builder(value.items);
    }
  }
}

class HorizontalSection extends StatelessWidget {
  final List<Widget> children;
  final double height;

  const HorizontalSection({
    super.key,
    required this.children,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        key: PageStorageKey<String>('horizontal-section-$height'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final RetailerBannerModel banner;
  final bool isCompact;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkImage(url: banner.imageUrl, semanticLabel: banner.title),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryDarkBlue.withValues(alpha: 0.20),
                      AppColors.primaryDarkBlue.withValues(alpha: 0.90),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: CustomPaint(painter: _GoldLinePainter()),
              ),
              Positioned(
                left: isCompact ? 12 : 16,
                right: isCompact ? 16 : 20,
                bottom: isCompact ? 12 : 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 10,
                        vertical: isCompact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: banner.accentColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.borderGold,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        AppConstants.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 10 : 11.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 8),
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 15 : 18,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      banner.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 10.5 : 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentGoldGlow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  final String semanticLabel;

  const _NetworkImage({required this.url, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return SafeNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 260),
      placeholder: (context, url) => const ShimmerCard(height: double.infinity),
      errorWidget: (context, url, error) => Container(
        color: AppColors.primaryLightBlue,
        alignment: Alignment.center,
        child: const Icon(
          Icons.diamond_rounded,
          color: AppColors.accentGold,
          size: 30,
        ),
      ),
      imageBuilder: (context, imageProvider) => Semantics(
        image: true,
        label: semanticLabel,
        child: Image(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool gold;
  final bool isCompact;

  const _IconBox({
    required this.icon,
    this.gold = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = isCompact ? 38.0 : 44.0;
    final iconSize = isCompact ? 19.0 : 22.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: gold ? AppColors.accentGoldSubtle : AppColors.primaryLightBlue,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(color: AppColors.borderGold, width: 0.8),
      ),
      child: Icon(
        icon,
        color: gold ? AppColors.accentGoldDark : AppColors.primaryRoyalBlue,
        size: iconSize,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            color: icon == Icons.favorite_rounded
                ? Colors.redAccent
                : AppColors.accentGoldDark,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;

  const _MiniButton({
    required this.label,
    this.icon,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRoyalBlue,
                foregroundColor: AppColors.surfaceWhite,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: AppColors.surfaceWhite),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentGoldDark,
                side: const BorderSide(color: AppColors.borderGold, width: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: AppColors.accentGoldDark),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentGoldDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBox(icon: icon, gold: true),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _JewelleryIllustration extends StatelessWidget {
  final double size;

  const _JewelleryIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.diamond_rounded,
            color: AppColors.accentGold.withValues(alpha: 0.95),
            size: size * 0.52,
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.16,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.surfaceWhite.withValues(alpha: 0.92),
              size: size * 0.20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;

  const _DecorativeCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
    );
  }
}

class _GoldLinePainter extends CustomPainter {
  const _GoldLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (double y = 12; y < size.height + 40; y += 18) {
      canvas.drawLine(
        Offset(size.width * 0.55, y),
        Offset(size.width, y - 42),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldLinePainter oldDelegate) => false;
}
