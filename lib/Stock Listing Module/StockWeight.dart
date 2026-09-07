// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'StockApis.dart';
import 'StockProductList.dart';
import 'StockWidget.dart';

class StockWeightScreen extends StatefulWidget {
  final String productName;
  final List<ProductModel> products;

  const StockWeightScreen({
    super.key,
    required this.productName,
    required this.products,
  });

  @override
  State<StockWeightScreen> createState() => _StockWeightScreenState();
}

class _StockWeightScreenState extends State<StockWeightScreen>
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
  void didUpdateWidget(covariant StockWeightScreen oldWidget) {
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
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: StockStrings.title,
      ),
      drawer: GlobalDrawer(selectedIndex: 3, onItemSelected: (_) {}),
      bottomNavigationBar: GlobalFooter(
        currentIndex: 1,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isCompact = screenWidth < 360;
            final isTablet = screenWidth >= 700;
            final horizontalPadding = isTablet
                ? 34.0
                : (isCompact ? 12.0 : 18.0);
            final maxWidth = screenWidth >= 1100
                ? 1040.0
                : (screenWidth >= 700 ? 840.0 : screenWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    SizedBox(height: 5),
                    Expanded(
                      child: _groups.isEmpty
                          ? StockEmptyWidget(
                              message:
                                  'No stock exists for available net weights.',
                              onRetry: () async {
                                setState(() {
                                  _groups = _repository.groupByWeight(
                                    widget.products,
                                  );
                                });
                              },
                            )
                          : ListView.separated(
                              key: PageStorageKey<String>(
                                'stock-weight-${widget.productName}',
                              ),
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                isCompact ? 4 : 6,
                                horizontalPadding,
                                isCompact ? 20 : 24,
                              ),
                              itemCount: _groups.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: isCompact ? 10 : 14),
                              itemBuilder: (context, index) {
                                final group = _groups[index];
                                return StockWeightCard(
                                  group: group,
                                  onTap: () => _openProductList(group),
                                );
                              },
                            ),
                    ),
                  ],
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
        pageBuilder: (context, animation, secondaryAnimation) {
          return StockProductListScreen(
            productName: widget.productName,
            range: group.range,
            products: group.products,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) return;
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
  }
}
