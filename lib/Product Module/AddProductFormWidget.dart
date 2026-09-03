// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class ProductCategoryOption {
  final String id;
  final String name;
  final List<ProductSubCategoryOption> subCategories;

  const ProductCategoryOption({
    required this.id,
    required this.name,
    this.subCategories = const <ProductSubCategoryOption>[],
  });
}

class ProductSubCategoryOption {
  final String id;
  final String name;

  const ProductSubCategoryOption({required this.id, required this.name});
}

class SelectedProductImage {
  final String id;
  final String path;
  final String fileName;
  final int quarterTurns;

  const SelectedProductImage({
    required this.id,
    required this.path,
    required this.fileName,
    this.quarterTurns = 0,
  });

  SelectedProductImage copyWith({
    String? path,
    String? fileName,
    int? quarterTurns,
  }) {
    return SelectedProductImage(
      id: id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    );
  }
}

class AddProductFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AddProductFormCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final effectivePadding = padding ?? EdgeInsets.all(isCompact ? 13.0 : 18.0);

    return Container(
      width: double.infinity,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentGoldGlow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AddProductSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AddProductSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final iconBoxSize = isCompact ? 38.0 : 44.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            size: isCompact ? 19 : 22,
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
                  fontSize: isCompact ? 14.5 : 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 11.5 : 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddProductImagePicker extends StatelessWidget {
  final List<SelectedProductImage> images;
  final int selectedIndex;
  final int maxImageCount;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpenViewer;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromCamera;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;
  final VoidCallback? onCrop;
  final VoidCallback? onRotate;
  final void Function(int oldIndex, int newIndex) onReorder;

  const AddProductImagePicker({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.maxImageCount,
    required this.onSelect,
    required this.onOpenViewer,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onReplace,
    required this.onDelete,
    required this.onCrop,
    required this.onRotate,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 700;
    final hasImages = images.isNotEmpty;
    final image = hasImages
        ? images[selectedIndex.clamp(0, images.length - 1)]
        : null;
    final aspectRatio = isTablet ? 16 / 9 : (isCompact ? 1.15 : 1.05);

    return AddProductFormCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AddProductSectionHeader(
            icon: Icons.photo_library_rounded,
            title: 'Product Images',
            subtitle:
                'Add clear catalogue images in the order retailers should see them.',
          ),
          SizedBox(height: isCompact ? 12 : 16),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Material(
              color: AppColors.surfaceCardSubtle,
              borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: image == null
                    ? onAddFromGallery
                    : () => onOpenViewer(selectedIndex),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: image == null
                      ? const _EmptyImageState()
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'product-image-${image.id}',
                              child: RotatedBox(
                                quarterTurns: image.quarterTurns,
                                child: Image.file(
                                  File(image.path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const _ImageErrorState(),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: _ImageCounter(
                                current: selectedIndex + 1,
                                total: images.length,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: _ImageIconPill(
                                icon: Icons.fullscreen_rounded,
                                label: 'View',
                                onTap: () => onOpenViewer(selectedIndex),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _ImageActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onPressed: images.length >= maxImageCount
                      ? null
                      : onAddFromGallery,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImageActionButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Camera',
                  onPressed: images.length >= maxImageCount
                      ? null
                      : onAddFromCamera,
                ),
              ),
            ],
          ),
          if (hasImages) ...[
            SizedBox(height: isCompact ? 10 : 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ImageToolChip(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Replace',
                  onPressed: onReplace,
                ),
                _ImageToolChip(
                  icon: Icons.crop_rotate_rounded,
                  label: 'Crop',
                  onPressed: onCrop,
                ),
                _ImageToolChip(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  label: 'Rotate',
                  onPressed: onRotate,
                ),
                _ImageToolChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  isDanger: true,
                  onPressed: onDelete,
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 14),
            AddProductImageGrid(
              images: images,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              onReorder: onReorder,
            ),
          ],
        ],
      ),
    );
  }
}

class AddProductImageGrid extends StatelessWidget {
  final List<SelectedProductImage> images;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;

  const AddProductImageGrid({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final gridHeight = isCompact ? 74.0 : 86.0;
    final itemWidth = isCompact ? 66.0 : 78.0;

    return SizedBox(
      height: gridHeight,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: images.length,
        onReorder: onReorder,
        itemBuilder: (context, index) {
          final image = images[index];
          final selected = selectedIndex == index;
          return ReorderableDragStartListener(
            key: ValueKey(image.id),
            index: index,
            child: GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: itemWidth,
                height: itemWidth,
                margin: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                  border: Border.all(
                    color: selected
                        ? AppColors.accentGold
                        : AppColors.borderLight,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isCompact ? 11 : 14),
                  child: RotatedBox(
                    quarterTurns: image.quarterTurns,
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: AppColors.primaryLightBlue,
                            child: Icon(Icons.broken_image_rounded, size: 20),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddProductTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AddProductTextInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.readOnly = false,
    this.errorText,
    this.onChanged,
  });

  TextInputType get _effectiveKeyboardType {
    if (textInputAction == TextInputAction.newline &&
        maxLines > 1 &&
        keyboardType == TextInputType.text) {
      return TextInputType.multiline;
    }
    return keyboardType;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return TextField(
      controller: controller,
      keyboardType: _effectiveKeyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(
        color: readOnly ? AppColors.primaryRoyalBlue : AppColors.textPrimary,
        fontWeight: readOnly ? FontWeight.w900 : FontWeight.w600,
        fontSize: isCompact ? 13.5 : 14.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(
          icon,
          color: AppColors.primaryRoyalBlue,
          size: isCompact ? 19 : 22,
        ),
        filled: true,
        fillColor: readOnly
            ? AppColors.primaryLightBlue
            : AppColors.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 13 : 16,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontSize: isCompact ? 12.5 : 13.5,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
          fontSize: isCompact ? 12.5 : 13.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class AddProductWeightInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AddProductWeightInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.readOnly = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AddProductTextInput(
      controller: controller,
      label: label,
      hint: hint,
      icon: Icons.scale_rounded,
      readOnly: readOnly,
      errorText: errorText,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class AddProductDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;

  const AddProductDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(
          icon,
          color: AppColors.primaryRoyalBlue,
          size: isCompact ? 19 : 22,
        ),
        filled: true,
        fillColor: onChanged == null
            ? AppColors.surfaceCardSubtle
            : AppColors.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: isCompact ? 13 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }
}

class AddProductProductNameDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final List<String> options;
  final bool loadingOptions;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AddProductProductNameDropdown({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.options = const <String>[],
    this.loadingOptions = false,
    this.errorText,
    this.onChanged,
  });

  @override
  State<AddProductProductNameDropdown> createState() =>
      _AddProductProductNameDropdownState();
}

class _AddProductProductNameDropdownState
    extends State<AddProductProductNameDropdown> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final showClear = !widget.readOnly && widget.controller.text.isNotEmpty;

    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        maximumSize: WidgetStateProperty.all(
          Size(screenWidth > 440 ? 440 : screenWidth - 32, 280),
        ),
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceWhite),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
      ),
      menuChildren: widget.loadingOptions
          ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading product names...'),
                  ],
                ),
              ),
            ]
          : widget.options.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No existing products found'),
              ),
            ]
          : widget.options.map((option) {
              final selected =
                  widget.controller.text.trim().toLowerCase() ==
                  option.trim().toLowerCase();
              return MenuItemButton(
                onPressed: widget.readOnly
                    ? null
                    : () {
                        widget.controller.text = option;
                        widget.onChanged?.call(option);
                        _menuController.close();
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.workspace_premium_rounded,
                        size: 18,
                        color: selected
                            ? AppColors.primaryRoyalBlue
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option,
                          style: AppTypography.bodyMedium.copyWith(
                            color: selected
                                ? AppColors.primaryRoyalBlue
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: isCompact ? 13 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      builder: (context, controller, child) {
        return TextField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: widget.readOnly
                ? AppColors.primaryRoyalBlue
                : AppColors.textPrimary,
            fontWeight: widget.readOnly ? FontWeight.w900 : FontWeight.w600,
            fontSize: isCompact ? 13.5 : 14.5,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: Icon(
              widget.icon,
              color: AppColors.primaryRoyalBlue,
              size: isCompact ? 19 : 22,
            ),
            suffixIcon: widget.readOnly
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showClear)
                        IconButton(
                          tooltip: 'Clear product name',
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: isCompact ? 18 : 20,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged?.call('');
                          },
                        ),
                      IconButton(
                        tooltip: 'Select product name',
                        icon: Icon(
                          controller.isOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryRoyalBlue,
                          size: isCompact ? 20 : 24,
                        ),
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                      ),
                    ],
                  ),
            filled: true,
            fillColor: widget.readOnly
                ? AppColors.primaryLightBlue
                : AppColors.surfaceWhite,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 13 : 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddProductPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AddProductPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<AddProductPrimaryButton> createState() =>
      _AddProductPrimaryButtonState();
}

class _AddProductPrimaryButtonState extends State<AddProductPrimaryButton> {
  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      scale: widget.isLoading ? 0.985 : 1,
      child: SizedBox(
        width: double.infinity,
        height: isCompact ? 48 : 54,
        child: ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onPressed,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.surfaceWhite,
                  ),
                )
              : Icon(widget.icon, size: isCompact ? 18 : 20),
          label: Text(
            widget.isLoading ? 'Saving Product' : widget.label,
            style: TextStyle(
              fontSize: isCompact ? 14 : 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryRoyalBlue,
            foregroundColor: AppColors.surfaceWhite,
            disabledBackgroundColor: AppColors.textMuted,
            disabledForegroundColor: AppColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class AddProductLoadingWidget extends StatelessWidget {
  final String label;

  const AddProductLoadingWidget({super.key, this.label = 'Please wait'});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 18,
          vertical: isCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primaryRoyalBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductImageViewer extends StatefulWidget {
  final List<SelectedProductImage> images;
  final int initialIndex;

  const AddProductImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<AddProductImageViewer> createState() => _AddProductImageViewerState();
}

class _AddProductImageViewerState extends State<AddProductImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final image = widget.images[index];
                return Center(
                  child: Hero(
                    tag: 'product-image-${image.id}',
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: RotatedBox(
                        quarterTurns: image.quarterTurns,
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ImageErrorState(dark: true),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _ViewerCounter(
                  current: _index + 1,
                  total: widget.images.length,
                ),
              ),
            ),
            if (widget.images.length > 1) ...[
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerNavButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: _index == 0
                        ? null
                        : () => _controller.previousPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerNavButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: _index == widget.images.length - 1
                        ? null
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final boxSize = isCompact ? 60.0 : 76.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: AppColors.primaryLightBlue,
            borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: Icon(
            Icons.add_photo_alternate_rounded,
            color: AppColors.primaryRoyalBlue,
            size: isCompact ? 26 : 34,
          ),
        ),
        SizedBox(height: isCompact ? 10 : 16),
        Text(
          'Add Product Images',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Gallery, camera, crop, rotate and reorder supported',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  final bool dark;

  const _ImageErrorState({this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_rounded,
        color: dark ? Colors.white : AppColors.primaryRoyalBlue,
        size: 42,
      ),
    );
  }
}

class _ImageCounter extends StatelessWidget {
  final int current;
  final int total;

  const _ImageCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$current / $total',
        style: AppTypography.caption.copyWith(
          color: AppColors.surfaceWhite,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _ImageIconPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageIconPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.surfaceWhite, size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isCompact ? 16 : 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 12.5 : 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, isCompact ? 42 : 46),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
        foregroundColor: AppColors.primaryRoyalBlue,
        side: const BorderSide(color: AppColors.borderGold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ImageToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback? onPressed;

  const _ImageToolChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final color = isDanger
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryRoyalBlue;

    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(icon, color: color, size: isCompact ? 15 : 17),
      label: Text(label),
      labelStyle: AppTypography.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: isCompact ? 11 : 12,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      backgroundColor: isDanger
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
          : AppColors.primaryLightBlue,
      side: BorderSide(
        color: isDanger
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.25)
            : AppColors.borderLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ViewerCounter extends StatelessWidget {
  final int current;
  final int total;

  const _ViewerCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$current of $total',
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ViewerNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ViewerNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 30),
    );
  }
}
