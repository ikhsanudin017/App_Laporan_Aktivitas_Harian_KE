import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';
import '../utils/responsive.dart';

class AdminPageShell extends StatelessWidget {
  const AdminPageShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.headerBottom,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? headerBottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.admin(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final horizontalPadding = context.responsiveHorizontalPadding;
          final bool isMobile = context.isMobile;
          return Scaffold(
            backgroundColor: AppColors.adminBackground,
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              bottom: false,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isMobile ? 24 : 28,
                        horizontalPadding,
                        isMobile ? 26 : 30,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(30, 64, 175, 0.22),
                            blurRadius: 28,
                            offset: Offset(0, 22),
                          ),
                        ],
                      ),
                      child: ResponsiveContent(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 768;
                                final titleBlock = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        height: 1.12,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white.withOpacity(0.88),
                                        ),
                                      ),
                                    ],
                                  ],
                                );

                                final hasActions =
                                    actions != null && actions!.isNotEmpty;
                                if (!hasActions) {
                                  return titleBlock;
                                }

                                final wrap = Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.end,
                                  runAlignment: WrapAlignment.end,
                                  children: actions!,
                                );

                                if (isCompact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titleBlock,
                                      const SizedBox(height: 16),
                                      wrap,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: titleBlock),
                                    const SizedBox(width: 24),
                                    Flexible(
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: wrap,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (headerBottom != null) ...[
                              const SizedBox(height: 24),
                              headerBottom!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                ],
                body: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    24,
                  ),
                  child: ResponsiveContent(
                    child: body,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trendLabel,
    this.trendIcon,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trendLabel;
  final IconData? trendIcon;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final LinearGradient colors = gradient ?? AppColors.adminButtonGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: colors,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(37, 99, 235, 0.18),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacityRatio(0.18),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacityRatio(0.85),
                  ),
            ),
            if (trendLabel != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(trendIcon ?? Icons.trending_up_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trendLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.margin,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final EdgeInsetsGeometry resolvedPadding = padding ??
        EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 28, vertical: isMobile ? 20 : 26);

    return Card(
      margin: margin ?? EdgeInsets.only(bottom: isMobile ? 18 : 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.adminCardBorder, width: 1.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 20),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? Colors.white : AppColors.adminPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.adminButtonGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.adminCardBorder,
              width: 1.2,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(37, 99, 235, 0.18),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 720;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 18 : 22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.adminSecondaryLight.withOpacityRatio(0.65),
          ),
          child: Icon(icon, size: 32, color: AppColors.adminSecondary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.adminPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: (screenWidth / 30).clamp(18, 22),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate.withOpacityRatio(0.7),
                fontSize: (screenWidth / 40).clamp(14, 16),
              ),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: 22),
          action!,
        ],
      ],
    );
  }
}
