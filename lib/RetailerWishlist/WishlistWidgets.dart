// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../Stock Listing Module/StockApis.dart';
import '../Stock Listing Module/StockWidget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class RetailerProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const RetailerProductSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Container(
          height: isCompact ? 48 : 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 13.5 : 14.5,
            ),
            decoration: InputDecoration(
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                vertical: isCompact ? 12 : 14,
                horizontal: 14,
              ),
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: isCompact ? 13 : 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryRoyalBlue,
                size: isCompact ? 20 : 22,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETAILER PRODUCT ACTION CARD (Responsive Thumbnail, Metric Wrap, SaaS Glow)
// ─────────────────────────────────────────────────────────────────────────────

class RetailerProductActionCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Widget actionArea;
  final int? quantity;
  final String? heroSuffix;

  /// When provided, a red heart overlay button is shown on the top corner of
  /// the product image. Pass null to hide the remove button.
  final VoidCallback? onRemove;
  final bool busy;

  const RetailerProductActionCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.actionArea,
    this.quantity,
    this.heroSuffix,
    this.onRemove,
    this.busy = false,
  });

  @override
  State<RetailerProductActionCard> createState() =>
      _RetailerProductActionCardState();
}

class _RetailerProductActionCardState extends State<RetailerProductActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product.primaryImageUrl;
    final heroTag = widget.heroSuffix == null
        ? product.heroTag
        : '${product.heroTag}-${widget.heroSuffix}';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 650;
    final imageWidth = isTablet ? 132.0 : (isCompact ? 96.0 : 116.0);
    final imageHeight = isTablet ? 144.0 : (isCompact ? 116.0 : 132.0);

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
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
                BoxShadow(
                  color: AppColors.accentGoldGlow,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -46,
                  top: -48,
                  child: _GoldCircle(size: 128),
                ),
                const Positioned(
                  left: -58,
                  bottom: -66,
                  child: _GoldCircle(size: 150),
                ),
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Product Image with floating remove heart badge ──
                        Stack(
                          children: [
                            Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 14 : 16,
                                ),
                                child: Container(
                                  width: imageWidth,
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLightBlue,
                                    borderRadius: BorderRadius.circular(
                                      isCompact ? 14 : 16,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderGold.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: _validUrl(imageUrl)
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const StockImageShimmer(),
                                          errorWidget: (context, url, error) =>
                                              const StockImagePlaceholder(),
                                        )
                                      : const StockImagePlaceholder(),
                                ),
                              ),
                            ),
                            // ── Remove / un-wishlist badge (top-right overlay)
                            if (widget.onRemove != null)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Tooltip(
                                  message: 'Remove from wishlist',
                                  child: GestureDetector(
                                    onTap: widget.busy ? null : widget.onRemove,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: isCompact ? 28 : 32,
                                      height: isCompact ? 28 : 32,
                                      decoration: BoxDecoration(
                                        color: widget.busy
                                            ? Colors.redAccent.withValues(
                                                alpha: 0.45,
                                              )
                                            : Colors.redAccent,
                                        borderRadius: BorderRadius.circular(
                                          isCompact ? 8 : 10,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: isCompact ? 15 : 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: isCompact ? 10 : 14),

                        // ── Product Details & Metrics ───────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.primaryRoyalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 14 : 15.5,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: isCompact ? 6 : 8),
                              _MetricWrap(
                                product: product,
                                quantity: widget.quantity,
                                isCompact: isCompact,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 10 : 12),
                    widget.actionArea,
                  ],
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
// WISHLIST CARD ACTIONS (Add To Cart & Order Now Buttons)
// ─────────────────────────────────────────────────────────────────────────────

class WishlistCardActions extends StatelessWidget {
  final bool busy;
  final VoidCallback onAddToCart;
  final VoidCallback onOrder;

  const WishlistCardActions({
    super.key,
    required this.busy,
    required this.onAddToCart,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final buttonHeight = isCompact ? 44.0 : 48.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onAddToCart,
            icon: Icon(Icons.shopping_cart_rounded, size: isCompact ? 16 : 18),
            label: Text(
              'Add To Cart',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 12 : 13.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, buttonHeight),
              foregroundColor: AppColors.primaryRoyalBlue,
              side: const BorderSide(color: AppColors.borderGold, width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 12),
            ),
          ),
        ),
        SizedBox(width: isCompact ? 6 : 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: busy ? null : onOrder,
            icon: Icon(Icons.flash_on_rounded, size: isCompact ? 16 : 18),
            label: Text(
              'Order',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 12 : 13.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(0, buttonHeight),
              backgroundColor: AppColors.primaryRoyalBlue,
              foregroundColor: AppColors.surfaceWhite,
              elevation: 2,
              shadowColor: AppColors.shadowPrimaryGlow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETAILER MODULE STATE (Responsive Empty / Error Screen)
// ─────────────────────────────────────────────────────────────────────────────

class RetailerModuleState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const RetailerModuleState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final iconBoxSize = isCompact ? 96.0 : 118.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 24,
        isCompact ? 36 : 52,
        isCompact ? 16 : 24,
        24,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _GoldCircle(size: isCompact ? 68 : 82),
                      Icon(
                        icon,
                        color: AppColors.primaryRoyalBlue,
                        size: isCompact ? 40 : 50,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primaryRoyalBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 18 : 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.diamond_rounded, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRoyalBlue,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER LOADING LIST (High Contrast Skeleton)
// ─────────────────────────────────────────────────────────────────────────────

class RetailerProductShimmerList extends StatelessWidget {
  final double horizontalPadding;

  const RetailerProductShimmerList({
    super.key,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
      itemCount: 5,
      separatorBuilder: (context, index) =>
          SizedBox(height: isCompact ? 10 : 12),
      itemBuilder: (context, index) => Container(
        padding: EdgeInsets.all(isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isCompact ? 96 : 116,
                height: isCompact ? 116 : 132,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY STEPPER (Responsive Button)
// ─────────────────────────────────────────────────────────────────────────────

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool busy;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.busy,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quantity $quantity',
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryLightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Decrease quantity',
              onPressed: busy || quantity <= 1 ? null : onDecrease,
              icon: const Icon(Icons.remove_rounded),
            ),
            Text(
              quantity.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              tooltip: 'Increase quantity',
              onPressed: busy ? null : onIncrease,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC WRAP & BADGE CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _MetricWrap extends StatelessWidget {
  final ProductModel product;
  final int? quantity;
  final bool isCompact;

  const _MetricWrap({
    required this.product,
    this.quantity,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quantity != null)
          _Metric(
            label: 'Qty',
            value: quantity.toString(),
            isCompact: isCompact,
          ),
        _Metric(
          label: 'Gross Wt.',
          value: stockFormatGram(product.weights.grossWeight),
          isCompact: isCompact,
        ),
        _Metric(
          label: 'Stone Wt.',
          value: stockFormatGram(product.weights.stoneWeight),
          isCompact: isCompact,
        ),
        _Metric(
          label: 'Stone Chg.',
          value: stockFormatGram(product.weights.stoneCharge),
          isCompact: isCompact,
        ),
        _Metric(
          label: 'Net Wt.',
          value: stockFormatGram(product.weights.netWeight),
          isCompact: isCompact,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isCompact;
  final bool highlight;

  const _Metric({
    required this.label,
    required this.value,
    required this.isCompact,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 4.5,
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.caption.copyWith(
          color: highlight
              ? AppColors.primaryRoyalBlue
              : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          fontSize: isCompact ? 12 : 13,
        ),
      ),
    );
  }
}

class _GoldCircle extends StatelessWidget {
  final double size;

  const _GoldCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.14)),
      ),
    );
  }
}

bool _validUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}
