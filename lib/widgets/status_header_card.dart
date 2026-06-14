import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/wave_painter.dart';

class StatusHeaderCard extends StatefulWidget {
  const StatusHeaderCard({super.key});

  @override
  State<StatusHeaderCard> createState() => _StatusHeaderCardState();
}

class _StatusHeaderCardState extends State<StatusHeaderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ─── Decorative Elements ──────────────────────────
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentBlue.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentBlue.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ─── Animated Wave ────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, c) => CustomPaint(
                  painter: WavePainter(
                    animationValue: _waveController.value,
                    color: AppTheme.accentBlue.withValues(alpha: 0.08),
                  ),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ),

            // ─── Content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentBlue.withValues(alpha: 0.3),
                              AppTheme.brightCyan.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.set_meal,
                          color: AppTheme.accentBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ao nuôi #1',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tất cả chỉ số bình thường',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.emerald
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.emerald,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.emerald
                                        .withValues(alpha: 0.7),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Tốt',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick stats
                  Row(
                    children: [
                      _buildStat(Icons.bubble_chart, 'Oxy', '6.5',
                          'mg/L', AppTheme.accentBlue),
                      const SizedBox(width: 10),
                      _buildStat(Icons.waves, 'Mực nước', '1.2', 'm',
                          AppTheme.brightCyan),
                      const SizedBox(width: 10),
                      _buildStat(Icons.schedule, 'Cập nhật', '2',
                          'phút', AppTheme.warmAmber),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      IconData icon, String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
