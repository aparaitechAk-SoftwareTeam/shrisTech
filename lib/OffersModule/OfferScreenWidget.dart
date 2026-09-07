// ignore_for_file: file_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'OffersApis.dart';

class OfferHeader extends StatelessWidget {
  final bool canCreate;
  final VoidCallback? onCreate;

  const OfferHeader({super.key, required this.canCreate, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final isCompact = constraints.maxWidth < 360;
        final text = _HeaderText(compact: compact, isCompact: isCompact);
        final button = canCreate
            ? Align(
                alignment: compact
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: _CreateButton(onPressed: onCreate, isCompact: isCompact),
              )
            : const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF172554), Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowPrimaryGlow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    if (canCreate) ...[
                      SizedBox(height: isCompact ? 10 : 14),
                      button,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: text),
                    if (canCreate) ...[const SizedBox(width: 16), button],
                  ],
                ),
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  final bool compact;
  final bool isCompact;

  const _HeaderText({required this.compact, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final boxSize = isCompact ? 44.0 : 56.0;
    return Row(
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(isCompact ? 14 : 17),
            border: Border.all(
              color: AppColors.surfaceWhite.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            Icons.local_offer_rounded,
            color: AppColors.accentGold,
            size: isCompact ? 22 : 28,
          ),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offers Management',
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 16 : 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Latest promotional offers and announcements.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.78),
                  height: 1.35,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isCompact;

  const _CreateButton({required this.onPressed, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: SizedBox(
        height: isCompact ? 42 : 48,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.add_rounded, size: isCompact ? 18 : 20),
          label: Text(isCompact ? 'Create' : 'Create Offer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryRoyalBlue,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
            textStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: isCompact ? 13 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            ),
          ),
        ),
      ),
    );
  }
}

class OfferSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool canCreate;
  final bool isCompact;
  final VoidCallback? onCreate;

  const OfferSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.canCreate = false,
    this.isCompact = false,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final searchInput = TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: isCompact ? 'Search offers...' : 'Search title, type or note',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.primaryRoyalBlue,
        ),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 12 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
        ),
      ),
    );

    if (!canCreate) {
      return searchInput;
    }

    return Row(
      children: [
        Expanded(child: searchInput),
        SizedBox(width: isCompact ? 8 : 12),
        IntrinsicWidth(
          child: SizedBox(
            height: isCompact ? 48 : 54,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add_rounded, size: isCompact ? 18 : 20),
              label: Text(isCompact ? 'Create' : 'Create Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryRoyalBlue,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
                textStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 13 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final bool canManage;
  final bool isCompact;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<int>? onImageTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.canManage,
    this.isCompact = false,
    required this.onViewDetails,
    this.onEdit,
    this.onDelete,
    this.onImageTap,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  late final PageController _pageController;
  int _imageIndex = 0;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isCompact = widget.isCompact;
    final title = _safeText(offer.title, fallback: 'Untitled Offer');
    final note = _safeText(offer.note, fallback: 'No description available.');
    final aspectRatio = MediaQuery.sizeOf(context).width >= 700
        ? 16 / 8
        : (isCompact ? 16 / 11 : 16 / 10);

    return Semantics(
      label: 'Offer ${offer.title}',
      button: true,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.985 : 1.0,
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onViewDetails,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.accentGoldGlow,
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: offer.bannerImages.isEmpty
                                  ? 1
                                  : offer.bannerImages.length,
                              onPageChanged: (value) {
                                setState(() => _imageIndex = value);
                              },
                              itemBuilder: (context, index) {
                                final imageUrl = offer.bannerImages.isEmpty
                                    ? ''
                                    : offer.bannerImages[index];
                                return OfferImage(
                                  imageUrl: imageUrl,
                                  heroTag: 'offer-${offer.id}-image-$index',
                                  isExpired: offer.isExpired,
                                  onTap: () => widget.onImageTap?.call(index),
                                );
                              },
                            ),
                            if (offer.bannerImages.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: OfferImageIndicators(
                                  count: offer.bannerImages.length,
                                  index: _imageIndex,
                                ),
                              ),
                            if (offer.isActive)
                              const Positioned(
                                left: 12,
                                top: 12,
                                child: OfferBadge(
                                  label: 'ACTIVE',
                                  backgroundColor: Color(0xFFD1FAE5),
                                  foregroundColor: Color(0xFF047857),
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                            if (offer.isNew && !offer.isExpired)
                              const Positioned(
                                right: 12,
                                top: 12,
                                child: _AnimatedNewBadge(),
                              ),
                            if (offer.isExpired) const _ExpiredRibbon(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: isCompact
                            ? const EdgeInsets.fromLTRB(14, 12, 14, 14)
                            : const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OfferMetaRow(offer: offer),
                                  SizedBox(height: isCompact ? 8 : 12),
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: isCompact ? 15 : 16,
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 5 : 7),
                                  Text(
                                    note,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                      fontSize: isCompact ? 12.5 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.canManage) ...[
                              const SizedBox(width: 8),
                              OfferActionButtons(
                                canManage: widget.canManage,
                                isCompact: isCompact,
                                onViewDetails: widget.onViewDetails,
                                onEdit: widget.onEdit,
                                onDelete: widget.onDelete,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    right: -34,
                    bottom: 98,
                    child: _GoldCircle(96),
                  ),
                  const Positioned(left: -26, top: 120, child: _GoldCircle(70)),
                  const Positioned(
                    right: 12,
                    bottom: 12,
                    child: _CornerPattern(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OfferImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final bool isExpired;
  final VoidCallback? onTap;

  const OfferImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.isExpired = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = imageUrl.trim().isEmpty
        ? const OfferPlaceholder()
        : _ImageBySource(imageUrl: imageUrl);
    return Material(
      color: AppColors.surfaceCardSubtle,
      child: InkWell(
        onTap: imageUrl.trim().isEmpty ? null : onTap,
        child: Hero(
          tag: heroTag,
          child: Opacity(opacity: isExpired ? 0.58 : 1, child: child),
        ),
      ),
    );
  }
}

class _ImageBySource extends StatefulWidget {
  final String imageUrl;

  const _ImageBySource({required this.imageUrl});

  @override
  State<_ImageBySource> createState() => _ImageBySourceState();
}

class _ImageBySourceState extends State<_ImageBySource> {
  late Future<bool> _canLoadRemoteImageFuture;

  @override
  void initState() {
    super.initState();
    _canLoadRemoteImageFuture = _canLoadRemoteImage(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _ImageBySource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _canLoadRemoteImageFuture = _canLoadRemoteImage(widget.imageUrl);
    }
  }

  Future<bool> _canLoadRemoteImage(String imageUrl) async {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('data:image')) return true;

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('provider.com') ||
        host.contains('example.com') ||
        host == 'localhost' ||
        host == '127.0.0.1') {
      return false;
    }

    try {
      final response = await http.head(uri).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.startsWith('data:image')) {
      final comma = widget.imageUrl.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(widget.imageUrl.substring(comma + 1));
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _BrokenImageWidget(),
          );
        } catch (_) {
          return const _BrokenImageWidget();
        }
      }
    }

    return FutureBuilder<bool>(
      future: _canLoadRemoteImageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const OfferPlaceholder(showIcon: false);
        }

        if (snapshot.data != true) {
          return const _BrokenImageWidget();
        }

        return Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const OfferPlaceholder(showIcon: false);
          },
          errorBuilder: (context, error, stackTrace) =>
              const _BrokenImageWidget(),
        );
      },
    );
  }
}

class OfferPlaceholder extends StatelessWidget {
  final bool showIcon;

  const OfferPlaceholder({super.key, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLightBlue, AppColors.surfaceWhite],
        ),
      ),
      child: Center(
        child: showIcon
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderGold),
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      color: AppColors.primaryRoyalBlue,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Premium offer banner',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
      ),
    );
  }
}

class _BrokenImageWidget extends StatelessWidget {
  const _BrokenImageWidget();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primaryLightBlue,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.primaryRoyalBlue,
          size: 42,
        ),
      ),
    );
  }
}

class OfferImageIndicators extends StatelessWidget {
  final int count;
  final int index;

  const OfferImageIndicators({
    super.key,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentGold
                : AppColors.surfaceWhite.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class OfferMetaRow extends StatelessWidget {
  final OfferModel offer;

  const OfferMetaRow({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // OfferBadge(
        //   label: offer.offerType,
        //   backgroundColor: AppColors.primaryLightBlue,
        //   foregroundColor: AppColors.primaryRoyalBlue,
        //   icon: Icons.category_rounded,
        // ),
        if (offer.discount != null && offer.discount! > 0)
          OfferBadge(
            label: discountLabel(offer),
            backgroundColor: AppColors.primaryLightBlue,
            foregroundColor: AppColors.primaryRoyalBlue,
            icon: Icons.discount_rounded,
          ),
        OfferBadge(
          label: offerValidityLabel(offer.startDate, offer.endDate),
          backgroundColor: AppColors.surfaceCardSubtle,
          foregroundColor: AppColors.accentGoldDark,
          icon: Icons.event_rounded,
        ),
      ],
    );
  }
}

class OfferBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  const OfferBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNewBadge extends StatefulWidget {
  const _AnimatedNewBadge();

  @override
  State<_AnimatedNewBadge> createState() => _AnimatedNewBadgeState();
}

class _AnimatedNewBadgeState extends State<_AnimatedNewBadge>
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
    return FadeTransition(
      opacity: Tween<double>(begin: 0.72, end: 1).animate(_controller),
      child: const OfferBadge(
        label: 'NEW',
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryRoyalBlue,
        icon: Icons.auto_awesome_rounded,
      ),
    );
  }
}

class _ExpiredRibbon extends StatelessWidget {
  const _ExpiredRibbon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -34,
      top: 22,
      child: Transform.rotate(
        angle: 0.72,
        child: Container(
          width: 136,
          padding: const EdgeInsets.symmetric(vertical: 7),
          color: const Color(0xFFDC2626),
          alignment: Alignment.center,
          child: Text(
            'EXPIRED',
            style: AppTypography.caption.copyWith(
              color: AppColors.surfaceWhite,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class OfferActionButtons extends StatelessWidget {
  final bool canManage;
  final bool isCompact;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OfferActionButtons({
    super.key,
    required this.canManage,
    this.isCompact = false,
    required this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!canManage) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'Offer options',
        onSelected: (value) {
          if (value == 'edit') {
            onEdit?.call();
          } else if (value == 'delete') {
            onDelete?.call();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primaryRoyalBlue,
                ),
                SizedBox(width: 10),
                Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        color: AppColors.surfaceWhite,
        elevation: 8,
        icon: Container(
          padding: EdgeInsets.all(isCompact ? 5 : 7),
          decoration: BoxDecoration(
            color: AppColors.primaryLightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: isCompact ? 18 : 20,
            color: AppColors.primaryRoyalBlue,
          ),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: MediaQuery.sizeOf(context).width >= 700
                  ? 16 / 8
                  : 16 / 10,
              child: const _SkeletonBox(radius: 22),
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(widthFactor: 0.7),
                  SizedBox(height: 12),
                  _SkeletonLine(widthFactor: 0.92, height: 18),
                  SizedBox(height: 8),
                  _SkeletonLine(widthFactor: 0.76, height: 18),
                  SizedBox(height: 18),
                  _SkeletonLine(widthFactor: 0.48, height: 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const EmptyWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.local_offer_outlined,
      title: 'No Offers Available',
      message:
          'Create a promotional announcement when the next campaign is ready.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class OfferErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OfferErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _StateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Unable to Load Offers',
      message: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _StateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final iconBoxSize = isCompact ? 68.0 : 86.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 22,
            vertical: isCompact ? 28 : 42,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
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
                  size: isCompact ? 32 : 40,
                ),
              ),
              SizedBox(height: isCompact ? 14 : 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 15 : 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 12.5 : 14,
                ),
              ),
              SizedBox(height: isCompact ? 14 : 18),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(isCompact ? 110 : 120, isCompact ? 40 : 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroPrefix;

  const ImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
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
                return Center(
                  child: Hero(
                    tag: '${widget.heroPrefix}-$index',
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: _ImageBySource(imageUrl: widget.images[index]),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                tooltip: 'Close image viewer',
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${_index + 1} of ${widget.images.length}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
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
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
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

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ViewerButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
      ),
      icon: Icon(icon, size: 30),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final position = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1 + position, -0.3),
              end: Alignment(position, 0.3),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double radius;

  const _SkeletonBox({this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: SizedBox(height: height, child: const _SkeletonBox()),
    );
  }
}

class _GoldCircle extends StatelessWidget {
  final double size;

  const _GoldCircle(this.size);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            width: 1.1,
          ),
        ),
      ),
    );
  }
}

class _CornerPattern extends StatelessWidget {
  const _CornerPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(52, 52),
        painter: _CornerPatternPainter(),
      ),
    );
  }
}

class _CornerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accentGold.withValues(alpha: 0.22);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 12, 12),
      Offset(size.width - 12, size.height - 12),
      paint,
    );
    canvas.drawLine(
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _safeText(String? value, {required String fallback}) {
  final text = value?.trim();
  return (text == null || text.isEmpty) ? fallback : text;
}

String discountLabel(OfferModel offer) {
  final value = offer.discount;
  if (value == null || value <= 0) return '';
  final text = value % 1 == 0
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  final normalizedType = _safeText(
    offer.offerType,
    fallback: 'Percentage',
  ).toLowerCase();
  return normalizedType == 'flat' ? 'INR $text OFF' : '$text% OFF';
}

String offerValidityLabel(DateTime? startDate, DateTime? endDate) {
  if (startDate == null && endDate == null) return 'Validity Not Specified';
  if (startDate == null) return 'Until ${formatOfferDate(endDate!)}';
  if (endDate == null) return 'From ${formatOfferDate(startDate)}';
  return '${formatOfferDate(startDate)} - ${formatOfferDate(endDate)}';
}

String formatOfferDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
}
