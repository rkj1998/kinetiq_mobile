import 'package:flutter/material.dart';

enum ThemeStyle {
  antigravityLight, // Clean Google / Apple aesthetic with airy white/slate surfaces
  antigravityNebula, // Soothing modern dark slate, calm and elevated
  obsidianOled, // True deep black for OLED displays
  cyberTitanium, // Apple metallic space-gray / titanium feel
}

enum ThemeAccent {
  googleBlue,
  quantumViolet,
  emeraldMint,
  amberGlow,
  roseQuartz,
  cyanNeon,
}

class AppThemeConfig {
  final ThemeStyle style;
  final ThemeAccent accent;
  final bool enableKineticAnimations;

  const AppThemeConfig({
    this.style = ThemeStyle.antigravityLight,
    this.accent = ThemeAccent.googleBlue,
    this.enableKineticAnimations = true,
  });

  AppThemeConfig copyWith({
    ThemeStyle? style,
    ThemeAccent? accent,
    bool? enableKineticAnimations,
  }) {
    return AppThemeConfig(
      style: style ?? this.style,
      accent: accent ?? this.accent,
      enableKineticAnimations: enableKineticAnimations ?? this.enableKineticAnimations,
    );
  }

  bool get isDark => style != ThemeStyle.antigravityLight;

  Color get primaryAccent {
    switch (accent) {
      case ThemeAccent.googleBlue:
        return const Color(0xFF1A73E8); // Google signature blue
      case ThemeAccent.quantumViolet:
        return const Color(0xFF7C3AED);
      case ThemeAccent.emeraldMint:
        return const Color(0xFF059669);
      case ThemeAccent.amberGlow:
        return const Color(0xFFD97706);
      case ThemeAccent.roseQuartz:
        return const Color(0xFFE11D48);
      case ThemeAccent.cyanNeon:
        return const Color(0xFF0284C7);
    }
  }

  Color get secondaryAccent {
    switch (accent) {
      case ThemeAccent.googleBlue:
        return const Color(0xFF4285F4);
      case ThemeAccent.quantumViolet:
        return const Color(0xFFA855F7);
      case ThemeAccent.emeraldMint:
        return const Color(0xFF10B981);
      case ThemeAccent.amberGlow:
        return const Color(0xFFF59E0B);
      case ThemeAccent.roseQuartz:
        return const Color(0xFFFB7185);
      case ThemeAccent.cyanNeon:
        return const Color(0xFF38BDF8);
    }
  }

  Color get glowColor {
    return primaryAccent.withValues(alpha: isDark ? 0.35 : 0.20);
  }

  Color get backgroundColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFF8FAFC); // Apple/Google airy paper
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF0F172A); // Modern dark slate
      case ThemeStyle.obsidianOled:
        return const Color(0xFF050508); // OLED black
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF18181B); // Titanium zinc
    }
  }

  Color get surfaceColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFFFFFFF);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF1E293B);
      case ThemeStyle.obsidianOled:
        return const Color(0xFF0F0F14);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF27272A);
    }
  }

  Color get cardColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFF1F5F9);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF283548);
      case ThemeStyle.obsidianOled:
        return const Color(0xFF16161E);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF323238);
    }
  }

  Color get borderColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFE2E8F0);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF334155);
      case ThemeStyle.obsidianOled:
        return const Color(0xFF23232E);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF3F3F46);
    }
  }

  Color get textPrimary {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFF0F172A);
      case ThemeStyle.antigravityNebula:
      case ThemeStyle.obsidianOled:
      case ThemeStyle.cyberTitanium:
        return const Color(0xFFF8FAFC);
    }
  }

  Color get textSecondary {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFF64748B);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF94A3B8);
      case ThemeStyle.obsidianOled:
        return const Color(0xFFA1A1AA);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFFA1A1AA);
    }
  }

  Color get inputBackgroundColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFFFFFFF);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF162032);
      case ThemeStyle.obsidianOled:
        return const Color(0xFF0D0D12);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF202025);
    }
  }

  Color get userBubbleColor {
    return primaryAccent;
  }

  Color get userBubbleText {
    return Colors.white;
  }

  Color get agentBubbleColor {
    switch (style) {
      case ThemeStyle.antigravityLight:
        return const Color(0xFFFFFFFF);
      case ThemeStyle.antigravityNebula:
        return const Color(0xFF1E293B);
      case ThemeStyle.obsidianOled:
        return const Color(0xFF121218);
      case ThemeStyle.cyberTitanium:
        return const Color(0xFF27272A);
    }
  }

  List<BoxShadow> get subtleShadow {
    if (style == ThemeStyle.antigravityLight) {
      return [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryAccent,
        onPrimary: Colors.white,
        secondary: secondaryAccent,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
    );
  }
}
