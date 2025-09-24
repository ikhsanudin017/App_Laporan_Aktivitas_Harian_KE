import 'package:flutter/material.dart';

extension ColorOpacityExtension on Color {
  Color withOpacityRatio(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    return withAlpha((clamped * 255).round());
  }
}
