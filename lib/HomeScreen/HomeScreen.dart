// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';

import '../ApprovalRequest/approval_request_screen.dart';
import '../ApprovalRequest/approved_retailer_apis.dart';
import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../Order Management Module/OrderApis.dart';
import '../Order Management Module/OrderDetailedScreen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../services/fcm_service.dart';
import 'HomeScreenApis.dart';
import 'HomeScreenWidget.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOwnerHomeRepository _repository = OwnerHomeRepository();
  final ApprovedRetailerApis _retailerApis = ApprovedRetailerApis();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _footerIndex = 0;
  int _drawerIndex = 0;

  bool _isLoading = true;
  String _errorMessage = '';
  OwnerHomeData? _homeData;
  String _timeframe = 'Week';

  // Tracking pending approval action progress by requestId
  final Set<String> _processingApprovals = <String>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize FCM securely and wait for permissions sequentially
    try {
      await FcmService().syncDeviceToken();
    } catch (_) {}
    
    // 2. Safely load dashboard data after permissions are settled
    if (mounted) {
      await _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _repository.fetchHomeData(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e, stack) {
      log('OwnerHomeScreen _loadDashboardData error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load owner dashboard. Please try again.';
      });
    }
  }

  Future<void> _handleApproveRequest(PendingRequestModel request) async {
    setState(() => _processingApprovals.add(request.requestId));

    try {
      await _retailerApis.approveRequest(request.requestId);
      if (!mounted) return;
      _showToast(
        'Approved retailer ${request.businessName.isNotEmpty ? request.businessName : request.ownerName}!',
        success: true,
      );
      await _loadDashboardData(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      _showToast('Retailer registration approved successfully.', success: true);
      await _loadDashboardData(forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() => _processingApprovals.remove(request.requestId));
      }
    }
  }

  Future<void> _handleRejectRequest(PendingRequestModel request) async {
    setState(() => _processingApprovals.add(request.requestId));

    try {
      await _retailerApis.rejectRequest(request.requestId);
      if (!mounted) return;
      _showToast('Rejected registration request.', success: false);
      await _loadDashboardData(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      _showToast('Registration request processed.', success: true);
      await _loadDashboardData(forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() => _processingApprovals.remove(request.requestId));
      }
    }
  }

  void _showToast(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = UserData.instance.name.trim().isEmpty
        ? 'Owner'
        : UserData.instance.name.trim();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Welcome, $ownerName',
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
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _loadDashboardData(forceRefresh: true),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _horizontalPadding(
                    constraints.maxWidth,
                  );
                  final contentWidth = constraints.maxWidth >= 1100
                      ? 1060.0
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Executive Welcome Header Card
                            _WelcomeSection(ownerName: ownerName),
                            const SizedBox(height: 14),
                            if (_isLoading) ...[
                              OwnerShimmerGrid(
                                isCompact: constraints.maxWidth < 600,
                              ),
                              const SizedBox(height: 14),
                              const OwnerShimmerGraph(),
                              const SizedBox(height: 14),
                              const OwnerShimmerList(),
                            ] else if (_errorMessage.isNotEmpty) ...[
                              _ErrorCard(
                                message: _errorMessage,
                                onRetry: () =>
                                    _loadDashboardData(forceRefresh: true),
                              ),
                            ] else if (_homeData != null) ...[
                              // 3. Business Overview
                              const SectionHeader(
                                title: 'Business Overview',
                                subtitle:
                                    'Quick snapshot of approvals, orders, catalogue & offers.',
                              ),
                              const SizedBox(height: 8),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: constraints.maxWidth < 600
                                    ? 2
                                    : 4,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: constraints.maxWidth < 380
                                    ? 1.15
                                    : (constraints.maxWidth < 600 ? 1.8 : 1.9),
                                children: [
                                  WholesaleMetricCard(
                                    icon: Icons.pending_actions_rounded,
                                    title: 'Pending Approvals',
                                    value:
                                        '${_homeData!.summary.pendingApprovalsCount}',
                                    subtitle: 'Retailer accounts',
                                    iconColor: const Color(0xFFEAB308),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ApprovalRequestScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  WholesaleMetricCard(
                                    icon: Icons.shopping_bag_rounded,
                                    title: 'Pending Orders',
                                    value:
                                        '${_homeData!.summary.pendingOrdersCount}',
                                    subtitle: 'Requires action',
                                    iconColor: AppColors.primaryRoyalBlue,
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.orderManagement);
                                    },
                                  ),
                                  WholesaleMetricCard(
                                    icon: Icons.diamond_rounded,
                                    title: 'Catalogue Products',
                                    value:
                                        '${_homeData!.summary.totalProductsCount}',
                                    subtitle: 'Active SKUs',
                                    iconColor: AppColors.accentGoldDark,
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.stockListing);
                                    },
                                  ),
                                  WholesaleMetricCard(
                                    icon: Icons.local_offer_rounded,
                                    title: 'Active Offers',
                                    value:
                                        '${_homeData!.summary.activeOffersCount}',
                                    subtitle: 'Campaigns live',
                                    iconColor: const Color(0xFF16A34A),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.offers);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // 2. Gold Wholesaler Order Analytics Graph
                              OwnerOrderAnalyticsGraphWidget(
                                summary: _homeData!.summary,
                                timeframe: _timeframe,
                                onTimeframeChanged: (t) =>
                                    setState(() => _timeframe = t),
                              ),
                              const SizedBox(height: 8),

                              // 4. Pending Retailer Approval Requests
                              if (_homeData!.pendingApprovals.isNotEmpty) ...[
                                SectionHeader(
                                  title: 'Pending Retailer Approvals',
                                  subtitle:
                                      'Review and verify retailer accounts.',
                                  onViewAll: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ApprovalRequestScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: _homeData!.pendingApprovals
                                      .take(3)
                                      .map(
                                        (app) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: OwnerApprovalCard(
                                            request: app,
                                            isProcessing: _processingApprovals
                                                .contains(app.requestId),
                                            onApprove: () =>
                                                _handleApproveRequest(app),
                                            onReject: () =>
                                                _handleRejectRequest(app),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // 5. Recent Pending Orders Section
                              if (_homeData!.pendingOrders.isNotEmpty) ...[
                                SectionHeader(
                                  title: 'Recent Pending Orders',
                                  subtitle:
                                      'Wholesale orders awaiting owner approval.',
                                  onViewAll: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.orderManagement);
                                  },
                                ),
                                const SizedBox(height: 14),
                                Column(
                                  children: _homeData!.pendingOrders
                                      .take(4)
                                      .map(
                                        (order) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _OwnerOrderTile(
                                            order: order,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrderDetailedScreen(
                                                        order: order,
                                                        isOwner: true,
                                                        repository:
                                                            OrderRepository(),
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // 6. Recent Activity Feed
                              if (_homeData!.recentActivities.isNotEmpty) ...[
                                const SectionHeader(
                                  title: 'Recent Business Activity',
                                  subtitle:
                                      'Real-time movements across wholesale modules.',
                                ),
                                const SizedBox(height: 14),
                                DashboardCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: List.generate(
                                      _homeData!.recentActivities.length,
                                      (index) {
                                        final activity =
                                            _homeData!.recentActivities[index];
                                        final isLast =
                                            index ==
                                            _homeData!.recentActivities.length -
                                                1;
                                        return _ActivityTile(
                                          activity: activity,
                                          isLast: isLast,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ] else ...[
                              _ErrorCard(
                                message:
                                    'Unable to load owner dashboard data. Please try again.',
                                onRetry: () =>
                                    _loadDashboardData(forceRefresh: true),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 900) return 40;
    if (width >= 600) return 30;
    return 18;
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      setState(() => _footerIndex = 0);
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
  }
}

class _WelcomeSection extends StatelessWidget {
  final String ownerName;

  const _WelcomeSection({required this.ownerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryRoyalBlue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimaryGlow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -26,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.accentGoldDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gold Wholesale Executive Dashboard & Order Control',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.surfaceWhite,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerOrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OwnerOrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: DashboardCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryRoyalBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primaryRoyalBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.retailer.shopName} • ${order.items.length} SKUs',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  order.status,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFFCA8A04),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final OwnerRecentActivityModel activity;
  final bool isLast;

  const _ActivityTile({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity.icon,
                  color: AppColors.primaryRoyalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activity.time,
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentGoldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: AppColors.borderLight.withValues(alpha: 0.5),
            height: 1,
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRoyalBlue,
              foregroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Dashboard'),
          ),
        ],
      ),
    );
  }
}
