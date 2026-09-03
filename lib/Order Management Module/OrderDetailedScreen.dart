// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'OrderApis.dart';
import 'OrderWidgets.dart';

class OrderDetailedScreen extends StatefulWidget {
  final OrderModel order;
  final bool isOwner;
  final IOrderRepository repository;

  const OrderDetailedScreen({
    super.key,
    required this.order,
    required this.isOwner,
    required this.repository,
  });

  @override
  State<OrderDetailedScreen> createState() => _OrderDetailedScreenState();
}

class _OrderDetailedScreenState extends State<OrderDetailedScreen> {
  late OrderModel _order;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _imageIndex = 0;
  bool _loadingAction = false;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _order.primaryItem;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      drawer: widget.isOwner
          ? const GlobalDrawer(selectedIndex: 4, onItemSelected: null)
          : const RetailerGlobalDrawer(selectedIndex: 3, onItemSelected: null),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          backgroundColor: AppColors.surfaceWhite,
          onRefresh: _loadDetail,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: _loadingDetail
                ? const _OrderDetailShimmer(
                    key: ValueKey('order-detail-shimmer'),
                  )
                : LayoutBuilder(
                    key: ValueKey(
                      'order-detail-body-${_order.id}-${_order.status}',
                    ),
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final isCompact = screenWidth < 360;
                      final isTablet = screenWidth >= 700;
                      final pad = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
                      final maxWidth = screenWidth >= 1100
                          ? 760.0
                          : (screenWidth >= 700 ? 680.0 : screenWidth);

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  pad,
                                  isCompact ? 10 : 14,
                                  pad,
                                  isCompact ? 20 : 30,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _ImageCarousel(
                                      order: _order,
                                      controller: _pageController,
                                      index: _imageIndex,
                                      isCompact: isCompact,
                                      isTablet: isTablet,
                                      onChanged: (index) =>
                                          setState(() => _imageIndex = index),
                                      onImageTap: _openZoom,
                                    ),
                                    SizedBox(height: isCompact ? 8 : 10),
                                    _Section(
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
                                                child: Text(
                                                  item.productName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography
                                                      .titleLarge
                                                      .copyWith(
                                                        color: AppColors
                                                            .primaryRoyalBlue,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: isCompact
                                                            ? 17
                                                            : 20,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              StatusBadge(
                                                status: _order.status,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isCompact ? 6 : 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Order ${_order.orderNumber} • ${formatDate(_order.orderDate)}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: isCompact
                                                            ? 12.5
                                                            : 14,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isCompact
                                                      ? 8
                                                      : 10,
                                                  vertical: isCompact ? 3 : 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .primaryLightBlue,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: AppColors.borderGold
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Qty: ${item.quantity == 0 ? 'N/A' : item.quantity}',
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .primaryRoyalBlue,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: isCompact
                                                            ? 11
                                                            : 12.5,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (widget.isOwner) ...[
                                            SizedBox(height: isCompact ? 6 : 8),
                                            Text(
                                              '${_order.retailer.shopName} • ${_order.retailer.ownerName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textMuted,
                                                    fontSize: isCompact
                                                        ? 11.5
                                                        : 13,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isCompact ? 8 : 10),
                                    GridView.count(
                                      crossAxisCount: isTablet ? 4 : 2,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: isCompact ? 8 : 10,
                                      mainAxisSpacing: isCompact ? 8 : 10,
                                      childAspectRatio: isTablet
                                          ? 1.55
                                          : (isCompact ? 2.4 : 2.6),
                                      children: [
                                        StatisticCard(
                                          label: 'Gross Weight',
                                          value: formatWeight(item.grossWeight),
                                          icon: Icons.scale_rounded,
                                        ),
                                        StatisticCard(
                                          label: 'Stone Weight',
                                          value: formatWeight(item.stoneWeight),
                                          icon: Icons.diamond_rounded,
                                        ),
                                        StatisticCard(
                                          label: 'Net Weight',
                                          value: formatWeight(item.netWeight),
                                          icon: Icons.monitor_weight_rounded,
                                        ),
                                        StatisticCard(
                                          label: 'Stone Charge',
                                          value: item.stoneCharge == null
                                              ? 'N/A'
                                              : item.stoneCharge!
                                                    .toStringAsFixed(2),
                                          icon: Icons.payments_rounded,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isCompact ? 8 : 10),
                                    _Section(
                                      title: 'Status Timeline',
                                      isCompact: isCompact,
                                      child: TimelineWidget(
                                        status: _order.status,
                                      ),
                                    ),
                                    SizedBox(height: isCompact ? 8 : 10),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (widget.isOwner) {
      return GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Order ${_order.orderNumber}',
      );
    }
    return RetailerGlobalAppbar(
      onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final latest = widget.isOwner
          ? await widget.repository.fetchOwnerOrderDetails(
              _order.id,
              forceRefresh: true,
            )
          : await widget.repository.fetchRetailerOrderDetails(
              _order.id,
              forceRefresh: true,
            );
      if (!mounted) return;
      if (latest.id.isNotEmpty) setState(() => _order = latest);
    } catch (_) {
      // The list payload is enough to render; detail fetch errors should not block the screen.
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _confirmAndUpdate(String status) async {
    final allowed = widget.isOwner
        ? canOwnerTransition(_order.status, status)
        : canRetailerTransition(_order.status, status);
    if (!allowed || _loadingAction) return;
    final reason = status == 'Rejected' ? await _reasonDialog() : null;
    if (status == 'Rejected' && reason == null) return;
    final confirmed = status == 'Rejected'
        ? true
        : await _confirmDialog(status);
    if (confirmed != true) return;
    final previous = _order;
    setState(() {
      _loadingAction = true;
      _order = _order.copyWith(
        status: status,
        rejectedReason: reason ?? _order.rejectedReason,
      );
    });
    try {
      final updated = widget.isOwner
          ? await widget.repository.updateOwnerOrderStatus(
              previous.id,
              status,
              rejectedReason: reason,
            )
          : status == 'Cancelled'
          ? await widget.repository.cancelRetailerOrder(previous.id)
          : await widget.repository.markRetailerDelivered(previous.id);
      if (!mounted) return;
      if (updated.id.isNotEmpty) {
        final isSparse =
            updated.orderNumber == 'N/A' ||
            updated.primaryItem.productName == 'N/A';
        setState(() {
          if (isSparse) {
            _order = _order.copyWith(
              status: updated.status,
              rejectedReason: updated.rejectedReason.isNotEmpty
                  ? updated.rejectedReason
                  : _order.rejectedReason,
              cancelledReason: updated.cancelledReason.isNotEmpty
                  ? updated.cancelledReason
                  : _order.cancelledReason,
              history: updated.history.isNotEmpty
                  ? updated.history
                  : _order.history,
            );
          } else {
            _order = updated;
          }
        });
      }
      _snack(
        'Order status updated to ${normalizeOrderStatus(status)}.',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _order = previous);
      _snack(
        error is ApiException
            ? error.message
            : 'Unable to update order status.',
      );
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  Future<bool?> _confirmDialog(String status) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${status == 'Dispatched' ? 'Dispatch' : status} Order?'),
      content: Text(
        'This will update the order status to ${normalizeOrderStatus(status)}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  Future<String?> _reasonDialog() {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _openZoom() {
    final images = _order.images.isEmpty ? [''] : _order.images;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImageZoomScreen(
          images: images,
          initialIndex: _imageIndex,
          heroTag: 'order-${_order.id}-image',
        ),
      ),
    );
  }

  void _snack(String message, {bool success = false}) {
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

class _ImageCarousel extends StatelessWidget {
  final OrderModel order;
  final PageController controller;
  final int index;
  final bool isCompact;
  final bool isTablet;
  final ValueChanged<int> onChanged;
  final VoidCallback onImageTap;

  const _ImageCarousel({
    required this.order,
    required this.controller,
    required this.index,
    required this.isCompact,
    required this.isTablet,
    required this.onChanged,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = order.images.isEmpty ? [''] : order.images;
    final aspectRatio = isTablet ? (16 / 9) : (isCompact ? 1.25 : 1.15);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          Hero(
            tag: 'order-${order.id}-image',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
              child: PageView.builder(
                controller: controller,
                itemCount: images.length,
                onPageChanged: onChanged,
                itemBuilder: (context, i) {
                  final image = images[i];
                  return GestureDetector(
                    onTap: onImageTap,
                    child: image.isEmpty
                        ? Container(
                            color: AppColors.primaryLightBlue,
                            child: Icon(
                              Icons.diamond_rounded,
                              color: AppColors.accentGold,
                              size: isCompact ? 54 : 72,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerBox(),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryLightBlue,
                              child: Icon(
                                Icons.refresh_rounded,
                                color: AppColors.accentGold,
                                size: isCompact ? 32 : 42,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: isCompact ? 8 : 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == index ? (isCompact ? 16 : 22) : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.accentGold
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool isCompact;

  const _Section({this.title, required this.child, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w900,
                fontSize: isCompact ? 14.5 : 16,
              ),
            ),
            SizedBox(height: isCompact ? 10 : 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _ImageZoomScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTag;

  const _ImageZoomScreen({
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  @override
  State<_ImageZoomScreen> createState() => _ImageZoomScreenState();
}

class _ImageZoomScreenState extends State<_ImageZoomScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _previousImage() {
    if (_currentIndex <= 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextImage() {
    if (_currentIndex >= widget.images.length - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? [''] : widget.images;
    final hasMultiple = images.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: hasMultiple
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
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
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Hero(
            tag: widget.heroTag,
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final image = images[index];
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: Center(
                    child: image.isEmpty
                        ? const Icon(
                            Icons.diamond_rounded,
                            color: AppColors.accentGold,
                            size: 96,
                          )
                        : CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentGold,
                              ),
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
          ),
          if (hasMultiple) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white30,
                  ),
                  onPressed: _currentIndex == 0 ? null : _previousImage,
                  icon: const Icon(Icons.chevron_left_rounded, size: 32),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white30,
                  ),
                  onPressed: _currentIndex == images.length - 1
                      ? null
                      : _nextImage,
                  icon: const Icon(Icons.chevron_right_rounded, size: 32),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderDetailShimmer extends StatelessWidget {
  const _OrderDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isTablet = screenWidth >= 700;
        final pad = isTablet ? 34.0 : (isCompact ? 12.0 : 18.0);
        final maxWidth = screenWidth >= 1100
            ? 760.0
            : (screenWidth >= 700 ? 680.0 : screenWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                pad,
                isCompact ? 10 : 14,
                pad,
                isCompact ? 20 : 30,
              ),
              children: [
                Shimmer.fromColors(
                  baseColor: const Color(0xFFE5E7EB),
                  highlightColor: AppColors.surfaceWhite,
                  child: AspectRatio(
                    aspectRatio: isTablet
                        ? (16 / 9)
                        : (isCompact ? 1.25 : 1.15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(
                          isCompact ? 18 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Shimmer.fromColors(
                  baseColor: const Color(0xFFE5E7EB),
                  highlightColor: AppColors.surfaceWhite,
                  child: Container(
                    height: isCompact ? 84 : 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                GridView.count(
                  crossAxisCount: isTablet ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: isCompact ? 8 : 10,
                  mainAxisSpacing: isCompact ? 8 : 10,
                  childAspectRatio: isTablet ? 1.55 : (isCompact ? 2.4 : 2.6),
                  children: List.generate(
                    4,
                    (index) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE5E7EB),
                      highlightColor: AppColors.surfaceWhite,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            isCompact ? 14 : 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Shimmer.fromColors(
                  baseColor: const Color(0xFFE5E7EB),
                  highlightColor: AppColors.surfaceWhite,
                  child: Container(
                    height: isCompact ? 100 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Shimmer.fromColors(
                  baseColor: const Color(0xFFE5E7EB),
                  highlightColor: AppColors.surfaceWhite,
                  child: Container(
                    height: isCompact ? 54 : 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
