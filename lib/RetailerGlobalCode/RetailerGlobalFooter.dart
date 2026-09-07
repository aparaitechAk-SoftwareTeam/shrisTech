// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class RetailerGlobalFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RetailerGlobalFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_RetailerFooterItem> _items = [
    _RetailerFooterItem(Icons.home_rounded, 'Home', 'Home'),
    _RetailerFooterItem(Icons.diamond_rounded, 'Catalogue', 'Product Catalogue'),
    _RetailerFooterItem(Icons.local_offer_rounded, 'Offers', 'Offers'),
    _RetailerFooterItem(Icons.receipt_long_rounded, 'Orders', 'Orders'),
    _RetailerFooterItem(Icons.shopping_cart_rounded, 'Cart', 'Cart'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 8 : 16,
              6,
              isCompact ? 8 : 16,
              bottomPadding > 0 ? 6 : 12,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryRoyalBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowPrimaryGlow,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = currentIndex == index;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.surfaceWhite.withValues(alpha: 0.13)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentGold.withValues(alpha: 0.45)
                              : Colors.transparent,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTap(index),
                          borderRadius: BorderRadius.circular(18),
                          child: Semantics(
                            button: true,
                            selected: selected,
                            label: item.fullLabel,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: isCompact ? 6 : 8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 220),
                                    scale: selected ? 1.06 : 1,
                                    child: Icon(
                                      item.icon,
                                      color: selected
                                          ? AppColors.accentGold
                                          : AppColors.surfaceWhite,
                                      size: isCompact ? 19 : 22,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      screenWidth >= 600
                                          ? item.fullLabel
                                          : item.shortLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.caption.copyWith(
                                        color: selected
                                            ? AppColors.accentGold
                                            : AppColors.surfaceWhite,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: isCompact ? 9 : 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetailerFooterItem {
  final IconData icon;
  final String shortLabel;
  final String fullLabel;

  const _RetailerFooterItem(this.icon, this.shortLabel, this.fullLabel);
}
