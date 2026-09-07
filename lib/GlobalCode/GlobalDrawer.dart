// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../ApprovalRequest/approval_request_screen.dart';
import '../OffersModule/OfferListScreen.dart';
import '../OwnerProfile/OwnerProfileScreen.dart';
import '../Order Management Module/OrderListScreen.dart';
import '../Order Management Module/RetailerOrderListScreen.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../core/widgets/logout_dialog.dart';
import '../navigation/app_routes.dart';
import '../OwnerOrderHistory/OwnerOrderHistoryScreen.dart';
import 'DrawerScreens.dart';

class GlobalDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const GlobalDrawer({super.key, this.selectedIndex = 0, this.onItemSelected});

  @override
  State<GlobalDrawer> createState() => _GlobalDrawerState();
}

class _GlobalDrawerState extends State<GlobalDrawer> {
  int? _pressedIndex;

  static const List<_DrawerMenuItem> _items = [
    _DrawerMenuItem(Icons.home_rounded, 'Home', 'Back to owner dashboard'),
    _DrawerMenuItem(
      Icons.approval_rounded,
      'Approval Requests',
      'Review pending retailer requests',
    ),
    _DrawerMenuItem(
      Icons.add_box_rounded,
      'Add Product',
      'Add new jewellery to inventory',
    ),
    _DrawerMenuItem(
      Icons.inventory_2_rounded,
      'Stock Listing',
      'View and manage stock items',
    ),
    // _DrawerMenuItem(
    //   Icons.storefront_rounded,
    //   'Retailers',
    //   'Manage registered retailers',
    // ),
    _DrawerMenuItem(
      Icons.receipt_long_rounded,
      'Order Management',
      'Track and process orders',
    ),
    _DrawerMenuItem(
      Icons.history_rounded,
      'Order History',
      'View complete order history',
    ),
    _DrawerMenuItem(
      Icons.local_offer_rounded,
      'Offers',
      'Create and manage promotions',
    ),
    _DrawerMenuItem(
      Icons.person_rounded,
      'Profile',
      'Manage your account details',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = UserData.instance;
    final ownerName = user.name.trim().isEmpty ? 'Owner' : user.name.trim();
    final email = user.email.trim().isEmpty ? 'owner@bbsgold.com' : user.email;

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
            const Positioned.fill(child: _DrawerBackgroundPattern()),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  _DrawerTopPanel(ownerName: ownerName, email: email),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isSelected = widget.selectedIndex == index;
                        final isPressed = _pressedIndex == index;

                        return _DrawerTile(
                          item: item,
                          isSelected: isSelected,
                          isPressed: isPressed,
                          onTapDown: () => setState(() {
                            _pressedIndex = index;
                          }),
                          onTapCancel: () => setState(() {
                            _pressedIndex = null;
                          }),
                          onTap: () => _handleMenuTap(context, index, item),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                    child: _LogoutTile(
                      onTap: () {
                        Navigator.of(context).pop();
                        LogoutDialog.show(context);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'BBS GOLD - v1.0.0',
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
    return width * 0.82;
  }

  void _handleMenuTap(BuildContext context, int index, _DrawerMenuItem item) {
    setState(() => _pressedIndex = null);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(); // always close drawer first
    final isOwner = UserData.instance.role.trim().toLowerCase() == 'owner';

    switch (item.title) {
      case 'Home':
        Navigator.of(context).pushNamedAndRemoveUntil(
          isOwner ? AppRoutes.ownerHome : AppRoutes.retailerHome,
          (route) => false,
        );

      case 'Approval Requests':
        if (!isOwner) {
          _showRolePlaceholder(messenger, item.title);
          return;
        }
        _pushDrawerRoute(
          context,
          routeName: ApprovalRequestScreen.routeName,
          screen: const ApprovalRequestScreen(),
        );

      case 'Add Product':
        if (!isOwner) {
          _showRolePlaceholder(messenger, item.title);
          return;
        }
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.addProduct,
          screen: const AddProductScreen(),
        );

      case 'Stock Listing':
        if (!isOwner) {
          _showRolePlaceholder(messenger, 'Product Catalogue');
          return;
        }
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.stockListing,
          screen: const StockListingScreen(),
        );

      case 'Retailers':
        if (!isOwner) {
          _showRolePlaceholder(messenger, item.title);
          return;
        }
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.retailers,
          screen: const RetailersScreen(),
        );

      case 'Order Management':
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.orderManagement,
          screen: isOwner
              ? const OrderListScreen()
              : const RetailerOrderListScreen(),
        );

      case 'Order History':
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.orderHistory,
          screen: const OwnerOrderHistoryScreen(),
        );

      case 'Offers':
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.offers,
          screen: const OfferListScreen(),
        );

      case 'Profile':
        if (!isOwner) {
          _showRolePlaceholder(messenger, item.title);
          return;
        }
        _pushDrawerRoute(
          context,
          routeName: AppRoutes.profile,
          screen: const OwnerProfileScreen(),
        );

      default:
        widget.onItemSelected?.call(index);
    }
  }

  void _showRolePlaceholder(ScaffoldMessengerState messenger, String title) {
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

  /// Pushes a screen with a premium fade+slide transition.
  /// Skips navigation if the route is already active.
  void _pushDrawerRoute(
    BuildContext context, {
    required String routeName,
    required Widget screen,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == routeName) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _DrawerTopPanel extends StatelessWidget {
  final String ownerName;
  final String email;

  const _DrawerTopPanel({required this.ownerName, required this.email});

  @override
  Widget build(BuildContext context) {
    // ClipRRect at the OUTERMOST level so the painter is clipped to the card
    return ClipRRect(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.of(context).padding.top + 22,
          22,
          22,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1E4A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPrimaryGlow,
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        // Stack with Clip.none: painter extends to corners, outer ClipRRect clips it
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Full-panel concentric ring pattern ──────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _HeaderPatternPainter()),
            ),
            // ── Actual content, always on top ───────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Logo + App Name + Badge
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.borderGold,
                          width: 1.5,
                        ),
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
                        filterQuality: FilterQuality.high,
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
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Gold badge pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFB38F24)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55D4AF37),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              ownerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Owner',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _DrawerMenuItem item;
  final bool isSelected;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;

  const _DrawerTile({
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
          onTap: onTap,
          onTapDown: (_) => onTapDown(),
          onTapCancel: onTapCancel,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.borderGold : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 38,
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
                      // const SizedBox(height: 3),
                      // Text(
                      //   item.subtitle,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: AppTypography.caption.copyWith(
                      //     color: AppColors.textMuted,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected
                      ? AppColors.accentGold
                      : AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFFBE123C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sign out of your account',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFFE11D48),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

class _DrawerBackgroundPattern extends StatelessWidget {
  const _DrawerBackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          right: -70,
          top: 210,
          child: _GoldRing(size: 170, alpha: 0.13),
        ),
        Positioned(
          left: -85,
          bottom: 130,
          child: _GoldRing(size: 190, alpha: 0.10),
        ),
        Positioned(
          right: 34,
          bottom: 42,
          child: _GoldRing(size: 78, alpha: 0.10),
        ),
      ],
    );
  }
}

class _GoldRing extends StatelessWidget {
  final double size;
  final double alpha;

  const _GoldRing({required this.size, this.alpha = 0.24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: alpha),
          width: 1.3,
        ),
      ),
    );
  }
}

// ── Header Pattern Painter ──────────────────────────────────────────────────
/// Draws concentric rings anchored at the card's top-right and bottom-left
/// corners with radii large enough to sweep across the entire panel area.
/// Always used inside a ClipRRect so rings are properly bounded.
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gold ring paint
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // White ring paint
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // ── Top-right corner rings ──────────────────────────────────────────────
    // Anchor exactly at the top-right corner of the card
    final topRight = Offset(size.width, 0);
    const trRadii = [60.0, 110.0, 160.0, 210.0, 265.0, 320.0, 380.0, 440.0];
    for (int i = 0; i < trRadii.length; i++) {
      final t = i / trRadii.length;
      final isGold = i % 2 == 0;
      final alpha = (isGold ? 0.22 : 0.10) * (1.0 - t * 0.55);
      if (alpha <= 0.01) continue;
      if (isGold) {
        gold.color = const Color(0xFFD4AF37).withValues(alpha: alpha);
        canvas.drawCircle(topRight, trRadii[i], gold);
      } else {
        white.color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
        canvas.drawCircle(topRight, trRadii[i], white);
      }
    }

    // ── Bottom-left corner rings ────────────────────────────────────────────
    // Anchor exactly at the bottom-left corner of the card
    final bottomLeft = Offset(0, size.height);
    const blRadii = [50.0, 95.0, 145.0, 198.0, 255.0, 315.0, 375.0];
    for (int i = 0; i < blRadii.length; i++) {
      final t = i / blRadii.length;
      final isGold = i % 2 == 0;
      final alpha = (isGold ? 0.18 : 0.08) * (1.0 - t * 0.55);
      if (alpha <= 0.01) continue;
      if (isGold) {
        gold.color = const Color(0xFFD4AF37).withValues(alpha: alpha);
        canvas.drawCircle(bottomLeft, blRadii[i], gold);
      } else {
        white.color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
        canvas.drawCircle(bottomLeft, blRadii[i], white);
      }
    }

    // ── Subtle center-right horizontal arc accent ───────────────────────────
    final midRight = Offset(size.width * 0.85, size.height * 0.5);
    for (int i = 0; i < 3; i++) {
      final radius = 55.0 + (i * 30.0);
      white.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: 0.06 - (i * 0.015));
      canvas.drawCircle(midRight, radius, white);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderPatternPainter oldDelegate) => false;
}

class _DrawerMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DrawerMenuItem(this.icon, this.title, this.subtitle);
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+')).where((word) {
    return word.isNotEmpty;
  });
  final letters = words.take(2).map((word) => word.substring(0, 1)).join();
  return letters.isEmpty ? 'BG' : letters.toUpperCase();
}
