import 'dart:io';
import 'package:flutter/material.dart';
import 'package:polaris/models/models.dart';
import 'package:polaris/services/theme_service.dart';
import 'package:polaris/ui/main/theme_animations.dart';

// ---------------------------------------------------------------------------
// Data class passed to the carousel
// ---------------------------------------------------------------------------

class SystemEntry {
  final SystemModel system;
  final int gameCount;

  const SystemEntry({required this.system, required this.gameCount});
}

// ---------------------------------------------------------------------------
// SystemCarousel
// ---------------------------------------------------------------------------

class SystemCarousel extends StatefulWidget {
  final List<SystemEntry> systems;
  final PolarisTheme polarisTheme;
  final PolarisThemeConfig themeConfig;
  final int selectedIndex;
  final void Function(int index) onIndexChanged;

  const SystemCarousel({
    super.key,
    required this.systems,
    required this.polarisTheme,
    required this.themeConfig,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<SystemCarousel> createState() => _SystemCarouselState();
}

class _SystemCarouselState extends State<SystemCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.32,
      initialPage: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(SystemCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: ThemeTransition.resolveDuration(widget.themeConfig.animation),
        curve: ThemeTransition.resolveCurve(widget.themeConfig.animation),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.polarisTheme;
    if (widget.systems.isEmpty) {
      return Center(
        child: Text(
          'No systems found.\nRun setup to add ROMs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.textSecondary, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.systems.length,
      onPageChanged: widget.onIndexChanged,
      itemBuilder: (context, index) {
        final entry = widget.systems[index];
        final isActive = index == widget.selectedIndex;
        return GestureDetector(
          onTap: () => widget.onIndexChanged(index),
          child: AnimatedScale(
            scale: isActive ? 1.0 : 0.82,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _SystemCard(
              entry: entry,
              isActive: isActive,
              polarisTheme: t,
              screenConfig: widget.themeConfig.systemsScreen,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SystemCard
// ---------------------------------------------------------------------------

class _SystemCard extends StatelessWidget {
  final SystemEntry entry;
  final bool isActive;
  final PolarisTheme polarisTheme;
  final SystemsScreenConfig screenConfig;

  const _SystemCard({
    required this.entry,
    required this.isActive,
    required this.polarisTheme,
    required this.screenConfig,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = polarisTheme.systemImagePath(entry.system.id);
    final t = polarisTheme;
    final cfg = screenConfig;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: t.cardBorderActive, width: 2.5)
              : Border.all(color: Colors.white10, width: 1),
          boxShadow: isActive
              ? [BoxShadow(
                  color: t.accentColor.withValues(alpha: 0.4),
                  blurRadius: 24, spreadRadius: 2)]
              : [const BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 0.70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // System image or fallback
              if (imagePath != null)
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _FallbackBackground(
                    system: entry.system, theme: t),
                )
              else
                _FallbackBackground(system: entry.system, theme: t),

              // Bottom gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        t.cardColor.withValues(alpha: 0.7),
                        t.cardColor.withValues(alpha: 0.96),
                      ],
                      stops: const [0.0, 0.45, 0.72, 1.0],
                    ),
                  ),
                ),
              ),

              // Info overlay
              Positioned(
                left: 14, right: 14, bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.system.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (cfg.showManufacturer || cfg.showYear) ...[
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(entry.system, cfg),
                        style: TextStyle(color: t.textSecondary, fontSize: 11),
                      ),
                    ],
                    if (cfg.showDescription &&
                        entry.system.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.system.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: t.textSecondary.withValues(alpha: 0.8),
                            fontSize: 10),
                      ),
                    ],
                    if (cfg.showGameCount) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${entry.gameCount} game${entry.gameCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: t.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
// _FallbackBackground
// ---------------------------------------------------------------------------

class _FallbackBackground extends StatelessWidget {
  final SystemModel system;
  final PolarisTheme theme;

  const _FallbackBackground({required this.system, required this.theme});

  @override
  Widget build(BuildContext context) {
    final initial = system.name.isNotEmpty ? system.name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accentColor.withValues(alpha: 0.3),
            theme.cardColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: theme.accentColor.withValues(alpha: 0.5),
            fontSize: 96,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
