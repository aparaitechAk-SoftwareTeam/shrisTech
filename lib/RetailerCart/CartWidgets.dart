// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../RetailerWishlist/WishlistWidgets.dart';
import '../core/theme/app_colors.dart';

class CartCardActions extends StatelessWidget {
  final int quantity;
  final bool busy;
  final bool isCompact;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final VoidCallback onOrder;

  const CartCardActions({
    super.key,
    required this.quantity,
    required this.busy,
    this.isCompact = false,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;
        final btnHeight = isCompact ? 40.0 : 44.0;
        final fontSize = isCompact ? 12.0 : 13.5;
        final iconSize = isCompact ? 16.0 : 18.0;

        final stepper = QuantityStepper(
          quantity: quantity,
          busy: busy,
          onDecrease: onDecrease,
          onIncrease: onIncrease,
        );

        final buttons = Row(
          children: [
            Expanded(
              child: SizedBox(
                height: btnHeight,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onRemove,
                  icon: Icon(Icons.delete_outline_rounded, size: iconSize),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0x44FF5252), width: 1),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Expanded(
              child: SizedBox(
                height: btnHeight,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onOrder,
                  icon: Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.accentGold,
                    size: iconSize,
                  ),
                  label: Text(
                    'Order',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRoyalBlue,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: stepper),
              SizedBox(height: isCompact ? 8 : 10),
              buttons,
            ],
          );
        }

        return Row(
          children: [
            stepper,
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(child: buttons),
          ],
        );
      },
    );
  }
}
