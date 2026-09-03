// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../services/notification_service.dart';

class RetailerGlobalAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onLogoTap;

  const RetailerGlobalAppbar({super.key, required this.onLogoTap});

  static const double appBarHeight = 82;

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);

  @override
  Widget build(BuildContext context) {
    final userName = UserData.instance.name.trim().isEmpty
        ? 'Retailer'
        : UserData.instance.name.trim();

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: appBarHeight,
      backgroundColor: AppColors.primaryRoyalBlue,
      surfaceTintColor: AppColors.primaryRoyalBlue,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 76,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onLogoTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                AppConstants.logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.accentGold,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.appName,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.surfaceWhite,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: MediaQuery.sizeOf(context).width < 360 ? 17 : 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.sizeOf(context).width - 140).clamp(120, 280),
            ),
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w700,
                fontSize: MediaQuery.sizeOf(context).width < 360 ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationService(),
            builder: (context, unreadCount, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () {
                      final currentRoute =
                          ModalRoute.of(context)?.settings.name;
                      if (currentRoute == AppRoutes.notifications) return;
                      Navigator.of(context).pushNamed(AppRoutes.notifications);
                    },
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.accentGold,
                      size: 26,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 14,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
    );
  }
}
