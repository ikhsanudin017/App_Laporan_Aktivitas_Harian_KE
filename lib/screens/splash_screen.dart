import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_pattern.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    final session = await _sessionService.loadSession();
    if (!mounted) return;

    if (session != null) {
      _goToDashboard(session);
    } else {
      _goToLogin();
    }
  }

  void _goToDashboard(SessionData session) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => session.user.isAdmin
            ? AdminDashboardScreen(initialSession: session)
            : DashboardScreen(initialSession: session),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPattern(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.asset('assets/images/logo-ksu-ke.png'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sistem Laporan Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KSU KIRAP ENTREPRENEURSHIP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _controller
                        .drive(CurveTween(curve: const Interval(0.5, 1.0))),
                    child: Text(
                      'Menyiapkan aplikasi...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark.withOpacity(0.8),
                      ),
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
