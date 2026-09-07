// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../Stock Listing Module/Stock_Product_Name_List_Screen.dart';
import '../navigation/app_routes.dart';

export '../Product Module/AddProductFormScreen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHARED PREMIUM PAGE SHELL
// ══════════════════════════════════════════════════════════════════════════════

/// Internal reusable shell used by every placeholder drawer screen.
/// Provides: GlobalAppbar, GlobalDrawer, GlobalFooter, premium empty-state card.
class _PlaceholderPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final Color iconColor;
  final Color iconBg;
  final int drawerIndex;
  final List<_FeatureChip> chips;

  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.iconColor,
    required this.iconBg,
    required this.drawerIndex,
    required this.chips,
  });

  @override
  State<_PlaceholderPage> createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<_PlaceholderPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  int _footerIndex = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: GlobalAppbar(
        subtitle: widget.title,
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: GlobalDrawer(
        selectedIndex: widget.drawerIndex,
        onItemSelected: (_) {},
      ),
      bottomNavigationBar: GlobalFooter(
        currentIndex: _footerIndex,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
            return;
          }
          if (i == 1) {
            Navigator.of(context).pushNamed(AppRoutes.stockListing);
            return;
          }
          if (i == 2) {
            Navigator.of(context).pushNamed(AppRoutes.addProduct);
            return;
          }
          if (i == 3) {
            Navigator.of(context).pushNamed(AppRoutes.orderManagement);
            return;
          }
          setState(() => _footerIndex = i);
        },
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Page Header ───────────────────────────────────
                      _PageHeader(
                        icon: widget.heroIcon,
                        iconColor: widget.iconColor,
                        iconBg: widget.iconBg,
                        title: widget.title,
                        subtitle: widget.subtitle,
                      ),
                      const SizedBox(height: 28),

                      // ── Feature chips row ─────────────────────────────
                      if (widget.chips.isNotEmpty) ...[
                        _ChipsRow(chips: widget.chips),
                        const SizedBox(height: 28),
                      ],

                      // ── Coming-soon card ──────────────────────────────
                      _ComingSoonCard(
                        icon: widget.heroIcon,
                        iconColor: widget.iconColor,
                        title: widget.title,
                      ),
                      const SizedBox(height: 28),

                      // ── Divider with label ────────────────────────────
                      _SectionDivider(label: 'What to expect'),
                      const SizedBox(height: 20),

                      // ── Feature preview tiles ─────────────────────────
                      ...widget.chips.map((c) => _FeatureTile(chip: c)),
                      const SizedBox(height: 12),
                    ]),
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

// ── Page Header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _PageHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172554), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401E3A8A),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Chips Row ─────────────────────────────────────────────────────────

class _ChipsRow extends StatelessWidget {
  final List<_FeatureChip> chips;
  const _ChipsRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon, size: 14, color: AppColors.primaryRoyalBlue),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Coming Soon Card ──────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _ComingSoonCard({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.15),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 36),
          ),
          const SizedBox(height: 20),
          // Gold badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFB38F24)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40D4AF37),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'COMING SOON',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This module is under development.\nThe backend API will be connected once ready.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Info pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDAFE), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRoyalBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Architecture is API-ready for integration',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryRoyalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.borderLight],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accentGoldSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGold, width: 1),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.accentGoldDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.borderLight, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Feature Tile ──────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final _FeatureChip chip;
  const _FeatureTile({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(chip.icon, color: AppColors.primaryRoyalBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chip.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chip.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _FeatureChip {
  final IconData icon;
  final String label;
  final String description;
  const _FeatureChip(this.icon, this.label, this.description);
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. ADD PRODUCT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════════
// 2. STOCK LISTING SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class StockListingScreen extends StatelessWidget {
  const StockListingScreen({super.key});
  static const String routeName = '/stock_listing';

  @override
  Widget build(BuildContext context) {
    return const StockProductNameListScreen();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. RETAILERS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class RetailersScreen extends StatelessWidget {
  const RetailersScreen({super.key});
  static const String routeName = '/retailers';

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Retailers',
      subtitle: 'Manage all verified B2B retailer accounts.',
      heroIcon: Icons.storefront_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
      drawerIndex: 4,
      chips: [
        _FeatureChip(
          Icons.verified_rounded,
          'Verified Retailers',
          'View all approved and active retailer accounts.',
        ),
        _FeatureChip(
          Icons.block_rounded,
          'Suspend Account',
          'Temporarily suspend a retailer\'s portal access.',
        ),
        _FeatureChip(
          Icons.phone_rounded,
          'Contact Details',
          'Access shop address, mobile and email directly.',
        ),
        _FeatureChip(
          Icons.history_rounded,
          'Order History',
          'View complete order history per retailer.',
        ),
        _FeatureChip(
          Icons.star_rounded,
          'Performance',
          'Track retailer order value and frequency.',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. ORDER MANAGEMENT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});
  static const String routeName = '/order_management';

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Order Management',
      subtitle: 'Track, process and dispatch wholesale orders.',
      heroIcon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF0891B2),
      iconBg: Color(0xFFCFFAFE),
      drawerIndex: 5,
      chips: [
        _FeatureChip(
          Icons.pending_actions_rounded,
          'Pending Orders',
          'Review and confirm incoming retailer orders.',
        ),
        _FeatureChip(
          Icons.local_shipping_rounded,
          'Dispatch',
          'Mark orders as dispatched with courier details.',
        ),
        _FeatureChip(
          Icons.check_circle_rounded,
          'Delivered',
          'Confirm deliveries and update order status.',
        ),
        _FeatureChip(
          Icons.cancel_rounded,
          'Cancelled',
          'Handle order cancellations and refund requests.',
        ),
        _FeatureChip(
          Icons.bar_chart_rounded,
          'Order Analytics',
          'View order volume trends and revenue reports.',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. OFFERS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  static const String routeName = '/offers';

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Offers',
      subtitle: 'Create and manage promotional schemes for retailers.',
      heroIcon: Icons.local_offer_rounded,
      iconColor: Color(0xFFDC2626),
      iconBg: Color(0xFFFEE2E2),
      drawerIndex: 6,
      chips: [
        _FeatureChip(
          Icons.discount_rounded,
          'Discount Codes',
          'Generate percentage or flat discount coupons.',
        ),
        _FeatureChip(
          Icons.calendar_today_rounded,
          'Seasonal Offers',
          'Schedule time-bound festive and seasonal deals.',
        ),
        _FeatureChip(
          Icons.people_rounded,
          'Retailer-Specific',
          'Apply exclusive offers to select retailer tiers.',
        ),
        _FeatureChip(
          Icons.notifications_rounded,
          'Push Notify',
          'Send offer notifications directly to retailers.',
        ),
        _FeatureChip(
          Icons.analytics_rounded,
          'Offer Analytics',
          'Track redemption rates and offer performance.',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Profile',
      subtitle: 'Manage your BBS GOLD owner account and settings.',
      heroIcon: Icons.person_rounded,
      iconColor: Color(0xFF1E3A8A),
      iconBg: Color(0xFFDBEAFE),
      drawerIndex: 7,
      chips: [
        _FeatureChip(
          Icons.edit_rounded,
          'Edit Profile',
          'Update your name, mobile and business details.',
        ),
        _FeatureChip(
          Icons.lock_rounded,
          'Change Password',
          'Set a new secure password for your account.',
        ),
        _FeatureChip(
          Icons.business_rounded,
          'Business Info',
          'Manage your shop name, GST and address.',
        ),
        _FeatureChip(
          Icons.notifications_active_rounded,
          'Notification Settings',
          'Control which alerts you receive and when.',
        ),
        _FeatureChip(
          Icons.security_rounded,
          'Security & Privacy',
          'Two-factor authentication and session management.',
        ),
      ],
    );
  }
}
