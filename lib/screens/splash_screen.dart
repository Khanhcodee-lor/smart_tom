import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/wave_painter.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _waveController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const DashboardScreen(),
        transitionsBuilder: (_, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        dark: true,
        child: Stack(
          children: [
            // ─── Animated Waves ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, c) => CustomPaint(
                  painter: WavePainter(
                    animationValue: _waveController.value,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  size: const Size(double.infinity, 120),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, c) => CustomPaint(
                  painter: WavePainter(
                    animationValue: _waveController.value + 0.3,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                  size: const Size(double.infinity, 100),
                ),
              ),
            ),

            // ─── Content ─────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // ─── Glowing Icon ──────────────────────────
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.accentBlue.withValues(alpha: 0.3),
                              AppTheme.brightCyan.withValues(alpha: 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentBlue.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          size: 54,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ─── App Name ──────────────────────────────
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, AppTheme.accentBlue],
                        ).createShader(bounds),
                        child: const Text(
                          'AquaSmart',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Giải pháp quản lý ao nuôi thông minh',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const Spacer(flex: 4),

                      // ─── Start Button ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _navigateToDashboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: AppTheme.deepNavy,
                              elevation: 12,
                              shadowColor: AppTheme.accentBlue.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bắt đầu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Phiên bản 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
