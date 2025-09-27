import 'package:flutter/material.dart';

/// Centralized color and gradient configuration for the sky-inspired UI.
class SkyPalette {
  static const Color primary = Color(0xFF63B4FF);
  static const Color primaryDark = Color(0xFF1E6DE0);
  static const Color accent = Color(0xFF8FD6FF);
  static const Color surface = Color(0xFFE8F4FF);
  static const Color bubbleMine = Color(0xFFC9E9FF);
  static const Color sunGlowLight = Color(0xFFFFF4B3);
  static const Color sunGlowDeep = Color(0xFFFFC960);
}

class SkyGradients {
  static const LinearGradient appBar = LinearGradient(
    colors: <Color>[SkyPalette.primaryDark, SkyPalette.primary, SkyPalette.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunGlow = LinearGradient(
    colors: <Color>[SkyPalette.sunGlowLight, SkyPalette.sunGlowDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlow = LinearGradient(
    colors: <Color>[SkyPalette.primary, SkyPalette.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SkyShadows {
  static List<BoxShadow> soft({
    double opacity = 0.18,
    double blurRadius = 10,
    Offset offset = const Offset(0, 4),
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
}
