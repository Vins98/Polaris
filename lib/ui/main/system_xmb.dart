import 'dart:io';
import 'package:flutter/material.dart';
import 'package:polaris/models/models.dart';
import 'package:polaris/services/theme_service.dart';
import 'package:polaris/ui/main/system_carousel.dart' show SystemEntry;
import 'package:polaris/ui/main/theme_animations.dart';

class SystemXmbView extends StatefulWidget {
  final List<SystemEntry> systems;
  final PolarisTheme polarisTheme;
  final PolarisThemeConfig themeConfig;
  final int selectedIndex;
  final void Function(int index) onSystemChanged;

  /// Game databases keyed by systemId, used for the vertical games rail.
  final Map<String, List<GameEntry>> gamesBySystem;

  const SystemXmbView({
    super.key,
    required this.systems,
    required this.polarisTheme,
    required this.themeConfig,
    required this.selectedIndex,
    required this.onSystemChanged,
    required this.gamesBySystem,
  });

  @override
  State<SystemXmbView> createState() => SystemXmbViewState();
}

class SystemXmbViewState extends State<SystemXmbView> {
  int _gameIndex = 0;
  late ScrollController _systemsScrollController;
  late ScrollController _gamesScrollController;

  static const _iconSize = 84.0;
  static const _iconSpacing = 16.0;
  static const _gameRowHeight = 52.0;

  List<GameEntry> get _currentGames {
    final sid = widget.systems.isNotEmpty
        ? widget.systems[widget.selectedIndex].system.id
        : '';
    return widget.gamesBySystem[sid] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _systemsScrollController = ScrollController();
    _gamesScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSystem());
  }

  @override
  void didUpdateWidget(SystemXmbView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _gameIndex = 0;
      _scrollToSystem();
      _gamesScrollController.jumpTo(0);
    }
  }

  void _scrollToSystem() {
    final offset =
        (widget.selectedIndex * (_iconSize + _iconSpacing)) - 120;
    _systemsScrollController.animateTo(
      offset.clamp(0.0, double.infinity),
      duration:
          ThemeTransition.resolveDuration(widget.themeConfig.animation),
      curve: ThemeTransition.resolveCurve(widget.themeConfig.animation),
    );
  }

  /// Called by MainScreen keyboard handler — up/down navigate games.
  void moveGame(int delta) {
    final games = _currentGames;
    if (games.isEmpty) return;
    final next = (_gameIndex + delta).clamp(0, games.length - 1);
    if (next == _gameIndex) return;
    setState(() => _gameIndex = next);
    final offset = (next * _gameRowHeight) - 150;
    _gamesScrollController.animateTo(
      offset.clamp(0.0, double.infinity),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _systemsScrollController.dispose();
    _gamesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.polarisTheme;
    final cfg = widget.themeConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal systems rail ─────────────────────────────────────
        SizedBox(
          height: _iconSize + 32,
          child: ListView.builder(
            controller: _systemsScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            itemCount: widget.systems.length,
            itemBuilder: (context, index) {
              final entry = widget.systems[index];
              final isActive = index == widget.selectedIndex;
              return GestureDetector(
                onTap: () {
                  widget.onSystemChanged(index);
                  setState(() => _gameIndex = 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: _iconSpacing),
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: isActive
                        ? t.accentColor.withValues(alpha: 0.2)
                        : t.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(color: t.accentColor, width: 2)
                        : Border.all(color: Colors.white10, width: 1),
                    boxShadow: isActive
                        ? [BoxShadow(
                            color: t.accentColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1)]
                        : [],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _SystemIcon(
                    system: entry.system,
                    theme: t,
                  ),
                ),
              );
            },
          ),
        ),

        // Divider with selected system name
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Row(
            children: [
              ThemeTransition.switcher(
                anim: cfg.animation,
                child: Text(
                  widget.systems.isNotEmpty
                      ? widget.systems[widget.selectedIndex].system.name
                      : '',
                  key: ValueKey(widget.selectedIndex),
                  style: TextStyle(
                    color: t.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: t.accentColor.withValues(alpha: 0.25))),
            ],
          ),
        ),

        // ── Vertical games rail ─────────────────────────────────────────
        Expanded(
          child: Builder(builder: (context) {
            final games = _currentGames;
            final gcfg = cfg.gamesScreen;
            if (games.isEmpty) {
              return Center(
                child: Text(
                  'No games',
                  style: TextStyle(color: t.textSecondary, fontSize: 14),
                ),
              );
            }
            return ListView.builder(
              controller: _gamesScrollController,
              itemCount: games.length,
              itemExtent: _gameRowHeight,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, i) {
                final game = games[i];
                final isActive = i == _gameIndex;
                return GestureDetector(
                  onTap: () => setState(() => _gameIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? t.accentColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isActive
                          ? Border(
                              left: BorderSide(
                                  color: t.accentColor, width: 3))
                          : Border(
                              left: BorderSide(
                                  color: Colors.transparent, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                game.name,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_gameSubtitle(game, gcfg).isNotEmpty)
                                Text(
                                  _gameSubtitle(game, gcfg),
                                  style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (gcfg.showRating &&
                            game.metadata['rating'] != null)
                          _RatingDot(
                            rating: (game.metadata['rating'] as num)
                                .toDouble(),
                            theme: t,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  String _gameSubtitle(GameEntry game, GamesScreenConfig cfg) {
    final parts = <String>[];
    if (cfg.showYear) {
      final year = game.metadata['releaseYear'];
      if (year != null && year.toString().isNotEmpty) parts.add(year.toString());
    }
    if (cfg.showDeveloper) {
      final dev = game.metadata['developer'];
      if (dev != null && dev.toString().isNotEmpty) parts.add(dev.toString());
    }
    if (cfg.showGenre) {
      final genre = game.metadata['genre'];
      if (genre != null && genre.toString().isNotEmpty &&
          genre.toString() != 'None') {
        parts.add(genre.toString());
      }
    }
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// _SystemIcon
// ---------------------------------------------------------------------------

class _SystemIcon extends StatelessWidget {
  final SystemModel system;
  final PolarisTheme theme;

  const _SystemIcon({required this.system, required this.theme});

  @override
  Widget build(BuildContext context) {
    final imagePath = theme.systemImagePath(system.id);
    if (imagePath != null) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, s) => _initial(),
      );
    }
    return _initial();
  }

  Widget _initial() {
    final initial = system.name.isNotEmpty ? system.name[0].toUpperCase() : '?';
    return Container(
      color: theme.accentColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RatingDot
// ---------------------------------------------------------------------------

class _RatingDot extends StatelessWidget {
  final double rating;
  final PolarisTheme theme;

  const _RatingDot({required this.rating, required this.theme});

  @override
  Widget build(BuildContext context) {
    final pct = (rating * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          color: theme.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
