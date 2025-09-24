import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/user_options.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_extensions.dart';
import '../utils/responsive.dart';
import '../widgets/background_pattern.dart';
import '../widgets/ksu_button.dart';
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
    FocusScope.of(context).unfocus();
    setState(() {
      _loginMode = mode;
      _errorMessage = null;
      _loading = false;
    });
  }

  Future<void> _handleUserLogin() async {
    FocusScope.of(context).unfocus();
    if (_selectedUser == null) {
      setState(
          () => _errorMessage = 'Silakan pilih nama Anda terlebih dahulu.');
      return;
    }

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
    if (form == null) {
      return;
    }
    if (!form.validate()) {
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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final maxContentWidth = isWide ? 1100.0 : 520.0;

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 24,
                    vertical: isWide ? 32 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child:
                                      _IntroPanel(isTablet: context.isTablet)),
                              const SizedBox(width: 36),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 440),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: _buildLoginCardContent(),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _buildLoginCardContent(),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCardContent() {
    final isAdmin = _loginMode == LoginMode.admin;
    final bool isMobile = context.isMobile;
    final double radius = isMobile ? 28 : 32;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DE),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEADBB5), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(212, 184, 120, 0.22),
            blurRadius: 32,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 40,
        vertical: isMobile ? 28 : 38,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeaderLogo(isCompact: isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          Text(
            'Sistem Laporan Aktivitas',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KSU KIRAP ENTREPRENEURSHIP',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryDeep,
            ),
          ),
          const SizedBox(height: 24),
          const _HeadingDivider(),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7EE),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFCDE5D6)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(37, 140, 86, 0.12),
                  blurRadius: 22,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 28,
              vertical: isMobile ? 24 : 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeSelector(
                  activeMode: _loginMode,
                  onChanged: _setMode,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _errorMessage == null
                      ? const SizedBox.shrink()
                      : _AnimatedMessage(
                          message: _errorMessage!, isError: true),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: isAdmin ? _buildAdminForm() : _buildUserSelection(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '© 2025 KSU Kirap Entrepreneurship',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelection() {
    return Column(
      key: const ValueKey('user-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masuk sebagai Pengguna',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<UserOption>(
          isExpanded: true,
          value: _selectedUser,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '-- Pilih Nama Anda --',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: AppColors.cardBorder.withOpacity(0.6), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          items: userOptions
              .map(
                (user) => DropdownMenuItem(
                  value: user,
                  child: Text(
                    user.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedUser = value),
        ),
        const SizedBox(height: 32),
        KsuButton(
          onPressed: _loading ? null : _handleUserLogin,
          label: 'Masuk ke Dashboard',
          icon: Icons.arrow_forward_ios_rounded,
          isLoading: _loading && _loginMode == LoginMode.user,
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: AppColors.primaryDark,
          shadowColor: AppColors.goldDeep.withOpacityRatio(0.32),
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
          Text(
            'Masuk sebagai Admin',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.adminPrimaryDark,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email admin',
              hintText: 'nama@ksuke.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.cardBorder.withOpacity(0.6), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.adminPrimary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.cardBorder.withOpacity(0.6), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.adminPrimary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          KsuButton(
            onPressed: _loading ? null : _handleAdminLogin,
            label: 'Masuk sebagai Admin',
            icon: Icons.login_rounded,
            isLoading: _loading,
            backgroundColor: AppColors.adminPrimary,
            foregroundColor: AppColors.adminPrimaryDark,
            shadowColor: AppColors.adminSecondary.withOpacityRatio(0.26),
          ),
        ],
      ),
    );
  }
}

class _HeadingDivider extends StatelessWidget {
  const _HeadingDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 1.2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacityRatio(0.0),
                  AppColors.gold.withOpacityRatio(0.8),
                  AppColors.gold.withOpacityRatio(0.0),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 1.2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacityRatio(0.0),
                  AppColors.gold.withOpacityRatio(0.8),
                  AppColors.gold.withOpacityRatio(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(right: isTablet ? 12 : 24, top: 60, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 44 : 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'di Sistem Laporan Aktivitas KSU Kirap Entrepreneurship.',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 18 : 22,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            'Platform digital untuk memantau dan melaporkan aktivitas harian para pegawai di lapangan secara efisien dan transparan.',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 15 : 16,
              color: Colors.white.withOpacity(0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final double outerSize = isCompact ? 132 : 150;
    final double innerSize = isCompact ? 108 : 124;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacityRatio(0.18),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.gold.withOpacityRatio(0.68), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(45, 90, 61, 0.18),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo-ksu-ke.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.activeMode, required this.onChanged});

  final LoginMode activeMode;
  final ValueChanged<LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 520;
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7ED),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCFE4D4)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(46, 125, 81, 0.12),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _ModeTile(
            label: 'Staff / User',
            isActive: activeMode == LoginMode.user,
            onTap: () => onChanged(LoginMode.user),
            icon: Icons.groups_rounded,
            activeBackground: AppColors.secondary,
            activeTextColor: AppColors.primaryDark,
            activeBorderColor: AppColors.secondaryDeep.withOpacityRatio(0.6),
            activeGradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            inactiveBackground: Colors.transparent,
            inactiveTextColor: AppColors.primaryDark,
            inactiveBorderColor: AppColors.cardBorder.withOpacity(0.8),
          ),
          _ModeTile(
            label: 'Admin',
            isActive: activeMode == LoginMode.admin,
            onTap: () => onChanged(LoginMode.admin),
            icon: Icons.verified_user_outlined,
            activeBackground: AppColors.adminPrimary,
            activeTextColor: AppColors.adminSecondaryLight,
            activeBorderColor: AppColors.adminSecondary.withOpacityRatio(0.5),
            activeGradient: const LinearGradient(
              colors: [AppColors.adminPrimary, AppColors.adminSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            inactiveBackground: Colors.transparent,
            inactiveTextColor: AppColors.adminPrimaryDark,
            inactiveBorderColor: AppColors.adminCardBorder.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.icon,
    this.activeBackground,
    required this.activeTextColor,
    required this.activeBorderColor,
    this.activeGradient,
    this.inactiveBackground,
    this.inactiveTextColor,
    this.inactiveBorderColor,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData icon;
  final Color? activeBackground;
  final Color activeTextColor;
  final Color activeBorderColor;
  final LinearGradient? activeGradient;
  final Color? inactiveBackground;
  final Color? inactiveTextColor;
  final Color? inactiveBorderColor;

  @override
  Widget build(BuildContext context) {
    final Color resolvedInactiveText = inactiveTextColor ?? AppColors.primary;
    final Color borderColor = isActive
        ? activeBorderColor
        : (inactiveBorderColor ?? AppColors.cardBorder.withOpacityRatio(0.85));
    final Color? backgroundColor = isActive && activeGradient == null
        ? activeBackground
        : (!isActive ? inactiveBackground : null);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: isActive ? activeGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.3),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBorderColor.withOpacityRatio(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.white.withOpacityRatio(0.22)
                          : (inactiveBackground ?? AppColors.primary)
                              .withOpacityRatio(0.08),
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? activeTextColor : resolvedInactiveText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? activeTextColor : resolvedInactiveText,
                    ),
                  ),
                ],
              ),
            ),
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
    final color = isError
        ? const Color(0xFFFFF1F2)
        : AppColors.mint.withOpacityRatio(0.45);
    final borderColor = isError
        ? const Color(0xFFF87171)
        : AppColors.primary.withOpacityRatio(0.35);
    final textColor = isError ? const Color(0xFFDC2626) : AppColors.primary;

    return Container(
      key: ValueKey(message),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
