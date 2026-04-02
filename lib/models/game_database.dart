import 'dart:convert';

class GameDatabase {
  final String folder;
  final String systemAlias;
  final String? emulatorName;
  final Map<String, dynamic> metadata;

  const GameDatabase({
    required this.folder,
    required this.systemAlias,
    this.emulatorName,
    this.metadata = const {},
  });

  GameDatabase copyWith({
    String? folder,
    String? systemAlias,
    String? emulatorName,
    Map<String, dynamic>? metadata,
  }) {
    return GameDatabase(
      folder: folder ?? this.folder,
      systemAlias: systemAlias ?? this.systemAlias,
      emulatorName: emulatorName ?? this.emulatorName,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder': folder,
      'systemAlias': systemAlias,
      'emulatorName': emulatorName,
      'metadata': metadata,
    };
  }

  factory GameDatabase.fromJson(Map<String, dynamic> json) {
    return GameDatabase(
      folder: json['folder'] as String,
      systemAlias: json['systemAlias'] as String,
      emulatorName: json['emulatorName'] as String?,
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
  String toString() => 'GameDatabase(folder: $folder, system: $systemAlias)';
}
