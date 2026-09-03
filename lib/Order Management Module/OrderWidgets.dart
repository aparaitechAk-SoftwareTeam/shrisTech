// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'OrderApis.dart';

const List<String> orderStatusFilters = [
  'Pending',
  'Accepted',
  'Rejected',
  'Dispatched',
  'Delivered',
  'Cancelled',
];

Color statusColor(String status) {
  switch (normalizeOrderStatus(status)) {
    case 'Accepted':
      return const Color(0xFF2563EB);
    case 'Dispatched':
      return const Color(0xFF7C3AED);
    case 'Delivered':
      return const Color(0xFF16A34A);
    case 'Rejected':
      return const Color(0xFFDC2626);
    case 'Cancelled':
      return const Color(0xFFF97316);
    default:
      return const Color(0xFFD97706);
  }
}

String formatDate(DateTime? date) {
  if (date == null) return 'N/A';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String formatWeight(double? value) => value == null
    ? 'N/A'
    : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} g';

// ─────────────────────────────────────────────────────────────────────────────
// ORDER SEARCH BAR (Responsive, High Contrast)
// ─────────────────────────────────────────────────────────────────────────────

class OrderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;
  final bool? isFilterExpanded;
  final bool? hasActiveFilters;
  final VoidCallback? onToggleFilter;

  const OrderSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.onClear,
    this.isFilterExpanded,
    this.hasActiveFilters,
    this.onToggleFilter,
  });

  @override
  Widget build(BuildContext context) {
    final showClear = controller.text.trim().isNotEmpty;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final barHeight = isCompact ? 48.0 : 52.0;

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
          fontSize: isCompact ? 13.5 : 14.5,
        ),
        decoration: InputDecoration(
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
          suffixIcon: showClear
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: isCompact ? 18 : 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 12 : 14,
          ),
        ),
      ),
    );

    if (onToggleFilter == null) {
      return searchField;
    }

    final expanded = isFilterExpanded ?? false;
    final active = hasActiveFilters ?? false;

    return Row(
      children: [
        Expanded(child: searchField),
        SizedBox(width: isCompact ? 8 : 12),
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
                    expanded ? Icons.tune_rounded : Icons.filter_list_rounded,
                    color: expanded
                        ? AppColors.surfaceWhite
                        : AppColors.accentGoldDark,
                    size: isCompact ? 20 : 24,
                  ),
                  if (active && !expanded)
                    Positioned(
                      top: isCompact ? 9 : 12,
                      right: isCompact ? 9 : 12,
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER PANEL (Responsive Chips & Segmented Controls)
// ─────────────────────────────────────────────────────────────────────────────

class FilterPanel extends StatefulWidget {
  final Set<String> selectedStatuses;
  final OrderSortMode sortMode;
  final ValueChanged<String> onStatusToggled;
  final ValueChanged<OrderSortMode> onSortChanged;
  final bool? isExpanded;
  final VoidCallback? onClearAllFilters;

  const FilterPanel({
    super.key,
    required this.selectedStatuses,
    required this.sortMode,
    required this.onStatusToggled,
    required this.onSortChanged,
    this.isExpanded,
    this.onClearAllFilters,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  bool _internalExpanded = false;

  bool get _effectiveExpanded => widget.isExpanded ?? _internalExpanded;

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.isExpanded == null;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onClearAllFilters != null) ...[
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.primaryRoyalBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Orders',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 14 : 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClearAllFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11.5 : 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: isCompact ? 6 : 8,
            runSpacing: isCompact ? 6 : 8,
            children: orderStatusFilters.map((status) {
              final selected = widget.selectedStatuses.contains(status);
              final color = statusColor(status);
              return FilterChip(
                label: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11 : 12.5,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 4 : 8,
                  vertical: isCompact ? 2 : 4,
                ),
                selected: selected,
                onSelected: (_) => widget.onStatusToggled(status),
                selectedColor: color.withValues(alpha: 0.14),
                checkmarkColor: color,
                side: BorderSide(
                  color: selected ? color : AppColors.borderLight,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<OrderSortMode>(
          segments: [
            ButtonSegment(
              value: OrderSortMode.newestFirst,
              label: Text(
                'Newest First',
                style: TextStyle(
                  fontSize: isCompact ? 11.5 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.south_rounded, size: 16),
            ),
            ButtonSegment(
              value: OrderSortMode.oldestFirst,
              label: Text(
                'Oldest First',
                style: TextStyle(
                  fontSize: isCompact ? 11.5 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.north_rounded, size: 16),
            ),
          ],
          selected: {widget.sortMode},
          onSelectionChanged: (value) => widget.onSortChanged(value.first),
        ),
      ],
    );

    if (!showHeader) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: _effectiveExpanded
            ? Container(
                margin: const EdgeInsets.only(top: 10),
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                  border: Border.all(
                    color: AppColors.borderGold.withValues(alpha: 0.8),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: content,
              )
            : const SizedBox.shrink(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _internalExpanded = !_internalExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 10 : 12,
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.accentGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Filters',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primaryRoyalBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ),
                  Icon(
                    _internalExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryRoyalBlue,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            child: _internalExpanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 10 : 14,
                      0,
                      isCompact ? 10 : 14,
                      isCompact ? 10 : 14,
                    ),
                    child: content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE (High Contrast Pill)
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeOrderStatus(status);
    final color = statusColor(normalized);
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38), width: 0.8),
      ),
      child: Text(
        normalized,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 10.5 : 11.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD (Responsive Hero Image, Metric Wrap, Action Row)
// ─────────────────────────────────────────────────────────────────────────────

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool shopCard;
  final VoidCallback onTap;
  final Widget? actionArea;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.actionArea,
    this.shopCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = order.primaryItem;
    final hasImage = item.imageUrl.trim().isNotEmpty;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final imageHeight = isCompact ? 144.0 : 180.0;

    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 160),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner image
                if (!shopCard && hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isCompact ? 18 : 22),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerBox(),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryLightBlue,
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.primaryRoyalBlue,
                              ),
                            ),
                          ),
                        ),
                        // Top-right chevron
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite.withValues(
                                alpha: 0.90,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.accentGold,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content area
                Padding(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: shopCard
                      ? _ShopSummary(order: order, isCompact: isCompact)
                      : _OrderSummary(order: order, isCompact: isCompact),
                ),

                if (actionArea != null) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 12 : 16,
                      0,
                      isCompact ? 12 : 16,
                      isCompact ? 12 : 16,
                    ),
                    child: actionArea!,
                  ),
                ],

                if (!hasImage && !shopCard)
                  const Padding(
                    padding: EdgeInsets.only(right: 12, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.accentGold,
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

class _ShopSummary extends StatelessWidget {
  final OrderModel order;
  final bool isCompact;

  const _ShopSummary({required this.order, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.retailer.shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 14.5 : 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Owner: ${order.retailer.ownerName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: isCompact ? 12 : 13.5,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Wrap(
          spacing: isCompact ? 6 : 8,
          runSpacing: isCompact ? 6 : 8,
          children: [
            _InfoPill(
              icon: Icons.calendar_today_rounded,
              label: formatDate(order.orderDate),
              isCompact: isCompact,
            ),
            _InfoPill(
              icon: Icons.receipt_long_rounded,
              label: '${order.totalOrders} orders',
              isCompact: isCompact,
            ),
            _InfoPill(
              icon: Icons.confirmation_number_rounded,
              label: order.orderNumber,
              isCompact: isCompact,
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final OrderModel order;
  final bool isCompact;

  const _OrderSummary({required this.order, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final item = order.primaryItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 14.5 : 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Order ${order.orderNumber} • ${formatDate(order.orderDate)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Wrap(
          spacing: isCompact ? 6 : 8,
          runSpacing: isCompact ? 6 : 8,
          children: [
            _InfoPill(
              icon: Icons.numbers_rounded,
              label: 'Qty ${item.quantity == 0 ? 'N/A' : item.quantity}',
              isCompact: isCompact,
            ),
            _InfoPill(
              icon: Icons.scale_rounded,
              label: 'GW ${formatWeight(item.grossWeight)}',
              isCompact: isCompact,
            ),
            _InfoPill(
              icon: Icons.diamond_rounded,
              label: 'NW ${formatWeight(item.netWeight)}',
              isCompact: isCompact,
              highlight: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompact;
  final bool highlight;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.isCompact,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 4 : 5.5,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryLightBlue
            : AppColors.surfaceCardSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.borderGold.withValues(alpha: 0.6)
              : AppColors.borderLight,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: highlight
                ? AppColors.primaryRoyalBlue
                : AppColors.accentGoldDark,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: highlight
                    ? AppColors.primaryRoyalBlue
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 10.5 : 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATISTIC CARD (Responsive Detail Card)
// ─────────────────────────────────────────────────────────────────────────────

class StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.accentGold,
                size: isCompact ? 15 : 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 11 : 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 3 : 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryRoyalBlue,
              fontWeight: FontWeight.w900,
              fontSize: isCompact ? 13.5 : 15.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE WIDGET (Order Progression Steps)
// ─────────────────────────────────────────────────────────────────────────────

class TimelineWidget extends StatelessWidget {
  final String status;
  const TimelineWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeOrderStatus(status);
    final special = normalized == 'Rejected' || normalized == 'Cancelled';
    final steps = special
        ? ['Pending', normalized]
        : ['Pending', 'Accepted', 'Dispatched', 'Delivered'];
    final activeIndex = steps.indexOf(normalized).clamp(0, steps.length - 1);
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Column(
      children: List.generate(steps.length, (index) {
        final done = index <= activeIndex;
        final color = done ? statusColor(steps[index]) : AppColors.borderLight;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCompact ? 18 : 22,
                  height: isCompact ? 18 : 22,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceWhite,
                      width: isCompact ? 2 : 3,
                    ),
                  ),
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          size: isCompact ? 10 : 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: isCompact ? 28 : 34,
                    color: done
                        ? color.withValues(alpha: 0.55)
                        : AppColors.borderLight,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  steps[index],
                  style: AppTypography.bodyMedium.copyWith(
                    color: done ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: done ? FontWeight.w900 : FontWeight.w600,
                    fontSize: isCompact ? 12.5 : 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTONS (Responsive Sizing, Loading Indicator)
// ─────────────────────────────────────────────────────────────────────────────

class ActionButtons extends StatelessWidget {
  final OrderModel order;
  final bool isOwner;
  final bool loading;
  final ValueChanged<String> onStatusSelected;

  const ActionButtons({
    super.key,
    required this.order,
    required this.isOwner,
    required this.loading,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final actions = <String>[];

    if (isOwner) {
      if (canOwnerTransition(order.status, 'Accepted')) {
        actions.addAll(['Accepted', 'Rejected']);
      }
      if (canOwnerTransition(order.status, 'Dispatched')) {
        actions.add('Dispatched');
      }
      if (canOwnerTransition(order.status, 'Delivered')) {
        actions.add('Delivered');
      }
    } else {
      if (canRetailerTransition(order.status, 'Cancelled')) {
        actions.add('Cancelled');
      }
      if (canRetailerTransition(order.status, 'Delivered')) {
        actions.add('Delivered');
      }
    }

    if (actions.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(status: order.status),
      );
    }

    return Wrap(
      spacing: isCompact ? 8 : 10,
      runSpacing: isCompact ? 8 : 10,
      children: actions.map((status) {
        final destructive = status == 'Rejected' || status == 'Cancelled';
        return SizedBox(
          height: isCompact ? 42 : 46,
          child: FilledButton.icon(
            onPressed: loading ? null : () => onStatusSelected(status),
            style: FilledButton.styleFrom(
              backgroundColor: destructive
                  ? statusColor(status)
                  : AppColors.primaryRoyalBlue,
              minimumSize: Size(isCompact ? 100 : 120, isCompact ? 42 : 46),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_actionIcon(status), size: isCompact ? 16 : 18),
            label: Text(
              _actionLabel(status),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 12 : 13.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

IconData _actionIcon(String status) {
  switch (status) {
    case 'Rejected':
    case 'Cancelled':
      return Icons.close_rounded;
    case 'Dispatched':
      return Icons.local_shipping_rounded;
    case 'Delivered':
      return Icons.verified_rounded;
    default:
      return Icons.check_rounded;
  }
}

String _actionLabel(String status) {
  if (status == 'Dispatched') {
    return 'Dispatch';
  }
  if (status == 'Cancelled') {
    return 'Cancel';
  }
  return status;
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER CARDS & BOXES
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE5E7EB),
        highlightColor: AppColors.surfaceWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: isCompact ? 120 : 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: AppColors.surfaceWhite,
      child: Container(color: AppColors.surfaceWhite),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY & ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────

class EmptyWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const EmptyWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => _StateWidget(
    icon: Icons.receipt_long_rounded,
    title: 'No Orders Found',
    message: 'Orders matching your view will appear here.',
    buttonLabel: 'Retry',
    onPressed: onRetry,
  );
}

class OrderErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const OrderErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => _StateWidget(
    icon: Icons.error_outline_rounded,
    title: 'Unable to Load Orders',
    message: message,
    buttonLabel: 'Retry',
    onPressed: onRetry,
    danger: true,
  );
}

class _StateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool danger;

  const _StateWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryRoyalBlue;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 28 : 40,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: isCompact ? 64 : 78,
            height: isCompact ? 64 : 78,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: color, size: isCompact ? 30 : 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: isCompact ? 18 : 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: isCompact ? 12.5 : 14,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
