import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_extensions.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFFFF8E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2E3A2F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0D9C6);
  static const Color success = Color(0xFF16A34A);

  static const Color primary = Color(0xFF1F6D44);
  static const Color primaryDark = Color(0xFF13472A);
  static const Color secondary = Color(0xFFF2C94C);
  static const Color secondaryDeep = Color(0xFFC89A19);
  static const Color accent = Color(0xFF1C7F4F);
  static const Color cream = Color(0xFFFFF9E5);
  static const Color sand = Color(0xFFFFF3CC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0D9C6);
  static const Color cardShadow = Color.fromRGBO(189, 163, 104, 0.18);
  static const Color mint = Color(0xFFE8F8EC);
  static const Color gold = Color(0xFFF5C74A);
  static const Color goldDeep = Color(0xFFDF9F1B);
  static const Color slate = Color(0xFF2E3A2F);
  static const Color danger = Color(0xFFD64545);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFE5E7EB);

  static const Color adminPrimary = Color(0xFF1E3A8A);
  static const Color adminPrimaryDark = Color(0xFF1D2A5C);
  static const Color adminSecondary = Color(0xFF2563EB);
  static const Color adminSecondaryLight = Color(0xFFDBEAFE);
  static const Color adminBackground = Color(0xFFF4F6FB);
  static const Color adminCardBorder = Color(0xFFE2E8F0);
  static const Color adminAccentGreen = Color(0xFF16A34A);
  static const Color adminAccentRed = Color(0xFFDC2626);
  static const Color adminAccentYellow = Color(0xFFF59E0B);
  static const Color adminAccentPurple = Color(0xFF7C3AED);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFCF3),
      Color(0xFFFFF3CE),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient adminHeaderGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      adminPrimary,
      adminSecondary,
    ],
  );

  static const LinearGradient adminButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      adminPrimary,
      adminSecondary,
    ],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.poppins(
        textStyle: base.textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: base.textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: base.textTheme.headlineMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      labelLarge: GoogleFonts.poppins(
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.slate.withOpacityRatio(0.82),
        ),
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: base.textTheme.bodySmall?.copyWith(
          color: AppColors.neutral,
        ),
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardSurface,
        background: AppColors.background,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface.withOpacityRatio(0.98),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardSurface.withOpacityRatio(0.98),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        margin: EdgeInsets.zero,
        shadowColor: AppColors.cardShadow,
      ),
    );
  }

  static ThemeData admin() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(
        textStyle: base.textTheme.headlineLarge?.copyWith(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: base.textTheme.headlineMedium?.copyWith(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: base.textTheme.headlineSmall?.copyWith(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: base.textTheme.titleLarge?.copyWith(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: base.textTheme.titleMedium?.copyWith(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: base.textTheme.bodyLarge?.copyWith(
          color: AppColors.slate.withOpacityRatio(0.92),
          fontWeight: FontWeight.w600,
        ),
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.slate.withOpacityRatio(0.85),
        ),
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: base.textTheme.bodySmall?.copyWith(
          color: AppColors.neutral,
        ),
      ),
      labelLarge: GoogleFonts.poppins(
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.adminPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.adminSecondary,
        onSecondary: Colors.white,
        surface: Colors.white,
        background: AppColors.adminBackground,
        error: AppColors.adminAccentRed,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.adminBackground,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color.fromRGBO(30, 58, 138, 0.08),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.adminCardBorder,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        labelColor: AppColors.adminPrimary,
        unselectedLabelColor: AppColors.adminPrimary.withOpacityRatio(0.48),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.adminButtonGradient,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(37, 99, 235, 0.18),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              const BorderSide(color: AppColors.adminCardBorder, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              const BorderSide(color: AppColors.adminCardBorder, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              const BorderSide(color: AppColors.adminSecondary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        prefixIconColor: AppColors.adminPrimary.withOpacityRatio(0.7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.adminPrimary,
          side: const BorderSide(color: AppColors.adminPrimary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: AppColors.adminPrimary,
        textColor: AppColors.slate,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.adminSecondaryLight,
        selectedColor: AppColors.adminSecondary,
        labelStyle: GoogleFonts.inter(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: const BorderSide(color: Colors.transparent),
      ),
      iconTheme: base.iconTheme.copyWith(color: AppColors.adminPrimary),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.adminSecondary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
