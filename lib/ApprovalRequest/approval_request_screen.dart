import 'dart:async';

import 'package:flutter/material.dart';
import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'approved_retailer_apis.dart';
import 'approved_retailer_details_screen.dart';

class ApprovalRequestScreen extends StatefulWidget {
  const ApprovalRequestScreen({super.key});

  static const String routeName = '/approval_requests';

  @override
  State<ApprovalRequestScreen> createState() => _ApprovalRequestScreenState();
}

class _ApprovalRequestScreenState extends State<ApprovalRequestScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final IApprovedRetailerRepository _repository = ApprovedRetailerRepository();

  late final TabController _tabController;
  Timer? _debounce;

  List<PendingRequestModel> _pendingRequests = const [];
  List<ApprovedRetailerModel> _approvedRetailers = const [];

  bool _loadingPending = true;
  bool _loadingApproved = true;
  String? _pendingError;
  String? _approvedError;
  String _query = '';
  int _footerIndex = -1;
  final Set<String> _busyRequestIds = <String>{};
  final Set<String> _busyRetailerIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
    _searchController.addListener(_onSearchChanged);
    _loadPendingRequests();
    _loadApprovedRetailers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Manage approval requests',
      ),
      drawer: GlobalDrawer(
        selectedIndex: 1,
        onItemSelected: _handleDrawerNavigation,
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
            final horizontalPadding = isTablet
                ? 34.0
                : (isCompact ? 12.0 : 18.0);
            final maxWidth = screenWidth >= 1100 ? 1060.0 : screenWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 14 : 20,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SearchBar(
                            controller: _searchController,
                            onClear: _clearSearch,
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          _ApprovalTabBar(controller: _tabController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingTab(horizontalPadding),
                          _buildApprovedTab(horizontalPadding),
                        ],
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

  Widget _buildPendingTab(double horizontalPadding) {
    final items = _pendingRequests
        .where((request) => request.matches(_query))
        .toList(growable: false);

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      onRefresh: _loadPendingRequests,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loadingPending
            ? _SkeletonList(
                key: const ValueKey('pending-loading'),
                padding: horizontalPadding,
              )
            : _pendingError != null
            ? _StateView(
                key: const ValueKey('pending-error'),
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load requests',
                message: _pendingError!,
                buttonText: 'Retry',
                onPressed: _loadPendingRequests,
              )
            : items.isEmpty
            ? _StateView(
                key: const ValueKey('pending-empty'),
                icon: Icons.inbox_rounded,
                title: 'No Data',
                message: _query.isEmpty
                    ? 'No pending registration requests found.'
                    : 'No pending requests match your search.',
                buttonText: 'Retry',
                onPressed: _loadPendingRequests,
              )
            : ListView.separated(
                key: const ValueKey('pending-list'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  6,
                  horizontalPadding,
                  24,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final request = items[index];
                  return _PendingRequestCard(
                    request: request,
                    isBusy: _busyRequestIds.contains(request.requestId),
                    onTap: () => _openDetails(request.toDetails()),
                    onApprove: () => _approveRequest(request),
                    onReject: () => _rejectRequest(request),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildApprovedTab(double horizontalPadding) {
    final items = _approvedRetailers
        .where((retailer) => retailer.matches(_query))
        .toList(growable: false);

    return RefreshIndicator(
      color: AppColors.primaryRoyalBlue,
      onRefresh: _loadApprovedRetailers,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loadingApproved
            ? _SkeletonList(
                key: const ValueKey('approved-loading'),
                padding: horizontalPadding,
              )
            : _approvedError != null
            ? _StateView(
                key: const ValueKey('approved-error'),
                icon: Icons.wifi_off_rounded,
                title: 'Unable to load retailers',
                message: _approvedError!,
                buttonText: 'Retry',
                onPressed: _loadApprovedRetailers,
              )
            : items.isEmpty
            ? _StateView(
                key: const ValueKey('approved-empty'),
                icon: Icons.groups_rounded,
                title: 'No Data',
                message: _query.isEmpty
                    ? 'No active retailers found.'
                    : 'No approved retailers match your search.',
                buttonText: 'Retry',
                onPressed: _loadApprovedRetailers,
              )
            : ListView.separated(
                key: const ValueKey('approved-list'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  6,
                  horizontalPadding,
                  24,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final retailer = items[index];
                  return _ApprovedRetailerCard(
                    retailer: retailer,
                    isBusy: _busyRetailerIds.contains(retailer.id),
                    onTap: () => _openDetails(retailer.toDetails()),
                    onToggleStatus: () => _toggleRetailerStatus(retailer),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _loadPendingRequests() async {
    if (mounted) {
      setState(() {
        _loadingPending = true;
        _pendingError = null;
      });
    }

    try {
      final requests = await _repository.fetchPendingRequests();
      if (!mounted) return;
      setState(() => _pendingRequests = requests);
    } catch (error) {
      if (!mounted) return;
      setState(() => _pendingError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingPending = false);
    }
  }

  Future<void> _loadApprovedRetailers() async {
    if (mounted) {
      setState(() {
        _loadingApproved = true;
        _approvedError = null;
      });
    }

    try {
      final retailers = await _repository.fetchApprovedRetailers();
      if (!mounted) return;
      setState(() => _approvedRetailers = retailers);
    } catch (error) {
      if (!mounted) return;
      setState(() => _approvedError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingApproved = false);
    }
  }

  Future<void> _approveRequest(PendingRequestModel request) async {
    final requestId = request.requestId;
    if (requestId.isEmpty || _busyRequestIds.contains(requestId)) return;

    setState(() => _busyRequestIds.add(requestId));
    try {
      await _repository.approveRequest(requestId);
      if (!mounted) return;
      setState(() {
        _pendingRequests = _pendingRequests
            .where((item) => item.requestId != requestId)
            .toList(growable: false);
      });
      _showSnackBar(
        'Retailer registration request has been approved successfully.',
        success: true,
      );
      await Future.wait([_loadPendingRequests(), _loadApprovedRetailers()]);
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busyRequestIds.remove(requestId));
    }
  }

  Future<void> _rejectRequest(PendingRequestModel request) async {
    final requestId = request.requestId;
    if (requestId.isEmpty || _busyRequestIds.contains(requestId)) return;

    setState(() => _busyRequestIds.add(requestId));
    try {
      await _repository.rejectRequest(requestId);
      if (!mounted) return;
      setState(() {
        _pendingRequests = _pendingRequests
            .where((item) => item.requestId != requestId)
            .toList(growable: false);
      });
      _showSnackBar(
        'Retailer registration request has been rejected successfully.',
        success: true,
      );
      await _loadPendingRequests();
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busyRequestIds.remove(requestId));
    }
  }

  Future<void> _toggleRetailerStatus(ApprovedRetailerModel retailer) async {
    final targetId = retailer.id.isNotEmpty ? retailer.id : retailer.requestId;
    if (_busyRetailerIds.contains(targetId)) return;

    setState(() => _busyRetailerIds.add(targetId));
    try {
      final statusStr = retailer.accountStatus.isNotEmpty
          ? retailer.accountStatus.toLowerCase()
          : retailer.status.toLowerCase();
      final isActive = statusStr == 'active';
      final updated = isActive
          ? await _repository.deactivateRetailer(retailer)
          : await _repository.activateRetailer(retailer);
      if (!mounted) return;
      setState(() {
        _approvedRetailers = _approvedRetailers
            .map((item) {
              final isMatch =
                  item.id == retailer.id ||
                  (item.requestId.isNotEmpty &&
                      item.requestId == retailer.requestId);
              return isMatch ? updated : item;
            })
            .toList(growable: false);
      });
      _showSnackBar(
        isActive
            ? 'Retailer registration request has been deactivated successfully.'
            : 'Retailer registration request has been activated successfully.',
        success: true,
      );
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busyRetailerIds.remove(targetId));
    }
  }

  void _openDetails(RetailerDetailsData retailer) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ApprovedRetailerDetailsScreen(retailer: retailer);
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
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = _searchController.text);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  void _handleDrawerNavigation(int index) {
    if (index == 0) return;
    _showSnackBar('This section will be connected soon.', success: true);
  }

  void _handleFooterNavigation(int index) {
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
    return 'Something went wrong. Please try again.';
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? AppColors.accentGold : AppColors.surfaceWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Container(
          height: isCompact ? 48 : 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 13 : 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceWhite,
              hintText: isCompact
                  ? 'Search retailer requests'
                  : 'Search owner, business, email, mobile or ID',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: isCompact ? 12.5 : 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryRoyalBlue,
                size: isCompact ? 20 : 22,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 12 : 14,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApprovalTabBar extends StatelessWidget {
  final TabController controller;

  const _ApprovalTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      height: isCompact ? 46 : 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.surfaceWhite,
        unselectedLabelColor: AppColors.primaryRoyalBlue,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: isCompact ? 12.5 : 14,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: isCompact ? 12.5 : 14,
        ),
        indicator: BoxDecoration(
          color: AppColors.primaryRoyalBlue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowPrimaryGlow,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        tabs: const [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('New Requests'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Approved Retailers'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatefulWidget {
  final PendingRequestModel request;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.request,
    required this.isBusy,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return _PressableCard(
      pressed: _pressed,
      onTap: widget.onTap,
      onTapDown: () => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: () => setState(() => _pressed = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RetailerCardHeader(
            initials: _initials(widget.request.ownerName),
            title: widget.request.ownerName,
            subtitle: widget.request.businessName,
            badgeText: 'Pending',
          ),
          SizedBox(height: isCompact ? 12 : 16),
          _RetailerInfoWrap(
            userId: widget.request.userId,
            email: widget.request.email,
            mobile: widget.request.mobileNumber,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  isBusy: widget.isBusy,
                  isPrimary: false,
                  onPressed: widget.isBusy ? null : widget.onReject,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  isBusy: widget.isBusy,
                  isPrimary: true,
                  onPressed: widget.isBusy ? null : widget.onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovedRetailerCard extends StatefulWidget {
  final ApprovedRetailerModel retailer;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _ApprovedRetailerCard({
    required this.retailer,
    required this.isBusy,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  State<_ApprovedRetailerCard> createState() => _ApprovedRetailerCardState();
}

class _ApprovedRetailerCardState extends State<_ApprovedRetailerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final statusStr = widget.retailer.accountStatus.isNotEmpty
        ? widget.retailer.accountStatus.toLowerCase()
        : widget.retailer.status.toLowerCase();
    final isActive = statusStr == 'active';

    return _PressableCard(
      pressed: _pressed,
      onTap: widget.onTap,
      onTapDown: () => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: () => setState(() => _pressed = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RetailerCardHeader(
            initials: _initials(widget.retailer.ownerName),
            title: widget.retailer.ownerName,
            subtitle: widget.retailer.businessName,
            badgeText: widget.retailer.accountStatus.isEmpty
                ? widget.retailer.status
                : widget.retailer.accountStatus,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          _RetailerInfoWrap(
            userId: widget.retailer.userId,
            email: widget.retailer.email,
            mobile: widget.retailer.mobileNumber,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: isCompact ? double.infinity : (isTablet ? 220 : 180),
              child: _ActionButton(
                label: isActive ? 'Deactivate' : 'Activate',
                icon: isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded,
                isBusy: widget.isBusy,
                isPrimary: !isActive,
                onPressed: widget.isBusy ? null : widget.onToggleStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PressableCard extends StatelessWidget {
  final bool pressed;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback onTapUp;

  const _PressableCard({
    required this.pressed,
    required this.child,
    required this.onTap,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: pressed ? 0.985 : 1,
      child: Card(
        elevation: 6,
        shadowColor: AppColors.shadowPrimaryGlow.withValues(alpha: 0.12),
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) => onTapDown(),
          onTapCancel: onTapCancel,
          onTapUp: (_) => onTapUp(),
          child: CustomPaint(
            painter: _ApprovalCardCornerPainter(),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _RetailerCardHeader extends StatelessWidget {
  final String initials;
  final String title;
  final String subtitle;
  final String badgeText;

  const _RetailerCardHeader({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isCompact ? 22 : 26,
          backgroundColor: AppColors.primaryLightBlue,
          child: Text(
            initials,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryRoyalBlue,
              fontWeight: FontWeight.w900,
              fontSize: isCompact ? 13 : 15,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 10 : 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Retailer' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 14.5 : 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle.isEmpty ? 'Business details unavailable' : subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 12 : 13.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusPill(text: badgeText),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentGoldSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Text(
        text.isEmpty ? 'N/A' : text,
        style: AppTypography.caption.copyWith(
          color: AppColors.accentGoldDark,
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 10.5 : 11.5,
        ),
      ),
    );
  }
}

class _RetailerInfoWrap extends StatelessWidget {
  final String userId;
  final String email;
  final String mobile;

  const _RetailerInfoWrap({
    required this.userId,
    required this.email,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.badge_rounded, label: userId),
        _InfoChip(icon: Icons.phone_rounded, label: mobile),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      constraints: BoxConstraints(maxWidth: isCompact ? 220 : 280),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 11,
        vertical: isCompact ? 6 : 7.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLightBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryRoyalBlue,
            size: isCompact ? 14 : 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.isEmpty ? 'N/A' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isBusy;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.surfaceWhite,
              ),
            )
          : Icon(icon, size: isCompact ? 16 : 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size(0, isCompact ? 42 : 46),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14),
        backgroundColor: isPrimary
            ? AppColors.primaryRoyalBlue
            : AppColors.surfaceWhite,
        foregroundColor: isPrimary
            ? AppColors.surfaceWhite
            : AppColors.primaryRoyalBlue,
        disabledBackgroundColor: isPrimary
            ? AppColors.primaryRoyalBlue
            : AppColors.surfaceWhite,
        disabledForegroundColor: isPrimary
            ? AppColors.surfaceWhite
            : AppColors.primaryRoyalBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isPrimary
                ? AppColors.primaryRoyalBlue
                : AppColors.borderGold,
          ),
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final double padding;

  const _SkeletonList({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(padding, 6, padding, 24),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(
                width: isCompact ? 44 : 52,
                height: isCompact ? 44 : 52,
                radius: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 140, height: 14),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 190, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SkeletonBox(width: double.infinity, height: 36, radius: 12),
          const SizedBox(height: 12),
          const _SkeletonBox(width: double.infinity, height: 42, radius: 14),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primaryLightBlue,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Future<void> Function() onPressed;

  const _StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final iconBoxSize = isCompact ? 86.0 : (isTablet ? 120.0 : 104.0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(20, isCompact ? 32 : 46, 20, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryRoyalBlue,
                    size: isCompact ? 40 : 50,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primaryRoyalBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 17 : 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: isCompact ? 150 : 180,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final letters = words.take(2).map((word) => word.substring(0, 1)).join();
  return letters.isEmpty ? 'BG' : letters.toUpperCase();
}

class _ApprovalCardCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Concentric circles at the top right corner
    final topRightCenter = Offset(size.width - 10, 10);
    paint.color = AppColors.accentGold.withValues(alpha: 0.18);
    canvas.drawCircle(topRightCenter, 45, paint);
    canvas.drawCircle(topRightCenter, 70, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentGold.withValues(alpha: 0.04);
    canvas.drawCircle(topRightCenter, 45, fillPaint);

    // 2. Linear curves / Line pattern in bottom left corner
    final path = Path();
    paint.color = AppColors.primaryRoyalBlue.withValues(alpha: 0.1);
    paint.strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final offset = i * 15.0;
      path.reset();
      path.moveTo(0, size.height - 80 - offset);
      path.quadraticBezierTo(
        40 + offset,
        size.height - 40 - offset,
        80 + offset,
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    final solidGoldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentGold.withValues(alpha: 0.08);
    canvas.drawCircle(topRightCenter, 15, solidGoldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
