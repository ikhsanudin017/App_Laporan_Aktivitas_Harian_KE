import 'package:flutter/material.dart';

class KsuCard extends StatelessWidget {
  const KsuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      // The theme is applied automatically from CardTheme in app_theme.dart
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}