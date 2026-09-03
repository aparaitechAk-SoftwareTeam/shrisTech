import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart' show Permission;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import 'permission_models.dart';

/// Centralized, production-grade System Permission Manager for BBS GOLD.
/// 
/// Enforces:
/// 1. Strict separation of one-time onboarding status vs actual dynamic OS permission state.
/// 2. Non-blocking onboarding flow between Login and Home navigation.
/// 3. Sequential native OS dialog invocation.
/// 4. Lifecycle & concurrency safety with execution lock.
/// 5. Session safety (NEVER touches UserData or auth state).
/// 6. BBS GOLD luxury branded rationale dialogs for protected features.
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  static PermissionManager get instance => _instance;
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  // SharedPreferences Key for non-sensitive onboarding metadata
  static const String keyPermissionOnboardingCompleted =
      'permission_onboarding_completed';

  // Concurrency lock to prevent duplicate runs on orientation change / rebuilds
  bool _isPermissionFlowRunning = false;
  bool get isPermissionFlowRunning => _isPermissionFlowRunning;

  // ══════════════════════════════════════════════════════════════════════════
  // ONBOARDING METADATA PERSISTENCE
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks if the one-time permission onboarding flow has already been executed.
  Future<bool> isOnboardingCompleted([SharedPreferences? prefs]) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      return sp.getBool(keyPermissionOnboardingCompleted) ?? false;
    } catch (e) {
      log('PermissionManager.isOnboardingCompleted error: $e');
      return false;
    }
  }

  /// Marks the one-time permission onboarding as completed.
  Future<void> markOnboardingCompleted([SharedPreferences? prefs]) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      await sp.setBool(keyPermissionOnboardingCompleted, true);
      log('PermissionManager: Onboarding marked as completed.');
    } catch (e) {
      log('PermissionManager.markOnboardingCompleted error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POST-LOGIN ONBOARDING FLOW
  // ══════════════════════════════════════════════════════════════════════════

  /// Executes the permission onboarding flow between successful login and Home navigation.
  ///
  /// Flow:
  /// Login successful → Check onboarding flag → If not completed, sequentially request
  /// native OS dialogs (Notification → Camera → Media) → Mark completed → Navigate to role Home.
  /// If already completed → Directly navigate to role Home without any popups.
  Future<void> handlePostLoginFlow({
    required BuildContext context,
    String? role,
  }) async {
    if (_isPermissionFlowRunning) {
      log('PermissionManager: Flow already in progress. Skipping duplicate call.');
      return;
    }

    _isPermissionFlowRunning = true;

    try {
      final alreadyCompleted = await isOnboardingCompleted();

      if (!alreadyCompleted) {
        log('PermissionManager: Fresh onboarding started.');
        await requestRequiredPermissionsSequentially();
        await markOnboardingCompleted();
        log('PermissionManager: Fresh onboarding finished.');
      } else {
        log('PermissionManager: Onboarding previously completed. Skipping dialogs.');
      }
    } catch (e, stack) {
      log('PermissionManager: Error during onboarding flow: $e\n$stack');
    } finally {
      _isPermissionFlowRunning = false;
      if (context.mounted) {
        AuthService().navigateByRole(context, role);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEQUENTIAL PERMISSION ONBOARDING
  // ══════════════════════════════════════════════════════════════════════════

  /// Requests required permissions sequentially using native OS dialogs:
  /// 1. Notification (Android 13+ / iOS)
  /// 2. Camera
  /// 3. Media / Photos
  ///
  /// Sequential requests prevent overwhelming users and avoid simultaneous dialog collisions.
  Future<void> requestRequiredPermissionsSequentially() async {
    // 1. Notification Permission
    try {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        log('PermissionManager: Requesting notification permission...');
        final res = await Permission.notification.request();
        log('PermissionManager: Notification permission result: $res');
        if (res.isGranted) {
          // Trigger FCM sync non-blockingly
          FcmService().syncDeviceToken();
        }
      } else {
        log('PermissionManager: Notification permission already granted.');
      }
    } catch (e) {
      log('PermissionManager: Notification permission request error: $e');
    }

    // 2. Camera Permission
    try {
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        log('PermissionManager: Requesting camera permission...');
        final res = await Permission.camera.request();
        log('PermissionManager: Camera permission result: $res');
      } else {
        log('PermissionManager: Camera permission already granted.');
      }
    } catch (e) {
      log('PermissionManager: Camera permission request error: $e');
    }

    // 3. Media / Photo Access
    try {
      final mediaStatus = await Permission.photos.status;
      if (!mediaStatus.isGranted && !mediaStatus.isLimited) {
        log('PermissionManager: Requesting media/photos permission...');
        final res = await Permission.photos.request();
        log('PermissionManager: Media/photos permission result: $res');
      } else {
        log('PermissionManager: Media/photos permission already granted.');
      }
    } catch (e) {
      log('PermissionManager: Media permission request error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RUNTIME OS PERMISSION AUDIT
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks and returns the real-time OS permission status for all categories without prompting.
  Future<PermissionStatusReport> checkAllPermissions() async {
    AppPermissionStatus notif = AppPermissionStatus.unknown;
    AppPermissionStatus cam = AppPermissionStatus.unknown;
    AppPermissionStatus med = AppPermissionStatus.unknown;

    try {
      final s = await Permission.notification.status;
      notif = AppPermissionStatus.fromPermissionStatus(s);
    } catch (e) {
      log('PermissionManager.checkAllPermissions(notification) error: $e');
    }

    try {
      final s = await Permission.camera.status;
      cam = AppPermissionStatus.fromPermissionStatus(s);
    } catch (e) {
      log('PermissionManager.checkAllPermissions(camera) error: $e');
    }

    try {
      final s = await Permission.photos.status;
      med = AppPermissionStatus.fromPermissionStatus(s);
      if (Platform.isAndroid && !med.isGranted) {
        final storage = await Permission.storage.status;
        if (storage.isGranted) {
          med = AppPermissionStatus.granted;
        }
      }
    } catch (e) {
      log('PermissionManager.checkAllPermissions(media) error: $e');
    }

    final report = PermissionStatusReport(
      notification: notif,
      camera: cam,
      media: med,
      checkedAt: DateTime.now(),
    );

    log('PermissionManager: OS Permission Report -> $report');
    return report;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEATURE-LEVEL PROTECTED PERMISSIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifies or requests Camera permission for a feature (e.g. Add Product image capture).
  /// If permanently denied, presents a BBS GOLD luxury rationale modal directing to Settings.
  Future<bool> requestCameraPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    try {
      final currentStatus = await Permission.camera.status;
      if (currentStatus.isGranted) {
        return true;
      }

      if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
        if (context != null && showRationale && context.mounted) {
          final shouldOpen = await showPermissionRationaleDialog(
            context: context,
            type: AppPermissionType.camera,
          );
          if (shouldOpen) {
            await openAppSettings();
            final recheck = await Permission.camera.status;
            return recheck.isGranted;
          }
        }
        return false;
      }

      final requestResult = await Permission.camera.request();
      if (requestResult.isGranted) {
        return true;
      }

      if (requestResult.isPermanentlyDenied && context != null && showRationale && context.mounted) {
        final shouldOpen = await showPermissionRationaleDialog(
          context: context,
          type: AppPermissionType.camera,
        );
        if (shouldOpen) {
          await openAppSettings();
          final recheck = await Permission.camera.status;
          return recheck.isGranted;
        }
      }

      return false;
    } catch (e) {
      log('PermissionManager.requestCameraPermission error: $e');
      return false;
    }
  }

  /// Verifies or requests Notification permission.
  Future<bool> requestNotificationPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    try {
      final currentStatus = await Permission.notification.status;
      if (currentStatus.isGranted) {
        FcmService().syncDeviceToken();
        return true;
      }

      if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
        if (context != null && showRationale && context.mounted) {
          final shouldOpen = await showPermissionRationaleDialog(
            context: context,
            type: AppPermissionType.notification,
          );
          if (shouldOpen) {
            await openAppSettings();
            final recheck = await Permission.notification.status;
            if (recheck.isGranted) {
              FcmService().syncDeviceToken();
              return true;
            }
          }
        }
        return false;
      }

      final requestResult = await Permission.notification.request();
      if (requestResult.isGranted) {
        FcmService().syncDeviceToken();
        return true;
      }

      if (requestResult.isPermanentlyDenied && context != null && showRationale && context.mounted) {
        final shouldOpen = await showPermissionRationaleDialog(
          context: context,
          type: AppPermissionType.notification,
        );
        if (shouldOpen) {
          await openAppSettings();
          final recheck = await Permission.notification.status;
          if (recheck.isGranted) {
            FcmService().syncDeviceToken();
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      log('PermissionManager.requestNotificationPermission error: $e');
      return false;
    }
  }

  /// Verifies or requests Photo/Media permission for image picking/uploading.
  Future<bool> requestMediaPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    try {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;
      }

      if (photosStatus.isPermanentlyDenied || photosStatus.isRestricted) {
        if (context != null && showRationale && context.mounted) {
          final shouldOpen = await showPermissionRationaleDialog(
            context: context,
            type: AppPermissionType.media,
          );
          if (shouldOpen) {
            await openAppSettings();
            final recheckPhotos = await Permission.photos.status;
            if (recheckPhotos.isGranted || recheckPhotos.isLimited) return true;
            if (Platform.isAndroid) {
              final recheckStorage = await Permission.storage.status;
              return recheckStorage.isGranted;
            }
          }
        }
        return false;
      }

      final res = await Permission.photos.request();
      if (res.isGranted || res.isLimited) return true;

      // Fallback for older Android versions
      if (Platform.isAndroid && (res.isDenied || res.isPermanentlyDenied)) {
        final storageRes = await Permission.storage.request();
        if (storageRes.isGranted) return true;
      }

      if (res.isPermanentlyDenied && context != null && showRationale && context.mounted) {
        final shouldOpen = await showPermissionRationaleDialog(
          context: context,
          type: AppPermissionType.media,
        );
        if (shouldOpen) {
          await openAppSettings();
          final recheckPhotos = await Permission.photos.status;
          if (recheckPhotos.isGranted || recheckPhotos.isLimited) return true;
          if (Platform.isAndroid) {
            final recheckStorage = await Permission.storage.status;
            return recheckStorage.isGranted;
          }
        }
      }

      return false;
    } catch (e) {
      log('PermissionManager.requestMediaPermission error: $e');
      return false;
    }
  }

  /// Opens the device App Settings screen.
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      log('PermissionManager.openAppSettings error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LUXURY BBS GOLD RATIONALE MODAL
  // ══════════════════════════════════════════════════════════════════════════

  /// Displays an ultra-luxury BBS GOLD styled rationale bottom sheet.
  /// Used exclusively when sensitive features are protected and require Settings guidance.
  Future<bool> showPermissionRationaleDialog({
    required BuildContext context,
    required AppPermissionType type,
    String? customTitle,
    String? customMessage,
  }) async {
    if (!context.mounted) return false;

    String title;
    String message;
    IconData icon;

    switch (type) {
      case AppPermissionType.camera:
        title = customTitle ?? 'Camera Access Required';
        message = customMessage ??
            'BBS GOLD needs camera permission to capture and upload high-resolution product jewellery images. Please enable camera access in Settings.';
        icon = Icons.camera_alt_outlined;
        break;
      case AppPermissionType.notification:
        title = customTitle ?? 'Notifications Required';
        message = customMessage ??
            'Stay updated in real-time with your wholesale gold order approvals, delivery tracking, and exclusive rate offers.';
        icon = Icons.notifications_active_outlined;
        break;
      case AppPermissionType.media:
        title = customTitle ?? 'Photo Library Access';
        message = customMessage ??
            'BBS GOLD requires access to your photo gallery to select hallmark certificates and product catalogue images.';
        icon = Icons.photo_library_outlined;
        break;
    }

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final mediaQuery = MediaQuery.of(modalContext);
        final isTablet = mediaQuery.size.width >= 600;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 480 : double.infinity,
            ),
            child: Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: mediaQuery.viewPadding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderGold,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gold luxury icon badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLightBlue,
                          border: Border.all(
                            color: AppColors.accentGold,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: AppColors.primaryRoyalBlue,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primaryRoyalBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description Message
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      PrimaryButton(
                        text: 'Open Settings',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(modalContext).pop(true);
                        },
                      ),
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(modalContext).pop(false);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: Text(
                          'Not Now',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}
