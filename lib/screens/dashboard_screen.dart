import 'package:flutter/material.dart';

import '../services/aqua_firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/device_control_card.dart';
import '../widgets/sensor_card.dart';
import 'chatbot_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AquaFirebaseService _firebaseService = AquaFirebaseService();
  late final Stream<AquaRealtimeData> _dataStream;

  @override
  void initState() {
    super.initState();
    _dataStream = _firebaseService.watchRealtimeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072FF).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ),
      ),
      body: AppBackground(
        child: StreamBuilder<AquaRealtimeData>(
          stream: _dataStream,
          initialData: const AquaRealtimeData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const AquaRealtimeData();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final isOnline =
                snapshot.connectionState == ConnectionState.active &&
                !snapshot.hasError;

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      isOnline: isOnline,
                      isLoading: isLoading,
                      hasError: snapshot.hasError,
                    ),
                    if (snapshot.hasError) ...[
                      const SizedBox(height: 14),
                      _buildFirebaseErrorBanner(),
                    ],

                    const SizedBox(height: 28),

                    // ─── Sensor Section ──────────────────────────────
                    _buildSectionTitle('Chỉ số cảm biến'),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 180,
                      child: SensorCard(
                        icon: Icons.thermostat,
                        label: 'Nhiệt độ nước',
                        value: _formatSensorValue(data.temperature),
                        unit: '°C',
                        gradient: AppTheme.tempGradient,
                        progressValue: _normalize(
                          data.temperature,
                          min: 15,
                          max: 40,
                        ),
                        statusText: _temperatureStatus(data),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(
                                title: 'Nhiệt độ nước',
                                icon: Icons.thermostat,
                                gradient: AppTheme.tempGradient,
                                unit: '°C',
                                sensorKind: AquaSensorKind.temperature,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── Device Section ──────────────────────────────
                    _buildSectionTitle('Điều khiển thiết bị'),

                    const SizedBox(height: 16),

                    _buildModeSelector(data.controlMode),

                    const SizedBox(height: 16),

                    Builder(
                      builder: (context) {
                        final isManual =
                            data.controlMode == PumpControlMode.manual;
                        final hotPumpActive = isManual
                            ? data.hotPumpOn
                            : _autoHotPumpOn(data);
                        final coldPumpActive = isManual
                            ? data.coldPumpOn
                            : _autoColdPumpOn(data);

                        return Column(
                          children: [
                            DeviceControlCard(
                              icon: Icons.local_fire_department,
                              deviceName: 'Bơm nóng',
                              subtitle: isManual
                                  ? 'Bật/tắt bằng công tắc'
                                  : 'Tự động bật khi < ${_formatThreshold(data.hotPumpThreshold)}°C',
                              isActive: hotPumpActive,
                              isSwitchEnabled: isManual,
                              onToggle: isManual
                                  ? (value) =>
                                        _setPumpState(PumpKind.hot, value)
                                  : null,
                              activeGradient: AppTheme.tempGradient,
                              accentColor: AppTheme.hotOrange,
                              thresholdLabel: 'Ngưỡng bơm nóng',
                              thresholdValue: isManual
                                  ? null
                                  : data.hotPumpThreshold,
                              thresholdUnit: '°C',
                              onEditThreshold: isManual
                                  ? null
                                  : () => _showThresholdDialog(
                                      PumpKind.hot,
                                      data,
                                    ),
                            ),
                            const SizedBox(height: 14),
                            DeviceControlCard(
                              icon: Icons.ac_unit,
                              deviceName: 'Bơm lạnh',
                              subtitle: isManual
                                  ? 'Bật/tắt bằng công tắc'
                                  : 'Tự động bật khi > ${_formatThreshold(data.coldPumpThreshold)}°C',
                              isActive: coldPumpActive,
                              isSwitchEnabled: isManual,
                              onToggle: isManual
                                  ? (value) =>
                                        _setPumpState(PumpKind.cold, value)
                                  : null,
                              activeGradient: AppTheme.humidityGradient,
                              accentColor: AppTheme.electricBlue,
                              thresholdLabel: 'Ngưỡng bơm lạnh',
                              thresholdValue: isManual
                                  ? null
                                  : data.coldPumpThreshold,
                              thresholdUnit: '°C',
                              onEditThreshold: isManual
                                  ? null
                                  : () => _showThresholdDialog(
                                      PumpKind.cold,
                                      data,
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isOnline,
    required bool isLoading,
    required bool hasError,
  }) {
    final statusColor = hasError
        ? AppTheme.softRed
        : (isOnline ? AppTheme.emerald : AppTheme.warmAmber);
    final statusText = hasError ? 'Lỗi' : (isLoading ? 'Đang tải' : 'Online');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppTheme.pumpGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'AquaSmart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softRed.withValues(alpha: 0.14)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.softRed, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa đọc được Firebase. Kiểm tra Realtime Database URL/rules nếu dữ liệu không hiện.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildModeSelector(PumpControlMode mode) {
    final isManual = mode == PumpControlMode.manual;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isManual ? AppTheme.electricBlue : AppTheme.emerald)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isManual ? Icons.touch_app : Icons.auto_mode,
              color: isManual ? AppTheme.electricBlue : AppTheme.emerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chế độ thủ công',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isManual
                      ? 'Dùng công tắc trên từng bơm'
                      : 'Tự động chạy theo ngưỡng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isManual,
            activeThumbColor: AppTheme.electricBlue,
            onChanged: (value) {
              _setControlMode(
                value ? PumpControlMode.manual : PumpControlMode.auto,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setControlMode(PumpControlMode mode) async {
    try {
      await _firebaseService.setControlMode(mode);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể đổi chế độ bơm.');
    }
  }

  Future<void> _setPumpState(PumpKind pump, bool isOn) async {
    try {
      await _firebaseService.setPumpState(pump, isOn);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể cập nhật trạng thái bơm.');
    }
  }

  Future<void> _showThresholdDialog(
    PumpKind pump,
    AquaRealtimeData data,
  ) async {
    final currentThreshold = pump == PumpKind.hot
        ? data.hotPumpThreshold
        : data.coldPumpThreshold;
    final controller = TextEditingController(
      text: _formatThreshold(currentThreshold),
    );
    final formKey = GlobalKey<FormState>();
    final pumpLabel = pump == PumpKind.hot ? 'bơm nóng' : 'bơm lạnh';

    final newThreshold = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Đặt ngưỡng $pumpLabel'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Ngưỡng nhiệt độ',
                suffixText: '°C',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (value) {
                final parsed = _parseThreshold(value);
                if (parsed == null) {
                  return 'Nhập một giá trị hợp lệ.';
                }
                if (parsed < 0 || parsed > 60) {
                  return 'Ngưỡng nên nằm trong khoảng 0-60°C.';
                }
                if (pump == PumpKind.hot && parsed >= data.coldPumpThreshold) {
                  return 'Ngưỡng nóng phải nhỏ hơn bơm lạnh.';
                }
                if (pump == PumpKind.cold && parsed <= data.hotPumpThreshold) {
                  return 'Ngưỡng lạnh phải lớn hơn bơm nóng.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                Navigator.pop(dialogContext, _parseThreshold(controller.text));
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newThreshold == null) {
      return;
    }

    try {
      await _firebaseService.setPumpThreshold(pump, newThreshold);
      if (!mounted) return;
      _showSnackBar('Đã lưu ngưỡng $pumpLabel.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu ngưỡng $pumpLabel.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSensorValue(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(1);
  }

  String _formatThreshold(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  double? _parseThreshold(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double? _normalize(
    double? value, {
    required double min,
    required double max,
  }) {
    if (value == null) {
      return null;
    }
    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  String _temperatureStatus(AquaRealtimeData data) {
    final value = data.temperature;
    if (value == null) {
      return 'Chờ dữ liệu';
    }
    if (_autoHotPumpOn(data)) {
      return 'Cần làm ấm';
    }
    if (_autoColdPumpOn(data)) {
      return 'Cần làm lạnh';
    }
    return 'Ổn định';
  }

  bool _autoHotPumpOn(AquaRealtimeData data) {
    final value = data.temperature;
    return value != null && value < data.hotPumpThreshold;
  }

  bool _autoColdPumpOn(AquaRealtimeData data) {
    final value = data.temperature;
    return value != null && value > data.coldPumpThreshold;
  }
}
