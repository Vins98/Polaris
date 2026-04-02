import 'dart:convert';

class LaunchParams {
  final List<String> beforeRom;
  final List<String> afterRom;
  final Map<String, String> envVars;

  const LaunchParams({
    this.beforeRom = const [],
    this.afterRom = const [],
    this.envVars = const {},
  });

  Map<String, dynamic> toJson() => {
    'beforeRom': beforeRom,
    'afterRom': afterRom,
    'envVars': envVars,
  };

  factory LaunchParams.fromJson(Map<String, dynamic> json) => LaunchParams(
    beforeRom:
        (json['beforeRom'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    afterRom:
        (json['afterRom'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    envVars: (json['envVars'] as Map?)?.cast<String, String>() ?? {},
  );
}

class EmulatorModel {
  final String name;
  final String? executable;
  final String? updaterExecutable;
  final LaunchParams launchParams;
  final List<String> supportedSystems;
  final Map<String, dynamic>? metadata;

  const EmulatorModel({
    required this.name,
    this.executable,
    this.updaterExecutable,
    this.launchParams = const LaunchParams(),
    this.supportedSystems = const [],
    this.metadata,
  });

  EmulatorModel copyWith({
    String? name,
    String? executable,
    String? updaterExecutable,
    LaunchParams? launchParams,
    List<String>? supportedSystems,
    Map<String, dynamic>? metadata,
  }) {
    return EmulatorModel(
      name: name ?? this.name,
      executable: executable ?? this.executable,
      updaterExecutable: updaterExecutable ?? this.updaterExecutable,
      launchParams: launchParams ?? this.launchParams,
      supportedSystems: supportedSystems ?? this.supportedSystems,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'executable': executable,
      'updaterExecutable': updaterExecutable,
      'launchParams': launchParams.toJson(),
      'supportedSystems': supportedSystems,
      'metadata': metadata,
    };
  }

  factory EmulatorModel.fromJson(Map<String, dynamic> json) {
    return EmulatorModel(
      name: json['name'] as String,
      executable: json['executable'] as String?,
      updaterExecutable: json['updaterExecutable'] as String?,
      launchParams: json['launchParams'] != null
          ? LaunchParams.fromJson(json['launchParams'] as Map<String, dynamic>)
          : const LaunchParams(),
      supportedSystems:
          (json['supportedSystems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ??
          (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  factory EmulatorModel.fromJsonString(String jsonStr) =>
      EmulatorModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  @override
  String toString() => 'EmulatorModel(name: $name, executable: $executable)';
}

class EmulatorsIndex {
  final int revision;
  final List<EmulatorModel> emulators;

  const EmulatorsIndex({required this.revision, this.emulators = const []});

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'emulators': emulators.map((e) => e.toJson()).toList(),
  };

  factory EmulatorsIndex.fromJson(Map<String, dynamic> json) => EmulatorsIndex(
    revision: json['revision'] as int,
    emulators:
        (json['emulators'] as List<dynamic>?)
            ?.map((e) => EmulatorModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  factory EmulatorsIndex.fromJsonString(String jsonStr) =>
      EmulatorsIndex.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
}
