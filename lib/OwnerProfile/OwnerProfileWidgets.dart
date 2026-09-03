// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'OwnerProfileApis.dart';

class ProfileHeader extends StatelessWidget {
  final OwnerProfileModel profile;
  final VoidCallback? onEdit;
  final VoidCallback onRefresh;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final business = profile.businessInfo;
    final name = business.ownerName.isEmpty ? 'Owner' : business.ownerName;
    final businessName = business.businessName.isEmpty
        ? 'BBS GOLD Business'
        : business.businessName;
    final mobile = business.mobileNumber.isEmpty
        ? 'Mobile not added'
        : business.mobileNumber;
    final address = business.address.isEmpty ? '' : business.address;

    return Semantics(
      label: 'Owner profile summary',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final avatarSize = isCompact ? 68.0 : 86.0;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isCompact ? 14 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDarkBlue,
                  AppColors.primaryRoyalBlue,
                  AppColors.primaryRoyalBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(isCompact ? 20 : 26),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowPrimaryGlow,
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _HeaderPattern()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'owner-profile-avatar',
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentGold,
                              border: Border.all(
                                color: AppColors.surfaceWhite,
                                width: isCompact ? 2.2 : 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.accentGoldGlow,
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _initials(name),
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 17 : 20,
                                ),
                              ),
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
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 16 : 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                businessName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.surfaceWhite.withValues(
                                    alpha: 0.86,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: isCompact ? 12.5 : 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mobile,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.surfaceWhite.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: isCompact ? 11 : 12,
                                ),
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.surfaceWhite.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: isCompact ? 11 : 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (onEdit != null)
                          _HeaderIconButton(
                            icon: Icons.edit_rounded,
                            tooltip: 'Edit profile',
                            isCompact: isCompact,
                            onPressed: onEdit!,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final iconBoxSize = isCompact ? 44.0 : 54.0;

        return AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.985 : 1,
          child: Card(
            elevation: 8,
            shadowColor: AppColors.shadowPrimaryGlow.withValues(alpha: 0.12),
            color: AppColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: ProfileCardCornerPainter(),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 13 : 18),
                  child: Row(
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRoyalBlue.withValues(
                            alpha: 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: AppColors.primaryRoyalBlue,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: isCompact ? 13.5 : 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: isCompact ? 11.5 : 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.all(isCompact ? 6 : 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.accentGold,
                          size: isCompact ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'Not added' : value.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 15),
          decoration: BoxDecoration(
            color: AppColors.surfaceCardSubtle,
            borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRoyalBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryRoyalBlue,
                  size: isCompact ? 18 : 20,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      displayValue,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        );
      },
    );
  }
}

class EditableField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const EditableField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, color: AppColors.primaryRoyalBlue),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class OwnerProfilePrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const OwnerProfilePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  color: AppColors.surfaceWhite,
                ),
              )
            : Icon(icon, size: 19),
        label: Text(isLoading ? 'Saving' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRoyalBlue,
          foregroundColor: AppColors.surfaceWhite,
          disabledBackgroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class OwnerProfileSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const OwnerProfileSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRoyalBlue,
          side: const BorderSide(color: AppColors.borderGold),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional edit action. When provided, an edit / cancel icon-button is
  /// rendered on the trailing edge of the header row.
  final VoidCallback? onEdit;
  final bool isEditing;
  final bool isSaving;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.isEditing = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final iconBoxSize = isCompact ? 38.0 : 44.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.primaryLightBlue,
                borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryRoyalBlue,
                size: isCompact ? 18 : 22,
              ),
            ),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 15 : 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: isCompact ? 11.5 : 12.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Inline Edit / Cancel button ──────────────────────────────
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: isEditing ? 'Cancel edit' : 'Edit',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSaving ? null : onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isCompact ? 36 : 42,
                      height: isCompact ? 36 : 42,
                      decoration: BoxDecoration(
                        color: isEditing
                            ? AppColors.primaryRoyalBlue.withValues(alpha: 0.10)
                            : AppColors.accentGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEditing
                              ? AppColors.primaryRoyalBlue.withValues(
                                  alpha: 0.30,
                                )
                              : AppColors.borderGold,
                        ),
                      ),
                      child: Icon(
                        isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        size: isCompact ? 17 : 19,
                        color: isEditing
                            ? AppColors.primaryRoyalBlue
                            : AppColors.accentGoldDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final int itemCount;

  const SkeletonLoader({super.key, this.itemCount = 4});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.45 + (_controller.value * 0.35);
        return Column(
          children: [
            _SkeletonBlock(height: 168, alpha: alpha),
            const SizedBox(height: 16),
            for (int index = 0; index < widget.itemCount; index++) ...[
              _SkeletonBlock(height: 86, alpha: alpha),
              if (index < widget.itemCount - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class OwnerProfileErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OwnerProfileErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'Unable to Load Profile',
      message: message,
      buttonLabel: 'Retry',
      onPressed: onRetry,
    );
  }
}

class OwnerProfileEmptyWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const OwnerProfileEmptyWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.account_circle_rounded,
      title: 'No Profile Data',
      message: 'Your profile information is not available yet.',
      buttonLabel: 'Retry',
      onPressed: onRetry,
    );
  }
}

class CopyButton extends StatelessWidget {
  final String value;
  final VoidCallback onCopied;

  const CopyButton({super.key, required this.value, required this.onCopied});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copy value',
      child: IconButton(
        tooltip: 'Copy',
        onPressed: value.trim().isEmpty
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: value.trim()));
                onCopied();
              },
        icon: const Icon(Icons.copy_rounded),
        color: AppColors.primaryRoyalBlue,
      ),
    );
  }
}

class ProfileSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProfileSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.shadowPrimaryGlow.withValues(alpha: 0.12),
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: ProfileCardCornerPainter(),
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isCompact;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.isCompact = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 40.0 : 48.0;
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceWhite.withValues(alpha: 0.14),
        foregroundColor: AppColors.accentGold,
        minimumSize: Size(size, size),
      ),
      icon: Icon(icon, size: isCompact ? 18 : 22),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double alpha;

  const _SkeletonBlock({required this.height, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLightBlue.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
      ),
    );
  }
}

class _StateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _StateWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final iconBoxSize = isCompact ? 68.0 : 82.0;

          return ProfileSurfaceCard(
            padding: EdgeInsets.all(isCompact ? 16 : 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue,
                    borderRadius: BorderRadius.circular(isCompact ? 20 : 26),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryRoyalBlue,
                    size: isCompact ? 30 : 38,
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 15 : 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 12.5 : 14,
                  ),
                ),
                SizedBox(height: isCompact ? 14 : 18),
                OwnerProfilePrimaryButton(
                  label: buttonLabel,
                  icon: Icons.refresh_rounded,
                  isLoading: false,
                  onPressed: onPressed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderPattern extends StatelessWidget {
  const _HeaderPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeaderPatternPainter());
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centers = [Offset(size.width, 0), Offset(0, size.height)];
    for (final center in centers) {
      for (var radius = 64.0; radius < size.width + size.height; radius += 58) {
        paint.color = AppColors.surfaceWhite.withValues(alpha: 0.05);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A custom painter that draws premium concentric gold circles at the
/// top-right corner and blue curved lines at the bottom-left corner.
/// Mirrors [ContactCardCornerPainter] used in RetailerContactScreen.
class ProfileCardCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Concentric circles at the top right corner
    final topRightCenter = Offset(size.width - 10, 10);
    paint.color = AppColors.accentGold.withValues(alpha: 0.18);
    canvas.drawCircle(topRightCenter, 45, paint);
    canvas.drawCircle(topRightCenter, 70, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentGold.withValues(alpha: 0.04);
    canvas.drawCircle(topRightCenter, 45, fillPaint);

    // 2. Blue curved lines at the bottom left corner
    final path = Path();
    paint.color = AppColors.primaryRoyalBlue.withValues(alpha: 0.10);
    paint.strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final offset = i * 15.0;
      path.reset();
      path.moveTo(0, size.height - 80 - offset);
      path.quadraticBezierTo(
        40 + offset,
        size.height - 40 - offset,
        80 + offset,
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    // 3. Solid gold circular accent in the top-right
    final solidGoldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentGold.withValues(alpha: 0.08);
    canvas.drawCircle(topRightCenter, 15, solidGoldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final letters = words.take(2).map((word) => word.substring(0, 1)).join();
  return letters.isEmpty ? 'BG' : letters.toUpperCase();
}
