import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'approved_retailer_apis.dart';

class ApprovedRetailerDetailsScreen extends StatelessWidget {
  final RetailerDetailsData retailer;

  const ApprovedRetailerDetailsScreen({super.key, required this.retailer});

  @override
  Widget build(BuildContext context) {
    final displayName = retailer.ownerName.isEmpty
        ? 'Retailer'
        : retailer.ownerName;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRoyalBlue,
        surfaceTintColor: AppColors.primaryRoyalBlue,
        foregroundColor: AppColors.surfaceWhite,
        centerTitle: true,
        title: Text(
          'Retailer Details',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.accentGold),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 700;
            final horizontalPadding = isTablet ? 40.0 : (isCompact ? 12.0 : 18.0);
            final maxWidth = screenWidth >= 900 ? 760.0 : screenWidth;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 16 : 24,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        name: displayName,
                        businessName: retailer.businessName,
                        status: retailer.accountStatus.isEmpty
                            ? retailer.status
                            : retailer.accountStatus,
                      ),
                      SizedBox(height: isCompact ? 16 : 20),
                      _DetailsCard(
                        children: [
                          _DetailRow(
                            icon: Icons.person_rounded,
                            label: 'Owner Name',
                            value: retailer.ownerName,
                          ),
                          _DetailRow(
                            icon: Icons.storefront_rounded,
                            label: 'Business Name',
                            value: retailer.businessName,
                          ),
                          _DetailRow(
                            icon: Icons.badge_rounded,
                            label: 'User ID',
                            value: retailer.userId,
                          ),
                          _DetailRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: retailer.email,
                          ),
                          _DetailRow(
                            icon: Icons.phone_rounded,
                            label: 'Mobile',
                            value: retailer.mobileNumber,
                          ),
                          _DetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'Address',
                            value: retailer.address,
                            multiLine: true,
                          ),
                          _DetailRow(
                            icon: Icons.verified_rounded,
                            label: 'Status',
                            value: retailer.status,
                          ),
                          _DetailRow(
                            icon: Icons.assignment_turned_in_rounded,
                            label: 'Registration Status',
                            value: retailer.registrationStatus,
                          ),
                          _DetailRow(
                            icon: Icons.admin_panel_settings_rounded,
                            label: 'Account Status',
                            value: retailer.accountStatus,
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String businessName;
  final String status;

  const _ProfileHeader({
    required this.name,
    required this.businessName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final avatarRadius = isCompact ? 28.0 : (isTablet ? 38.0 : 32.0);
    final cardPadding = isCompact ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryRoyalBlue,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimaryGlow,
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppColors.bg,
            child: Text(
              _initials(name),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
                fontSize: isCompact ? 15 : 18,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 17 : 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessName.isEmpty
                      ? 'Business details unavailable'
                      : businessName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                    fontSize: isCompact ? 12.5 : 13.5,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                _StatusBadge(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final bool multiLine;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final labelWidth = isCompact ? 104.0 : (isTablet ? 150.0 : 124.0);
    final iconBoxSize = isCompact ? 36.0 : 40.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isCompact ? 10 : 14)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: multiLine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryRoyalBlue,
                  size: isCompact ? 18 : 20,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 12),
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11.5 : 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'N/A' : value,
                  maxLines: multiLine ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 12.5 : 13.5,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 10 : 14),
              child: const Divider(height: 1, color: AppColors.borderSubtle),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active';
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 9 : 12,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.accentGoldSubtle : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Text(
        status.trim().isEmpty ? 'N/A' : status,
        style: AppTypography.caption.copyWith(
          color: active ? AppColors.accentGoldDark : AppColors.primaryRoyalBlue,
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 10.5 : 11.5,
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  final letters = parts.take(2).map((e) => e.substring(0, 1)).join();
  return letters.isEmpty ? 'BG' : letters.toUpperCase();
}
