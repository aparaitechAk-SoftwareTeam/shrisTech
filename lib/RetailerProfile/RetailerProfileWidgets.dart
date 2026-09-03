// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'RetailerProfileApis.dart';

/// Luxury Profile Header Card widget with gradient, decorative circles,
/// gold borders, user avatar, name, badges, and top-right Edit button.
class ProfileHeaderCard extends StatelessWidget {
  final RetailerProfileModel profile;
  final bool isEditing;
  final bool isCompact;
  final VoidCallback onEditToggle;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.isEditing,
    this.isCompact = false,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : 'Retailer';
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'R';

    final avatarSize = isCompact ? 54.0 : 66.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryRoyalBlue,
        borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimaryGlow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Circle 1
          Positioned(
            right: -24,
            top: -26,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
            ),
          ),
          // Background Decorative Circle 2
          Positioned(
            left: -35,
            bottom: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(isCompact ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Edit Toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hero Avatar Container
                    Hero(
                      tag: 'retailer_profile_avatar',
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceWhite,
                          border: Border.all(
                            color: AppColors.accentGold,
                            width: 2.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.accentGoldGlow,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.primaryRoyalBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: isCompact ? 18 : 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isCompact ? 12 : 16),
                    // Name & Details
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
                              fontSize: isCompact ? 16.5 : 19,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.userId.isNotEmpty
                                ? 'ID: ${profile.userId}'
                                : (profile.id.isNotEmpty
                                      ? 'ID: ${profile.id}'
                                      : 'ID: N/A'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontSize: isCompact ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit Mode Button
                    Material(
                      color: isEditing
                          ? AppColors.accentGold
                          : AppColors.surfaceWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                      child: InkWell(
                        onTap: onEditToggle,
                        borderRadius: BorderRadius.circular(
                          isCompact ? 12 : 16,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isCompact ? 8 : 10),
                          child: Icon(
                            isEditing
                                ? Icons.close_rounded
                                : Icons.edit_rounded,
                            color: isEditing
                                ? AppColors.primaryRoyalBlue
                                : AppColors.accentGold,
                            size: isCompact ? 18 : 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 14 : 18),
                // Divider Line
                Container(
                  height: 1,
                  color: AppColors.accentGold.withValues(alpha: 0.25),
                ),
                SizedBox(height: isCompact ? 12 : 14),
                // Badges Row
                Wrap(
                  spacing: isCompact ? 8 : 10,
                  runSpacing: 6,
                  children: [
                    // Retailer Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 9 : 12,
                        vertical: isCompact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.accentGold,
                            size: isCompact ? 13 : 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            profile.role.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w800,
                              fontSize: isCompact ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    StatusBadge(
                      status: profile.accountStatus,
                      isCompact: isCompact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge for Active/Pending/Inactive account statuses.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = status.trim().isEmpty ? 'Active' : status.trim();
    final isActive = statusText.toLowerCase() == 'active';

    final bgColor = isActive
        ? const Color(0xFF10B981).withValues(alpha: 0.18)
        : AppColors.accentGold.withValues(alpha: 0.2);
    final borderColor = isActive
        ? const Color(0xFF10B981)
        : AppColors.accentGold;
    final textColor = isActive
        ? const Color(0xFF10B981)
        : AppColors.accentGold;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 9 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 7,
            height: isCompact ? 6 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Header with gold accent icon and title.
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompact;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: isCompact ? 16 : 18,
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 16 : 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 11.5 : 12.5,
          ),
        ),
      ],
    );
  }
}

/// Profile Information Card Container widget.
class ProfileInfoCard extends StatelessWidget {
  final Widget child;
  final bool isCompact;

  const ProfileInfoCard({
    super.key,
    required this.child,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Styled Editable TextFormField for Name, Email, and Mobile.
class EditableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isCompact;
  final ValueChanged<String>? onChanged;

  const EditableTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.enabled = true,
    this.isCompact = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.primaryRoyalBlue,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 12 : 13,
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 13.5 : 14.5,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.primaryRoyalBlue,
              size: isCompact ? 18 : 20,
            ),
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceWhite
                : AppColors.backgroundOffWhite,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 11 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.9),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.9),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.8,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
              borderSide: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Styled Read-only TextField widget for User ID, Username, Role, Status.
class ReadOnlyTextField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isCompact;

  const ReadOnlyTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayVal = value.trim().isNotEmpty ? value.trim() : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 12 : 13,
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 11 : 14,
            vertical: isCompact ? 11 : 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundOffWhite,
            borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
            border: Border.all(
              color: AppColors.borderLight.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textMuted,
                size: isCompact ? 18 : 20,
              ),
              SizedBox(width: isCompact ? 10 : 12),
              Expanded(
                child: Text(
                  displayVal,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 13 : 14,
                  ),
                ),
              ),
              Icon(
                Icons.lock_rounded,
                color: AppColors.borderGold,
                size: isCompact ? 14 : 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary Save Changes Button widget.
class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isCompact;

  const SaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRoyalBlue,
        foregroundColor: AppColors.surfaceWhite,
        disabledBackgroundColor:
            AppColors.primaryRoyalBlue.withValues(alpha: 0.45),
        elevation: disabled ? 0 : 4,
        padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            SizedBox(
              width: isCompact ? 16 : 20,
              height: isCompact ? 16 : 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Saving...',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.surfaceWhite,
                fontSize: isCompact ? 13 : 14.5,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_rounded,
              color: AppColors.accentGold,
              size: isCompact ? 18 : 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Save Changes',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.surfaceWhite,
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 13 : 14.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Secondary Cancel Button widget.
class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final bool isCompact;

  const CancelButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryRoyalBlue,
        side: const BorderSide(color: AppColors.borderGold, width: 1.2),
        padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
        ),
      ),
      child: Text(
        'Cancel',
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primaryRoyalBlue,
          fontWeight: FontWeight.w700,
          fontSize: isCompact ? 13 : 14.5,
        ),
      ),
    );
  }
}

/// Empty State Illustration widget.
class EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isCompact;

  const EmptyState({
    super.key,
    required this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 64 : 80,
            height: isCompact ? 64 : 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundOffWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGold),
            ),
            child: Icon(
              Icons.person_off_rounded,
              size: isCompact ? 32 : 40,
              color: AppColors.primaryRoyalBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Profile Found',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primaryRoyalBlue,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 17 : 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unable to load your profile details right now.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
          SizedBox(height: isCompact ? 14 : 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRoyalBlue,
              foregroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 18 : 24,
                vertical: isCompact ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error State Illustration widget.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isCompact;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 64 : 80,
            height: isCompact ? 64 : 80,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: isCompact ? 34 : 42,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primaryRoyalBlue,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 17 : 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
          SizedBox(height: isCompact ? 14 : 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRoyalBlue,
              foregroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 18 : 24,
                vertical: isCompact ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer Profile Card loading placeholder widget.
class ShimmerProfileCard extends StatelessWidget {
  final bool isCompact;

  const ShimmerProfileCard({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shimmer Header
        Container(
          height: isCompact ? 140 : 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.borderLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
          ),
        ),
        SizedBox(height: isCompact ? 16 : 24),
        // Shimmer Info Card
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 12 : 16),
                child: Container(
                  height: isCompact ? 44 : 52,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
