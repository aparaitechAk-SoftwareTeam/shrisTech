// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'OwnerOrderHistoryApis.dart';

/// Top Premium Search Bar Widget with Filter Toggle Button
class OrderHistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isFilterExpanded;
  final bool hasActiveFilters;
  final VoidCallback onToggleFilter;

  const OrderHistorySearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.isFilterExpanded,
    required this.hasActiveFilters,
    required this.onToggleFilter,
  });

  @override
  Widget build(BuildContext context) {
    final showClear = controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
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
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryRoyalBlue,
                  size: 22,
                ),
                suffixIcon: showClear
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: onClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleFilter,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isFilterExpanded
                    ? AppColors.primaryRoyalBlue
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFilterExpanded
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
                    isFilterExpanded
                        ? Icons.tune_rounded
                        : Icons.filter_list_rounded,
                    color: isFilterExpanded
                        ? AppColors.surfaceWhite
                        : AppColors.accentGoldDark,
                    size: 24,
                  ),
                  if (hasActiveFilters && !isFilterExpanded)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 9,
                        height: 9,
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

/// Smooth Animated Expandable Filter Panel
class ExpandableFilterPanel extends StatelessWidget {
  final bool isExpanded;
  final String selectedStatus;
  final String selectedSort;
  final String shopNameQuery;
  final String productNameQuery;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onShopNameChanged;
  final ValueChanged<String> onProductNameChanged;
  final VoidCallback onClearAllFilters;

  const ExpandableFilterPanel({
    super.key,
    required this.isExpanded,
    required this.selectedStatus,
    required this.selectedSort,
    required this.shopNameQuery,
    required this.productNameQuery,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onShopNameChanged,
    required this.onProductNameChanged,
    required this.onClearAllFilters,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'All',
      'Pending',
      'Accepted',
      'Dispatched',
      'Delivered',
      'Rejected',
    ];
    final sortOptions = ['Newest First', 'Oldest First'];

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: isExpanded
          ? Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.borderGold.withValues(alpha: 0.8),
                ),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primaryRoyalBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Refine History Filters',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onClearAllFilters,
                        child: Text(
                          'Reset All',
                          style: AppTypography.caption.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Chips
                  Text(
                    'Order Status',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((st) {
                      final isSelected = selectedStatus == st;
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        onSelected: (_) => onStatusChanged(st),
                        selectedColor: AppColors.primaryRoyalBlue,
                        backgroundColor: AppColors.backgroundOffWhite,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryRoyalBlue
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sort Options
                  Text(
                    'Sort Chronology',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: sortOptions.map((so) {
                      final isSelected = selectedSort == so;
                      return ChoiceChip(
                        label: Text(so),
                        selected: isSelected,
                        onSelected: (_) => onSortChanged(so),
                        selectedColor: AppColors.accentGold,
                        backgroundColor: AppColors.backgroundOffWhite,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.primaryDarkBlue
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Order Summary Statistic Cards Widget
class OrderHistorySummaryHeader extends StatelessWidget {
  final OwnerHistorySummaryModel summary;

  const OrderHistorySummaryHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isNarrow ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isNarrow ? 1.55 : 1.45,
            children: [
              _StatTile(
                title: 'Total Orders',
                count: '${summary.totalOrders}',
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primaryRoyalBlue,
              ),
              _StatTile(
                title: 'Pending',
                count: '${summary.pendingCount}',
                icon: Icons.hourglass_top_rounded,
                iconColor: const Color(0xFFEAB308),
              ),
              _StatTile(
                title: 'Accepted',
                count: '${summary.acceptedCount}',
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF16A34A),
              ),
              _StatTile(
                title: 'Delivered',
                count: '${summary.deliveredCount}',
                icon: Icons.local_shipping_rounded,
                iconColor: AppColors.accentGoldDark,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Luxury Owner Order History Card
class OwnerHistoryOrderCard extends StatelessWidget {
  final OwnerHistoryOrderModel order;
  final VoidCallback onTap;

  const OwnerHistoryOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstImage = order.items.isNotEmpty ? order.items.first.image : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final imgSize = isCompact ? 54.0 : 62.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                child: Stack(
                  children: [
                    // Decorative Gold Line & Pattern Accent
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentGold.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isCompact ? 14 : 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Order No + Shop Name & Status Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First Product Image Preview
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 12 : 16,
                                ),
                                child: SizedBox(
                                  width: imgSize,
                                  height: imgSize,
                                  child: firstImage.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: firstImage,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color:
                                                    AppColors.primaryLightBlue,
                                                child: const Icon(
                                                  Icons.diamond_rounded,
                                                  color: AppColors.accentGold,
                                                  size: 24,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color:
                                                    AppColors.primaryLightBlue,
                                                child: const Icon(
                                                  Icons.diamond_rounded,
                                                  color: AppColors.accentGold,
                                                  size: 24,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: AppColors.primaryLightBlue,
                                          child: Icon(
                                            Icons.diamond_rounded,
                                            color: AppColors.accentGold,
                                            size: isCompact ? 24 : 28,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '#${order.orderNumber}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  color: AppColors
                                                      .primaryRoyalBlue,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: isCompact ? 14 : 16,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 8 : 10,
                                            vertical: isCompact ? 3 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: order.statusColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color:
                                                  order.statusColor.withValues(
                                                    alpha: 0.4,
                                                  ),
                                            ),
                                          ),
                                          child: Text(
                                            order.status,
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: order.statusColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize:
                                                      isCompact ? 10 : 11,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      order.shopName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: isCompact ? 13 : 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Owner: ${order.ownerName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: isCompact ? 10.5 : 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 12 : 16),

                          // Gold Divider Accent
                          Container(
                            height: 1,
                            color: AppColors.borderGold.withValues(alpha: 0.35),
                          ),
                          SizedBox(height: isCompact ? 10 : 14),

                          // Order Status Progress Tracker Bar
                          OrderStatusProgressTracker(status: order.status),
                          SizedBox(height: isCompact ? 12 : 16),

                          // Quantities & Net Gold Weight Metrics Row
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MetricChip(
                                    label: 'SKUs',
                                    value: '${order.items.length}',
                                    icon: Icons.category_rounded,
                                  ),
                                  const SizedBox(width: 6),
                                  _MetricChip(
                                    label: 'Total Qty',
                                    value: '${order.totalQuantity}',
                                    icon: Icons.numbers_rounded,
                                  ),
                                ],
                              ),
                              Text(
                                'Net: ${order.totalNetWeight.toStringAsFixed(2)} g',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.primaryRoyalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 12.5 : 14,
                                ),
                              ),
                            ],
                          ),

                          if (order.remarks.trim().isNotEmpty) ...[
                            SizedBox(height: isCompact ? 8 : 10),
                            Text(
                              'Remarks: ${order.remarks}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                                fontSize: isCompact ? 10.5 : 11,
                              ),
                            ),
                          ],
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryRoyalBlue, size: 13),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryRoyalBlue,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order Status Progress Tracker Widget
class OrderStatusProgressTracker extends StatelessWidget {
  final String status;

  const OrderStatusProgressTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    final isRejected = s == 'rejected' || s == 'cancelled';

    if (isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              'Order Rejected / Cancelled',
              style: AppTypography.caption.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    int stepIndex = 0;
    if (s == 'accepted' || s == 'processing') stepIndex = 1;
    if (s == 'dispatched' || s == 'shipped') stepIndex = 2;
    if (s == 'delivered') stepIndex = 3;

    final steps = ['Pending', 'Accepted', 'Dispatched', 'Delivered'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= stepIndex;
        final isCurrent = index == stepIndex;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (isCurrent
                                  ? AppColors.accentGold
                                  : AppColors.primaryRoyalBlue)
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isCompleted
                            ? AppColors.primaryRoyalBlue
                            : AppColors.textMuted,
                        fontWeight: isCurrent
                            ? FontWeight.w900
                            : FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

/// Sticky Date Grouping Header Delegate
class StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  StickyDateHeaderDelegate({required this.title});

  @override
  double get minExtent => 44.0;

  @override
  double get maxExtent => 44.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 44,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryRoyalBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            color: AppColors.borderGold.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyDateHeaderDelegate oldDelegate) {
    return title != oldDelegate.title;
  }
}

/// Skeleton Shimmer Loading Placeholder Card for Owner Order History
class OwnerHistoryShimmerCard extends StatelessWidget {
  const OwnerHistoryShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        period: const Duration(milliseconds: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Row: Thumbnail + Order Title & Badge Skeleton
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 90,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 70,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Metrics Grid Pills Skeleton
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 38,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Progress Lifecycle Bar Skeleton
            Container(
              height: 10,
              width: double.infinity,
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

/// Luxury Empty State
class OwnerHistoryEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const OwnerHistoryEmptyState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryLightBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGold),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: AppColors.primaryRoyalBlue,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Order History Found',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No retailer orders match your search or filter criteria.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRoyalBlue,
                foregroundColor: AppColors.surfaceWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Orders'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Luxury Error State
class OwnerHistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OwnerHistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRoyalBlue,
                foregroundColor: AppColors.surfaceWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
