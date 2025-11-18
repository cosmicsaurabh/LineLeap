import 'package:flutter/material.dart';

/// Breakpoint constants for responsive design
class ResponsiveBreakpoints {
  // Landscape threshold: width > height * ratio
  static const double landscapeRatio = 1.5;
  
  // Low height threshold (in logical pixels)
  static const double lowHeightThreshold = 600;
  
  // Small screen thresholds
  static const double smallWidthThreshold = 600;
  static const double smallHeightThreshold = 800;
  
  // Very small screen thresholds
  static const double verySmallWidthThreshold = 400;
  static const double verySmallHeightThreshold = 600;
}

/// Helper class for determining responsive layout modes
class ResponsiveLayoutHelper {
  final Size screenSize;
  final double width;
  final double height;
  final double aspectRatio;

  ResponsiveLayoutHelper(BuildContext context)
      : screenSize = MediaQuery.of(context).size,
        width = MediaQuery.of(context).size.width,
        height = MediaQuery.of(context).size.height,
        aspectRatio = MediaQuery.of(context).size.width /
            MediaQuery.of(context).size.height;

  /// Check if screen is in landscape mode (width much larger than height)
  bool get isLandscape => aspectRatio > ResponsiveBreakpoints.landscapeRatio;

  /// Check if screen height is low
  bool get isLowHeight => height < ResponsiveBreakpoints.lowHeightThreshold;

  /// Check if screen is small (both dimensions below thresholds)
  bool get isSmallScreen =>
      width < ResponsiveBreakpoints.smallWidthThreshold &&
      height < ResponsiveBreakpoints.smallHeightThreshold;

  /// Check if screen is very small
  bool get isVerySmallScreen =>
      width < ResponsiveBreakpoints.verySmallWidthThreshold &&
      height < ResponsiveBreakpoints.verySmallHeightThreshold;

  /// Determine if navigation bar should be vertical
  bool shouldUseVerticalNavBar() {
    return isLandscape || isLowHeight;
  }

  /// Determine if app bar should be vertical
  bool shouldUseVerticalAppBar() {
    return isLandscape || (width > ResponsiveBreakpoints.smallWidthThreshold &&
        height < ResponsiveBreakpoints.lowHeightThreshold);
  }

  /// Determine if components should be scaled down
  bool shouldScaleDown() {
    return isSmallScreen || isVerySmallScreen;
  }

  /// Get scale factor for small screens
  double getScaleFactor() {
    if (isVerySmallScreen) return 0.85;
    if (isSmallScreen) return 0.9;
    return 1.0;
  }

  /// Get optimal toolbar overlay position
  ToolbarPosition getToolbarPosition() {
    if (isLandscape || isLowHeight) {
      // In landscape/low height, prefer bottom or left side
      return ToolbarPosition.bottom;
    }
    return ToolbarPosition.right;
  }

  /// Get icon size based on screen size
  double getIconSize({double baseSize = 24.0}) {
    return baseSize * getScaleFactor();
  }

  /// Get font size based on screen size
  double getFontSize({double baseSize = 14.0}) {
    return baseSize * getScaleFactor();
  }

  /// Get max height for bottom sheets (as percentage of screen height)
  double getBottomSheetMaxHeight() {
    if (isLowHeight) return 0.85; // Use more of screen when height is limited
    if (isSmallScreen) return 0.75;
    return 0.6; // Default max height
  }

  /// Check if bottom sheet should use side layout (for landscape)
  bool shouldUseSideSheet() {
    return isLandscape && width > 800;
  }
}

/// Toolbar position enum
enum ToolbarPosition {
  top,
  bottom,
  left,
  right,
}

