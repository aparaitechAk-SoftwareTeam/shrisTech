// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'OwnerOrderHistoryApis.dart';
import 'OwnerOrderHistoryWidgets.dart';

class OwnerOrderHistoryDetailScreen extends StatefulWidget {
  final OwnerHistoryOrderModel order;

  const OwnerOrderHistoryDetailScreen({super.key, required this.order});

  @override
  State<OwnerOrderHistoryDetailScreen> createState() =>
      _OwnerOrderHistoryDetailScreenState();
}

class _OwnerOrderHistoryDetailScreenState
    extends State<OwnerOrderHistoryDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _footerIndex = 4;
  int _drawerIndex = 5;

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushNamed(AppRoutes.ownerHome);
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
      setState(() => _footerIndex = 4);
      return;
    }
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    final images = widget.order.items
        .map((e) => e.image)
        .where((img) => img.isNotEmpty)
        .toList();

    if (images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenGalleryViewer(
          images: images,
          initialIndex: initialIndex.clamp(0, images.length - 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Order History Details',
      ),
      drawer: GlobalDrawer(
        selectedIndex: _drawerIndex,
        onItemSelected: (index) => setState(() => _drawerIndex = index),
      ),
      bottomNavigationBar: GlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 700;
            final pad = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
            final maxWidth = screenWidth >= 1100
                ? 1040.0
                : (screenWidth >= 700 ? 840.0 : screenWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: pad,
                    vertical: isCompact ? 12 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Order Header Card
                      _HeaderCard(order: order, isCompact: isCompact),
                      SizedBox(height: isCompact ? 12 : 20),

                      // 2. Order Status Progress Tracker
                      Container(
                        padding: EdgeInsets.all(isCompact ? 14 : 18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(
                            isCompact ? 18 : 22,
                          ),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Progress Lifecycle',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primaryRoyalBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: isCompact ? 14.5 : 16,
                              ),
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            OrderStatusProgressTracker(status: order.status),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 14 : 24),

                      // 4. Products List Section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order Items (${order.items.length})',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.primaryRoyalBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: isCompact ? 16 : 19,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 10 : 14),
                      Column(
                        children: List.generate(order.items.length, (index) {
                          final item = order.items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isCompact ? 10 : 14,
                            ),
                            child: _ProductItemCard(
                              item: item,
                              index: index,
                              isCompact: isCompact,
                              onImageTap: () =>
                                  _openFullScreenGallery(context, index),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: isCompact ? 14 : 24),

                      // 5. Audit Timeline Log
                      if (order.logs.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order Activity Log',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primaryRoyalBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: isCompact ? 16 : 19,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 10 : 14),
                        _TimelineWidget(logs: order.logs, isCompact: isCompact),
                      ],
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

class _HeaderCard extends StatelessWidget {
  final OwnerHistoryOrderModel order;
  final bool isCompact;

  const _HeaderCard({required this.order, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.primaryRoyalBlue,
        borderRadius: BorderRadius.circular(isCompact ? 20 : 26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimaryGlow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER #${order.orderNumber}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.surfaceWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: isCompact ? 17 : 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Retailer: ${order.ownerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.85,
                            ),
                            fontSize: isCompact ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 9 : 12,
                      vertical: isCompact ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.statusColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.surfaceWhite,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      order.status,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 10.5 : 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.remarks.trim().isNotEmpty) ...[
                SizedBox(height: isCompact ? 10 : 14),
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        color: AppColors.accentGold,
                        size: isCompact ? 14 : 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.remarks,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.surfaceWhite,
                            fontStyle: FontStyle.italic,
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final OwnerHistoryItemModel item;
  final int index;
  final bool isCompact;
  final VoidCallback onImageTap;

  const _ProductItemCard({
    required this.item,
    required this.index,
    required this.isCompact,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final imgSize = isCompact ? 68.0 : 84.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Hero
            GestureDetector(
              onTap: onImageTap,
              child: Hero(
                tag: 'item-img-$index-${item.productCode}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  child: SizedBox(
                    width: imgSize,
                    height: imgSize,
                    child: item.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primaryLightBlue,
                              child: const Icon(
                                Icons.diamond_rounded,
                                color: AppColors.accentGold,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryLightBlue,
                              child: const Icon(
                                Icons.diamond_rounded,
                                color: AppColors.accentGold,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryLightBlue,
                            child: Icon(
                              Icons.diamond_rounded,
                              color: AppColors.accentGold,
                              size: isCompact ? 26 : 32,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryRoyalBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                  if (item.productCode.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${item.productCode}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 10.5 : 12,
                      ),
                    ),
                  ],
                  SizedBox(height: isCompact ? 6 : 10),
                  Wrap(
                    spacing: isCompact ? 6 : 8,
                    runSpacing: 4,
                    children: [
                      _DetailTag('Qty: ${item.quantity}'),
                      _DetailTag(
                        'Gross: ${item.grossWeight.toStringAsFixed(2)}g',
                      ),
                      _DetailTag(
                        'Stone: ${item.stoneWeight.toStringAsFixed(2)}g',
                      ),
                      _DetailTag('Net: ${item.netWeight.toStringAsFixed(2)}g'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final String label;

  const _DetailTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.backgroundOffWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TimelineWidget extends StatelessWidget {
  final List<OwnerHistoryLogModel> logs;
  final bool isCompact;

  const _TimelineWidget({required this.logs, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(logs.length, (index) {
          final logItem = logs[index];
          final isLast = index == logs.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.borderGold.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                logItem.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primaryRoyalBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 13 : 14,
                                ),
                              ),
                            ),
                            if (logItem.date != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${logItem.date!.day}/${logItem.date!.month}/${logItem.date!.year}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: isCompact ? 10 : 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (logItem.message.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            logItem.message,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isCompact ? 11 : 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FullScreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGalleryViewer> createState() =>
      __FullScreenGalleryViewerState();
}

class __FullScreenGalleryViewerState extends State<_FullScreenGalleryViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Image ${_currentIndex + 1} of ${widget.images.length}',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 5),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
