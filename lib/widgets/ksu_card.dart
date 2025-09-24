import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';

class KsuCard extends StatelessWidget {
  const KsuCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacityRatio(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: AppColors.cardBorder.withOpacityRatio(0.8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
