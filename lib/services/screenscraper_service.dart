import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:polaris/models/models.dart';
import 'package:screenscraper/screenscraper.dart';

// ---------------------------------------------------------------------------
// ScreenScraper system ID map  (Polaris string id → ScreenScraper int id)
// ---------------------------------------------------------------------------
const Map<String, int> kScreenScraperSystemIds = {
  '3do': 29,
  'amiga': 64,
  'amstradcpc': 65,
  'apple2': 86,
  'apple2gs': 217,
  'arcade': 75,
  'atari2600': 26,
  'atari5200': 40,
  'atari7800': 41,
  'atari800': 43,
  'atarijaguar': 27,
  'atarijaguarcd': 171,
  'atarilynx': 28,
  'atarist': 42,
  'atarixe': 43,
  'c64': 66,
  'cdimono1': 62,
  'cdtv': 64,
  'colecovision': 48,
  'dos': 135,
  'dreamcast': 23,
  'fds': 106,
  'flash': 88,
  'gameandwatch': 52,
  'gamegear': 21,
  'gb': 9,
  'gba': 12,
  'gbc': 10,
  'gc': 13,
  'genesis': 1,
  'intellivision': 115,
  'laserdisc': 91,
  'macintosh': 146,
  'mastersystem': 2,
  'megacd': 20,
  'msx1': 57,
  'msx2': 57,
  'msxturbor': 57,
  'n3ds': 17,
  'n64': 14,
  'naomi': 56,
  'naomi2': 56,
  'nds': 15,
  'neogeo': 142,
  'neogeocd': 70,
  'nes': 3,
  'ngage': 112,
  'ngp': 25,
  'ngpc': 82,
  'pc88': 221,
  'pc98': 208,
  'pcengine': 31,
  'pcfx': 72,
  'pokemini': 211,
  'ps2': 58,
  'ps3': 59,
  'ps4': 60,
  'psp': 61,
  'psvita': 62,
  'psx': 57,
  'saturn': 22,
  'scummvm': 123,
  'sega32x': 19,
  'segacd': 20,
  'sg-1000': 109,
  'snes': 4,
  'switch': 225,
  'symbian': 92,
  'triforce': 56,
  'vic20': 73,
  'virtualboy': 11,
  'wii': 16,
  'wiiu': 18,
  'wonderswan': 45,
  'wonderswancolor': 46,
  'x68000': 79,
  'xbox': 32,
  'xbox360': 33,
  'zxspectrum': 76,
};

// ---------------------------------------------------------------------------
// ScreenscraperService
// ---------------------------------------------------------------------------

class ScreenscraperService {
  static const _devId = 'Vins98';
  static const _devPassword = 'pKnsdnxbKKn';
  static const _softwareName = 'Polaris';

  final String _userName;
  final String _userPassword;

  const ScreenscraperService({
    String userName = _devId,
    String userPassword = _devPassword,
  })  : _userName = userName,
        _userPassword = userPassword;

  RomScraper _buildScraper() => RomScraper(
        devId: _devId,
        devPassword: _devPassword,
        softwareName: _softwareName,
        userName: _userName,
        userPassword: _userPassword,
      );

  /// Returns the ScreenScraper int system ID for a Polaris [systemId], or null
  /// if the system is not mapped.
  static int? screenScraperSystemId(String systemId) =>
      kScreenScraperSystemIds[systemId];

  // ---------------------------------------------------------------------------
  // Core scrape call
  // ---------------------------------------------------------------------------

  /// Scrape metadata for a single ROM file using a shared [scraper] instance.
  ///
  /// Returns a [Game] or null on any failure (not found, network error, etc.).
  Future<Game?> scrapeRom({
    required String systemId,
    required String romPath,
    RomScraper? scraper,
  }) async {
    final ssId = screenScraperSystemId(systemId);
    if (ssId == null) {
      print('[SS] No ScreenScraper system ID mapped for systemId=$systemId');
      return null;
    }

    final ownScraper = scraper == null;
    final s = scraper ?? _buildScraper();
    try {
      final game = await s.scrapeRom(systemId: ssId, romPath: romPath);
      print('[SS] Found: ${game.name} (gameId=${game.gameId})  '
          'screenshot=${game.media.screenshot?.url}  '
          'box2d=${game.media.box2d?.url}');
      return game;
    } catch (e) {
      print('[SS] scrapeRom failed for $romPath: $e');
      return null;
    } finally {
      if (ownScraper) s.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Image download helper
  // ---------------------------------------------------------------------------

  /// Downloads [url] to [destPath]. Appends ScreenScraper auth params if the
  /// URL points to screenscraper.fr. Creates parent directories as needed.
  /// Returns true on success.
  Future<bool> downloadImage(String url, String destPath) async {
    try {
      // ScreenScraper media URLs require auth query params.
      Uri uri = Uri.parse(url);
      if (uri.host.contains('screenscraper.fr')) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'devid': _devId,
          'devpassword': _devPassword,
          'softname': _softwareName,
          'ssid': _userName,
          'sspassword': _userPassword,
        });
      }

      print('[SS] Downloading image: ${uri.host}${uri.path} → $destPath');

      final client = HttpClient();
      client.autoUncompress = true;
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        print('[SS] Image download failed: HTTP ${res.statusCode} for $destPath');
        client.close();
        return false;
      }
      final file = File(destPath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      await res.pipe(sink);
      client.close();
      print('[SS] Image saved: $destPath');
      return true;
    } catch (e) {
      print('[SS] downloadImage error for $destPath: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // High-level: scrape + enrich a GameEntry
  // ---------------------------------------------------------------------------

  /// Scrapes [entry] and returns an enriched copy with metadata and local image
  /// paths.  Images are saved under [imageBaseDir].
  ///
  /// Pass a shared [scraper] to reuse one HTTP client across many calls.
  /// Returns the original [entry] unchanged on failure.
  Future<GameEntry> scrapeGameEntry(
    GameEntry entry, {
    String imageBaseDir = 'data/images',
    RomScraper? scraper,
    bool downloadImages = true,
  }) async {
    // Skip if already scraped: ssGameId in metadata, and either
    // we're not downloading images or the image folder already exists.
    final sysDir = p.join(imageBaseDir, entry.systemId, entry.hash);
    final hasMetadata = entry.metadata.containsKey('ssGameId');
    final hasImages = await Directory(sysDir).exists();
    if (hasMetadata && (!downloadImages || hasImages)) {
      print('[SS] Skipping already scraped: ${entry.name}');
      return entry;
    }

    final game = await scrapeRom(
      systemId: entry.systemId,
      romPath: entry.path,
      scraper: scraper,
    );
    if (game == null) return entry;

    // sysDir already declared above.

    String? screenshotPath;
    String? box2dPath;
    String? wheelPath;
    String? fanArtPath;

    if (downloadImages) {
      if (game.media.screenshot != null) {
        final ext = game.media.screenshot!.format.isNotEmpty
            ? '.${game.media.screenshot!.format}'
            : '.png';
        final dest = p.join(sysDir, 'screenshot$ext');
        if (await downloadImage(game.media.screenshot!.url, dest)) {
          screenshotPath = dest;
        }
      }

      if (game.media.box2d != null) {
        final ext = game.media.box2d!.format.isNotEmpty
            ? '.${game.media.box2d!.format}'
            : '.png';
        final dest = p.join(sysDir, 'box2d$ext');
        if (await downloadImage(game.media.box2d!.url, dest)) {
          box2dPath = dest;
        }
      }

      if (game.media.wheel != null) {
        final ext = game.media.wheel!.format.isNotEmpty
            ? '.${game.media.wheel!.format}'
            : '.png';
        final dest = p.join(sysDir, 'wheel$ext');
        if (await downloadImage(game.media.wheel!.url, dest)) {
          wheelPath = dest;
        }
      }

      if (game.media.fanArt != null) {
        final ext = game.media.fanArt!.format.isNotEmpty
            ? '.${game.media.fanArt!.format}'
            : '.png';
        final dest = p.join(sysDir, 'fanart$ext');
        if (await downloadImage(game.media.fanArt!.url, dest)) {
          fanArtPath = dest;
        }
      }
    } else {
      // Preserve existing image paths from metadata.
      screenshotPath = entry.metadata['screenshotPath'] as String?;
      box2dPath = entry.metadata['box2dPath'] as String?;
      wheelPath = entry.metadata['wheelPath'] as String?;
      fanArtPath = entry.metadata['fanArtPath'] as String?;
    }

    final meta = <String, dynamic>{
      'ssGameId': game.gameId,
      'ssRomId': game.romId,
      'ssSystemId': game.systemId,
      'ssSystemName': game.systemName,
      'description': game.description,
      'developer': game.developer,
      'publisher': game.publisher,
      'players': game.players,
      'rating': game.rating,
      'releaseYear': game.releaseYear,
      'genre': game.normalizedGenre?.name,
      'genres': game.genres?.map((g) => g.name).toList(),
      'isTopStaff': game.isTopStaff,
      'screenshotPath': ?screenshotPath,
      'box2dPath': ?box2dPath,
      'wheelPath': ?wheelPath,
      'fanArtPath': ?fanArtPath,
    };

    final scrapedName = game.name.trim();
    final resolvedName = scrapedName.isNotEmpty ? scrapedName : entry.name;
    print('[SS] Saving entry: name="$resolvedName" developer="${game.developer}" year="${game.releaseYear}" imageDir=$sysDir');

    return entry.copyWith(
      name: resolvedName,
      metadata: meta,
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk scrape: enrich all games in a list of GameDatabase files
  // ---------------------------------------------------------------------------

  /// Scrapes every game across [dbPaths] and overwrites each file with the
  /// enriched data.
  ///
  /// [onProgress] is called after each ROM with (done, total, gameName).
  static Future<void> scrapeAllDatabases({
    String dbDir = 'data/game_databases',
    String imageBaseDir = 'data/images',
    bool downloadImages = true,
    void Function(int done, int total, String gameName)? onProgress,
  }) async {
    final service = ScreenscraperService();
    final scraper = service._buildScraper();
    final dir = Directory(dbDir);
    if (!await dir.exists()) {
      scraper.close();
      return;
    }

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    // Count total games first
    final allDbs = <File, GameDatabase>{};
    var total = 0;
    for (final file in files) {
      try {
        final raw = await file.readAsString();
        final db = GameDatabase.fromJsonString(raw);
        allDbs[file] = db;
        total += db.games.length;
      } catch (e) {
        print('[SS] Failed to read DB ${file.path}: $e');
      }
    }

    var done = 0;
    const encoder = JsonEncoder.withIndent('  ');
    try {
      for (final entry in allDbs.entries) {
        final file = entry.key;
        var db = entry.value;

        for (final game in db.games) {
          final result = await service.scrapeGameEntry(
            game,
            imageBaseDir: imageBaseDir,
            scraper: scraper,
            downloadImages: downloadImages,
          );
          // Only write back if the entry was actually enriched.
          if (!identical(result, game) && result.metadata.isNotEmpty) {
            final updatedGames = db.games
                .map((g) => g.path == result.path ? result : g)
                .toList();
            db = db.copyWith(games: updatedGames);
            await file.writeAsString(encoder.convert(db.toJson()));
          }
          done++;
          onProgress?.call(done, total, result.name);
        }
      }
    } finally {
      scraper.close();
    }
  }
}
