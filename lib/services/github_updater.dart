import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:polaris/models/models.dart';

/// Simple GitHub raw file updater for index-style JSON files.
///
/// Usage:
/// final updater = GitHubUpdater(owner: 'owner', repo: 'repo');
/// await updater.checkAndUpdateAll();
class FileUpdateResult<T> {
  final bool updated;
  final int? oldRevision;
  final int? newRevision;
  final T? index;
  final String localPath;
  final String remotePath;
  final String? error;

  const FileUpdateResult({
    required this.updated,
    this.oldRevision,
    this.newRevision,
    this.index,
    required this.localPath,
    required this.remotePath,
    this.error,
  });

  @override
  String toString() =>
      'FileUpdateResult(updated: $updated, old: $oldRevision, new: $newRevision, path: $localPath, error: $error)';
}

class UpdateSummary {
  final FileUpdateResult<SystemsIndex> systems;
  final FileUpdateResult<EmulatorsIndex> emulators;

  const UpdateSummary({required this.systems, required this.emulators});
}

class GitHubUpdater {
  final String owner;
  final String repo;
  final String branch;
  final http.Client _client;

  GitHubUpdater({
    required this.owner,
    required this.repo,
    this.branch = 'main',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _rawUri(String path) =>
      Uri.https('raw.githubusercontent.com', '/$owner/$repo/$branch/$path');

  Future<String> _fetchRaw(String remotePath) async {
    final uri = _rawUri(remotePath);
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw HttpException('Failed to fetch $uri (status ${resp.statusCode})');
    }
    return resp.body;
  }

  Future<int?> _localRevision(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic> && decoded['revision'] is int) {
        return decoded['revision'] as int;
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  Future<FileUpdateResult<SystemsIndex>> checkAndUpdateSystems({
    String remotePath = 'data/systems.json',
    String localPath = 'data/systems.json',
  }) async {
    try {
      final remoteContent = await _fetchRaw(remotePath);
      final remoteMap = json.decode(remoteContent) as Map<String, dynamic>;
      final remoteIndex = SystemsIndex.fromJson(remoteMap);
      final remoteRev = remoteIndex.revision;

      final localRev = await _localRevision(localPath);

      if (localRev == null || remoteRev > localRev) {
        final file = File(localPath);
        await file.create(recursive: true);
        await file.writeAsString(remoteContent);
        return FileUpdateResult<SystemsIndex>(
          updated: true,
          oldRevision: localRev,
          newRevision: remoteRev,
          index: remoteIndex,
          localPath: localPath,
          remotePath: remotePath,
        );
      }

      return FileUpdateResult<SystemsIndex>(
        updated: false,
        oldRevision: localRev,
        newRevision: remoteRev,
        index: remoteIndex,
        localPath: localPath,
        remotePath: remotePath,
      );
    } catch (e) {
      return FileUpdateResult<SystemsIndex>(
        updated: false,
        oldRevision: await _localRevision(localPath),
        newRevision: null,
        index: null,
        localPath: localPath,
        remotePath: remotePath,
        error: e.toString(),
      );
    }
  }

  Future<FileUpdateResult<EmulatorsIndex>> checkAndUpdateEmulators({
    String remotePath = 'data/emulators.json',
    String localPath = 'data/emulators.json',
  }) async {
    try {
      final remoteContent = await _fetchRaw(remotePath);
      final remoteMap = json.decode(remoteContent) as Map<String, dynamic>;
      final remoteIndex = EmulatorsIndex.fromJson(remoteMap);
      final remoteRev = remoteIndex.revision;

      final localRev = await _localRevision(localPath);

      if (localRev == null || remoteRev > localRev) {
        final file = File(localPath);
        await file.create(recursive: true);
        await file.writeAsString(remoteContent);
        return FileUpdateResult<EmulatorsIndex>(
          updated: true,
          oldRevision: localRev,
          newRevision: remoteRev,
          index: remoteIndex,
          localPath: localPath,
          remotePath: remotePath,
        );
      }

      return FileUpdateResult<EmulatorsIndex>(
        updated: false,
        oldRevision: localRev,
        newRevision: remoteRev,
        index: remoteIndex,
        localPath: localPath,
        remotePath: remotePath,
      );
    } catch (e) {
      return FileUpdateResult<EmulatorsIndex>(
        updated: false,
        oldRevision: await _localRevision(localPath),
        newRevision: null,
        index: null,
        localPath: localPath,
        remotePath: remotePath,
        error: e.toString(),
      );
    }
  }

  /// Check/update both systems and emulators. Returns an [UpdateSummary].
  Future<UpdateSummary> checkAndUpdateAll({
    String systemsRemote = 'data/systems.json',
    String emulatorsRemote = 'data/emulators.json',
    String systemsLocal = 'data/systems.json',
    String emulatorsLocal = 'data/emulators.json',
  }) async {
    final sys = await checkAndUpdateSystems(
      remotePath: systemsRemote,
      localPath: systemsLocal,
    );
    final emu = await checkAndUpdateEmulators(
      remotePath: emulatorsRemote,
      localPath: emulatorsLocal,
    );
    return UpdateSummary(systems: sys, emulators: emu);
  }

  void dispose() => _client.close();
}
