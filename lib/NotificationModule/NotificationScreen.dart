// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../OwnerProfile/OwnerProfileWidgets.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../models/notification_models.dart';
import '../navigation/app_routes.dart';
import '../services/notification_service.dart';

enum NotificationFilter { all, unread, orders, system }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  NotificationFilter _selectedFilter = NotificationFilter.all;
  int _footerIndex = 0;

  bool get _isOwner => UserData.instance.role.trim().toLowerCase() == 'owner';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _fetchNotifications();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _notificationService.fetchNotifications();
      if (!mounted) return;

      setState(() {
        _notifications = response.notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMarkAllRead() async {
    HapticFeedback.mediumImpact();
    setState(() => _isMarkingAllRead = true);

    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _isMarkingAllRead = false;
      });
      _showSnackBar('All notifications marked as read.', success: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _isMarkingAllRead = false;
      });
    }
  }

  Future<void> _handleMarkSingleRead(NotificationModel item) async {
    if (item.isRead) return;
    HapticFeedback.lightImpact();

    await _notificationService.markAsRead(item.id);
    if (!mounted) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  List<NotificationModel> get _filteredNotifications {
    final query = _searchController.text.trim().toLowerCase();

    return _notifications.where((n) {
      if (_isOwner && n.roleTarget == 'retailer') return false;
      if (!_isOwner && n.roleTarget == 'owner') return false;

      if (_selectedFilter == NotificationFilter.unread && n.isRead) {
        return false;
      }
      if (_selectedFilter == NotificationFilter.orders &&
          !n.type.toLowerCase().contains('order')) {
        return false;
      }
      if (_selectedFilter == NotificationFilter.system &&
          (n.type.toLowerCase().contains('order') ||
              n.type.toLowerCase().contains('promo'))) {
        return false;
      }

      if (query.isNotEmpty) {
        final titleMatches = n.title.toLowerCase().contains(query);
        final msgMatches = n.message.toLowerCase().contains(query);
        final refMatches = (n.referenceId ?? '').toLowerCase().contains(query);
        return titleMatches || msgMatches || refMatches;
      }

      return true;
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: _isOwner
          ? GlobalAppbar(
              onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
              subtitle: 'Notifications',
            )
          : RetailerGlobalAppbar(
              onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      drawer: _isOwner
          ? GlobalDrawer(selectedIndex: 0, onItemSelected: (_) {})
          : RetailerGlobalDrawer(selectedIndex: 0, onItemSelected: (_) {}),
      // bottomNavigationBar: _isOwner
      //     ? GlobalFooter(
      //         currentIndex: _footerIndex,
      //         onTap: _handleFooterNavigation,
      //       )
      //     : RetailerGlobalFooter(
      //         currentIndex: _footerIndex,
      //         onTap: _handleFooterNavigation,
      //       ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _fetchNotifications(forceRefresh: true),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 700
                  ? 34.0
                  : 18.0;
              final maxWidth = constraints.maxWidth >= 1100
                  ? 1040.0
                  : constraints.maxWidth;

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
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // _buildHeaderBanner(),
                                // const SizedBox(height: 18),
                                _buildSearchBar(),
                                const SizedBox(height: 6),
                                _buildFilterChips(),
                                const SizedBox(height: 4),
                                _buildNotificationList(),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDarkBlue, AppColors.primaryRoyalBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimaryGlow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.accentGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isOwner
                          ? 'Owner Activity Feed'
                          : 'Retailer Notifications',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadCount NEW',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDarkBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _unreadCount > 0
                      ? 'You have $_unreadCount unread updates pending.'
                      : 'All notifications are up to date.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'Mark All as Read',
              onPressed: _isMarkingAllRead ? null : _handleMarkAllRead,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceWhite.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentGold,
              ),
              icon: _isMarkingAllRead
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentGold,
                      ),
                    )
                  : const Icon(Icons.done_all_rounded, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search product name, order ID, or notification...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryRoyalBlue,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            'All (${_notifications.length})',
            NotificationFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Unread ($_unreadCount)', NotificationFilter.unread),
          const SizedBox(width: 8),
          _buildFilterChip('Orders', NotificationFilter.orders),
          const SizedBox(width: 8),
          _buildFilterChip('System / Approvals', NotificationFilter.system),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filter);
      },
      selectedColor: AppColors.primaryRoyalBlue,
      backgroundColor: AppColors.surfaceCardSubtle,
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryRoyalBlue : AppColors.borderSubtle,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading) {
      return const SkeletonLoader(itemCount: 4);
    }

    final filtered = _filteredNotifications;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLightBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 40,
                color: AppColors.primaryRoyalBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications Found',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No matching notifications found for "${_searchController.text}".'
                  : 'You are all caught up!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _NotificationCard(
          item: item,
          onTap: () => _handleMarkSingleRead(item),
        );
      },
    );
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        _isOwner ? AppRoutes.ownerHome : AppRoutes.retailerHome,
        (route) => false,
      );
      return;
    }
    setState(() => _footerIndex = index);
    _showSnackBar('Section will be connected soon.');
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    return Card(
      elevation: isUnread ? 6 : 1,
      shadowColor: isUnread
          ? AppColors.shadowPrimaryGlow.withValues(alpha: 0.16)
          : Colors.black12,
      color: isUnread ? AppColors.surfaceWhite : AppColors.surfaceCardSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isUnread
              ? AppColors.accentGold.withValues(alpha: 0.6)
              : AppColors.borderSubtle,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: isUnread ? ProfileCardCornerPainter() : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryIcon(item.type, isUnread),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: isUnread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'UNREAD',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryDarkBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'READ',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (item.referenceId != null &&
                          item.referenceId!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRoyalBlue.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryRoyalBlue.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.link_rounded,
                                size: 13,
                                color: AppColors.primaryRoyalBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.referenceId!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryRoyalBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String type, bool isUnread) {
    final IconData icon;
    final Color color;

    final lower = type.toLowerCase();
    if (lower.contains('order')) {
      icon = Icons.shopping_bag_rounded;
      color = AppColors.primaryRoyalBlue;
    } else if (lower.contains('registration') || lower.contains('approval')) {
      icon = Icons.verified_user_rounded;
      color = AppColors.accentGold;
    } else if (lower.contains('stock')) {
      icon = Icons.inventory_2_rounded;
      color = Colors.amber.shade800;
    } else if (lower.contains('promo') || lower.contains('offer')) {
      icon = Icons.local_offer_rounded;
      color = Colors.green.shade700;
    } else {
      icon = Icons.notifications_rounded;
      color = AppColors.primaryRoyalBlue;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUnread ? 0.14 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: isUnread ? 0.35 : 0.15),
          width: 1.2,
        ),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
