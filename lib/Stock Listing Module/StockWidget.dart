// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/safe_network_image.dart';
import 'StockApis.dart';

class StockSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;
  final bool? isFilterExpanded;
  final bool? hasActiveFilters;
  final VoidCallback? onToggleFilter;

  const StockSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onClear,
    this.onChanged,
    this.isFilterExpanded,
    this.hasActiveFilters,
    this.onToggleFilter,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final barHeight = isCompact ? 48.0 : 52.0;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        Widget searchField = Container(
          height: barHeight,
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
              fontSize: isCompact ? 13 : 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceWhite,
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: isCompact ? 12.5 : 14,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 12 : 14,
              ),
            ),
          ),
        );

        if (onToggleFilter == null) {
          return Semantics(
            textField: true,
            label: hintText,
            child: searchField,
          );
        }

        final expanded = isFilterExpanded ?? false;
        final active = hasActiveFilters ?? false;

        return Row(
          children: [
            Expanded(
              child: Semantics(
                textField: true,
                label: hintText,
                child: searchField,
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleFilter,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: barHeight,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: expanded
                        ? AppColors.primaryRoyalBlue
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: expanded
                          ? AppColors.primaryRoyalBlue
                          : AppColors.borderGold,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        expanded
                            ? Icons.tune_rounded
                            : Icons.filter_list_rounded,
                        color: expanded
                            ? AppColors.surfaceWhite
                            : AppColors.accentGoldDark,
                        size: isCompact ? 21 : 24,
                      ),
                      if (active && !expanded)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class StockProductNameCard extends StatefulWidget {
  final ProductNameGroup group;
  final VoidCallback onTap;

  const StockProductNameCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  State<StockProductNameCard> createState() => _StockProductNameCardState();
}

class _StockProductNameCardState extends State<StockProductNameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final imageSize = isCompact ? 58.0 : (isTablet ? 78.0 : 66.0);
    final cardPadding = isCompact ? 10.0 : 14.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _premiumCardDecoration(radius: 22),
            child: Row(
              children: [
                StockProductImage(
                  imageUrl: widget.group.imageUrl,
                  heroTag: 'stock-name-${widget.group.productName}',
                  size: imageSize,
                  onTap: () => openStockImageUrlZoom(
                    context,
                    imageUrl: widget.group.imageUrl,
                    heroTag: 'stock-name-${widget.group.productName}',
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
                Expanded(
                  child: Text(
                    widget.group.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryRoyalBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ProductBadge(
                  label: widget.group.count.toString(),
                  compact: isCompact,
                  semanticsLabel: '${widget.group.count} products',
                ),
                SizedBox(width: isCompact ? 3 : 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentGoldDark,
                  size: isCompact ? 22 : 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StockWeightCard extends StatefulWidget {
  final StockWeightGroup group;
  final VoidCallback onTap;

  const StockWeightCard({super.key, required this.group, required this.onTap});

  @override
  State<StockWeightCard> createState() => _StockWeightCardState();
}

class _StockWeightCardState extends State<StockWeightCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final iconBoxSize = isCompact ? 44.0 : (isTablet ? 56.0 : 50.0);
    final cardPadding = isCompact ? 12.0 : 16.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _premiumCardDecoration(radius: 22),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Icon(
                    Icons.scale_rounded,
                    color: AppColors.primaryRoyalBlue,
                    size: isCompact ? 21 : 24,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
                Expanded(
                  child: Text(
                    widget.group.range.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryRoyalBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ProductBadge(
                  label: widget.group.count.toString(),
                  compact: isCompact,
                  semanticsLabel: '${widget.group.count} products',
                ),
                SizedBox(width: isCompact ? 3 : 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentGoldDark,
                  size: isCompact ? 22 : 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StockProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const StockProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<StockProductCard> createState() => _StockProductCardState();
}

class _StockProductCardState extends State<StockProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final imageSize = isCompact ? 76.0 : (isTablet ? 104.0 : 88.0);
    final cardPadding = isCompact ? 10.0 : 12.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _premiumCardDecoration(radius: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StockProductImage(
                  imageUrl: product.primaryImageUrl,
                  heroTag: product.heroTag,
                  size: imageSize,
                  onTap: () => openStockImageZoom(context, product: product),
                ),
                SizedBox(width: isCompact ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 14 : 15.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MetricWrap(product: product, compact: isCompact),
                    ],
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

class _MetricWrap extends StatelessWidget {
  final ProductModel product;
  final bool compact;

  const _MetricWrap({required this.product, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Metric(
          label: 'Gross Wt.',
          value: _gm(product.weights.grossWeight),
          compact: compact,
        ),
        _Metric(
          label: 'Stone Wt.',
          value: _gm(product.weights.stoneWeight),
          compact: compact,
        ),
        _Metric(
          label: 'Stone Chg.',
          value: _gm(product.weights.stoneCharge),
          compact: compact,
        ),
        _Metric(
          label: 'Net Wt.',
          value: _gm(product.weights.netWeight),
          compact: compact,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _Metric({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: compact ? 14 : 15,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.primaryDarkBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductBadge extends StatelessWidget {
  final String label;
  final String? semanticsLabel;
  final bool compact;

  const ProductBadge({
    super.key,
    required this.label,
    this.semanticsLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? label,
      child: Container(
        constraints: BoxConstraints(maxWidth: compact ? 84 : 120),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentGoldSubtle,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.trim().isEmpty ? StockStrings.unavailable : label.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.accentGoldDark,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 10 : 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

class StockProductImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final double size;
  final BoxFit fit;
  final VoidCallback? onTap;

  const StockProductImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.size = 92,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valid = _isValidUrl(imageUrl);
    Widget imageWidget = Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primaryLightBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.35),
            ),
          ),
          child: valid
              ? SafeNetworkImage(
                  imageUrl: imageUrl,
                  fit: fit,
                  memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  placeholder: (context, url) => const StockImageShimmer(),
                  errorWidget: (context, url, error) =>
                      const StockBrokenImage(),
                  fadeInDuration: const Duration(milliseconds: 220),
                )
              : const StockImagePlaceholder(),
        ),
      ),
    );

    if (onTap != null && valid) {
      return GestureDetector(onTap: onTap, child: imageWidget);
    }
    return imageWidget;
  }
}

class StockImageShimmer extends StatelessWidget {
  const StockImageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLightBlue,
      highlightColor: AppColors.surfaceWhite,
      child: Container(color: AppColors.surfaceWhite),
    );
  }
}

class StockImagePlaceholder extends StatelessWidget {
  const StockImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.diamond_rounded,
        color: AppColors.accentGoldDark,
        size: 32,
      ),
    );
  }
}

class StockBrokenImage extends StatelessWidget {
  const StockBrokenImage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.broken_image_rounded,
        color: AppColors.primaryRoyalBlue,
        size: 30,
      ),
    );
  }
}

class StockEmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const StockEmptyWidget({
    super.key,
    this.title = StockStrings.noProducts,
    this.message = 'No matching catalogue products are available.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.inventory_2_rounded,
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }
}

class StockErrorWidget extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const StockErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'Unable to load stock',
      message: message,
      onRetry: onRetry,
    );
  }
}

class _StateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _StateWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final iconBoxSize = isCompact ? 88.0 : 108.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(20, isCompact ? 36 : 48, 20, 24),
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
                  child: Icon(
                    icon,
                    color: AppColors.primaryRoyalBlue,
                    size: isCompact ? 42 : 50,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primaryRoyalBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 17 : 20,
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
                SizedBox(
                  width: isCompact ? 150 : 178,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(StockStrings.retry),
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

class StockShimmerCard extends StatelessWidget {
  final bool compact;

  const StockShimmerCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLightBlue,
      highlightColor: AppColors.surfaceWhite,
      child: Container(
        height: compact ? 86 : 110,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class StockWeightChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const StockWeightChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        label: Text(label),
        avatar: selected
            ? const Icon(Icons.check_rounded, size: 16)
            : const Icon(Icons.tune_rounded, size: 16),
        selectedColor: AppColors.primaryRoyalBlue,
        checkmarkColor: AppColors.accentGold,
        backgroundColor: AppColors.surfaceWhite,
        labelStyle: AppTypography.caption.copyWith(
          color: selected ? AppColors.surfaceWhite : AppColors.primaryRoyalBlue,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(
          color: selected ? AppColors.primaryRoyalBlue : AppColors.borderGold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class StockSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const StockSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inventory_2_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Row(
      children: [
        Container(
          width: isCompact ? 36 : 42,
          height: isCompact ? 36 : 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLightBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryRoyalBlue,
            size: isCompact ? 18 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 15 : 17,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StockStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StockStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Semantics(
      label: '$label $value',
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        decoration: _premiumCardDecoration(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 36 : 42,
              height: isCompact ? 36 : 42,
              decoration: BoxDecoration(
                color: AppColors.accentGoldSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Icon(
                icon,
                color: AppColors.accentGoldDark,
                size: isCompact ? 18 : 21,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value.trim().isEmpty ? StockStrings.unavailable : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
                fontSize: isCompact ? 14 : 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
    );
  }
}

BoxDecoration _premiumCardDecoration({double radius = 22}) {
  return BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowSoft,
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
      BoxShadow(
        color: AppColors.accentGoldGlow,
        blurRadius: 14,
        offset: Offset(0, 7),
      ),
    ],
  );
}

String stockFormatGram(double value) => _gm(value);

String stockFormatMoney(double value) => _money(value);

String _gm(double value) =>
    value == 0 ? StockStrings.unavailable : '${value.toStringAsFixed(3)} gm';

String _money(double? value) => value == null || value == 0
    ? StockStrings.unavailable
    : value.toStringAsFixed(2);

void openStockImageZoom(
  BuildContext context, {
  required ProductModel product,
  int initialIndex = 0,
  ValueChanged<int>? onPageChanged,
}) {
  final images = product.images
      .map((e) => e.url)
      .where((url) => url.isNotEmpty)
      .toList();
  final list = images.isEmpty
      ? (product.primaryImageUrl.isNotEmpty
            ? [product.primaryImageUrl]
            : <String>[])
      : images;
  if (list.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StockImageZoomScreen(
        images: list,
        initialIndex: initialIndex,
        heroTagPrefix: product.heroTag,
        onPageChanged: onPageChanged,
      ),
    ),
  );
}

void openStockImageUrlZoom(
  BuildContext context, {
  required String imageUrl,
  required String heroTag,
}) {
  if (imageUrl.trim().isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StockImageZoomScreen(
        images: [imageUrl],
        initialIndex: 0,
        heroTagPrefix: heroTag,
      ),
    ),
  );
}

class StockImageZoomScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;
  final ValueChanged<int>? onPageChanged;

  const StockImageZoomScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.heroTagPrefix,
    this.onPageChanged,
  });

  @override
  State<StockImageZoomScreen> createState() => _StockImageZoomScreenState();
}

class _StockImageZoomScreenState extends State<StockImageZoomScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _previousImage() {
    if (_currentIndex <= 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextImage() {
    if (_currentIndex >= widget.images.length - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? [''] : widget.images;
    final hasMultiple = images.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: hasMultiple
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final image = images[index];
              final tag = index == 0
                  ? widget.heroTagPrefix
                  : '${widget.heroTagPrefix}-$index';
              return Hero(
                tag: tag,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: image.isEmpty
                        ? const Icon(
                            Icons.diamond_rounded,
                            color: AppColors.accentGold,
                            size: 96,
                          )
                        : SafeNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.contain,
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
          if (hasMultiple) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white30,
                  ),
                  onPressed: _currentIndex == 0 ? null : _previousImage,
                  icon: const Icon(Icons.chevron_left_rounded, size: 32),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white30,
                  ),
                  onPressed: _currentIndex == images.length - 1
                      ? null
                      : _nextImage,
                  icon: const Icon(Icons.chevron_right_rounded, size: 32),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}
