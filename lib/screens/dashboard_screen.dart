import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../config/form_configs.dart';
import '../models/app_user.dart';
import '../models/form_models.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/background_pattern.dart';
import '../widgets/ksu_button.dart';
import '../widgets/ksu_card.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.initialSession,
    this.initialReport,
    this.showLogoutButton = true,
  });

  final SessionData initialSession;
  final Report? initialReport;
  final bool showLogoutButton;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late SessionData _session;
  late AppUser _user;
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();

  FormConfig? _formConfig;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentTime = DateTime.now();
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> _reportData = {};

  bool _submitting = false;
  bool _loadingReport = false;
  bool _loadingHistory = false;
  bool _historyLoaded = false;
  String? _statusMessage;

  List<Report> _history = [];
  Report? _editingReport;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _user = _session.user;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_historyLoaded) {
        _loadHistory();
      }
    });

    initializeDateFormatting('id_ID', null);

    _formConfig = resolveFormConfig(_user.role);
    final initialReport = widget.initialReport;
    if (initialReport != null) {
      _selectedDate = initialReport.date;
    }
    _initializeControllers(
        initialData: initialReport?.reportData,
        resetStatus: initialReport == null);
    if (initialReport != null) {
      _editingReport = initialReport;
      _statusMessage = 'Data dimuat untuk diedit.';
    }
    _startClock();
  }

  void _initializeControllers({
    Map<String, dynamic>? initialData,
    bool resetStatus = true,
  }) {
    final config = _formConfig;
    if (config == null) {
      return;
    }

    final Map<String, dynamic> data = {};
    for (final field in config.fields) {
      final dynamic rawValue =
          initialData != null ? initialData[field.name] : null;
      final TextEditingController controller =
          _controllers[field.name] ?? TextEditingController();

      if (field.isNumericField) {
        final int value;
        if (rawValue is num) {
          value = rawValue.toInt();
        } else if (rawValue is String && rawValue.isNotEmpty) {
          value = int.tryParse(rawValue) ?? 0;
        } else {
          value = 0;
        }
        controller.text = value.toString();
        data[field.name] = value;
      } else {
        final String value = (rawValue ?? '').toString();
        controller.text = value;
        data[field.name] = value;
      }

      _controllers[field.name] = controller;
    }

    setState(() {
      _reportData = data;
      if (resetStatus) {
        _statusMessage = null;
      }
    });
  }

  void _startClock() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPattern(
      addScrollGradient: true,
      child: Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveHorizontalPadding,
                      vertical: context.isMobile ? 16 : 24,
                    ),
                    child: ResponsiveContent(
                      child: _DashboardHeader(
                        user: _user,
                        dateLabel: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(_currentTime),
                        onLogout:
                            _submitting || _loadingReport ? null : _logout,
                        onExport: _exportHistory,
                        showLogoutButton: widget.showLogoutButton,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveHorizontalPadding,
                    ),
                    child: ResponsiveContent(
                      child: _StatisticRow(
                        selectedDate: DateFormat('dd MMM yyyy', 'id_ID')
                            .format(_selectedDate),
                        filledCount: _filledFieldCount,
                        historyCount: _history.length,
                        role: _user.role,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.isMobile ? 16 : 24),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveHorizontalPadding,
                    ),
                    child: ResponsiveContent(
                      child: _buildTabSelector(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.isMobile ? 8 : 12),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInputView(context),
                _buildHistoryView(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.primary,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(text: 'Input Laporan'),
          Tab(text: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildInputView(BuildContext context) {
    final horizontalPadding = context.responsiveHorizontalPadding;
    final scrollPadding =
        EdgeInsets.symmetric(horizontal: horizontalPadding).add(
      EdgeInsets.only(
        top: context.isMobile ? 12 : 20,
        bottom: 120,
      ),
    );
    return RefreshIndicator(
      onRefresh: _loadLatestForDate,
      edgeOffset: 120,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: scrollPadding,
        child: ResponsiveContent(
          child: KsuCard(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 22 : 32,
              vertical: context.isMobile ? 24 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormHeader(context),
                const SizedBox(height: 24),
                _buildFieldsSection(context),
                const SizedBox(height: 28),
                if (_statusMessage != null)
                  StatusBanner(
                      message: _statusMessage!, isError: _statusIsError),
                const SizedBox(height: 28),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isEditing = _editingReport != null;

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submitReport,
            icon: _submitting
                ? const SizedBox.square(dimension: 20)
                : Icon(isEditing
                    ? Icons.check_circle_outline
                    : Icons.save_outlined),
            label: Text(isEditing ? 'Perbarui Laporan' : 'Simpan Laporan'),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _resetForm,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Form'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 8.0),
            TextButton(
              onPressed: _submitting ? null : _cancelEditing,
              child: const Text('Batalkan Edit'),
            ),
          ],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        if (isEditing)
          TextButton(
            onPressed: _submitting ? null : _cancelEditing,
            child: const Text('Batalkan'),
          ),
        OutlinedButton(
          onPressed: _submitting ? null : _resetForm,
          child: const Text('Reset'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submitReport,
          icon: _submitting
              ? const SizedBox.square(dimension: 20)
              : Icon(
                  isEditing ? Icons.check_circle_outline : Icons.save_outlined),
          label: Text(isEditing ? 'Perbarui' : 'Simpan'),
        ),
      ],
    );
  }

  Widget _buildFormHeader(BuildContext context) {
    final theme = Theme.of(context);
    final config = _formConfig;
    final dateLabel = DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config?.title ?? 'Form Laporan Harian',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tanggal laporan: $dateLabel',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _submitting ? null : _selectDate,
              icon: const Icon(Icons.date_range_outlined),
              label: const Text('Pilih Tanggal'),
            ),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _setTodayDate,
              icon: const Icon(Icons.wb_sunny_outlined),
              label: const Text('Hari Ini'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: _loadingReport ? null : _loadLatestForDate,
              icon: _loadingReport
                  ? const SizedBox.square(dimension: 20)
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(_loadingReport ? 'Memuat...' : 'Muat Data'),
            ),
          ],
        ),
        if (_editingReport != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_outlined,
                    color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mengedit laporan tanggal ${DateFormat('dd MMM yyyy', 'id_ID').format(_editingReport!.date)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldsSection(BuildContext context) {
    final config = _formConfig;
    if (config == null) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 660;
        final double itemWidth =
            isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: config.fields.map((field) {
            final bool fullWidth =
                !isWide || field.type == FormFieldType.textarea;
            final double width = fullWidth ? constraints.maxWidth : itemWidth;
            return SizedBox(width: width, child: _buildFormField(field));
          }).toList(),
        );
      },
    );
  }

  Widget _buildFormField(FormFieldConfig field) {
    final controller = _controllers[field.name]!;

    final decoration = InputDecoration(
      hintText: field.placeholder,
      labelText: field.label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );

    switch (field.type) {
      case FormFieldType.text:
        return TextFormField(
          controller: controller,
          decoration: decoration,
          onChanged: (value) => _updateField(field, value),
        );
      case FormFieldType.number:
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: decoration,
          onChanged: (value) => _updateField(field, value),
        );
      case FormFieldType.textarea:
        return TextFormField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          decoration: decoration,
          onChanged: (value) => _updateField(field, value),
        );
      case FormFieldType.date:
        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: decoration.copyWith(
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          onTap: () async {
            final initialDate = controller.text.isNotEmpty
                ? DateTime.tryParse(controller.text)
                : DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
              _updateField(field, controller.text);
            }
          },
        );
      case FormFieldType.dropdownNumber:
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: decoration.copyWith(
            suffixIcon: PopupMenuButton<int>(
              icon: const Icon(Icons.arrow_drop_down_rounded),
              onSelected: (value) {
                controller.text = value.toString();
                _updateField(field, controller.text);
              },
              itemBuilder: (_) => List.generate(
                31,
                (index) => PopupMenuItem<int>(
                  value: index,
                  child: Text(index.toString()),
                ),
              ),
            ),
          ),
          onChanged: (value) => _updateField(field, value),
        );
    }
  }

  Widget _buildHistoryView(BuildContext context) {
    final horizontalPadding = context.responsiveHorizontalPadding;
    final listPadding = EdgeInsets.symmetric(horizontal: horizontalPadding).add(
      EdgeInsets.only(
        top: context.isMobile ? 12 : 20,
        bottom: 120,
      ),
    );
    final List<Widget> content = [];
    if (_loadingHistory) {
      content.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(),
          ),
        ),
      ));
    } else if (_history.isEmpty) {
      content.add(KsuCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat laporan tersimpan.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tarik untuk menyegarkan atau tekan tombol di bawah ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadHistory,
              label: const Text('Muat Riwayat'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ));
    } else {
      content.addAll(_history.map(
        (report) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _HistoryTile(
            report: report,
            onEdit: () => _startEditing(report),
            onDelete: () => _confirmDelete(report),
            summary: _buildSummary(report.reportData),
            relativeTime: _relativeTime(report.updatedAt),
          ),
        ),
      ));
    }
    if (content.isEmpty) {
      content.add(const SizedBox.shrink());
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      edgeOffset: 120,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummary(Map<String, dynamic> data) {
    final entries = data.entries
        .where((entry) {
          final value = entry.value;
          if (value == null) return false;
          if (value is String && value.trim().isEmpty) return false;
          if (value is num && value == 0) return false;
          return true;
        })
        .take(3)
        .map((entry) => '${_fieldLabel(entry.key)}: ${entry.value}')
        .toList();
    return entries.join(', ');
  }

  String _fieldLabel(String key) {
    final config = _formConfig;
    if (config == null) {
      return key;
    }
    try {
      return config.fields.firstWhere((field) => field.name == key).label;
    } catch (_) {
      return key;
    }
  }

  String _relativeTime(DateTime date) {
    final diff = _currentTime.difference(date);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} hari lalu';
    }
    final months = (diff.inDays / 30).floor();
    return '$months bulan lalu';
  }

  int get _filledFieldCount {
    return _reportData.entries.where((entry) {
      final value = entry.value;
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (value is num && value == 0) return false;
      return true;
    }).length;
  }

  Future<void> _loadLatestForDate() async {
    setState(() {
      _loadingReport = true;
      _statusMessage = null;
    });

    try {
      final data = await _apiService.fetchReportDataForDate(
        token: _session.token,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (!mounted) return;
      _initializeControllers(initialData: data);
      setState(() {
        _statusMessage = data.isEmpty
            ? 'Belum ada data pada tanggal ini.'
            : 'Data tanggal ini berhasil dimuat.';
        _editingReport = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _statusMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Tidak dapat memuat data.');
    } finally {
      if (mounted) {
        setState(() => _loadingReport = false);
      }
    }
  }

  void _setTodayDate() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final reports =
          await _apiService.fetchReportHistory(token: _session.token);
      if (!mounted) return;
      setState(() {
        _history = reports;
        _historyLoaded = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat riwayat laporan.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  void _exportHistory() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data untuk diekspor.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Fitur export akan tersedia setelah integrasi Excel pada versi ini.'),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_formConfig == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _statusMessage = null;
    });

    final payload = <String, dynamic>{};
    payload.addAll(_reportData);

    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      if (_editingReport != null) {
        final report = await _apiService.updateReport(
          token: _session.token,
          reportId: _editingReport!.id,
          reportData: payload,
          date: date,
        );
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Laporan berhasil diperbarui.';
          _editingReport = null;
        });
        _initializeControllers(
            initialData: report.reportData, resetStatus: false);
      } else {
        await _apiService.createReport(
          token: _session.token,
          date: date,
          reportData: payload,
        );
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Laporan berhasil disimpan.';
        });
        _resetForm();
      }

      await _loadHistory();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _statusMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Gagal menyimpan laporan.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _updateField(FormFieldConfig field, String value) {
    setState(() {
      if (field.isNumericField) {
        final parsed = int.tryParse(value);
        _reportData[field.name] = parsed ?? 0;
      } else {
        _reportData[field.name] = value;
      }
    });
  }

  void _resetForm() {
    _initializeControllers();
    setState(() {
      _selectedDate = DateTime.now();
      _editingReport = null;
    });
  }

  void _startEditing(Report report) {
    _tabController.animateTo(0);
    _initializeControllers(initialData: report.reportData, resetStatus: false);
    setState(() {
      _editingReport = report;
      _selectedDate = report.date;
      _statusMessage = 'Data dimuat untuk diedit.';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingReport = null;
      _statusMessage = 'Mode edit dibatalkan.';
    });
    _resetForm();
  }

  Future<void> _confirmDelete(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Laporan'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (!mounted) return;

    try {
      await _apiService.deleteReport(
          token: _session.token, reportId: report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus.')),
      );
      await _loadHistory();
      if (!mounted) return;
      if (_editingReport?.id == report.id) {
        _resetForm();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus laporan.')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _logout() async {
    await _sessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  bool get _statusIsError {
    final message = _statusMessage?.toLowerCase();
    if (message == null) return false;
    return message.contains('gagal') ||
        message.contains('tidak') ||
        message.contains('error');
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.user,
    required this.dateLabel,
    required this.onLogout,
    required this.onExport,
    required this.showLogoutButton,
  });

  final AppUser user;
  final String dateLabel;
  final VoidCallback? onLogout;
  final VoidCallback onExport;
  final bool showLogoutButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(user.name);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 20 : 28,
        vertical: context.isMobile ? 20 : 26,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.22),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: context.isMobile ? 26 : 30,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: context.isMobile ? 20 : 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang,',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: context.isMobile ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeaderChip(
                icon: Icons.shield_moon_outlined,
                label: user.role,
              ),
              _HeaderChip(
                icon: Icons.calendar_today_outlined,
                label: dateLabel,
              ),
              _HeaderChip(
                icon: Icons.cloud_done_outlined,
                label: 'Sinkron otomatis',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KsuButton(
                      onPressed: onExport,
                      label: 'Export',
                      icon: Icons.download_outlined,
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                    if (showLogoutButton)
                      KsuButton(
                        onPressed: onLogout,
                        label: 'Logout',
                        icon: Icons.logout_rounded,
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      )
                    else
                      KsuButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        label: 'Kembali',
                        icon: Icons.arrow_back_ios_new,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return '';
    }
    String first = words.first.substring(0, 1).toUpperCase();
    String second =
        words.length > 1 ? words[1].substring(0, 1).toUpperCase() : '';
    return (first + second).trim();
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({
    required this.selectedDate,
    required this.filledCount,
    required this.historyCount,
    required this.role,
  });

  final String selectedDate;
  final int filledCount;
  final int historyCount;
  final String role;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatisticCard(
        icon: Icons.calendar_month,
        label: 'Tanggal Aktif',
        value: selectedDate,
      ),
      _StatisticCard(
        icon: Icons.task_alt_rounded,
        label: 'Kolom Terisi',
        value: '$filledCount bidang',
      ),
      _StatisticCard(
        icon: Icons.history_rounded,
        label: 'Riwayat Tersimpan',
        value: '$historyCount laporan',
      ),
      _StatisticCard(
        icon: Icons.workspace_premium_outlined,
        label: 'Peran Aktif',
        value: role,
      ),
    ];

    if (!context.isMobile) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: cards,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.report,
    required this.onEdit,
    required this.onDelete,
    required this.summary,
    required this.relativeTime,
  });

  final Report report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String summary;
  final String relativeTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(report.date);
    final createdAt = DateFormat('dd MMM yyyy HH:mm', 'id_ID')
        .format(report.createdAt.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formattedDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                  icon: Icon(Icons.more_vert_rounded,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.isNotEmpty)
              Text(
                summary,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 16, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Text(
                  'Diperbarui $relativeTime',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dibuat: $createdAt',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
