import 'package:flutter/material.dart';

/// Screen device categories for BBS GOLD responsive adaptation
enum DeviceType {
  smallPhone, // < 360 logical px (e.g. 320x568, small Androids)
  phone,      // 360–599 logical px (standard smartphones)
  tablet,     // 600–899 logical px (tablets, foldables unfolded)
  largeTablet // >= 900 logical px (iPad Pro, desktop)
}

/// Centralized responsive design helper for BBS GOLD.
/// Provides safe adaptive dimensions, bounded typography, max width constraints,
/// dynamic paddings, and grid column calculators without altering design identity.
class ResponsiveHelper {
  /// Detect device type from BuildContext
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return DeviceType.smallPhone;
    if (width < 600) return DeviceType.phone;
    if (width < 900) return DeviceType.tablet;
    return DeviceType.largeTablet;
  }

  /// Whether current orientation is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Max content width constraint for forms, auth cards, and dialogs.
  /// Prevents inputs and dialogs from awkwardly stretching across 800px+ tablet screens.
  static double maxFormWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 560;
    if (width >= 600) return 500;
    return double.infinity;
  }

  /// Max content width constraint for main dashboard/catalogue pages.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 1140;
    if (width >= 900) return 960;
    return double.infinity;
  }

  /// Adaptive horizontal padding based on screen width
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12.0;
    if (width < 600) return 16.0;
    if (width < 900) return 24.0;
    return 32.0;
  }

  /// Adaptive vertical spacing for sections
  static double verticalSpacing(BuildContext context, {double base = 16.0}) {
    final device = getDeviceType(context);
    switch (device) {
      case DeviceType.smallPhone:
        return base * 0.8;
      case DeviceType.phone:
        return base;
      case DeviceType.tablet:
        return base * 1.15;
      case DeviceType.largeTablet:
        return base * 1.3;
    }
  }

  /// Calculates dynamic grid column count preserving existing card aspect ratio
  static int gridColumnCount(BuildContext context, {int phoneCols = 2, int tabletCols = 3, int largeCols = 4}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 1;
    if (width < 600) return phoneCols;
    if (width < 900) return tabletCols;
    return largeCols;
  }

  /// Clamps font size within upper/lower bounds so accessibility settings or large screens don't break layout
  static double fontSize(BuildContext context, double baseFontSize, {double minScale = 0.85, double maxScale = 1.2}) {
    final textScaler = MediaQuery.textScalerOf(context);
    final width = MediaQuery.sizeOf(context).width;

    double deviceFactor = 1.0;
    if (width < 360) {
      deviceFactor = 0.9;
    } else if (width >= 900) {
      deviceFactor = 1.1;
    } else if (width >= 600) {
      deviceFactor = 1.05;
    }

    final calculated = baseFontSize * deviceFactor;
    final scaled = textScaler.scale(calculated);
    final minSize = baseFontSize * minScale;
    final maxSize = baseFontSize * maxScale;

    return scaled.clamp(minSize, maxSize);
  }

  /// Safe dynamic height for AppBars
  static double appBarHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    if (height < 600) return 70.0;
    return 80.0;
  }

  /// Safe dynamic width for side Drawers
  static double drawerWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 380;
    if (width >= 600) return width * 0.52;
    if (width < 360) return width * 0.88;
    return width * 0.82;
  }

  /// Safe dynamic width for dialogs
  static double dialogWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 460;
    if (width >= 600) return 420;
    return width * 0.9;
  }
}

/// Convenience Extension on BuildContext for quick access to responsive properties
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  bool get isLandscape => ResponsiveHelper.isLandscape(this);
  double get maxFormWidth => ResponsiveHelper.maxFormWidth(this);
  double get maxContentWidth => ResponsiveHelper.maxContentWidth(this);
  double get responsiveHorizontalPadding => ResponsiveHelper.horizontalPadding(this);
  double clampedFontSize(double base, {double minScale = 0.85, double maxScale = 1.2}) =>
      ResponsiveHelper.fontSize(this, base, minScale: minScale, maxScale: maxScale);
}
