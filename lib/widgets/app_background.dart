import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.dark = false});

  static const assetPath = 'assets/img/logo_tom.png';

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 1.45).clamp(360.0, 640.0).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark
            ? AppTheme.splashGradient
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9FCFF), Color(0xFFEAF4FF)],
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Align(
              alignment: dark ? const Alignment(0, -0.15) : Alignment.center,
              child: SizedBox.square(
                dimension: logoSize,
                child: Opacity(
                  opacity: dark ? 0.2 : 0.1,
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          if (!dark)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.58),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
