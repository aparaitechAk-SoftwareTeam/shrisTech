import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Premium Custom Text Field for BBS GOLD with Animated Rounded Corners,
/// focus glow, rich color highlights, and smooth error indicator.
class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? errorText;
  final bool isObscured;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final String? helperText;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.errorText,
    this.isObscured = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label header with optional system badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.readOnly
                    ? AppColors.textMuted
                    : (hasError
                          ? const Color(0xFFEF4444)
                          : (_isFocused
                                ? AppColors.primaryRoyalBlue
                                : AppColors.textPrimary)),
              ),
            ),
            if (widget.readOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTintBlue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SYSTEM GENERATED',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRoyalBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Text Field Container with Animated Rounded Corners (16px to 20px on focus)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.readOnly
                ? AppColors.surfaceCardSubtle
                : (_isFocused
                      ? AppColors.primaryLightBlue.withValues(alpha: 0.2)
                      : AppColors.surfaceWhite),
            borderRadius: BorderRadius.circular(_isFocused ? 20.0 : 16.0),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : (_isFocused
                        ? AppColors.primaryRoyalBlue
                        : AppColors.borderLight),
              width: _isFocused || hasError ? 1.8 : 1.2,
            ),
            // boxShadow: _isFocused && !widget.readOnly && !hasError
            //     ? [
            //         BoxShadow(
            //           color: AppColors.primaryRoyalBlue.withValues(alpha: 0.18),
            //           blurRadius: 14,
            //           offset: const Offset(0, 4),
            //           spreadRadius: 1,
            //         ),
            //         BoxShadow(
            //           color: const Color.fromARGB(
            //             51,
            //             212,
            //             55,
            //             55,
            //           ).withValues(alpha: 0.15),
            //           blurRadius: 10,
            //           offset: const Offset(0, 2),
            //         ),
            //       ]
            //     : [
            //         const BoxShadow(
            //           color: AppColors.shadowSoft,
            //           blurRadius: 4,
            //           offset: Offset(0, 1),
            //         ),
            //       ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            readOnly: widget.readOnly,
            obscureText: widget.isObscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            style: AppTypography.bodyLarge.copyWith(
              color: widget.readOnly
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primaryRoyalBlue,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.maxLines > 1 ? 14 : 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              counterText: '',
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused
                          ? AppColors.primaryRoyalBlue
                          : (hasError
                                ? const Color(0xFFEF4444)
                                : AppColors.textMuted),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),

        // Helper / Error Text
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null &&
            widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
