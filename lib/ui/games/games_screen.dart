import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polaris/models/models.dart';
import 'package:polaris/services/theme_service.dart';

class GamesScreen extends StatefulWidget {
  final SystemModel system;
  final List<GameEntry> games;
  final PolarisTheme polarisTheme;
  final PolarisThemeConfig themeConfig;

  const GamesScreen({
    super.key,
    required this.system,
    required this.games,
    required this.polarisTheme,
    required this.themeConfig,
  });

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _selectedIndex = 0;
  bool _descExpanded = false;

  late FocusNode _focusNode;
  late ScrollController _scrollController;

  static const _rowHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final offset = (_selectedIndex * _rowHeight) - 200;
    _scrollController.animateTo(
      offset.clamp(0.0, double.infinity),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_selectedIndex > 0) {
          setState(() {
            _selectedIndex--;
            _descExpanded = false;
          });
          _scrollToSelected();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        if (_selectedIndex < widget.games.length - 1) {
          setState(() {
            _selectedIndex++;
            _descExpanded = false;
          });
          _scrollToSelected();
        }
        return KeyEventResult.handled;

      // X button (Xbox) = gameButtonX — expand/collapse description
      case LogicalKeyboardKey.gameButtonX:
      case LogicalKeyboardKey.keyX:
        setState(() => _descExpanded = !_descExpanded);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.gameButtonB:
        Navigator.of(context).pop();
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.polarisTheme;
    final cfg = widget.themeConfig.gamesScreen;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: t.backgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.arrow_back_ios,
                          color: t.accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.system.name.toUpperCase(),
                      style: TextStyle(
                        color: t.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    _HintBadge(label: 'X  Description', theme: t),
                    const SizedBox(width: 8),
                    _HintBadge(label: 'B / Esc  Back', theme: t),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Body: artwork + list ────────────────────────────────────────
            Expanded(
              child: widget.games.isEmpty
                  ? Center(
                      child: Text('No games',
                          style: TextStyle(
                              color: t.textSecondary, fontSize: 16)))
                  : Row(
                      children: [
                        // Artwork + description panel — 70%
                        Expanded(
                          flex: 7,
                          child: _ArtworkPanel(
                            game: widget.games[_selectedIndex],
                            artworkType: cfg.artworkType,
                            cfg: cfg,
                            theme: t,
                            descExpanded: _descExpanded,
                            onToggleDesc: () =>
                                setState(() => _descExpanded = !_descExpanded),
                          ),
                        ),

                        // Game list — 30%
                        Expanded(
                          flex: 3,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: widget.games.length,
                            itemExtent: _rowHeight,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final game = widget.games[index];
                              final isSelected =
                                  index == _selectedIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                    _descExpanded = false;
                                  });
                                  _focusNode.requestFocus();
                                },
                                child: _GameRow(
                                  game: game,
                                  isSelected: isSelected,
                                  cfg: cfg,
                                  theme: t,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            // ── Nav hint ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HintBadge(label: '↑ ↓  Navigate', theme: t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artwork panel (left side)
// ---------------------------------------------------------------------------

class _ArtworkPanel extends StatelessWidget {
  final GameEntry game;
  final String artworkType;
  final GamesScreenConfig cfg;
  final PolarisTheme theme;
  final bool descExpanded;
  final VoidCallback onToggleDesc;

  const _ArtworkPanel({
    required this.game,
    required this.artworkType,
    required this.cfg,
    required this.theme,
    required this.descExpanded,
    required this.onToggleDesc,
  });

  String? _imagePath() {
    final meta = game.metadata;
    switch (artworkType) {
      case 'fanart':
        return meta['fanArtPath'] as String?;
      case 'screenshot':
        return meta['screenshotPath'] as String?;
      case 'wheel':
        return meta['wheelPath'] as String?;
      case 'box2d':
      default:
        return meta['box2dPath'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _imagePath();
    final t = theme;
    final meta = game.metadata;
    final description = cfg.showDescription
        ? (meta['description'] as String? ?? '').trim()
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Artwork image — 70% of vertical space
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: t.accentColor.withValues(alpha: 0.25)),
              ),
              clipBehavior: Clip.antiAlias,
              child: path != null && File(path).existsSync()
                  ? Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, s) => _placeholder(t),
                    )
                  : _placeholder(t),
            ),
          ),

          // Description area — 30% of vertical space
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                          color: t.textSecondary, fontSize: 13, height: 1.5),
                      maxLines: descExpanded ? null : 5,
                      overflow: descExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onToggleDesc,
                      child: Text(
                        descExpanded ? 'Show less' : 'Read more  (X)',
                        style: TextStyle(
                          color: t.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _placeholder(PolarisTheme t) {
    return Container(
      color: t.accentColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: t.textSecondary.withValues(alpha: 0.4), size: 48),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game row
// ---------------------------------------------------------------------------

class _GameRow extends StatelessWidget {
  final GameEntry game;
  final bool isSelected;
  final GamesScreenConfig cfg;
  final PolarisTheme theme;

  const _GameRow({
    required this.game,
    required this.isSelected,
    required this.cfg,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final meta = game.metadata;

    final name = (meta['name'] as String?)?.trim().isNotEmpty == true
        ? meta['name'] as String
        : game.name;

    final year = cfg.showYear ? meta['releaseYear']?.toString() : null;
    final publisher =
        cfg.showPublisher ? meta['publisher']?.toString() : null;

    final subtitle = [
      if (year != null && year.isNotEmpty) year,
      if (publisher != null && publisher.isNotEmpty) publisher,
    ].join('  ·  ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? t.accentColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border(left: BorderSide(color: t.accentColor, width: 3))
            : Border(
                left: BorderSide(color: Colors.transparent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: t.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hint badge
// ---------------------------------------------------------------------------

class _HintBadge extends StatelessWidget {
  final String label;
  final PolarisTheme theme;

  const _HintBadge({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(label,
          style:
              TextStyle(color: theme.textSecondary, fontSize: 11)),
    );
  }
}
