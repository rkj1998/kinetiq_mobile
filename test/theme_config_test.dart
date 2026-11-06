import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/models/app_theme_config.dart';

void main() {
  group('AppThemeConfig Tests', () {
    test('default configuration is Antigravity Light', () {
      const config = AppThemeConfig();
      expect(config.style, ThemeStyle.antigravityLight);
      expect(config.accent, ThemeAccent.googleBlue);
      expect(config.isDark, false);
      expect(config.backgroundColor, const Color(0xFFF8FAFC));
      expect(config.primaryAccent, const Color(0xFF1A73E8));
    });

    test('Antigravity Nebula has modern dark slate palette', () {
      const config = AppThemeConfig(
        style: ThemeStyle.antigravityNebula,
        accent: ThemeAccent.quantumViolet,
      );
      expect(config.isDark, true);
      expect(config.backgroundColor, const Color(0xFF0F172A));
      expect(config.surfaceColor, const Color(0xFF1E293B));
      expect(config.primaryAccent, const Color(0xFF7C3AED));
    });

    test('toThemeData generates valid Material 3 ThemeData', () {
      const lightConfig = AppThemeConfig(style: ThemeStyle.antigravityLight);
      final lightTheme = lightConfig.toThemeData();
      expect(lightTheme.useMaterial3, true);
      expect(lightTheme.brightness, Brightness.light);

      const darkConfig = AppThemeConfig(style: ThemeStyle.obsidianOled);
      final darkTheme = darkConfig.toThemeData();
      expect(darkTheme.brightness, Brightness.dark);
    });
  });
}
