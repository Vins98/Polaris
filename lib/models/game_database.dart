import 'dart:convert';

class GameEntry {
  final String path;
  final String systemId;
  final String? emulator;
  final String name;
  final String hash;
  final bool favorite;
  final List<String> groups;
  final Map<String, dynamic> metadata;

  const GameEntry({
    required this.path,
    required this.systemId,
    this.emulator,
    required this.name,
    required this.hash,
    this.favorite = false,
    this.groups = const [],
    this.metadata = const {},
  });

  GameEntry copyWith({
    String? path,
    String? systemId,
    String? emulator,
    String? name,
    String? hash,
    bool? favorite,
    List<String>? groups,
    Map<String, dynamic>? metadata,
  }) {
    return GameEntry(
      path: path ?? this.path,
      systemId: systemId ?? this.systemId,
      emulator: emulator ?? this.emulator,
      name: name ?? this.name,
      hash: hash ?? this.hash,
      favorite: favorite ?? this.favorite,
      groups: groups ?? this.groups,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'systemId': systemId,
    'emulator': emulator,
    'name': name,
    'hash': hash,
    'favorite': favorite,
    'groups': groups,
    'metadata': metadata,
  };

  factory GameEntry.fromJson(Map<String, dynamic> json) {
    return GameEntry(
      path: json['path'] as String,
      systemId: json['systemId'] as String,
      emulator: json['emulator'] as String?,
      name:
          (json['name'] as String?) ??
          (json['metadata'] is Map &&
                  (json['metadata'] as Map).containsKey('name')
              ? (json['metadata'] as Map)['name'] as String
              : (json['path'] is String
                    ? (json['path'] as String).split('/').last
                    : '')),
      hash: json['hash'] as String,
      favorite: json['favorite'] as bool? ?? false,
      groups:
          (json['groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ??
          (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          {},
    );
  }

  factory GameEntry.fromJsonString(String jsonStr) =>
      GameEntry.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  /// Create a `GameEntry` from a screenscraper-style metadata map.
  ///
  /// `meta` should be the decoded metadata for the game. `path` and
  /// `hash` are required to populate the entry fields.
  factory GameEntry.fromScreenscraperMap(
    Map<String, dynamic> meta,
    String path,
    String systemId,
    String hash, {
    String? emulator,
  }) {
    final name =
        (meta['name'] as String?) ??
        (path.split('/').isNotEmpty ? path.split('/').last : '');
    return GameEntry(
      path: path,
      systemId: systemId,
      emulator: emulator,
      name: name,
      hash: hash,
      metadata: meta,
    );
  }

  String toJsonString() => json.encode(toJson());

  @override
  String toString() => 'GameEntry(path: $path, name: $name, system: $systemId)';
}

class GameDatabase {
  final String folder;
  final String systemId;
  final String? emulator;
  final List<GameEntry> games;
  final Map<String, dynamic> metadata;

  const GameDatabase({
    required this.folder,
    required this.systemId,
    this.emulator,
    this.games = const [],
    this.metadata = const {},
  });

  GameDatabase copyWith({
    String? folder,
    String? systemId,
    String? emulator,
    List<GameEntry>? games,
    Map<String, dynamic>? metadata,
  }) {
    return GameDatabase(
      folder: folder ?? this.folder,
      systemId: systemId ?? this.systemId,
      emulator: emulator ?? this.emulator,
      games: games ?? this.games,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder': folder,
      'systemId': systemId,
      'emulator': emulator,
      'games': games.map((g) => g.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory GameDatabase.fromJson(Map<String, dynamic> json) {
    final sysId = json['systemId'] as String;
    final emu = json['emulator'] as String?;
    final gamesJson = (json['games'] as List<dynamic>?) ?? const [];

    return GameDatabase(
      folder: json['folder'] as String,
      systemId: sysId,
      emulator: emu,
      games: gamesJson
          .map((e) => GameEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ??
          (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          {},
    );
  }

  factory GameDatabase.fromJsonString(String jsonStr) =>
      GameDatabase.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  @override
  String toString() =>
      'GameDatabase(folder: $folder, system: $systemId, games: ${games.length})';
}
