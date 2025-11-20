import 'package:flutter/material.dart';

/// Pre-defined border radius values
class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xLarge = 20.0;
  static const double round = 999.0;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get xLargeRadius => BorderRadius.circular(xLarge);
  static BorderRadius get roundRadius => BorderRadius.circular(round);
}

/// Pre-defined spacing values
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// Responsive helper class for adaptive UI
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Check if device is mobile (width < 600)
  bool get isMobile => width < 600;

  /// Check if device is tablet (600 <= width < 1024)
  bool get isTablet => width >= 600 && width < 1024;

  /// Check if device is desktop (width >= 1024)
  bool get isDesktop => width >= 1024;

  /// Get responsive value based on screen size
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Responsive font size
  double fontSize(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  /// Responsive spacing
  double spacing(double baseSpacing) {
    if (isMobile) return baseSpacing;
    if (isTablet) return baseSpacing * 1.2;
    return baseSpacing * 1.5;
  }

  /// Responsive icon size
  double iconSize(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.15;
    return baseSize * 1.3;
  }

  /// Get responsive padding
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final multiplier = isMobile ? 1.0 : (isTablet ? 1.2 : 1.5);

    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }

    return EdgeInsets.only(
      top: (top ?? vertical ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? 0) * multiplier,
      left: (left ?? horizontal ?? 0) * multiplier,
      right: (right ?? horizontal ?? 0) * multiplier,
    );
  }

  /// Grid cross axis count based on screen size
  int gridCrossAxisCount({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }
}

/// Extension to easily access Responsive helper
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
