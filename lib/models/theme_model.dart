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
