import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';
import '../utils/app_routes.dart';
import '../utils/responsive.dart';
import '../widgets/admin_components.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.initialSession,
  });

  final SessionData initialSession;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _ReportQuickFilter { all, today, week, month, custom }

enum _PerformanceCategory { excellent, good, attention, critical }

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late SessionData _session;
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late final NumberFormat _numberFormat;

  List<Report> _reports = [];
  bool _loading = false;
  bool _resetting = false;
  String? _errorMessage;
  _ReportQuickFilter _quickFilter = _ReportQuickFilter.week;
  DateTimeRange? _customRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _numberFormat = NumberFormat.decimalPattern('id_ID');
    initializeDateFormatting('id_ID', null);
    _searchController.addListener(_onSearchChanged);
    _loadReports();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({bool showSpinner = true}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        if (showSpinner) {
          _errorMessage = null;
        }
      });
    }

    try {
      final reports =
          await _apiService.fetchAdminReports(token: _session.token);
      reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _reports = reports;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _reports = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak dapat memuat data: ${e.toString()}';
        _reports = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshReports() => _loadReports(showSpinner: false);

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  void _setQuickFilter(_ReportQuickFilter filter) {
    FocusScope.of(context).unfocus();
    if (_quickFilter == filter && filter != _ReportQuickFilter.custom) {
      return;
    }
    setState(() {
      _quickFilter = filter;
      if (filter != _ReportQuickFilter.custom) {
        _customRange = null;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initial,
      locale: const Locale('id'),
      builder: (context, child) {
        return Theme(
            data: AppTheme.admin(), child: child ?? const SizedBox.shrink());
      },
    );
    if (range != null && mounted) {
      setState(() {
        _quickFilter = _ReportQuickFilter.custom;
        _customRange = DateTimeRange(
          start: _stripTime(range.start),
          end: _stripTime(range.end),
        );
      });
    }
  }

  Future<void> _handleLogout() async {
    FocusScope.of(context).unfocus();
    await _sessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _confirmResetAll() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.admin(),
        child: AlertDialog(
          title: const Text('Reset Semua Data'),
          content: const Text(
            'Tindakan ini akan menghapus seluruh laporan aktivitas. Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.adminAccentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || _resetting) return;

    setState(() => _resetting = true);
    try {
      await _apiService.resetAllReports(token: _session.token);
      await _loadReports(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seluruh data aktivitas berhasil dihapus.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus data: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  List<Report> get _filteredReports {
    if (_reports.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    final bool Function(Report) dateMatcher = _getDateMatcher();

    bool matchesSearch(Report report) {
      if (query.isEmpty) return true;
      final owner = report.owner;
      if ((owner?.name.toLowerCase().contains(query) ?? false) ||
          (owner?.email.toLowerCase().contains(query) ?? false)) {
        return true;
      }
      if (dateFormatter.format(report.date).toLowerCase().contains(query)) {
        return true;
      }
      return report.reportData.entries.any((entry) =>
          entry.value?.toString().toLowerCase().contains(query) ?? false);
    }

    return _reports.where(dateMatcher).where(matchesSearch).toList();
  }

  bool Function(Report) _getDateMatcher() {
    final today = _stripTime(DateTime.now());
    switch (_quickFilter) {
      case _ReportQuickFilter.all:
        return (report) => true;
      case _ReportQuickFilter.today:
        return (report) => _stripTime(report.date) == today;
      case _ReportQuickFilter.week:
        final start = today.subtract(const Duration(days: 6));
        return (report) {
          final date = _stripTime(report.date);
          return !date.isBefore(start) && !date.isAfter(today);
        };
      case _ReportQuickFilter.month:
        final start = today.subtract(const Duration(days: 29));
        return (report) {
          final date = _stripTime(report.date);
          return !date.isBefore(start) && !date.isAfter(today);
        };
      case _ReportQuickFilter.custom:
        final range = _customRange;
        if (range == null) return (report) => true;
        final start = _stripTime(range.start);
        final end = _stripTime(range.end);
        return (report) {
          final date = _stripTime(report.date);
          return !date.isBefore(start) && !date.isAfter(end);
        };
    }
  }

  String get _customRangeLabel {
    final range = _customRange;
    if (range == null) return 'Rentang Kustom';
    final formatter = DateFormat('dd MMM', 'id_ID');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String get _activeRangeDescription {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    final now = DateTime.now();
    switch (_quickFilter) {
      case _ReportQuickFilter.all:
        return 'Semua Waktu';
      case _ReportQuickFilter.today:
        return 'Hari Ini (${formatter.format(now)})';
      case _ReportQuickFilter.week:
        final start = now.subtract(const Duration(days: 6));
        return '${formatter.format(start)} - ${formatter.format(now)}';
      case _ReportQuickFilter.month:
        final start = now.subtract(const Duration(days: 29));
        return '${formatter.format(start)} - ${formatter.format(now)}';
      case _ReportQuickFilter.custom:
        final range = _customRange;
        if (range == null) return 'Rentang Kustom';
        return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;
    final performance = _aggregateUserPerformance(reports);
    final metrics = _buildMetricItems(reports, performance);

    return AdminPageShell(
      title: 'Monitoring Pengisian Laporan',
      subtitle:
          'Pantau kepatuhan pengisian laporan aktivitas harian secara real-time',
      actions: [
        _buildHeaderActionButton(
          icon: Icons.refresh_rounded,
          label: 'Segarkan',
          onPressed: _loading ? null : () => _loadReports(),
          isBusy: _loading,
        ),
        _buildHeaderActionButton(
          icon: Icons.delete_sweep_rounded,
          label: 'Reset Data',
          onPressed: (_loading || _resetting) ? null : _confirmResetAll,
          isBusy: _resetting,
          color: AppColors.adminAccentRed,
        ),
        _buildHeaderActionButton(
          icon: Icons.logout_rounded,
          label: 'Keluar',
          onPressed: _loading ? null : _handleLogout,
          color: AppColors.adminPrimaryDark,
        ),
      ],
      headerBottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodInfo(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AdminFilterChip(
                label: 'Semua',
                icon: Icons.all_inclusive_rounded,
                selected: _quickFilter == _ReportQuickFilter.all,
                onTap: () => _setQuickFilter(_ReportQuickFilter.all),
              ),
              AdminFilterChip(
                label: 'Hari Ini',
                icon: Icons.today_rounded,
                selected: _quickFilter == _ReportQuickFilter.today,
                onTap: () => _setQuickFilter(_ReportQuickFilter.today),
              ),
              AdminFilterChip(
                label: '7 Hari',
                icon: Icons.calendar_view_week_rounded,
                selected: _quickFilter == _ReportQuickFilter.week,
                onTap: () => _setQuickFilter(_ReportQuickFilter.week),
              ),
              AdminFilterChip(
                label: '30 Hari',
                icon: Icons.calendar_month_rounded,
                selected: _quickFilter == _ReportQuickFilter.month,
                onTap: () => _setQuickFilter(_ReportQuickFilter.month),
              ),
              AdminFilterChip(
                label: _customRangeLabel,
                icon: Icons.date_range_rounded,
                selected: _quickFilter == _ReportQuickFilter.custom,
                onTap: _pickCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama anggota atau kata kunci laporan',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Hapus Pencarian',
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: _buildBody(reports, performance, metrics),
    );
  }

  Widget _buildBody(List<Report> reports, List<_UserPerformance> performance,
      List<_MetricItem> metrics) {
    final horizontalPadding = context.responsiveHorizontalPadding;
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 64),
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildErrorBanner(),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildMetricsGrid(metrics),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildUserPerformance(performance),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildReportsSection(reports),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    bool isBusy = false,
  }) {
    final theme = Theme.of(context);
    final Color baseColor = color ?? theme.colorScheme.secondary;
    final Color background =
        baseColor.withOpacityRatio(onPressed == null ? 0.24 : 0.18);
    final Color border = baseColor.withOpacityRatio(0.32);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.4),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: baseColor.withOpacityRatio(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfo() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Periode: ',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            Expanded(
              child: Text(
                _activeRangeDescription,
                style:
                    theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Hari kerja saja (Kecuali Minggu & libur nasional)',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);
    final message = _errorMessage;
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: theme.colorScheme.error,
            tooltip: 'Sembunyikan',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<_MetricItem> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      if (context.isMobile) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _DashboardMetricCard(
              icon: metric.icon,
              label: metric.label,
              value: metric.value,
              color: metric.color ?? Theme.of(context).colorScheme.secondary,
            );
          },
        );
      }

      final width = constraints.maxWidth;
      final double maxExtent;
      if (width >= 1280) {
        maxExtent = 160;
      } else if (width >= 1024) {
        maxExtent = 150;
      } else {
        maxExtent = 140;
      }

      final double aspectRatio = width < 520 ? 0.78 : 0.95;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxExtent,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return _DashboardMetricCard(
            icon: metric.icon,
            label: metric.label,
            value: metric.value,
            color: metric.color ?? Theme.of(context).colorScheme.secondary,
          );
        },
      );
    });
  }

  Widget _buildUserPerformance(List<_UserPerformance> performance) {
    final theme = Theme.of(context);
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 720;

    return AdminSectionCard(
      title: 'Detail Performa User',
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 28,
        vertical: 24,
      ),
      child: performance.isEmpty
          ? const AdminEmptyState(
              icon: Icons.insights_outlined,
              title: 'Belum ada data performa',
              message:
                  'Saat laporan mulai masuk, ringkasan kepatuhan tim akan tampil di sini.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerformanceIntro(theme),
                const SizedBox(height: 20),
                if (!isCompact) ...[
                  _buildPerformanceHeaderRow(theme),
                  const SizedBox(height: 16),
                ],
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: performance.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildPerformanceRow(performance[index], isCompact),
                ),
              ],
            ),
    );
  }

  Widget _buildPerformanceIntro(ThemeData theme) {
    final Color accent = theme.colorScheme.primary;
    final Color textColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.78) ?? accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withOpacityRatio(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.verified_rounded, color: accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Rincian tingkat kepatuhan setiap user dalam mengisi laporan harian.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceHeaderRow(ThemeData theme) {
    final Color background = theme.colorScheme.primary.withOpacityRatio(0.05);
    final Color textColor = theme.colorScheme.primary.withOpacityRatio(0.85);
    final TextStyle? style = theme.textTheme.labelLarge?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    Expanded buildCell(String text,
        {int flex = 1, TextAlign align = TextAlign.left}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          style: style,
          textAlign: align,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          buildCell('USER & INFORMASI', flex: 3),
          const SizedBox(width: 12),
          buildCell('PROGRESS & PRESENTASE', flex: 3),
          const SizedBox(width: 12),
          buildCell('STATISTIK LAPORAN', flex: 2),
          const SizedBox(width: 12),
          buildCell('STATUS', flex: 2),
          const SizedBox(width: 12),
          buildCell('TERAKHIR INPUT', flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(
    _UserPerformance performance,
    bool isCompact,
  ) {
    final visuals = _resolvePerformanceVisuals(performance);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stack = isCompact || constraints.maxWidth < 720;
        final EdgeInsets padding = stack
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 18);

        return Container(
          decoration: _performanceTileDecoration(visuals.progressColor),
          padding: padding,
          child: stack
              ? _buildPerformanceRowMobile(performance, visuals)
              : _buildPerformanceRowDesktop(performance, visuals),
        );
      },
    );
  }

  Widget _buildPerformanceRowDesktop(
    _UserPerformance performance,
    _PerformanceVisualData visuals,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildInfoContent(performance, visuals),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildProgressContent(performance, visuals),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildStatisticsContent(performance),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildStatusContent(performance, visuals,
              alignment: CrossAxisAlignment.start),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildLastInputContent(performance,
              alignment: CrossAxisAlignment.end),
        ),
      ],
    );
  }

  Widget _buildPerformanceRowMobile(
    _UserPerformance performance,
    _PerformanceVisualData visuals,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoContent(performance, visuals),
        const SizedBox(height: 16),
        _buildPerformanceSectionLabel(theme, 'Progress & Presentase'),
        const SizedBox(height: 8),
        _buildProgressContent(performance, visuals),
        const SizedBox(height: 16),
        _buildPerformanceSectionLabel(theme, 'Statistik Laporan'),
        const SizedBox(height: 8),
        _buildStatisticsContent(performance),
        const SizedBox(height: 16),
        _buildPerformanceSectionLabel(theme, 'Status'),
        const SizedBox(height: 8),
        _buildStatusContent(performance, visuals,
            alignment: CrossAxisAlignment.start),
        const SizedBox(height: 16),
        _buildPerformanceSectionLabel(theme, 'Terakhir Input'),
        const SizedBox(height: 8),
        _buildLastInputContent(performance,
            alignment: CrossAxisAlignment.start),
      ],
    );
  }

  Widget _buildPerformanceSectionLabel(ThemeData theme, String text) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: theme.colorScheme.primary.withOpacityRatio(0.75),
      ),
    );
  }

  Widget _buildInfoContent(
    _UserPerformance performance,
    _PerformanceVisualData visuals,
  ) {
    final theme = Theme.of(context);
    final String initials = _extractInitials(performance.name);
    final String email =
        performance.email.isNotEmpty ? performance.email : 'Tidak ada email';
    final String role = _formatRole(performance.role);
    final Color subtleText =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPerformanceAvatar(theme, visuals.avatarGradient, initials),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                performance.name.isEmpty ? 'Tidak Diketahui' : performance.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 16, color: subtleText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtleText,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Role: $role',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtleText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressContent(
    _UserPerformance performance,
    _PerformanceVisualData visuals, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    final theme = Theme.of(context);
    final Color subtleText =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54;
    final double percent =
        (performance.completionRate * 100).clamp(0, 100).toDouble();
    final double missing = (100 - percent).clamp(0, 100);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          _formatPercentage(performance.completionRate),
          style: theme.textTheme.titleLarge?.copyWith(
            color: visuals.progressColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${performance.daysReported}/${performance.totalPeriodDays} hari',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtleText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: performance.completionRate.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: visuals.progressColor.withOpacityRatio(0.18),
            valueColor: AlwaysStoppedAnimation<Color>(visuals.progressColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Target: 100% - Kurang: ${missing.toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsContent(
    _UserPerformance performance, {
    TextAlign align = TextAlign.left,
  }) {
    final theme = Theme.of(context);
    final CrossAxisAlignment crossAxis = align == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        _buildProgressStatLine(
          'Total laporan',
          performance.totalReports,
          theme.colorScheme.primary,
          textAlign: align,
        ),
        const SizedBox(height: 8),
        _buildProgressStatLine(
          'Hari dilaporkan',
          performance.daysReported,
          AppColors.adminAccentGreen,
          textAlign: align,
        ),
        const SizedBox(height: 8),
        _buildProgressStatLine(
          'Hari terlewat',
          performance.daysMissed,
          AppColors.adminAccentRed,
          textAlign: align,
        ),
      ],
    );
  }

  Widget _buildStatusContent(
    _UserPerformance performance,
    _PerformanceVisualData visuals, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    final theme = Theme.of(context);
    final Color subtleText =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildStatusChip(
          visuals.statusLabel,
          visuals.statusIcon,
          visuals.statusColor,
        ),
        const SizedBox(height: 10),
        Text(
          'Ranking #${performance.rank}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: subtleText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLastInputContent(
    _UserPerformance performance, {
    CrossAxisAlignment alignment = CrossAxisAlignment.end,
  }) {
    final theme = Theme.of(context);
    final Color subtleText =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54;
    final DateTime? lastDate = performance.lastReportDate;
    final String dateText = lastDate != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(lastDate)
        : 'Belum ada laporan';
    final String dayText = lastDate != null
        ? toBeginningOfSentenceCase(
              DateFormat('EEEE', 'id_ID').format(lastDate),
              'id_ID',
            ) ??
            ''
        : '-';

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          dateText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacityRatio(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacityRatio(0.3), width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatLine(
    String label,
    int value,
    Color color, {
    TextAlign textAlign = TextAlign.left,
  }) {
    final theme = Theme.of(context);
    final Color subtleText =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54;

    return Text.rich(
      TextSpan(
        text: '$value ',
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(
            text: label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtleText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }

  Widget _buildPerformanceAvatar(
    ThemeData theme,
    LinearGradient gradient,
    String initials,
  ) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration _performanceTileDecoration(Color highlight) {
    return BoxDecoration(
      color: highlight.withOpacityRatio(0.06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: highlight.withOpacityRatio(0.2),
        width: 1.1,
      ),
    );
  }

  _PerformanceVisualData _resolvePerformanceVisuals(
      _UserPerformance performance) {
    final double rate = performance.completionRate.clamp(0.0, 1.0);
    final _PerformanceCategory category;
    if (rate >= 0.9) {
      category = _PerformanceCategory.excellent;
    } else if (rate >= 0.75) {
      category = _PerformanceCategory.good;
    } else if (rate >= 0.5) {
      category = _PerformanceCategory.attention;
    } else {
      category = _PerformanceCategory.critical;
    }

    switch (category) {
      case _PerformanceCategory.excellent:
        return _PerformanceVisualData(
          category: category,
          progressColor: const Color(0xFF2563EB),
          avatarGradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusLabel: 'Baik Sekali',
          statusIcon: Icons.thumb_up_alt_rounded,
          statusColor: const Color(0xFF2563EB),
        );
      case _PerformanceCategory.good:
        return _PerformanceVisualData(
          category: category,
          progressColor: const Color(0xFF3B82F6),
          avatarGradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusLabel: 'Baik Sekali',
          statusIcon: Icons.thumb_up_alt_rounded,
          statusColor: const Color(0xFF3B82F6),
        );
      case _PerformanceCategory.attention:
        return _PerformanceVisualData(
          category: category,
          progressColor: AppColors.adminAccentYellow,
          avatarGradient: const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusLabel: 'Perlu Perhatian',
          statusIcon: Icons.warning_amber_rounded,
          statusColor: AppColors.adminAccentYellow,
        );
      case _PerformanceCategory.critical:
        return _PerformanceVisualData(
          category: category,
          progressColor: AppColors.adminAccentRed,
          avatarGradient: const LinearGradient(
            colors: [Color(0xFFF472B6), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusLabel: 'Perlu Tindakan',
          statusIcon: Icons.priority_high_rounded,
          statusColor: AppColors.adminAccentRed,
        );
    }
  }

  String _formatPercentage(double value) {
    final double percent = (value * 100).clamp(0, 100);
    return '${percent.toStringAsFixed(0)}%';
  }

  String _extractInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _formatRole(String role) {
    if (role.trim().isEmpty) return '-';
    return role.replaceAll('_', ' ').trim().toUpperCase();
  }

  Widget _buildReportsSection(List<Report> reports) {
    final bool isCompact = MediaQuery.of(context).size.width < 720;
    final int totalRecords = reports.length;
    final DateTime? lastUpdate = reports.isEmpty
        ? null
        : reports
            .map((report) => report.updatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final List<_ReportGroup> groups = _groupReportsByOwner(reports);

    return AdminSectionCard(
      title:
          'Laporan Aktivitas Harian (${_formatNumber(totalRecords)} records)',
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: isCompact ? 20 : 28),
      trailing: Wrap(
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (lastUpdate != null) _buildRealtimeBadge(lastUpdate),
          _buildLiveIndicator(),
        ],
      ),
      child: _loading && reports.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : reports.isEmpty
              ? const AdminEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada laporan',
                  message:
                      'Coba atur ulang filter tanggal atau segarkan data.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < groups.length; i++) ...[
                      _buildReportGroupHeader(groups[i]),
                      const SizedBox(height: 12),
                      if (isCompact)
                        _buildReportGroupMobile(groups[i])
                      else
                        _buildReportGroupDesktop(groups[i]),
                      if (i != groups.length - 1)
                        const Divider(height: 32),
                    ],
                  ],
                ),
    );
  }

  Widget _buildRealtimeBadge(DateTime timestamp) {
    final theme = Theme.of(context);
    final String timeText = DateFormat('HH.mm', 'id_ID')
        .format(timestamp.toLocal())
        .replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacityRatio(0.08),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: theme.colorScheme.primary.withOpacityRatio(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.update_rounded,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Update Real-time: $timeText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.adminAccentGreen.withOpacityRatio(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.adminAccentGreen.withOpacityRatio(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.adminAccentGreen,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.adminAccentGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGroupHeader(_ReportGroup group) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${group.reports.length} laporan',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReportGroupDesktop(_ReportGroup group) {
    return Column(
      children: [
        _buildReportDesktopHeaderRow(),
        const SizedBox(height: 8),
        ...List.generate(group.reports.length, (index) {
          return Column(
            children: [
              _buildReportDesktopRow(group.reports[index], index + 1),
              if (index != group.reports.length - 1)
                const Divider(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildReportDesktopHeaderRow() {
    final theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: theme.colorScheme.primary.withOpacityRatio(0.8),
    );

    Widget buildCell(String text,
        {int flex = 1, TextAlign align = TextAlign.left}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          style: style,
          textAlign: align,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacityRatio(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          buildCell('NO', flex: 1),
          const SizedBox(width: 12),
          buildCell('TANGGAL', flex: 2),
          const SizedBox(width: 12),
          buildCell('WAKTU INPUT REALTIME', flex: 2),
          const SizedBox(width: 12),
          buildCell('STATUS UPDATE', flex: 1),
          const SizedBox(width: 12),
          buildCell('DATA LAPORAN', flex: 3),
          const SizedBox(width: 12),
          buildCell('AKSI', flex: 1, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReportDesktopRow(Report report, int index) {
    final theme = Theme.of(context);
    final DateTime reportDate = report.date.toLocal();
    final DateTime updatedAt = report.updatedAt.toLocal();
    final String primaryDate =
        DateFormat('EEEE, dd/MM/yyyy', 'id_ID').format(reportDate);
    final String secondaryDate =
        DateFormat('d/M/yyyy', 'id_ID').format(reportDate);
    final String updateTimestamp =
        DateFormat('EEE, dd/MM/yyyy, HH.mm.ss', 'id_ID').format(updatedAt);
    final String relativeTime = _formatRelativeTime(updatedAt);
    final String ownerName = report.owner?.name ?? 'Tidak diketahui';
    final _ReportStatusVisual statusVisual = _resolveReportStatusVisual(report);

    return InkWell(
      onTap: () => _showReportDetail(report),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '$index',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondaryDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          updateTimestamp,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.adminAccentGreen.withOpacityRatio(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      relativeTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.adminAccentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(
                        '$ownerName WIB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildReportStatusChip(statusVisual),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildReportDataEntries(report),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReportDetail(report),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(report),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adminAccentRed,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportGroupMobile(_ReportGroup group) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: group.reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildReportMobileCard(group.reports[index], index + 1),
    );
  }

  Widget _buildReportMobileCard(Report report, int index) {
    final theme = Theme.of(context);
    final DateTime reportDate = report.date.toLocal();
    final DateTime updatedAt = report.updatedAt.toLocal();
    final String dateHeader =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(reportDate);
    final String timeStamp =
        DateFormat('dd MMM yyyy, HH.mm', 'id_ID').format(updatedAt);
    final String relativeTime = _formatRelativeTime(updatedAt);
    final String ownerName = report.owner?.name ?? 'Tidak diketahui';
    final _ReportStatusVisual statusVisual = _resolveReportStatusVisual(report);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _showReportDetail(report),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#$index',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _buildReportStatusChip(statusVisual),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dateHeader,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$timeStamp • $relativeTime',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 16,
                      color:
                          theme.textTheme.bodySmall?.color?.withOpacity(0.65)),
                  const SizedBox(width: 6),
                  Text(
                    '$ownerName WIB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReportDataEntries(report),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReportDetail(report),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(report),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adminAccentRed,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDataEntries(Report report) {
    final theme = Theme.of(context);
    final entries = _extractEntries(report);
    if (entries.isEmpty) {
      return Text(
        'Tidak ada detail aktivitas.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      );
    }

    const int maxLines = 8;
    final List<MapEntry<String, String>> limited =
        entries.length > maxLines ? entries.take(maxLines).toList() : entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in limited)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              entry.value.isEmpty
                  ? '${entry.key}:'
                  : '${entry.key}: ${entry.value}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (entries.length > maxLines)
          Text(
            '+${entries.length - maxLines} item lainnya',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildReportStatusChip(_ReportStatusVisual visual) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visual.color.withOpacityRatio(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.color.withOpacityRatio(0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 16, color: visual.color),
          const SizedBox(width: 6),
          Text(
            visual.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: visual.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds.abs() < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes.abs() < 60) {
      return '${diff.inMinutes.abs()} menit yang lalu';
    } else if (diff.inHours.abs() < 24) {
      return '${diff.inHours.abs()} jam yang lalu';
    } else if (diff.inDays.abs() < 7) {
      return '${diff.inDays.abs()} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(timestamp);
    }
  }

  _ReportStatusVisual _resolveReportStatusVisual(Report report) {
    final String status = _resolveReportStatus(report);
    final String normalized = status.toLowerCase();
    if (normalized.contains('revisi')) {
      return _ReportStatusVisual(
        label: status,
        color: AppColors.adminAccentYellow,
        icon: Icons.cached_rounded,
      );
    } else if (normalized.contains('hapus') || normalized.contains('cancel')) {
      return _ReportStatusVisual(
        label: status,
        color: AppColors.adminAccentRed,
        icon: Icons.priority_high_rounded,
      );
    }
    return _ReportStatusVisual(
      label: status.isEmpty ? 'Original' : status,
      color: AppColors.adminAccentGreen,
      icon: Icons.bolt_rounded,
    );
  }

  String _resolveReportStatus(Report report) {
    const keys = ['status', 'statusUpdate', 'status_update', 'updateStatus'];
    for (final key in keys) {
      final value = report.reportData[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Original';
  }

  List<_ReportGroup> _groupReportsByOwner(List<Report> reports) {
    if (reports.isEmpty) return const <_ReportGroup>[];
    final Map<String, _ReportGroupBuilder> builders = {};
    for (final report in reports) {
      final owner = report.owner;
      final String key;
      if (owner == null || owner.email.isEmpty) {
        key = owner?.name ?? 'Tanpa nama';
      } else {
        key = owner.email;
      }
      builders.putIfAbsent(
        key,
        () => _ReportGroupBuilder(owner: owner),
      );
      builders[key]!.reports.add(report);
    }

    return builders.values.map((builder) => builder.build()).toList()
      ..sort((a, b) {
        final DateTime aTime = a.reports.first.updatedAt;
        final DateTime bTime = b.reports.first.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  void _confirmDelete(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.admin(),
        child: AlertDialog(
          title: const Text('Hapus Laporan'),
          content: const Text(
              'Tindakan ini akan menghapus laporan aktivitas ini. Anda yakin?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.adminAccentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteReport(
          token: _session.token, reportId: report.id);
      await _loadReports(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus laporan: ${e.toString()}')),
      );
    }
  }

  void _showReportDetail(Report report) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final entries = _extractEntries(report);
        final theme = AppTheme.admin();
        final dateLabel =
            DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(report.date);
        final created = DateFormat('dd MMM yyyy HH:mm', 'id_ID')
            .format(report.createdAt.toLocal());
        final updated = DateFormat('dd MMM yyyy HH:mm', 'id_ID')
            .format(report.updatedAt.toLocal());
        return Theme(
          data: theme,
          child: AlertDialog(
            title: Text(report.owner?.name ?? 'Detail Laporan'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dateLabel,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('Dibuat: $created', style: theme.textTheme.bodySmall),
                    Text('Diperbarui: $updated',
                        style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    if (entries.isEmpty)
                      const Text('Tidak ada data aktivitas.')
                    else
                      ...entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _humanizeKey(entry.key),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(entry.value,
                                    style: theme.textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup')),
            ],
          ),
        );
      },
    );
  }

  List<_MetricItem> _buildMetricItems(
      List<Report> reports, List<_UserPerformance> performance) {
    if (reports.isEmpty) return [];

    final uniqueUsers = performance.length;
    int compliantCount = 0;
    int goodCount = 0;
    int warningCount = 0;
    int dangerCount = 0;
    double totalCompletion = 0;

    for (final p in performance) {
      totalCompletion += p.completionRate;
      if (p.completionRate >= 0.95) {
        compliantCount++;
      } else if (p.completionRate >= 0.75) {
        goodCount++;
      } else if (p.completionRate >= 0.5) {
        warningCount++;
      } else {
        dangerCount++;
      }
    }

    final averageCompletion =
        uniqueUsers > 0 ? totalCompletion / uniqueUsers : 0.0;

    return [
      _MetricItem(
        icon: Icons.people_alt_rounded,
        label: 'Total User Aktif',
        value: _formatNumber(uniqueUsers),
        color: AppColors.adminPrimary,
      ),
      _MetricItem(
        icon: Icons.check_circle_rounded,
        label: 'Kepatuhan > 95%',
        value: _formatNumber(compliantCount),
        color: AppColors.adminAccentGreen,
      ),
      _MetricItem(
        icon: Icons.thumb_up_rounded,
        label: 'Kepatuhan > 75%',
        value: _formatNumber(goodCount),
        color: Colors.lightBlue,
      ),
      _MetricItem(
        icon: Icons.warning_rounded,
        label: 'Kepatuhan > 50%',
        value: _formatNumber(warningCount),
        color: AppColors.adminAccentYellow,
      ),
      _MetricItem(
        icon: Icons.error_rounded,
        label: 'Kepatuhan < 50%',
        value: _formatNumber(dangerCount),
        color: AppColors.adminAccentRed,
      ),
      _MetricItem(
        icon: Icons.pie_chart_rounded,
        label: 'Rata-rata Kepatuhan',
        value: '${(averageCompletion * 100).toStringAsFixed(0)}%',
        color: Colors.purple,
      ),
    ];
  }

  List<_UserPerformance> _aggregateUserPerformance(List<Report> reports) {
    final Map<String, _UserPerformanceBuilder> aggregations = {};
    if (_reports.isEmpty) return [];

    final allUsers =
        _reports.map((r) => r.owner).whereType<ReportOwner>().toSet();

    int totalPeriodDays;
    final now = DateTime.now();
    switch (_quickFilter) {
      case _ReportQuickFilter.all:
        final firstReport =
            _reports.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
        totalPeriodDays = now.difference(firstReport).inDays + 1;
        break;
      case _ReportQuickFilter.today:
        totalPeriodDays = 1;
        break;
      case _ReportQuickFilter.week:
        totalPeriodDays = 7;
        break;
      case _ReportQuickFilter.month:
        totalPeriodDays = 30;
        break;
      case _ReportQuickFilter.custom:
        totalPeriodDays = (_customRange?.duration.inDays ?? 0) + 1;
        break;
    }
    totalPeriodDays = max(1, totalPeriodDays);

    for (final user in allUsers) {
      final key = user.email.isNotEmpty ? user.email : user.name;
      aggregations.putIfAbsent(
        key,
        () => _UserPerformanceBuilder(
          name: user.name,
          email: user.email,
          role: user.role,
          reportDates: {},
        ),
      );
    }

    for (final report in reports) {
      final owner = report.owner;
      if (owner == null) continue;
      final key = owner.email.isNotEmpty ? owner.email : owner.name;
      aggregations[key]?.reportDates.add(_stripTime(report.date));
    }

    final performances = aggregations.values.map((builder) {
      final daysReported = builder.reportDates.length;
      final completionRate = (daysReported / totalPeriodDays).clamp(0.0, 1.0);
      final daysMissed = totalPeriodDays - daysReported;
      final DateTime? lastReportDate = builder.reportDates.isEmpty
          ? null
          : builder.reportDates.reduce(
              (a, b) => a.isAfter(b) ? a : b,
            );

      final String status;
      if (completionRate >= 0.95) {
        status = 'Sangat Baik';
      } else if (completionRate >= 0.75) {
        status = 'Baik';
      } else if (completionRate >= 0.5) {
        status = 'Perlu Perhatian';
      } else {
        status = 'Perlu Tindakan';
      }

      return _UserPerformance(
        name: builder.name,
        email: builder.email,
        role: builder.role,
        totalReports: daysReported,
        daysReported: daysReported,
        daysMissed: max(0, daysMissed),
        status: status,
        rank: 0,
        completionRate: completionRate,
        totalPeriodDays: totalPeriodDays,
        lastReportDate: lastReportDate,
      );
    }).toList();

    performances.sort((a, b) {
      final compare = b.completionRate.compareTo(a.completionRate);
      if (compare != 0) return compare;
      return a.name.compareTo(b.name);
    });

    return performances
        .asMap()
        .entries
        .map((e) => e.value.copyWith(rank: e.key + 1))
        .toList();
  }

  List<MapEntry<String, String>> _extractEntries(Report report) {
    return report.reportData.entries
        .where((entry) {
          final key = entry.key.toLowerCase();
          if (entry.value == null) return false;
          if (key.contains('status')) return false;
          return true;
        })
        .map((entry) => MapEntry(entry.key, entry.value.toString().trim()))
        .toList();
  }

  DateTime _stripTime(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatNumber(int value) => _numberFormat.format(value);

  String _humanizeKey(String key) {
    final withSpaces = key.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    final cleaned = withSpaces.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color textColor = color.withOpacityRatio(0.82);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacityRatio(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacityRatio(0.22), width: 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacityRatio(0.15),
              ),
              child: Icon(icon, size: 16, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}

class _ReportStatusVisual {
  const _ReportStatusVisual({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _ReportGroupBuilder {
  _ReportGroupBuilder({this.owner}) : reports = <Report>[];

  final ReportOwner? owner;
  final List<Report> reports;

  _ReportGroup build() {
    reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _ReportGroup(
      owner: owner,
      reports: List<Report>.unmodifiable(reports),
    );
  }
}

class _ReportGroup {
  const _ReportGroup({required this.owner, required this.reports});

  final ReportOwner? owner;
  final List<Report> reports;

  String get displayName {
    final name = owner?.name ?? '';
    if (name.trim().isEmpty) return 'Tanpa nama';
    return name;
  }

  String get email => owner?.email ?? '';
}

class _PerformanceVisualData {
  const _PerformanceVisualData({
    required this.category,
    required this.progressColor,
    required this.avatarGradient,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
  });

  final _PerformanceCategory category;
  final Color progressColor;
  final LinearGradient avatarGradient;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusColor;
}

@immutable
class _UserPerformance {
  const _UserPerformance({
    required this.name,
    required this.email,
    required this.role,
    required this.totalReports,
    required this.daysReported,
    required this.daysMissed,
    required this.status,
    required this.rank,
    required this.completionRate,
    required this.totalPeriodDays,
    this.lastReportDate,
  });

  final String name;
  final String email;
  final String role;
  final int totalReports;
  final int daysReported;
  final int daysMissed;
  final String status;
  final int rank;
  final double completionRate;
  final int totalPeriodDays;
  final DateTime? lastReportDate;

  _UserPerformance copyWith({int? rank, DateTime? lastReportDate}) {
    return _UserPerformance(
      name: name,
      email: email,
      role: role,
      totalReports: totalReports,
      daysReported: daysReported,
      daysMissed: daysMissed,
      status: status,
      rank: rank ?? this.rank,
      completionRate: completionRate,
      totalPeriodDays: totalPeriodDays,
      lastReportDate: lastReportDate ?? this.lastReportDate,
    );
  }
}

class _UserPerformanceBuilder {
  _UserPerformanceBuilder({
    required this.name,
    required this.email,
    required this.role,
    required this.reportDates,
  });

  final String name;
  final String email;
  final String role;
  final Set<DateTime> reportDates;
}
