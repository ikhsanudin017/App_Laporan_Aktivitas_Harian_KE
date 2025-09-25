import "package:flutter/widgets.dart";

class ResponsiveBreakpoints {
  static const double tabletMinWidth = 720;
  static const double desktopMinWidth = 1080;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletMinWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletMinWidth && width < desktopMinWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMinWidth;

  static double horizontalPadding(double width) {
    if (width >= desktopMinWidth) {
      return 36;
    }
    if (width >= tabletMinWidth) {
      return 28;
    }
    return 20;
  }

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(width));

  static double pageMaxWidth(double width) {
    if (width >= 1600) {
      return 1320;
    }
    if (width >= desktopMinWidth) {
      return 1180;
    }
    if (width >= tabletMinWidth) {
      return 860;
    }
    return width;
  }
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);

  double get responsiveHorizontalPadding =>
      ResponsiveBreakpoints.horizontalPadding(MediaQuery.sizeOf(this).width);

  EdgeInsets get responsivePagePadding =>
      ResponsiveBreakpoints.pagePadding(MediaQuery.sizeOf(this).width);

  double get responsiveMaxWidth =>
      ResponsiveBreakpoints.pageMaxWidth(MediaQuery.sizeOf(this).width);
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.maxWidth,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final double resolvedMaxWidth =
        maxWidth ?? ResponsiveBreakpoints.pageMaxWidth(width);

    if (width <= resolvedMaxWidth) {
      return child;
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: child,
      ),
    );
  }
}
