import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:polaris/models/models.dart';

/// Simple CRC32 implementation and folder scanner.
class _Crc32 {
  static final List<int> _table = _makeTable();

  static List<int> _makeTable() {
    final table = List<int>.filled(256, 0);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >> 1);
        } else {
          c = c >> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  /// Compute CRC32 for a file, returning lowercase 8-char hex string.
  static Future<String> file(File file) async {
    var c = 0xFFFFFFFF;
    try {
      await for (final chunk in file.openRead()) {
        for (final b in chunk) {
          c = _table[(c ^ b) & 0xFF] ^ ((c >> 8) & 0x00FFFFFF);
        }
      }
    } catch (e) {
      rethrow;
    }
    c = c ^ 0xFFFFFFFF;
    final masked = c & 0xFFFFFFFF;
    return masked.toRadixString(16).padLeft(8, '0').toLowerCase();
  }
}

class ScanService {
  /// Scans the folders described in `data/setup_result.json` and writes
  /// a per-folder GameDatabase JSON file under [outputDir].
  ///
  /// Returns the number of databases written.
  static Future<int> scanFromSetupResult({
    String setupResultPath = 'data/setup_result.json',
    String systemsPath = 'data/systems.json',
    String outputDir = 'data/game_databases',
  }) async {
    final f = File(setupResultPath);
    if (!await f.exists()) return 0;

    final raw = await f.readAsString();
    final map = json.decode(raw) as Map<String, dynamic>;

    final folders = (map['folders'] as List<dynamic>?) ?? const [];
    final emulators = (map['emulators'] as List<dynamic>?) ?? const [];

    final emuMap = <String, String?>{};
    for (final e in emulators) {
      if (e is Map<String, dynamic>) {
        final sid = e['systemId'] as String?;
        final emu = e['emulator'];
        if (sid != null) {
          if (emu is Map<String, dynamic>) {
            emuMap[sid] = emu['name'] as String?;
          } else {
            emuMap[sid] = null;
          }
        }
      }
    }

    final systemsIndex = await loadSystemsIndexFromFile(systemsPath);
    final sysById = {for (final s in systemsIndex.systems) s.id: s};

    final outDir = Directory(outputDir);
    await outDir.create(recursive: true);

    var written = 0;

    for (final fobj in folders) {
      if (fobj is! Map<String, dynamic>) continue;
      final folderPath = fobj['path'] as String?;
      final systemId = fobj['systemId'] as String?;
      if (folderPath == null || systemId == null) continue;

      final sys = sysById[systemId];
      if (sys == null) continue;

      final exts = sys.romFormats.map((e) => e.toLowerCase()).toSet();

      final dir = Directory(folderPath);
      if (!await dir.exists()) continue;

      final fname = '${_sanitizeFilename(folderPath)}.json';
      final outPath = p.join(outDir.path, fname);

      // Load existing DB to preserve metadata on unchanged entries.
      GameDatabase? existingDb;
      final outFile = File(outPath);
      if (await outFile.exists()) {
        try {
          existingDb = GameDatabase.fromJsonString(await outFile.readAsString());
        } catch (_) {}
      }
      final existingByPath = {
        for (final g in existingDb?.games ?? <GameEntry>[]) g.path: g,
      };

      // Scan disk for current ROM files.
      final diskPaths = <String>{};
      final games = <GameEntry>[];

      try {
        await for (final ent in dir.list(recursive: true, followLinks: false)) {
          if (ent is File) {
            final ext = p.extension(ent.path).toLowerCase();
            if (ext.isEmpty) continue;
            if (!exts.contains(ext)) continue;
            diskPaths.add(ent.path);

            final existing = existingByPath[ent.path];
            if (existing != null) {
              // File already known — keep entry with all its metadata intact.
              games.add(existing);
            } else {
              // New file — hash and create a bare entry.
              final hash = await _Crc32.file(ent);
              final name = p.basenameWithoutExtension(ent.path);
              games.add(GameEntry(
                path: ent.path,
                systemId: systemId,
                emulator: emuMap[systemId],
                name: name,
                hash: hash,
              ));
            }
          }
        }
      } catch (e) {
        // ignore read errors for individual folders/files
      }
      // Entries not on disk any more are simply omitted (deleted ROMs removed).

      final db = GameDatabase(
        folder: folderPath,
        systemId: systemId,
        emulator: emuMap[systemId],
        games: games,
        metadata: existingDb?.metadata ?? {},
      );
      await saveModelToFile<GameDatabase>(
        outPath,
        db,
        (d) => d.toJson(),
        pretty: true,
      );
      written++;
    }

    return written;
  }
}

String _sanitizeFilename(String s) {
  var out = s.replaceAll(RegExp(r'[:\\/]'), '_');
  out = out.replaceAll(RegExp(r'[^0-9A-Za-z_\-\.]'), '_');
  if (out.length > 120) {
    out = out.substring(out.length - 120);
  }
  if (out.isEmpty) out = 'db';
  return out;
}
