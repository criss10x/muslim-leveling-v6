import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_sync.dart';
import 'auth_screen.dart';
import 'welcome_pejuang.dart';
import 'dashboard_shell.dart';

/// Splash screen — pulsing shield + animated loading bar.
/// Mirrors splash_screen_animated_loading_sequence.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtl;
  late final AnimationController _barCtl;
  late final AnimationController _fadeCtl;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _barCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _navTimer = Timer(const Duration(milliseconds: 2400), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool('onboarding_done') ?? false;
        final nickname = prefs.getString('nickname');
        final hasProfile = done && nickname != null && nickname.isNotEmpty;
        final isAuth = AuthService.signedIn;
        _fadeCtl.forward().then((_) {
          if (mounted) {
            Widget dest;
            if (!isAuth) {
              dest = const AuthScreen();
            } else if (hasProfile) {
              dest = const DashboardShell();
            } else {
              dest = const WelcomePejuangScreen();
            }
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => dest,
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    _barCtl.dispose();
    _fadeCtl.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtl,
                  builder: (_, __) {
                    final t = _pulseCtl.value;
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3 + 0.4 * t),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15 + 0.4 * t),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 64,
                        height: 64,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.tertiary],
                  ).createShader(rect),
                  child: Text(
                    'MUSLIM LEVELING',
                    textAlign: TextAlign.center,
                    style: AppText.displayHero(40).copyWith(
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Level Up iman, Level Up Kehidupanmu',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 200,
                  child: AnimatedBuilder(
                    animation: _barCtl,
                    builder: (_, __) => Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _barCtl.value,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.tertiary],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'MEMUAT DATA PEJUANG...',
                  style: AppText.labelCaps().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
