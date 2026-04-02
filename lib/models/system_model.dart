import 'dart:convert';

class SystemModel {
  final String id;
  final List<String> aliases;
  final String name;
  final String description;
  final List<String> romFormats;
  final int? year;
  final String manufacturer;

  const SystemModel({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.description = '',
    this.romFormats = const [],
    this.year,
    this.manufacturer = '',
  });

  SystemModel copyWith({
    String? id,
    List<String>? aliases,
    String? name,
    String? description,
    List<String>? romFormats,
    int? year,
    String? manufacturer,
  }) {
    return SystemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      description: description ?? this.description,
      romFormats: romFormats ?? this.romFormats,
      year: year ?? this.year,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aliases': aliases,
      'name': name,
      'description': description,
      'romFormats': romFormats,
      'year': year,
      'manufacturer': manufacturer,
    };
  }

  factory SystemModel.fromJson(Map<String, dynamic> json) {
    return SystemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases:
          (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      romFormats:
          (json['romFormats'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      year: json['year'] as int?,
      manufacturer: json['manufacturer'] as String? ?? '',
    );
  }

  factory SystemModel.fromJsonString(String jsonStr) =>
      SystemModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  @override
  String toString() => 'SystemModel(id: $id, name: $name, aliases: $aliases)';
}

class SystemsIndex {
  final int revision;
  final List<SystemModel> systems;

  const SystemsIndex({required this.revision, this.systems = const []});

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'systems': systems.map((s) => s.toJson()).toList(),
  };

  factory SystemsIndex.fromJson(Map<String, dynamic> json) => SystemsIndex(
    revision: json['revision'] as int,
    systems:
        (json['systems'] as List<dynamic>?)
            ?.map((e) => SystemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  factory SystemsIndex.fromJsonString(String jsonStr) =>
      SystemsIndex.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
}
