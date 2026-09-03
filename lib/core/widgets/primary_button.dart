import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Ultra-Luxury CTA Button for BBS GOLD.
/// Designed according to premium jewellery brand standards (Luxury, Trust, Professional, Modern).
/// Features Royal Blue to Dark Navy gradient, dual-layer Gold glow ambient shadow,
/// metallic gold accent border, tactile press animation, dynamic disabled styling,
/// and smooth golden loading state.
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isEnabled && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: active,
      label: widget.text,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: active ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: active ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: Builder(
            builder: (context) {
              final isCompact = MediaQuery.sizeOf(context).width < 360;
              final btnHeight = isCompact ? 50.0 : 54.0;
              final btnHorizontalPadding = isCompact ? 16.0 : 24.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: btnHeight,
                width: double.infinity,
                constraints: BoxConstraints(minHeight: isCompact ? 48 : 52),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [
                            AppColors.primaryRoyalBlue,
                            AppColors.primaryDarkBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: active ? null : AppColors.surfaceCardSubtle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active
                        ? AppColors.accentGold.withValues(alpha: 0.65)
                        : AppColors.borderLight,
                    width: active ? 1.5 : 1.0,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primaryRoyalBlue
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: AppColors.shadowSoft,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [
                          const BoxShadow(
                            color: AppColors.shadowSoft,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    splashColor: active
                        ? AppColors.accentGoldLight.withValues(alpha: 0.2)
                        : Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: active ? widget.onPressed : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: btnHorizontalPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isLoading) ...[
                            const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accentGold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Processing Request...',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: isCompact ? 14 : 16,
                                ),
                              ),
                            ),
                          ] else ...[
                            Flexible(
                              child: Text(
                                widget.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge.copyWith(
                                  color: active
                                      ? AppColors.textOnPrimary
                                      : AppColors.textMuted,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: isCompact ? 14 : 16,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (widget.icon != null) ...[
                              const SizedBox(width: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.accentGoldLight,
                                            AppColors.accentGold,
                                            AppColors.accentGoldDark,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: active ? null : AppColors.borderLight,
                                  shape: BoxShape.circle,
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accentGold
                                                .withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: isCompact ? 14 : 16,
                                  color: active
                                      ? AppColors.primaryDarkBlue
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
