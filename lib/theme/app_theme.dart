import 'package:flutter/material.dart';

class AppTheme {
  // ─── Core Colors ─────────────────────────────────────────────────
  static const Color deepNavy = Color(0xFF0B1A33);
  static const Color navyBlue = Color(0xFF112240);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color electricBlue = Color(0xFF2196F3);
  static const Color brightCyan = Color(0xFF00E5FF);

  static const Color emerald = Color(0xFF00E676);
  static const Color mintGreen = Color(0xFF69F0AE);

  static const Color warmAmber = Color(0xFFFFB74D);
  static const Color hotOrange = Color(0xFFFF7043);
  static const Color softRed = Color(0xFFFF5252);

  static const Color surface = Color(0xFFF2F5FA);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF0D1B2A);
  static const Color textMuted = Color(0xFF7A8BA0);

  // ─── Gradients ───────────────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B1A33),
      Color(0xFF112240),
      Color(0xFF1A3565),
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B1A33),
      Color(0xFF112240),
      Color(0xFF1B3A5C),
    ],
  );

  static const LinearGradient tempGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Premium sunset gradient
  );

  static const LinearGradient humidityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  );

  static const LinearGradient phGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)], // Premium emerald gradient
  );

  static const LinearGradient pumpGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Electric blue gradient
  );

  // ─── Theme ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricBlue,
        brightness: Brightness.light,
      ),
    );
  }
}
