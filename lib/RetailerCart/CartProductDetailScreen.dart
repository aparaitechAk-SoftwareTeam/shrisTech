// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../RetailerCatalogue/RetailerProductDetailScreen.dart';
import '../RetailerWishlist/WishlistWidgets.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../screens/home/owner_home_screen.dart';
import 'CartApis.dart';

class CartProductDetailScreen extends StatefulWidget {
  final CartItemModel item;

  const CartProductDetailScreen({super.key, required this.item});

  @override
  State<CartProductDetailScreen> createState() =>
      _CartProductDetailScreenState();
}

class _CartProductDetailScreenState extends State<CartProductDetailScreen> {
  final ICartRepository _repository = CartRepository();

  late CartItemModel _item;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    if (UserData.instance.role.trim().toLowerCase() == 'owner') {
      return const OwnerHomeScreen();
    }
    return RetailerProductDetailScreen(
      product: _item.product,
      showWishlistButton: false,
      bottomNavigationBar: _CartDetailActionBar(
        quantity: _item.quantity,
        busy: _busy,
        onDecrease: () => _updateQuantity(_item.quantity - 1),
        onIncrease: () => _updateQuantity(_item.quantity + 1),
        onRemove: _remove,
        onOrder: _order,
      ),
    );
  }

  Future<void> _updateQuantity(int quantity) async {
    if (_busy || quantity < 1) return;
    final previous = _item;
    setState(() {
      _busy = true;
      _item = _item.copyWith(quantity: quantity);
    });
    try {
      await _repository.updateQuantity(
        cartItemId: _item.cartItemId,
        quantity: quantity,
      );
      if (!mounted) return;
      _snack('Quantity updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _item = previous);
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.removeItem(_item.cartItemId);
      if (!mounted) return;
      Navigator.of(context).pop<CartItemModel?>(null);
    } catch (error) {
      if (!mounted) return;
      _snack(_errorText(error), success: false);
      setState(() => _busy = false);
    }
  }

  Future<void> _order() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.placeOrder(
        retailerId: _retailerId,
        productId: _item.productId,
        variantId: _item.variantId,
        quantity: _item.quantity,
      );
      if (!mounted) return;
      _snack('Order placed successfully.');
    } catch (error) {
      if (!mounted) return;
      _snack(_errorText(error), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _retailerId {
    final user = UserData.instance;
    return user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
  }

  void _snack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Colors.redAccent,
      ),
    );
  }

  String _errorText(Object error) {
    return error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';
  }
}

class _CartDetailActionBar extends StatelessWidget {
  final int quantity;
  final bool busy;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final VoidCallback onOrder;

  const _CartDetailActionBar({
    required this.quantity,
    required this.busy,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final btnHeight = isCompact ? 42.0 : 48.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 16,
          isCompact ? 8 : 10,
          isCompact ? 12 : 16,
          bottom > 0 ? bottom : (isCompact ? 10 : 16),
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
            QuantityStepper(
              quantity: quantity,
              busy: busy,
              onDecrease: onDecrease,
              onIncrease: onIncrease,
            ),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(
              child: SizedBox(
                height: btnHeight,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: isCompact ? 16 : 18,
                  ),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0x44FF5252), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isCompact ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(
              child: SizedBox(
                height: btnHeight,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onOrder,
                  icon: Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.accentGold,
                    size: isCompact ? 16 : 18,
                  ),
                  label: Text(
                    'Order Now',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRoyalBlue,
                    foregroundColor: AppColors.surfaceWhite,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isCompact ? 12 : 14,
                      ),
                    ),
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
