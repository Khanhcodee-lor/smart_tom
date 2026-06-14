import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/aqua_firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class HistoryScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final String unit;
  final AquaSensorKind sensorKind;

  const HistoryScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.unit,
    required this.sensorKind,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AquaFirebaseService _firebaseService = AquaFirebaseService();
  late final Stream<List<AquaHistoryEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _firebaseService.watchSensorHistory(widget.sensorKind);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<AquaHistoryEntry>>(
            stream: _historyStream,
            initialData: const [],
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const <AquaHistoryEntry>[];
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 14),
                    _buildErrorBanner(),
                  ],
                  const SizedBox(height: 24),
                  _buildChartSection(entries, isLoading: isLoading),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Lịch sử đo gần đây',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildHistoryList(entries, isLoading: isLoading),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppTheme.textDark,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử đo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.gradient.colors.first.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: widget.gradient.colors.first,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              'Không đọc được lịch sử từ Firebase.',
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

  Widget _buildChartSection(
    List<AquaHistoryEntry> entries, {
    required bool isLoading,
  }) {
    final chartEntries = _latestEntries(entries, 7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 16),
      height: 210,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: chartEntries.isEmpty
          ? _buildChartPlaceholder(isLoading)
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _horizontalInterval(chartEntries),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(value, meta, chartEntries);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _horizontalInterval(chartEntries),
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAxisValue(value),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: chartEntries.length <= 1
                    ? 1
                    : (chartEntries.length - 1).toDouble(),
                minY: _minY(chartEntries),
                maxY: _maxY(chartEntries),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots(chartEntries),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _chartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: _chartColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _chartColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _chartColor.withValues(alpha: 0.3),
                          _chartColor.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartPlaceholder(bool isLoading) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          else
            Icon(
              Icons.show_chart,
              color: Colors.white.withValues(alpha: 0.72),
              size: 30,
            ),
          const SizedBox(height: 12),
          Text(
            isLoading ? 'Đang tải lịch sử' : 'Chưa có dữ liệu lịch sử',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<AquaHistoryEntry> entries,
  ) {
    final index = value.round();
    final isExactIndex = (value - index).abs() < 0.01;
    if (!isExactIndex || index < 0 || index >= entries.length) {
      return const SizedBox.shrink();
    }

    final middleIndex = entries.length ~/ 2;
    final shouldShow =
        index == 0 || index == middleIndex || index == entries.length - 1;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        _shortTime(entries[index]),
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w400,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    List<AquaHistoryEntry> entries, {
    required bool isLoading,
  }) {
    if (entries.isEmpty) {
      return _buildEmptyHistory(isLoading);
    }

    final recentEntries = entries.reversed.take(30).toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recentEntries.length,
      itemBuilder: (context, index) {
        final item = recentEntries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.gradient.colors.first.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.gradient.colors.first.withValues(alpha: 0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullTime(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText(item.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatReading(item.value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.gradient.colors.first,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory(bool isLoading) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(
                Icons.history,
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                size: 42,
              ),
            const SizedBox(height: 12),
            Text(
              isLoading
                  ? 'Đang tải dữ liệu'
                  : 'Chưa có lịch sử đo cho cảm biến này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AquaHistoryEntry> _latestEntries(
    List<AquaHistoryEntry> entries,
    int count,
  ) {
    if (entries.length <= count) {
      return entries;
    }
    return entries.sublist(entries.length - count);
  }

  List<FlSpot> _spots(List<AquaHistoryEntry> entries) {
    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i += 1) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }
    return spots;
  }

  double _minY(List<AquaHistoryEntry> entries) {
    if (entries.isEmpty) {
      return widget.sensorKind == AquaSensorKind.ph ? 5 : 20;
    }

    final minValue = entries
        .map((entry) => entry.value)
        .reduce((value, element) => math.min(value, element));
    final padding = widget.sensorKind == AquaSensorKind.ph ? 0.5 : 2;
    return math.max(0, minValue - padding);
  }

  double _maxY(List<AquaHistoryEntry> entries) {
    if (entries.isEmpty) {
      return widget.sensorKind == AquaSensorKind.ph ? 9 : 40;
    }

    final maxValue = entries
        .map((entry) => entry.value)
        .reduce((value, element) => math.max(value, element));
    final padding = widget.sensorKind == AquaSensorKind.ph ? 0.5 : 2;
    final computedMax = maxValue + padding;
    if (widget.sensorKind == AquaSensorKind.ph) {
      return math.min(14, computedMax);
    }
    return computedMax;
  }

  double _horizontalInterval(List<AquaHistoryEntry> entries) {
    if (widget.sensorKind == AquaSensorKind.ph) {
      return 1;
    }

    final minY = _minY(entries);
    final maxY = _maxY(entries);
    final range = maxY - minY;
    if (range <= 5) {
      return 1;
    }
    return 5;
  }

  String _formatAxisValue(double value) {
    if (widget.sensorKind == AquaSensorKind.ph) {
      return value.toStringAsFixed(1);
    }
    return value.round().toString();
  }

  String _formatReading(double value) {
    return value.toStringAsFixed(1);
  }

  String _statusText(double value) {
    if (widget.sensorKind == AquaSensorKind.ph) {
      if (value < 6.5) {
        return 'pH thấp';
      }
      if (value > 8.5) {
        return 'pH cao';
      }
      return 'Hoạt động bình thường';
    }

    if (value < 26) {
      return 'Nhiệt độ thấp';
    }
    if (value > 32) {
      return 'Nhiệt độ cao';
    }
    return 'Hoạt động bình thường';
  }

  String _shortTime(AquaHistoryEntry entry) {
    final date = entry.measuredAt;
    if (date == null) {
      return entry.label ?? '--:--';
    }

    final localDate = date.toLocal();
    return '${_twoDigits(localDate.hour)}:${_twoDigits(localDate.minute)}';
  }

  String _fullTime(AquaHistoryEntry entry) {
    final date = entry.measuredAt;
    if (date == null) {
      return entry.label ?? 'Không rõ thời gian';
    }

    final localDate = date.toLocal();
    final time =
        '${_twoDigits(localDate.hour)}:${_twoDigits(localDate.minute)}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(localDate.year, localDate.month, localDate.day);

    if (entryDay == today) {
      return '$time, Hôm nay';
    }
    if (entryDay == today.subtract(const Duration(days: 1))) {
      return '$time, Hôm qua';
    }

    return '$time, ${_twoDigits(localDate.day)}/${_twoDigits(localDate.month)}/${localDate.year}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Color get _chartColor {
    return widget.sensorKind == AquaSensorKind.ph
        ? const Color(0xFF00E676)
        : const Color(0xFFFF9800);
  }
}
