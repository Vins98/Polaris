import 'dart:convert';

enum LayoutType { grid, list, carousel, coverflow, fullscreen, custom }

LayoutType _layoutTypeFromString(String? s) {
  if (s == null) return LayoutType.custom;
  switch (s.toLowerCase()) {
    case 'grid':
      return LayoutType.grid;
    case 'list':
      return LayoutType.list;
    case 'carousel':
      return LayoutType.carousel;
    case 'coverflow':
      return LayoutType.coverflow;
    case 'fullscreen':
      return LayoutType.fullscreen;
    default:
      return LayoutType.custom;
  }
}

String _layoutTypeToString(LayoutType t) => t.toString().split('.').last;

class ThemeColorScheme {
  final String id;
  final Map<String, String> tokens;

  const ThemeColorScheme({required this.id, this.tokens = const {}});

  Map<String, dynamic> toJson() => {'id': id, 'tokens': tokens};

  factory ThemeColorScheme.fromJson(Map<String, dynamic> json) =>
      ThemeColorScheme(
        id: json['id'] as String,
        tokens: (json['tokens'] as Map?)?.cast<String, String>() ?? {},
      );
}

class ThemeFont {
  final String id;
  final String family;
  final String? asset;
  final double? size;
  final String? weight;

  const ThemeFont({
    required this.id,
    required this.family,
    this.asset,
    this.size,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'family': family,
    'asset': asset,
    'size': size,
    'weight': weight,
  };

  factory ThemeFont.fromJson(Map<String, dynamic> json) => ThemeFont(
    id: json['id'] as String,
    family: json['family'] as String,
    asset: json['asset'] as String?,
    size: (json['size'] as num?)?.toDouble(),
    weight: json['weight'] as String?,
  );
}

class ThemeAsset {
  final String id;
  final String path;
  final String? type;

  const ThemeAsset({required this.id, required this.path, this.type});

  Map<String, dynamic> toJson() => {'id': id, 'path': path, 'type': type};

  factory ThemeAsset.fromJson(Map<String, dynamic> json) => ThemeAsset(
    id: json['id'] as String,
    path: json['path'] as String,
    type: json['type'] as String?,
  );
}

class ThemeAnimation {
  final String id;
  final String type;
  final Map<String, dynamic> params;

  const ThemeAnimation({
    required this.id,
    required this.type,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'params': params};

  factory ThemeAnimation.fromJson(Map<String, dynamic> json) => ThemeAnimation(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    params: (json['params'] as Map?)?.cast<String, dynamic>() ?? {},
  );
}

class ItemTemplate {
  final String id;
  final String artworkPosition;
  final bool showTitle;
  final bool showSubtitle;
  final Map<String, dynamic> overlays;
  final Map<String, dynamic> extras;

  const ItemTemplate({
    required this.id,
    this.artworkPosition = 'left',
    this.showTitle = true,
    this.showSubtitle = false,
    this.overlays = const {},
    this.extras = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'artworkPosition': artworkPosition,
    'showTitle': showTitle,
    'showSubtitle': showSubtitle,
    'overlays': overlays,
    'extras': extras,
  };

  factory ItemTemplate.fromJson(Map<String, dynamic> json) => ItemTemplate(
    id: json['id'] as String,
    artworkPosition: json['artworkPosition'] as String? ?? 'left',
    showTitle: json['showTitle'] as bool? ?? true,
    showSubtitle: json['showSubtitle'] as bool? ?? false,
    overlays: (json['overlays'] as Map?)?.cast<String, dynamic>() ?? {},
    extras: (json['extras'] as Map?)?.cast<String, dynamic>() ?? {},
  );
}

class ScreenTemplate {
  final String id;
  final LayoutType layout;
  final ItemTemplate itemTemplate;
  final String? backgroundAsset;
  final String? palette;
  final ThemeAnimation? enterAnimation;
  final ThemeAnimation? exitAnimation;
  final Map<String, dynamic> extras;

  const ScreenTemplate({
    required this.id,
    this.layout = LayoutType.custom,
    required this.itemTemplate,
    this.backgroundAsset,
    this.palette,
    this.enterAnimation,
    this.exitAnimation,
    this.extras = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'layout': _layoutTypeToString(layout),
    'itemTemplate': itemTemplate.toJson(),
    'backgroundAsset': backgroundAsset,
    'palette': palette,
    'enterAnimation': enterAnimation?.toJson(),
    'exitAnimation': exitAnimation?.toJson(),
    'extras': extras,
  };

  factory ScreenTemplate.fromJson(Map<String, dynamic> json) => ScreenTemplate(
    id: json['id'] as String,
    layout: _layoutTypeFromString(json['layout'] as String?),
    itemTemplate: ItemTemplate.fromJson(
      json['itemTemplate'] as Map<String, dynamic>,
    ),
    backgroundAsset: json['backgroundAsset'] as String?,
    palette: json['palette'] as String?,
    enterAnimation: json['enterAnimation'] != null
        ? ThemeAnimation.fromJson(
            json['enterAnimation'] as Map<String, dynamic>,
          )
        : null,
    exitAnimation: json['exitAnimation'] != null
        ? ThemeAnimation.fromJson(json['exitAnimation'] as Map<String, dynamic>)
        : null,
    extras: (json['extras'] as Map?)?.cast<String, dynamic>() ?? {},
  );
}

class ThemeModel {
  final String id;
  final String name;
  final String? author;
  final String? version;
  final String? previewImage;
  final List<String> supportedSystems;
  final Map<String, ThemeColorScheme> palettes;
  final Map<String, ThemeFont> fonts;
  final Map<String, ThemeAsset> assets;
  final Map<String, ScreenTemplate> templates;
  final Map<String, dynamic> globals;
  final Map<String, dynamic> metadata;

  const ThemeModel({
    required this.id,
    required this.name,
    this.author,
    this.version,
    this.previewImage,
    this.supportedSystems = const [],
    this.palettes = const {},
    this.fonts = const {},
    this.assets = const {},
    this.templates = const {},
    this.globals = const {},
    this.metadata = const {},
  });

  ThemeModel copyWith({
    String? id,
    String? name,
    String? author,
    String? version,
    String? previewImage,
    List<String>? supportedSystems,
    Map<String, ThemeColorScheme>? palettes,
    Map<String, ThemeFont>? fonts,
    Map<String, ThemeAsset>? assets,
    Map<String, ScreenTemplate>? templates,
    Map<String, dynamic>? globals,
    Map<String, dynamic>? metadata,
  }) {
    return ThemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      previewImage: previewImage ?? this.previewImage,
      supportedSystems: supportedSystems ?? this.supportedSystems,
      palettes: palettes ?? this.palettes,
      fonts: fonts ?? this.fonts,
      assets: assets ?? this.assets,
      templates: templates ?? this.templates,
      globals: globals ?? this.globals,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'version': version,
    'previewImage': previewImage,
    'supportedSystems': supportedSystems,
    'palettes': palettes.map((k, v) => MapEntry(k, v.toJson())),
    'fonts': fonts.map((k, v) => MapEntry(k, v.toJson())),
    'assets': assets.map((k, v) => MapEntry(k, v.toJson())),
    'templates': templates.map((k, v) => MapEntry(k, v.toJson())),
    'globals': globals,
    'metadata': metadata,
  };

  factory ThemeModel.fromJson(Map<String, dynamic> json) => ThemeModel(
    id: json['id'] as String,
    name: json['name'] as String,
    author: json['author'] as String?,
    version: json['version'] as String?,
    previewImage: json['previewImage'] as String?,
    supportedSystems:
        (json['supportedSystems'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    palettes:
        (json['palettes'] as Map?)
            ?.map(
              (k, v) => MapEntry(
                k as String,
                ThemeColorScheme.fromJson(v as Map<String, dynamic>),
              ),
            )
            .cast<String, ThemeColorScheme>() ??
        {},
    fonts:
        (json['fonts'] as Map?)
            ?.map(
              (k, v) => MapEntry(
                k as String,
                ThemeFont.fromJson(v as Map<String, dynamic>),
              ),
            )
            .cast<String, ThemeFont>() ??
        {},
    assets:
        (json['assets'] as Map?)
            ?.map(
              (k, v) => MapEntry(
                k as String,
                ThemeAsset.fromJson(v as Map<String, dynamic>),
              ),
            )
            .cast<String, ThemeAsset>() ??
        {},
    templates:
        (json['templates'] as Map?)
            ?.map(
              (k, v) => MapEntry(
                k as String,
                ScreenTemplate.fromJson(v as Map<String, dynamic>),
              ),
            )
            .cast<String, ScreenTemplate>() ??
        {},
    globals: (json['globals'] as Map?)?.cast<String, dynamic>() ?? {},
    metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
  );

  factory ThemeModel.fromJsonString(String jsonStr) =>
      ThemeModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  @override
  String toString() => 'ThemeModel(id: $id, name: $name)';
}

// =============================================================================
// PolarisThemeConfig — the runtime theme format used by the UI
// =============================================================================

/// Preset animation identifiers supported by all view modes.
/// Themes declare one of these; optional duration/curve fields override defaults.
const List<String> kAnimationPresets = [
  'fade_scale',  // fade + scale from center
  'slide_fade',  // slide in from right + fade
  'slide_up',    // slide up from bottom
  'zoom',        // zoom from previous position
  'none',        // instant, no animation
];

class ThemeAnimationConfig {
  /// One of [kAnimationPresets].
  final String preset;

  /// Override transition duration in milliseconds. Null → use preset default.
  final int? duration;

  /// Flutter [Curves] name, e.g. "easeOutCubic". Null → use preset default.
  final String? curve;

  const ThemeAnimationConfig({
    this.preset = 'fade_scale',
    this.duration,
    this.curve,
  });

  Map<String, dynamic> toJson() => {
        'preset': preset,
        if (duration != null) 'duration': duration,
        if (curve != null) 'curve': curve,
      };

  factory ThemeAnimationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ThemeAnimationConfig();
    return ThemeAnimationConfig(
      preset: json['preset'] as String? ?? 'fade_scale',
      duration: json['duration'] as int?,
      curve: json['curve'] as String?,
    );
  }
}

class SystemsScreenConfig {
  final bool showDescription;
  final bool showYear;
  final bool showManufacturer;
  final bool showGameCount;

  const SystemsScreenConfig({
    this.showDescription = false,
    this.showYear = true,
    this.showManufacturer = true,
    this.showGameCount = true,
  });

  Map<String, dynamic> toJson() => {
        'showDescription': showDescription,
        'showYear': showYear,
        'showManufacturer': showManufacturer,
        'showGameCount': showGameCount,
      };

  factory SystemsScreenConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SystemsScreenConfig();
    return SystemsScreenConfig(
      showDescription: json['showDescription'] as bool? ?? false,
      showYear: json['showYear'] as bool? ?? true,
      showManufacturer: json['showManufacturer'] as bool? ?? true,
      showGameCount: json['showGameCount'] as bool? ?? true,
    );
  }
}

class GamesScreenConfig {
  final bool showDescription;
  final bool showYear;
  final bool showDeveloper;
  final bool showPublisher;
  final bool showRating;
  final bool showGenre;
  final bool showPlayers;

  /// Which artwork image to show per game.
  /// Valid values: "box2d" | "fanart" | "screenshot" | "wheel"
  final String artworkType;

  const GamesScreenConfig({
    this.showDescription = true,
    this.showYear = true,
    this.showDeveloper = true,
    this.showPublisher = false,
    this.showRating = true,
    this.showGenre = true,
    this.showPlayers = false,
    this.artworkType = 'box2d',
  });

  Map<String, dynamic> toJson() => {
        'showDescription': showDescription,
        'showYear': showYear,
        'showDeveloper': showDeveloper,
        'showPublisher': showPublisher,
        'showRating': showRating,
        'showGenre': showGenre,
        'showPlayers': showPlayers,
        'artworkType': artworkType,
      };

  factory GamesScreenConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GamesScreenConfig();
    return GamesScreenConfig(
      showDescription: json['showDescription'] as bool? ?? true,
      showYear: json['showYear'] as bool? ?? true,
      showDeveloper: json['showDeveloper'] as bool? ?? true,
      showPublisher: json['showPublisher'] as bool? ?? false,
      showRating: json['showRating'] as bool? ?? true,
      showGenre: json['showGenre'] as bool? ?? true,
      showPlayers: json['showPlayers'] as bool? ?? false,
      artworkType: json['artworkType'] as String? ?? 'box2d',
    );
  }
}

/// The runtime theme configuration parsed from `data/themes/<id>/theme.json`.
class PolarisThemeConfig {
  final String id;
  final String name;
  final String? author;
  final String? version;

  /// Raw hex color map. Keys: background, card, accent, textPrimary,
  /// textSecondary, cardBorderActive.
  final Map<String, String> colors;

  /// "carousel" | "list" | "xmb"
  final String viewMode;

  final ThemeAnimationConfig animation;
  final SystemsScreenConfig systemsScreen;
  final GamesScreenConfig gamesScreen;

  /// Absolute path to the theme directory (set by ThemeService after loading).
  final String themeDir;

  const PolarisThemeConfig({
    required this.id,
    required this.name,
    this.author,
    this.version,
    required this.colors,
    this.viewMode = 'carousel',
    this.animation = const ThemeAnimationConfig(),
    this.systemsScreen = const SystemsScreenConfig(),
    this.gamesScreen = const GamesScreenConfig(),
    required this.themeDir,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'author': author,
        'version': version,
        'colors': colors,
        'viewMode': viewMode,
        'animation': animation.toJson(),
        'systemsScreen': systemsScreen.toJson(),
        'gamesScreen': gamesScreen.toJson(),
      };

  factory PolarisThemeConfig.fromJson(
    Map<String, dynamic> json, {
    required String themeDir,
  }) {
    return PolarisThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String?,
      version: json['version'] as String?,
      colors: (json['colors'] as Map?)?.cast<String, String>() ?? {},
      viewMode: json['viewMode'] as String? ?? 'carousel',
      animation: ThemeAnimationConfig.fromJson(
          json['animation'] as Map<String, dynamic>?),
      systemsScreen: SystemsScreenConfig.fromJson(
          json['systemsScreen'] as Map<String, dynamic>?),
      gamesScreen: GamesScreenConfig.fromJson(
          json['gamesScreen'] as Map<String, dynamic>?),
      themeDir: themeDir,
    );
  }

  factory PolarisThemeConfig.fromJsonString(
    String jsonStr, {
    required String themeDir,
  }) =>
      PolarisThemeConfig.fromJson(
        json.decode(jsonStr) as Map<String, dynamic>,
        themeDir: themeDir,
      );

  @override
  String toString() => 'PolarisThemeConfig(id: $id, viewMode: $viewMode)';
}

