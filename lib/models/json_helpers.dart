import 'dart:convert';
import 'dart:io';

import 'system_model.dart';
import 'emulator_model.dart';
import 'game_database.dart';
import 'theme_model.dart';

/// Generic JSON file helpers for models.
/// These helpers assume JSON files use UTF-8 encoding and that
/// models expose `fromJson(Map<String, dynamic>)` factories and `toJson()` methods.

Future<T> loadModelFromFile<T>(
  String path,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('File not found', path);
  }
  final content = await file.readAsString();
  final decoded = json.decode(content);
  if (decoded is Map<String, dynamic>) {
    return fromJson(decoded);
  }
  throw FormatException('JSON root is not an object in $path');
}

Future<List<T>> loadModelListFromFile<T>(
  String path,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('File not found', path);
  }
  final content = await file.readAsString();
  final decoded = json.decode(content);
  if (decoded is List) {
    return decoded.map<T>((e) {
      if (e is Map<String, dynamic>) return fromJson(e);
      throw FormatException('List element is not an object in $path');
    }).toList();
  }
  throw FormatException('JSON root is not a list in $path');
}

Future<void> saveModelToFile<T>(
  String path,
  T model,
  Map<String, dynamic> Function(T) toJson, {
  bool pretty = false,
}) async {
  final encoder = pretty ? JsonEncoder.withIndent('  ') : const JsonEncoder();
  final jsonStr = encoder.convert(toJson(model));
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(jsonStr);
}

Future<void> saveModelListToFile<T>(
  String path,
  List<T> items,
  Map<String, dynamic> Function(T) toJson, {
  bool pretty = false,
}) async {
  final encoder = pretty ? JsonEncoder.withIndent('  ') : const JsonEncoder();
  final jsonList = items.map((e) => toJson(e)).toList();
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(encoder.convert(jsonList));
}

List<File> listJsonFilesInDirectory(String dirPath, {bool recursive = false}) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: recursive)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList();
}

Future<List<T>> loadAllJsonModelsInDirectory<T>(
  String dirPath,
  T Function(Map<String, dynamic>) fromJson, {
  bool recursive = false,
}) async {
  final files = listJsonFilesInDirectory(dirPath, recursive: recursive);
  final result = <T>[];
  for (final f in files) {
    try {
      result.add(await loadModelFromFile<T>(f.path, fromJson));
    } catch (_) {
      // ignore invalid files
    }
  }
  return result;
}

// Convenience helpers for known models

Future<ThemeModel> loadThemeFromFile(String path) =>
    loadModelFromFile<ThemeModel>(path, (m) => ThemeModel.fromJson(m));

Future<SystemModel> loadSystemFromFile(String path) =>
    loadModelFromFile<SystemModel>(path, (m) => SystemModel.fromJson(m));

Future<EmulatorModel> loadEmulatorFromFile(String path) =>
    loadModelFromFile<EmulatorModel>(path, (m) => EmulatorModel.fromJson(m));

/// Loads an index-style emulators file that contains a `revision` and
/// an `emulators` array (e.g. `data/emulators.json`).
Future<EmulatorsIndex> loadEmulatorsIndexFromFile(String path) =>
    loadModelFromFile<EmulatorsIndex>(path, (m) => EmulatorsIndex.fromJson(m));

/// Loads an index-style systems file that contains a `revision` and
/// a `systems` array (e.g. `data/systems.json`).
Future<SystemsIndex> loadSystemsIndexFromFile(String path) =>
    loadModelFromFile<SystemsIndex>(path, (m) => SystemsIndex.fromJson(m));

Future<GameDatabase> loadGameDatabaseFromFile(String path) =>
    loadModelFromFile<GameDatabase>(path, (m) => GameDatabase.fromJson(m));

Future<List<ThemeModel>> loadAllThemesInDirectory(
  String dirPath, {
  bool recursive = false,
}) async => loadAllJsonModelsInDirectory<ThemeModel>(
  dirPath,
  (m) => ThemeModel.fromJson(m),
  recursive: recursive,
);

Future<List<SystemModel>> loadAllSystemsInDirectory(
  String dirPath, {
  bool recursive = false,
}) async => loadAllJsonModelsInDirectory<SystemModel>(
  dirPath,
  (m) => SystemModel.fromJson(m),
  recursive: recursive,
);

Future<List<EmulatorModel>> loadAllEmulatorsInDirectory(
  String dirPath, {
  bool recursive = false,
}) async => loadAllJsonModelsInDirectory<EmulatorModel>(
  dirPath,
  (m) => EmulatorModel.fromJson(m),
  recursive: recursive,
);

Future<List<GameDatabase>> loadAllGameDatabasesInDirectory(
  String dirPath, {
  bool recursive = false,
}) async => loadAllJsonModelsInDirectory<GameDatabase>(
  dirPath,
  (m) => GameDatabase.fromJson(m),
  recursive: recursive,
);
