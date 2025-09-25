import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';
import '../utils/responsive.dart';

class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern(
      {super.key, required this.child, this.addScrollGradient = false});

  final Widget child;
  final bool addScrollGradient;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale =
        (size.width / 430).clamp(0.65, context.isDesktop ? 1.6 : 1.25);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120 * scale,
            left: -90 * scale,
            child: _blurCircle(
              size: 280 * scale,
              color: AppColors.primary.withOpacityRatio(0.18),
            ),
          ),
          Positioned(
            top: context.isDesktop ? 180 * scale : 120 * scale,
            right: -70 * scale,
            child: _rotatedSquare(
              size: 210 * scale,
              color: AppColors.secondary.withOpacityRatio(0.18),
            ),
          ),
          Positioned(
            bottom: -110 * scale,
            left: context.isTablet ? -40 * scale : 20 * scale,
            child: _blurCircle(
              size: 260 * scale,
              color: AppColors.secondary.withOpacityRatio(0.14),
            ),
          ),
          Positioned(
            bottom: 120 * scale,
            right: 40 * scale,
            child: _outlinedCircle(
              size: 160 * scale,
              borderColor: AppColors.gold.withOpacityRatio(0.22),
            ),
          ),
          if (addScrollGradient)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacityRatio(0.08),
                        Colors.transparent,
                        Colors.white.withOpacityRatio(0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _blurCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacityRatio(0.4),
            blurRadius: 120,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _rotatedSquare({required double size, required Color color}) {
    return Transform.rotate(
      angle: 0.7,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          color: color,
        ),
      ),
    );
  }

  Widget _outlinedCircle({required double size, required Color borderColor}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
      ),
    );
  }
}
