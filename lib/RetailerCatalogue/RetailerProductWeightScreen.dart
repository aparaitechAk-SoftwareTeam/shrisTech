// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../Stock Listing Module/StockApis.dart';
import '../Stock Listing Module/StockWidget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'RetailerProductListScreen.dart';

class RetailerProductWeightScreen extends StatefulWidget {
  final String productName;
  final List<ProductModel> products;

  const RetailerProductWeightScreen({
    super.key,
    required this.productName,
    required this.products,
  });

  @override
  State<RetailerProductWeightScreen> createState() =>
      _RetailerProductWeightScreenState();
}

class _RetailerProductWeightScreenState
    extends State<RetailerProductWeightScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final IStockRepository _repository = StockRepository.instance;

  late List<StockWeightGroup> _groups;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _groups = _repository.groupByWeight(widget.products);
  }

  @override
  void didUpdateWidget(covariant RetailerProductWeightScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _groups = _repository.groupByWeight(widget.products);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(selectedIndex: 1, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: 1,
        onTap: _handleFooterTap,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 650;
            final horizontalPadding = isTablet
                ? 28.0
                : (isCompact ? 12.0 : 16.0);
            final maxWidth = screenWidth >= 1100
                ? 1040.0
                : (screenWidth >= 700 ? 820.0 : screenWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _groups.isEmpty
                    ? StockEmptyWidget(
                        message: 'No stock exists for available net weights.',
                        onRetry: () async => setState(() {
                          _groups = _repository.groupByWeight(widget.products);
                        }),
                      )
                    : ListView.separated(
                        key: PageStorageKey<String>(
                          'retailer-weight-${widget.productName}',
                        ),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 10 : 14,
                          horizontalPadding,
                          28,
                        ),
                        itemCount: _groups.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: isCompact ? 10 : 12),
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return _RetailerWeightCard(
                            group: group,
                            isCompact: isCompact,
                            onTap: () => _openProductList(group),
                          );
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openProductList(StockWeightGroup group) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RetailerProductListScreen(
              productName: widget.productName,
              range: group.range,
              products: group.products,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _handleFooterTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 1:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.retailerCatalogue,
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.offers);
        break;
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.orderManagement);
        break;
      case 4:
        Navigator.of(context).pushNamed(AppRoutes.retailerCart);
        break;
      default:
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETAILER WEIGHT CARD (Responsive, High Contrast, Polished)
// ─────────────────────────────────────────────────────────────────────────────

class _RetailerWeightCard extends StatefulWidget {
  final StockWeightGroup group;
  final bool isCompact;
  final VoidCallback onTap;

  const _RetailerWeightCard({
    required this.group,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_RetailerWeightCard> createState() => _RetailerWeightCardState();
}

class _RetailerWeightCardState extends State<_RetailerWeightCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isCompact = widget.isCompact;
    final iconBoxSize = isCompact ? 44.0 : 50.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.98 : 1.0,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
              color: AppColors.surfaceWhite,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: AppColors.accentGoldGlow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1E4C), AppColors.primaryRoyalBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.scale_rounded,
                    color: AppColors.accentGold,
                    size: isCompact ? 19 : 22,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.range.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 14 : 15.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 9,
                          vertical: isCompact ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightBlue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderGold.withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          '${group.count} product${group.count == 1 ? '' : 's'}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryRoyalBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: isCompact ? 10.5 : 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: isCompact ? 28 : 32,
                  height: isCompact ? 28 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentGoldDark,
                    size: isCompact ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
