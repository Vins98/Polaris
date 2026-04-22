import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/models/models.dart';

// ---------------------------------------------------------------------------
// PolarisTheme — resolved Flutter colors derived from PolarisThemeConfig
// ---------------------------------------------------------------------------

class PolarisTheme {
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorderActive;
  final String themeDir;

  const PolarisTheme({
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorderActive,
    required this.themeDir,
  });

  factory PolarisTheme.fromConfig(PolarisThemeConfig config) {
    Color c(String key, Color fallback) {
      final hex = config.colors[key];
      if (hex == null) return fallback;
      return _hexToColor(hex) ?? fallback;
    }

    return PolarisTheme(
      backgroundColor:   c('background',       const Color(0xFF0D0D0D)),
      cardColor:         c('card',             const Color(0xFF1A1A2E)),
      accentColor:       c('accent',           const Color(0xFF7B61FF)),
      textPrimary:       c('textPrimary',      const Color(0xFFF0F0F0)),
      textSecondary:     c('textSecondary',    const Color(0xFF888888)),
      cardBorderActive:  c('cardBorderActive', const Color(0xFF7B61FF)),
      themeDir:          config.themeDir,
    );
  }

  /// Returns the path to a system image, or null if not found.
  String? systemImagePath(String systemId) {
    final dir = p.join(themeDir, 'systems');
    for (final ext in ['.png', '.jpg', '.jpeg', '.webp']) {
      final path = p.join(dir, '$systemId$ext');
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  ThemeData toMaterialTheme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          surface: cardColor,
          onSurface: textPrimary,
          secondary: accentColor,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
        ),
        useMaterial3: true,
      );

  static Color? _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return value != null ? Color(value) : null;
  }
}

// ---------------------------------------------------------------------------
// ThemeService
// ---------------------------------------------------------------------------

class ThemeService {
  static const _themesDir = 'data/themes';
  static const _defaultThemeId = 'polaris';
  static const _activeFile = 'data/themes/active';

  /// Loads and returns the active [PolarisThemeConfig].
  ///
  /// 1. Reads [_activeFile] for the theme ID (writes "polaris" if missing).
  /// 2. Loads `data/themes/<id>/theme.json`.
  /// 3. Throws if the theme.json is not found — no silent fallback.
  static Future<PolarisThemeConfig> loadConfig() async {
    // Resolve active theme id
    String themeId = _defaultThemeId;
    final activeF = File(_activeFile);
    if (await activeF.exists()) {
      final content = (await activeF.readAsString()).trim();
      if (content.isNotEmpty) themeId = content;
    } else {
      await activeF.create(recursive: true);
      await activeF.writeAsString(_defaultThemeId);
    }

    final themeDir = p.join(_themesDir, themeId);
    final themeFile = File(p.join(themeDir, 'theme.json'));

    if (!await themeFile.exists()) {
      throw FileSystemException(
        'Theme "$themeId" not found. '
        'Expected theme.json at: ${themeFile.path}',
      );
    }

    final raw = await themeFile.readAsString();
    return PolarisThemeConfig.fromJson(
      json.decode(raw) as Map<String, dynamic>,
      themeDir: themeDir,
    );
  }

  /// Convenience: load config then derive [PolarisTheme] from it.
  static Future<({PolarisThemeConfig config, PolarisTheme theme})>
      load() async {
    final config = await loadConfig();
    return (config: config, theme: PolarisTheme.fromConfig(config));
  }
}
