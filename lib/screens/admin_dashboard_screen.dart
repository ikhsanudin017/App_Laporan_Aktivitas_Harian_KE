import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
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
    return RefreshIndicator(
      color: AppColors.adminSecondary,
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildErrorBanner(),
              ),
            _buildMetricsGrid(metrics),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildUserPerformance(performance),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildReportsSection(reports),
            ),
          ],
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
    return FilledButton.icon(
      onPressed: onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppColors.adminAccentRed.withOpacityRatio(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.adminAccentRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.adminAccentRed),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.adminAccentRed,
            tooltip: 'Sembunyikan',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<_MetricItem> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width >= 1200
          ? 6
          : width >= 800
              ? 3
              : 2;
      final aspectRatio = width < 500
          ? 1.2
          : width < 800
              ? 1.0
              : 1.5;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: aspectRatio,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _DashboardMetricCard(
              icon: metric.icon,
              label: metric.label,
              value: metric.value,
              color: metric.color ?? Colors.blue,
            );
          },
        ),
      );
    });
  }

  Widget _buildUserPerformance(List<_UserPerformance> performance) {
    return AdminSectionCard(
      title: 'Performa Kepatuhan User',
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: performance.isEmpty
          ? const AdminEmptyState(
              icon: Icons.insights_outlined,
              title: 'Belum ada data performa',
              message:
                  'Saat laporan mulai masuk, ringkasan kepatuhan tim akan tampil di sini.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPerformanceChart(performance),
                ),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: performance.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 24, endIndent: 24),
                  itemBuilder: (context, index) {
                    return _buildUserPerformanceTile(performance[index]);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPerformanceChart(List<_UserPerformance> performance) {
    final theme = Theme.of(context);

    if (performance.isEmpty) return const SizedBox.shrink();

    final maxValue =
        performance.map((p) => p.totalPeriodDays).reduce(max).toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = performance[group.x.toInt()];
                return BarTooltipItem(
                  '${p.name.split(' ').first}\n',
                  theme.textTheme.bodyLarge!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          '${p.daysReported} dari ${p.totalPeriodDays} hari\n',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(color: Colors.white),
                    ),
                    TextSpan(
                      text:
                          '${(p.completionRate * 100).toStringAsFixed(0)}% Kepatuhan',
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == meta.max)
                      return const SizedBox.shrink();
                    return Text(value.toInt().toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.left);
                  }),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final name = performance[value.toInt()].name;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(name.split(' ').first,
                        style: theme.textTheme.bodySmall),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.adminCardBorder.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          barGroups: performance
              .asMap()
              .map((index, p) => MapEntry(
                    index,
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: p.daysReported.toDouble(),
                          gradient: AppColors.adminButtonGradient,
                          width: 22,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        )
                      ],
                    ),
                  ))
              .values
              .toList(),
        ),
      ),
    );
  }

  Widget _buildUserPerformanceTile(_UserPerformance performance) {
    final theme = Theme.of(context);
    final initials = performance.name.isNotEmpty
        ? performance.name.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.adminPrimary.withOpacity(0.1),
        child: Text(
          initials.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.adminPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        performance.name.isEmpty ? 'Tidak Diketahui' : performance.name,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${performance.daysReported} dari ${performance.totalPeriodDays} hari (${(performance.completionRate * 100).toStringAsFixed(0)}%)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.slate.withOpacity(0.7),
        ),
      ),
      trailing: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: performance.completionRate,
              backgroundColor: AppColors.adminPrimary.withOpacity(0.15),
              color: AppColors.adminPrimary,
              strokeWidth: 5,
            ),
            Text(
              '#${performance.rank}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  Widget _buildReportsSection(List<Report> reports) {
    final theme = Theme.of(context);
    return AdminSectionCard(
      title: 'Log Laporan Terbaru',
      padding: EdgeInsets.zero,
      trailing: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.adminSecondaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '${reports.length} Laporan',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.adminPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: _loading && reports.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.adminSecondary),
              ),
            )
          : reports.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: AdminEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada laporan',
                    message:
                        'Coba atur ulang filter tanggal atau segarkan data.',
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth < 720) {
                    // Mobile view: Cards
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildReportCard(reports[index], index + 1),
                    );
                  } else {
                    // Desktop view: Table
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildReportTableHeader(theme),
                        const Divider(height: 1),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16),
                          itemBuilder: (context, index) {
                            return _buildReportTableRow(
                                reports[index], index + 1);
                          },
                        ),
                      ],
                    );
                  }
                }),
    );
  }

  Widget _buildReportTableHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('NO',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 4,
              child: Text('NAMA',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child: Text('TANGGAL',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 6,
              child: Text('DATA LAPORAN',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child: Text('AKSI',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildReportTableRow(Report report, int index) {
    final theme = Theme.of(context);
    final ownerName = report.owner?.name ?? 'Tanpa nama';
    final dateText = DateFormat('dd MMM yyyy', 'id_ID').format(report.date);
    final summary = _summarizeReport(report);

    return InkWell(
      onTap: () => _showReportDetail(report),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 1,
                child: Text('$index', style: theme.textTheme.bodyMedium)),
            Expanded(
                flex: 4,
                child: Text(ownerName,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis)),
            Expanded(
                flex: 3,
                child: Text(dateText, style: theme.textTheme.bodyMedium)),
            Expanded(
                flex: 6,
                child: Text(summary,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 3,
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => _showReportDetail(report),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Detail'),
                  ),
                  TextButton(
                    onPressed: () => _confirmDelete(report),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adminAccentRed,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Report report, int index) {
    final theme = Theme.of(context);
    final ownerName = report.owner?.name ?? 'Tanpa nama';
    final dateText =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(report.date);
    final timeText =
        'Diperbarui: ${DateFormat('dd MMM HH:mm', 'id_ID').format(report.updatedAt)}';
    final summary = _summarizeReport(report);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.adminCardBorder.withOpacity(0.8)),
      ),
      color: AppColors.adminSecondaryLight.withOpacity(0.3),
      child: InkWell(
        onTap: () => _showReportDetail(report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ownerName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('#$index',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.slate)),
                ],
              ),
              const Divider(height: 20),
              Text(dateText, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(timeText, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(
                summary,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate.withOpacity(0.9)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _confirmDelete(report),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.adminAccentRed,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _showReportDetail(report),
                      child: const Text('Lihat Detail'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        final created =
            DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(report.createdAt);
        final updated =
            DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(report.updatedAt);
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
        .where((entry) =>
            entry.value != null &&
            entry.value.toString().trim().isNotEmpty &&
            entry.value.toString().trim() != '0')
        .map((entry) => MapEntry(entry.key, entry.value.toString().trim()))
        .toList();
  }

  String _summarizeReport(Report report) {
    final entries = _extractEntries(report);
    if (entries.isEmpty) return 'Tidak ada detail aktivitas.';
    return entries
        .take(3)
        .map((e) => '${_humanizeKey(e.key)}: ${e.value}')
        .join(' • ');
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
    return Card(
      color: color.withOpacity(0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
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

  _UserPerformance copyWith({int? rank}) {
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
