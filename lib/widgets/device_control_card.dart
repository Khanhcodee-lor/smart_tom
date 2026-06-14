import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeviceControlCard extends StatelessWidget {
  final IconData icon;
  final String deviceName;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool>? onToggle;
  final bool isSwitchEnabled;
  final LinearGradient activeGradient;
  final Color accentColor;
  final String? thresholdLabel;
  final double? thresholdValue;
  final String thresholdUnit;
  final VoidCallback? onEditThreshold;

  const DeviceControlCard({
    super.key,
    required this.icon,
    required this.deviceName,
    required this.subtitle,
    required this.isActive,
    required this.onToggle,
    this.isSwitchEnabled = true,
    this.activeGradient = AppTheme.pumpGradient,
    this.accentColor = AppTheme.electricBlue,
    this.thresholdLabel,
    this.thresholdValue,
    this.thresholdUnit = '',
    this.onEditThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isActive ? activeGradient : null,
        color: isActive ? null : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? activeGradient.colors.first.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isActive ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // ─── Icon ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.3)
                          : accentColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // ─── Info ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.72)
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? AppTheme.mintGreen
                                  : AppTheme.textMuted,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.mintGreen.withValues(
                                          alpha: 0.7,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Đang hoạt động' : 'Đang tắt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Switch ────────────────────────────────────
                CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: isActive ? Colors.white : AppTheme.textMuted,
                  onChanged: isSwitchEnabled ? onToggle : null,
                ),
              ],
            ),

            // ─── Threshold Bar ─────────────────────────────────
            if (thresholdValue != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.14)
                        : accentColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: isActive ? Colors.white : accentColor,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thresholdLabel ?? 'Ngưỡng bật',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.62)
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatThreshold(thresholdValue!)}$thresholdUnit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onEditThreshold != null)
                      IconButton(
                        tooltip: 'Đặt ngưỡng',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEditThreshold,
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: isActive ? Colors.white : accentColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatThreshold(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
