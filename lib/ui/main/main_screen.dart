import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polaris/models/models.dart';
import 'package:polaris/services/screenscraper_service.dart';
import 'package:polaris/services/theme_service.dart';
import 'package:polaris/ui/games/games_screen.dart';
import 'package:polaris/ui/main/start_menu.dart';
import 'package:polaris/ui/main/system_carousel.dart';
import 'package:polaris/ui/main/system_list.dart';
import 'package:polaris/ui/main/system_xmb.dart';
import 'package:polaris/ui/main/theme_animations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _loading = true;
  String? _error;

  List<SystemEntry> _systems = [];
  Map<String, List<GameEntry>> _gamesBySystem = {};
  int _selectedIndex = 0;

  PolarisThemeConfig _themeConfig =
      PolarisThemeConfig.fromJson({'id': '', 'name': '', 'colors': {}}, themeDir: '');
  PolarisTheme _theme = PolarisTheme(
    backgroundColor: const Color(0xFF0D0D0D),
    cardColor: const Color(0xFF1A1A2E),
    accentColor: const Color(0xFF7B61FF),
    textPrimary: const Color(0xFFF0F0F0),
    textSecondary: const Color(0xFF888888),
    cardBorderActive: const Color(0xFF7B61FF),
    themeDir: '',
  );

  bool _scraping = false;
  int _scrapeDone = 0;
  int _scrapeTotal = 0;
  String _scrapeCurrentGame = '';

  late FocusNode _focusNode;
  final GlobalKey<SystemXmbViewState> _xmbKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _load();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final themeResult = await ThemeService.load();
      final sysIndex =
          await loadSystemsIndexFromFile('data/systems.json');
      final dbs = await loadAllGameDatabasesInDirectory('data/game_databases');

      final gameCounts = <String, int>{};
      final gamesBySystem = <String, List<GameEntry>>{};
      for (final db in dbs) {
        gameCounts[db.systemId] =
            (gameCounts[db.systemId] ?? 0) + db.games.length;
        gamesBySystem[db.systemId] = [
          ...(gamesBySystem[db.systemId] ?? []),
          ...db.games,
        ];
      }

      final entries = sysIndex.systems
          .where((s) => (gameCounts[s.id] ?? 0) > 0)
          .map((s) =>
              SystemEntry(system: s, gameCount: gameCounts[s.id]!))
          .toList();

      if (mounted) {
        setState(() {
          _themeConfig = themeResult.config;
          _theme = themeResult.theme;
          _systems = entries;
          _gamesBySystem = gamesBySystem;
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_scraping) return KeyEventResult.ignored;

    final isXmb = _themeConfig.viewMode == 'xmb';

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_selectedIndex > 0) setState(() => _selectedIndex--);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        if (_selectedIndex < _systems.length - 1) {
          setState(() => _selectedIndex++);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (isXmb) _xmbKey.currentState?.moveGame(-1);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        if (isXmb) _xmbKey.currentState?.moveGame(1);
        // List view uses up/down for system nav
        if (_themeConfig.viewMode == 'list') {
          if (_selectedIndex > 0) setState(() => _selectedIndex--);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.gameButtonStart:
        _openStartMenu();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.gameButtonA:
        _openGamesScreen();
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  // ── Games screen ─────────────────────────────────────────────────────────

  Future<void> _openGamesScreen() async {
    if (_systems.isEmpty) return;
    final entry = _systems[_selectedIndex];
    final games = _gamesBySystem[entry.system.id] ?? [];
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => GamesScreen(
          system: entry.system,
          games: games,
          polarisTheme: _theme,
          themeConfig: _themeConfig,
        ),
      ),
    );
    if (mounted) _focusNode.requestFocus();
  }

  // ── Start menu ────────────────────────────────────────────────────────────

  Future<void> _openStartMenu() async {
    if (!mounted) return;
    final action = await showStartMenu(context, _theme);
    if (!mounted) return;
    switch (action) {
      case StartMenuAction.generalSettings:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('General Settings — coming soon')),
        );
      case StartMenuAction.sorting:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorting — coming soon')),
        );
      case StartMenuAction.scraping:
        _showScrapeDialog();
      case StartMenuAction.exit:
        exit(0);
      case StartMenuAction.dismissed:
        break;
    }
    _focusNode.requestFocus();
  }

  // ── Scraping ──────────────────────────────────────────────────────────────

  Future<void> _showScrapeDialog() async {
    if (!mounted) return;
    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _theme.cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Scrape Metadata',
            style: TextStyle(color: _theme.textPrimary)),
        content: Text(
          'Download metadata and images for all ROMs from ScreenScraper?\n\n'
          'This may take a while depending on your library size.',
          style: TextStyle(color: _theme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Skip')),
          OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Metadata Only')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Metadata + Images')),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    _runScrape(downloadImages: choice);
  }

  Future<void> _runScrape({bool downloadImages = true}) async {
    setState(() {
      _scraping = true;
      _scrapeDone = 0;
      _scrapeTotal = 0;
      _scrapeCurrentGame = '';
    });
    try {
      await ScreenscraperService.scrapeAllDatabases(
        downloadImages: downloadImages,
        onProgress: (done, total, gameName) {
          if (mounted) {
            setState(() {
              _scrapeDone = done;
              _scrapeTotal = total;
              _scrapeCurrentGame = gameName;
            });
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scraping complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scrape error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scraping = false);
        _focusNode.requestFocus();
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: t.backgroundColor,
        body: _loading
            ? Center(child: CircularProgressIndicator(color: t.accentColor))
            : _error != null
                ? _buildError(t)
                : _buildMain(t),
      ),
    );
  }

  Widget _buildError(PolarisTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Failed to load:\n$_error',
            style: TextStyle(color: t.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildMain(PolarisTheme t) {
    return Stack(
      children: [
        Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'POLARIS',
                      style: TextStyle(
                        color: t.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    _HintBadge(
                        label: 'Start / Esc',
                        icon: Icons.menu,
                        theme: t),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── System headline (carousel + list) ────────────────────────
            if (_themeConfig.viewMode != 'xmb' && _systems.isNotEmpty)
              ThemeTransition.switcher(
                anim: _themeConfig.animation,
                child: Text(
                  _systems[_selectedIndex].system.name,
                  key: ValueKey(_selectedIndex),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            if (_themeConfig.viewMode != 'xmb')
              const SizedBox(height: 8),

            // ── Main view ────────────────────────────────────────────────
            Expanded(child: _buildView(t)),

            // ── Nav hint ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildNavHint(t),
            ),
          ],
        ),

        // ── Scraping overlay ─────────────────────────────────────────────
        if (_scraping) _buildScrapeOverlay(t),
      ],
    );
  }

  Widget _buildView(PolarisTheme t) {
    switch (_themeConfig.viewMode) {
      case 'list':
        return SystemListView(
          systems: _systems,
          polarisTheme: t,
          themeConfig: _themeConfig,
          selectedIndex: _selectedIndex,
          onIndexChanged: (i) {
            setState(() => _selectedIndex = i);
            _focusNode.requestFocus();
          },
        );
      case 'xmb':
        return SystemXmbView(
          key: _xmbKey,
          systems: _systems,
          polarisTheme: t,
          themeConfig: _themeConfig,
          selectedIndex: _selectedIndex,
          onSystemChanged: (i) {
            setState(() => _selectedIndex = i);
            _focusNode.requestFocus();
          },
          gamesBySystem: _gamesBySystem,
        );
      case 'carousel':
      default:
        return SystemCarousel(
          systems: _systems,
          polarisTheme: t,
          themeConfig: _themeConfig,
          selectedIndex: _selectedIndex,
          onIndexChanged: (i) {
            setState(() => _selectedIndex = i);
            _focusNode.requestFocus();
          },
        );
    }
  }

  Widget _buildNavHint(PolarisTheme t) {
    final isXmb = _themeConfig.viewMode == 'xmb';
    final isList = _themeConfig.viewMode == 'list';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HintBadge(
          label: isXmb ? '← →' : (isList ? '↑ ↓' : '← →'),
          icon: null,
          theme: t,
        ),
        const SizedBox(width: 6),
        Text(
          'Systems',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        if (isXmb) ...[
          const SizedBox(width: 14),
          _HintBadge(label: '↑ ↓', icon: null, theme: t),
          const SizedBox(width: 6),
          Text(
            'Games',
            style: TextStyle(color: t.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildScrapeOverlay(PolarisTheme t) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scraping Metadata…',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _scrapeTotal > 0
                      ? _scrapeDone / _scrapeTotal
                      : null,
                  color: t.accentColor,
                  backgroundColor: t.accentColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 10),
                Text(
                  _scrapeTotal > 0
                      ? '$_scrapeDone / $_scrapeTotal'
                      : 'Starting…',
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
                if (_scrapeCurrentGame.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _scrapeCurrentGame,
                    style:
                        TextStyle(color: t.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HintBadge
// ---------------------------------------------------------------------------

class _HintBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final PolarisTheme theme;

  const _HintBadge(
      {required this.label, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.textSecondary, size: 13),
            const SizedBox(width: 5),
          ],
          Text(label,
              style:
                  TextStyle(color: theme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
