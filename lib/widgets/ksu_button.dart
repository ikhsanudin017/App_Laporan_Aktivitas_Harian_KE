import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';

class KsuButton extends StatelessWidget {
  const KsuButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.borderColor,
    this.shadowColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final Color textColor = foregroundColor ?? Colors.white;
    LinearGradient? baseGradient;
    LinearGradient? resolvedGradient;

    if (backgroundColor case null) {
      baseGradient = gradient ?? AppColors.buttonGradient;
      resolvedGradient = LinearGradient(
        begin: baseGradient.begin,
        end: baseGradient.end,
        colors: baseGradient.colors
            .map((color) => color.withOpacityRatio(enabled ? 1 : 0.55))
            .toList(),
        stops: baseGradient.stops,
      );
    }
    final Color? resolvedBackground =
        backgroundColor?.withOpacityRatio(enabled ? 1 : 0.6);
    final Color resolvedShadow = shadowColor ??
        (baseGradient != null
            ? baseGradient.colors.last.withOpacityRatio(enabled ? 0.28 : 0.18)
            : (backgroundColor ?? AppColors.primary)
                .withOpacityRatio(enabled ? 0.32 : 0.22));

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: enabled ? 1 : 0.75,
        child: Ink(
          decoration: BoxDecoration(
            gradient: resolvedGradient,
            color: resolvedBackground,
            borderRadius: BorderRadius.circular(18),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.4)
                : null,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: resolvedShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isLoading)
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: textColor,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: textColor),
                if (icon != null || isLoading) const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: textColor,
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
    );
  }
}

class KsuSecondaryButton extends StatelessWidget {
  const KsuSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.foregroundColor,
    this.borderColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final Color color = foregroundColor ?? AppColors.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 18, color: color)
          : const SizedBox.shrink(),
      label: Text(label,
          style:
              Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor ?? color, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }
}
