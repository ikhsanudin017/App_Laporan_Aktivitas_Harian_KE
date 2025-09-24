import 'package:flutter/widgets.dart';

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
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
}
