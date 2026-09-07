// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import 'AddEditOfferScreen.dart';
import 'OfferScreenWidget.dart';
import 'OffersApis.dart';

class OfferDeleteResult {
  final OfferModel offer;
  final String message;

  const OfferDeleteResult({required this.offer, required this.message});
}

class OfferDetailedScreen extends StatefulWidget {
  final OfferModel offer;
  final bool canManage;

  const OfferDetailedScreen({
    super.key,
    required this.offer,
    required this.canManage,
  });

  @override
  State<OfferDetailedScreen> createState() => _OfferDetailedScreenState();
}

class _OfferDetailedScreenState extends State<OfferDetailedScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOffersRepository _repository = OffersRepository();
  late OfferModel _offer;
  Object? _pendingReturnResult;
  int _imageIndex = 0;
  int _footerIndex = -1;
  bool _deleting = false;

  bool get _isOwner => UserData.instance.role.trim().toLowerCase() == 'owner';

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_pendingReturnResult);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.bg,
        appBar: _isOwner
            ? GlobalAppbar(
                onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
                subtitle: 'Offers Management',
              )
            : RetailerGlobalAppbar(
                onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        drawer: _isOwner
            ? GlobalDrawer(selectedIndex: 6, onItemSelected: (_) {})
            : RetailerGlobalDrawer(selectedIndex: 5, onItemSelected: (_) {}),
        bottomNavigationBar: _isOwner
            ? GlobalFooter(
                currentIndex: _footerIndex,
                onTap: _handleFooterNavigation,
              )
            : RetailerGlobalFooter(
                currentIndex: 2,
                onTap: _handleFooterNavigation,
              ),
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isCompact = screenWidth < 360;
                  final isTablet = screenWidth >= 700;
                  final horizontalPadding = isTablet
                      ? 34.0
                      : (isCompact ? 12.0 : 18.0);
                  final maxWidth = screenWidth >= 1100
                      ? 760.0
                      : (screenWidth >= 700 ? 680.0 : screenWidth);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              isCompact ? 12 : 22,
                              horizontalPadding,
                              isCompact ? 20 : 26,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _HeroCarousel(
                                  offer: _offer,
                                  index: _imageIndex,
                                  isCompact: isCompact,
                                  isTablet: isTablet,
                                  onChanged: (value) {
                                    setState(() => _imageIndex = value);
                                  },
                                  onImageTap: _openImageViewer,
                                ),
                                SizedBox(height: isCompact ? 12 : 18),
                                _DetailCard(
                                  isCompact: isCompact,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              spacing: isCompact ? 6 : 8,
                                              runSpacing: isCompact ? 6 : 8,
                                              children: [
                                                if (_offer.isActive)
                                                  const OfferBadge(
                                                    label: 'ACTIVE',
                                                    backgroundColor: Color(
                                                      0xFFD1FAE5,
                                                    ),
                                                    foregroundColor: Color(
                                                      0xFF047857,
                                                    ),
                                                    icon: Icons
                                                        .check_circle_rounded,
                                                  ),
                                                if (_offer.isExpired)
                                                  const OfferBadge(
                                                    label: 'EXPIRED',
                                                    backgroundColor: Color(
                                                      0xFFFEE2E2,
                                                    ),
                                                    foregroundColor: Color(
                                                      0xFFDC2626,
                                                    ),
                                                    icon: Icons
                                                        .event_busy_rounded,
                                                  ),
                                                if (_offer.isNew)
                                                  const OfferBadge(
                                                    label: 'NEW',
                                                    backgroundColor:
                                                        AppColors.accentGold,
                                                    foregroundColor: AppColors
                                                        .primaryRoyalBlue,
                                                    icon: Icons
                                                        .auto_awesome_rounded,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (_isOwner && widget.canManage) ...[
                                            const SizedBox(width: 8),
                                            OfferActionButtons(
                                              canManage: true,
                                              isCompact: isCompact,
                                              onViewDetails: () {},
                                              onEdit: _openEdit,
                                              onDelete: _confirmDelete,
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: isCompact ? 10 : 14),
                                      Text(
                                        _offer.title,
                                        style: AppTypography.titleLarge
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: isCompact ? 17 : 20,
                                            ),
                                      ),
                                      SizedBox(height: isCompact ? 6 : 8),
                                      Text(
                                        _offer.note,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                              height: 1.55,
                                              fontSize: isCompact ? 12.5 : 14,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 12 : 18),
                                _DetailCard(
                                  isCompact: isCompact,
                                  child: Column(
                                    children: [
                                      _DetailRow(
                                        icon: Icons.category_rounded,
                                        label: 'Offer Type',
                                        value: _offerTypeDisplay(_offer),
                                        isCompact: isCompact,
                                      ),
                                      _DetailRow(
                                        icon: Icons.calendar_today_rounded,
                                        label: 'Start Date',
                                        value: _offer.startDate == null
                                            ? 'Validity Not Specified'
                                            : formatOfferDate(
                                                _offer.startDate!,
                                              ),
                                        isCompact: isCompact,
                                      ),
                                      _DetailRow(
                                        icon: Icons.event_available_rounded,
                                        label: 'End Date',
                                        value: _offer.endDate == null
                                            ? 'Validity Not Specified'
                                            : formatOfferDate(_offer.endDate!),
                                        isCompact: isCompact,
                                      ),
                                      _DetailRow(
                                        icon: Icons.verified_rounded,
                                        label: 'Status',
                                        value: _statusLabel(_offer),
                                        showDivider: false,
                                        isCompact: isCompact,
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_deleting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRoyalBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openImageViewer(int index) async {
    if (_offer.bannerImages.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewer(
          images: _offer.bannerImages,
          initialIndex: index,
          heroPrefix: 'offer-detail-${_offer.id}-image',
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<OfferFormResult>(
      MaterialPageRoute<OfferFormResult>(
        builder: (_) => AddEditOfferScreen(offer: _offer),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _offer = result.offer;
      _pendingReturnResult = result;
    });
    _showSnackBar(result.message, success: true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: Text(
          'This promotional offer will be removed from the feed.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _repository.deleteOffer(_offer.apiId);
      if (!mounted) return;
      Navigator.of(context).pop(
        OfferDeleteResult(
          offer: _offer,
          message: 'Offer deleted successfully.',
        ),
      );
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _handleFooterNavigation(int index) {
    if (!_isOwner) {
      switch (index) {
        case 0:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
          break;
        case 1:
          Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
          break;
        case 2:
          break;
        case 3:
          Navigator.of(context).pushNamed(AppRoutes.orderManagement);
          break;
        case 4:
          Navigator.of(context).pushNamed(AppRoutes.retailerCart);
          break;
      }
      return;
    }
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.stockListing);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.addProduct);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.orderManagement);
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushNamed(AppRoutes.orderHistory);
      return;
    }
    setState(() => _footerIndex = index);
    _showSnackBar('This section will be connected soon.', success: true);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is SocketException) {
      return 'Please check your internet connection.';
    }
    return 'Something went wrong.';
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final OfferModel offer;
  final int index;
  final bool isCompact;
  final bool isTablet;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onImageTap;

  const _HeroCarousel({
    required this.offer,
    required this.index,
    required this.isCompact,
    required this.isTablet,
    required this.onChanged,
    required this.onImageTap,
  });

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.offer.bannerImages;
    final aspectRatio = widget.isTablet
        ? 16 / 7
        : (widget.isCompact ? 16 / 11 : 16 / 10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isCompact ? 18 : 24),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.isEmpty ? 1 : images.length,
              onPageChanged: widget.onChanged,
              itemBuilder: (context, index) {
                final image = images.isEmpty ? '' : images[index];
                return OfferImage(
                  imageUrl: image,
                  heroTag: 'offer-detail-${widget.offer.id}-image-$index',
                  isExpired: widget.offer.isExpired,
                  onTap: () => widget.onImageTap(index),
                );
              },
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: OfferImageIndicators(
                  count: images.length,
                  index: widget.index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  final bool isCompact;

  const _DetailCard({required this.child, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final bool isCompact;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: isCompact ? 36 : 42,
              height: isCompact ? 36 : 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLightBlue,
                borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryRoyalBlue,
                size: isCompact ? 18 : 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 10.5 : 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
            child: const Divider(height: 1, color: AppColors.borderSubtle),
          ),
      ],
    );
  }
}

String _statusLabel(OfferModel offer) {
  if (offer.status.trim().isNotEmpty) return offer.status;
  if (offer.isExpired) return 'Expired';
  if (offer.isActive) return 'Active';
  return 'Scheduled';
}

String _offerTypeDisplay(OfferModel offer) {
  final discount = offer.discount;
  if (discount == null || discount <= 0) {
    return offer.offerType;
  }
  final formatted = (discount % 1 == 0)
      ? discount.toInt().toString()
      : discount.toStringAsFixed(2);
  final isFlat = offer.offerType.trim().toLowerCase() == 'flat';
  return isFlat
      ? '${offer.offerType} (₹$formatted)'
      : '${offer.offerType} ($formatted%)';
}
