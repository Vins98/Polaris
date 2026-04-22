import 'dart:io';
import 'package:flutter/material.dart';
import 'package:polaris/models/models.dart';
import 'package:polaris/services/theme_service.dart';
import 'package:polaris/ui/main/system_carousel.dart' show SystemEntry;
import 'package:polaris/ui/main/theme_animations.dart';

class SystemListView extends StatefulWidget {
  final List<SystemEntry> systems;
  final PolarisTheme polarisTheme;
  final PolarisThemeConfig themeConfig;
  final int selectedIndex;
  final void Function(int index) onIndexChanged;

  const SystemListView({
    super.key,
    required this.systems,
    required this.polarisTheme,
    required this.themeConfig,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<SystemListView> createState() => _SystemListViewState();
}

class _SystemListViewState extends State<SystemListView> {
  late ScrollController _scrollController;

  static const _rowHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _scrollOffset(widget.selectedIndex),
    );
  }

  @override
  void didUpdateWidget(SystemListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final target = _scrollOffset(widget.selectedIndex);
      _scrollController.animateTo(
        target,
        duration: ThemeTransition.resolveDuration(widget.themeConfig.animation),
        curve: ThemeTransition.resolveCurve(widget.themeConfig.animation),
      );
    }
  }

  double _scrollOffset(int index) {
    final offset = (index * _rowHeight) - 200;
    return offset.clamp(0.0, double.infinity);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.polarisTheme;
    if (widget.systems.isEmpty) {
      return Center(
        child: Text(
          'No systems found.',
          style: TextStyle(color: t.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.systems.length,
      itemExtent: _rowHeight,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        final entry = widget.systems[index];
        final isSelected = index == widget.selectedIndex;
        return _SystemListRow(
          entry: entry,
          isSelected: isSelected,
          polarisTheme: t,
          screenConfig: widget.themeConfig.systemsScreen,
          onTap: () => widget.onIndexChanged(index),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SystemListRow
// ---------------------------------------------------------------------------

class _SystemListRow extends StatelessWidget {
  final SystemEntry entry;
  final bool isSelected;
  final PolarisTheme polarisTheme;
  final SystemsScreenConfig screenConfig;
  final VoidCallback onTap;

  const _SystemListRow({
    required this.entry,
    required this.isSelected,
    required this.polarisTheme,
    required this.screenConfig,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = polarisTheme;
    final cfg = screenConfig;
    final imagePath = t.systemImagePath(entry.system.id);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? t.accentColor.withValues(alpha: 0.12)
              : t.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border(left: BorderSide(color: t.accentColor, width: 3))
              : Border(left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imagePath != null
                    ? Image.file(File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) =>
                            _FallbackThumb(system: entry.system, theme: t))
                    : _FallbackThumb(system: entry.system, theme: t),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.system.name,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (_subtitle(entry.system, cfg).isNotEmpty)
                        Text(
                          _subtitle(entry.system, cfg),
                          style: TextStyle(
                              color: t.textSecondary, fontSize: 11),
                        ),
                      if (cfg.showGameCount) ...[
                        if (_subtitle(entry.system, cfg).isNotEmpty)
                          Text('  ·  ',
                              style: TextStyle(
                                  color: t.textSecondary, fontSize: 11)),
                        Text(
                          '${entry.gameCount} game${entry.gameCount == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: t.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  if (cfg.showDescription &&
                      entry.system.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.system.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textSecondary.withValues(alpha: 0.7),
                          fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (isSelected)
              Icon(Icons.chevron_right,
                  color: t.accentColor.withValues(alpha: 0.6), size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _subtitle(SystemModel s, SystemsScreenConfig cfg) {
    final parts = <String>[];
    if (cfg.showManufacturer && s.manufacturer.isNotEmpty) {
      parts.add(s.manufacturer);
    }
    if (cfg.showYear && s.year != null) parts.add(s.year.toString());
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// _FallbackThumb
// ---------------------------------------------------------------------------

class _FallbackThumb extends StatelessWidget {
  final SystemModel system;
  final PolarisTheme theme;

  const _FallbackThumb({required this.system, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.accentColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          system.name.isNotEmpty ? system.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
