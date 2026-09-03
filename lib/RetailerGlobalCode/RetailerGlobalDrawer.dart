// ignore_for_file: file_names

import 'dart:developer';

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../core/widgets/logout_dialog.dart';
import '../navigation/app_routes.dart';

class RetailerGlobalDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const RetailerGlobalDrawer({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  State<RetailerGlobalDrawer> createState() => _RetailerGlobalDrawerState();
}

class _RetailerGlobalDrawerState extends State<RetailerGlobalDrawer> {
  int? _pressedIndex;

  static const List<_RetailerDrawerItem> _items = [
    _RetailerDrawerItem(Icons.home_rounded, 'Home', 'Retailer dashboard'),
    _RetailerDrawerItem(
      Icons.diamond_rounded,
      'Product Catalogue',
      'Browse premium jewellery',
    ),
    _RetailerDrawerItem(Icons.favorite_rounded, 'Wishlist', 'Saved designs'),
    _RetailerDrawerItem(
      Icons.receipt_long_rounded,
      'Order Management',
      'Track wholesale orders',
    ),
    _RetailerDrawerItem(
      Icons.support_agent_rounded,
      'Contact',
      'BBS support desk',
    ),
    _RetailerDrawerItem(
      Icons.local_offer_rounded,
      'Offers',
      'Latest campaigns',
    ),
    _RetailerDrawerItem(Icons.person_rounded, 'Profile', 'Account details'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = UserData.instance;
    final retailerName = user.name.trim().isEmpty
        ? 'Verified Retailer'
        : user.name.trim();

    return Drawer(
      width: _drawerWidth(context),
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
        child: Stack(
          children: [
            const Positioned.fill(child: _RetailerDrawerBackground()),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  _RetailerDrawerHeader(retailerName: retailerName),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final selected = widget.selectedIndex == index;
                        final pressed = _pressedIndex == index;
                        return _RetailerDrawerTile(
                          item: item,
                          isSelected: selected,
                          isPressed: pressed,
                          onTapDown: () => setState(() {
                            _pressedIndex = index;
                          }),
                          onTapCancel: () => setState(() {
                            _pressedIndex = null;
                          }),
                          onTap: () => _handleTap(context, index, item.title),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                    child: _RetailerLogoutTile(
                      onTap: () {
                        Navigator.of(context).pop();
                        LogoutDialog.show(context);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'BBS GOLD - Retailer Portal',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _drawerWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 380;
    if (width >= 600) return (width * 0.52).clamp(320.0, 420.0);
    if (width < 360) return width * 0.88;
    return width * 0.84;
  }

  void _handleTap(BuildContext context, int index, String title) {
    setState(() => _pressedIndex = null);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    widget.onItemSelected?.call(index);

    switch (title) {
      case 'Home':
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 'Product Catalogue':
        Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
        break;
      case 'Wishlist':
        Navigator.of(context).pushNamed(AppRoutes.retailerWishlist);
        break;
      case 'Order Management':
        Navigator.of(context).pushNamed(AppRoutes.orderManagement);
        break;
      case 'Offers':
        Navigator.of(context).pushNamed(AppRoutes.offers);
        break;
      case 'Contact':
        Navigator.of(context).pushNamed(AppRoutes.retailerContact);
        break;
      case 'Profile':
        Navigator.of(context).pushNamed(AppRoutes.profile);
        break;
      default:
        _showPlaceholder(messenger, title);
    }
  }

  void _showPlaceholder(ScaffoldMessengerState messenger, String title) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title screen will be connected soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryRoyalBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _RetailerDrawerHeader extends StatelessWidget {
  final String retailerName;

  const _RetailerDrawerHeader({required this.retailerName});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.paddingOf(context).top + 22,
          22,
          24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1E4A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _LinePainter())),
            const Positioned(right: -42, top: -46, child: _GoldRing(size: 160)),
            const Positioned(
              left: -64,
              bottom: -72,
              child: _GoldRing(size: 190),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderGold),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppConstants.logoAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.accentGold,
                              size: 34,
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.surfaceWhite,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.profile);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFB38F24),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                retailerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RetailerDrawerTile extends StatelessWidget {
  final _RetailerDrawerItem item;
  final bool isSelected;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;

  const _RetailerDrawerTile({
    required this.item,
    required this.isSelected,
    required this.isPressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: isPressed ? 0.98 : 1,
      child: Material(
        color: isSelected ? AppColors.primaryLightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            log(
              'RetailerDrawerTile initialized: ${UserData.instance.email}, ${UserData.instance.userId}, ${UserData.instance.id}',
            );
            onTap();
          },
          onTapDown: (_) => onTapDown(),
          onTapCancel: onTapCancel,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.borderGold : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryRoyalBlue
                        : AppColors.primaryLightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? AppColors.accentGold
                        : AppColors.primaryRoyalBlue,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected
                      ? AppColors.accentGold
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetailerLogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _RetailerLogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Logout',
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFFBE123C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE11D48)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetailerDrawerBackground extends StatelessWidget {
  const _RetailerDrawerBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(right: -70, top: 230, child: _GoldRing(size: 170)),
        Positioned(left: -86, bottom: 150, child: _GoldRing(size: 190)),
      ],
    );
  }
}

class _GoldRing extends StatelessWidget {
  final double size;

  const _GoldRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.13),
          width: 1.2,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (double y = 20; y < size.height; y += 18) {
      canvas.drawLine(
        Offset(size.width * 0.42, y),
        Offset(size.width, y - 32),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => false;
}

class _RetailerDrawerItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RetailerDrawerItem(this.icon, this.title, this.subtitle);
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+')).where((word) {
    return word.isNotEmpty;
  });
  final letters = words.take(2).map((word) => word.substring(0, 1)).join();
  return letters.isEmpty ? 'BG' : letters.toUpperCase();
}
