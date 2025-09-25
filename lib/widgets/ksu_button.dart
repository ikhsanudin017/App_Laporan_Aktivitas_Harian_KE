import 'package:flutter/material.dart';

class KsuButton extends StatelessWidget {
  const KsuButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.elevatedButtonTheme.style?.copyWith(
      backgroundColor: backgroundColor != null ? WidgetStateProperty.all(backgroundColor) : null,
      foregroundColor: foregroundColor != null ? WidgetStateProperty.all(foregroundColor) : null,
    );

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: style,
      icon: isLoading
          ? const SizedBox.shrink()
          : icon != null
              ? Icon(icon, size: 18)
              : const SizedBox.shrink(),
      label: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: foregroundColor),
            )
          : Text(label),
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
    final theme = Theme.of(context);
    final color = foregroundColor ?? theme.colorScheme.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: theme.outlinedButtonTheme.style?.copyWith(
        foregroundColor: WidgetStateProperty.all(color),
        side: borderColor != null ? WidgetStateProperty.all(BorderSide(color: borderColor!, width: 1.5)) : null,
      ),
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}