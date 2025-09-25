import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/user_options.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/background_pattern.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';

enum LoginMode { user, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService();

  LoginMode _loginMode = LoginMode.user;
  UserOption? _selectedUser;
  bool _loading = false;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _adminFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(LoginMode mode) {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loginMode = mode;
      _errorMessage = null;
    });
  }

  Future<void> _handleUserLogin() async {
    FocusScope.of(context).unfocus();
    if (_selectedUser == null) {
      setState(
          () => _errorMessage = 'Silakan pilih nama Anda terlebih dahulu.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1));
    final option = _selectedUser!;
    final user = AppUser(
      id: option.id.toString(),
      name: option.name,
      email: option.email,
      role: option.role,
    );
    final token = 'mock-token-${option.id}';

    await _sessionService.saveSession(user, token);
    if (!mounted) return;

    _navigateToDashboard(SessionData(user: user, token: token));
  }

  Future<void> _handleAdminLogin() async {
    final form = _adminFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = await _apiService.loginAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _sessionService.saveSession(session.user, session.token);
      if (!mounted) return;
      _navigateToDashboard(session);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _navigateToDashboard(SessionData session) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => session.user.isAdmin
            ? AdminDashboardScreen(initialSession: session)
            : DashboardScreen(initialSession: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPattern(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout();
          }
          return _buildNarrowLayout();
        }),
      ),
    );
  }

  Widget _buildWideLayout() {
    return ResponsiveContent(
      alignment: Alignment.center,
      child: Row(
        children: [
          const Expanded(child: _SideInfoPanel()),
          Expanded(
            child: Center(
              child: _buildMobileContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SafeArea(
      child: Center(
        child: _buildMobileContent(),
      ),
    );
  }

  Widget _buildMobileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo-ksu-ke.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            _buildTitles(),
            const SizedBox(height: 24),
            _buildFormCard(),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitles() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Sistem Laporan Aktivitas',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'KOPERASI SERBA USAHA',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          'KIRAP ENTREPRENEURSHIP',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 20),
        _HeadingDivider(),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSelector(activeMode: _loginMode, onChanged: _setMode),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              _AnimatedMessage(message: _errorMessage!, isError: true),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _loginMode == LoginMode.user
                  ? _buildUserSelection()
                  : _buildAdminForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelection() {
    return Column(
      key: const ValueKey('user-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DropdownLabel(),
        const SizedBox(height: 8),
        DropdownButtonFormField<UserOption>(
          value: _selectedUser,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: '-- Pilih Nama Anda --',
          ),
          items: userOptions.map((user) {
            return DropdownMenuItem(
              value: user,
              child: Text(
                user.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedUser = value),
        ),
        const SizedBox(height: 24),
        _LoginButton(
          onPressed: _loading ? null : _handleUserLogin,
          isLoading: _loading && _loginMode == LoginMode.user,
        ),
      ],
    );
  }

  Widget _buildAdminForm() {
    return Form(
      key: _adminFormKey,
      child: Column(
        key: const ValueKey('admin-login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v?.isEmpty ?? true) ? 'Email wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) =>
                (v?.isEmpty ?? true) ? 'Password wajib diisi' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _handleAdminLogin,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Login as Admin'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Dengan berkah Allah SWT',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _HeadingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(radius: 3, backgroundColor: AppColors.secondary),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.activeMode, required this.onChanged});

  final LoginMode activeMode;
  final ValueChanged<LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<LoginMode>(
        segments: const <ButtonSegment<LoginMode>>[
          ButtonSegment<LoginMode>(
            value: LoginMode.user,
            label: Text('Staff / User'),
            icon: Icon(Icons.person_outline),
          ),
          ButtonSegment<LoginMode>(
            value: LoginMode.admin,
            label: Text('Admin'),
            icon: Icon(Icons.shield_outlined),
          ),
        ],
        selected: <LoginMode>{activeMode},
        onSelectionChanged: (Set<LoginMode> newSelection) {
          onChanged(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
          foregroundColor: theme.textTheme.bodyLarge?.color,
          selectedForegroundColor: theme.colorScheme.onPrimary,
          selectedBackgroundColor: theme.colorScheme.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_search_outlined,
            size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Pilih Nama Anda',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: isLoading
          ? const SizedBox.shrink()
          : const Icon(Icons.login_rounded, color: Colors.white),
      label: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Text(
              'Masuk ke Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _SideInfoPanel extends StatelessWidget {
  const _SideInfoPanel();

  @override
  Widget build(BuildContext context) {
    return BackgroundPattern(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo-ksu-ke.png',
                height: 120,
              ),
              const SizedBox(height: 24),
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'di Sistem Laporan Aktivitas KSU Kirap Entrepreneurship.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      key: ValueKey(message),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
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
