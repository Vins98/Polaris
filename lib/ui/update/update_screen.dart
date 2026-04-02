import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:polaris/services/github_updater.dart';
import 'package:polaris/models/models.dart';

typedef UpdateComplete = void Function(UpdateSummary result);

class UpdateScreen extends StatefulWidget {
  final String owner;
  final String repo;
  final String branch;
  final UpdateComplete? onComplete;

  const UpdateScreen({
    super.key,
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.onComplete,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _message = 'Preparing update...';
  UpdateSummary? _summary;
  late final AnimationController _shimmerController;
  final List<Timer> _progressTimers = [];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // start update after first frame so UI builds
    WidgetsBinding.instance.addPostFrameCallback((_) => _runUpdate());
  }

  @override
  void dispose() {
    // cancel any pending progress timers to avoid them firing after dispose
    for (final t in _progressTimers) {
      try {
        t.cancel();
      } catch (_) {}
    }
    _progressTimers.clear();
    _shimmerController.dispose();
    super.dispose();
  }

  void _setProgress(double value) {
    // cancel pending timers so manual progress updates take precedence
    for (final t in _progressTimers) {
      try {
        t.cancel();
      } catch (_) {}
    }
    _progressTimers.clear();
    if (!mounted) return;
    setState(() => _progress = value.clamp(0.0, 1.0));
  }

  Future<void> _runUpdate() async {
    final updater = GitHubUpdater(
      owner: widget.owner,
      repo: widget.repo,
      branch: widget.branch,
    );
    try {
      setState(() {
        _message = 'Checking systems index...';
      });
      _setProgress(0.08);

      // start systems update
      _animateTo(0.25, duration: 600);
      final systemsResult = await updater.checkAndUpdateSystems();
      setState(() {
        _message = systemsResult.updated
            ? 'Systems updated'
            : 'Systems up-to-date';
      });
      _setProgress(0.5);

      // small pause for UX
      await Future.delayed(const Duration(milliseconds: 300));

      // start emulators update
      setState(() {
        _message = 'Checking emulators index...';
      });
      _animateTo(0.7, duration: 800);
      final emulatorsResult = await updater.checkAndUpdateEmulators();
      setState(() {
        _message = emulatorsResult.updated
            ? 'Emulators updated'
            : 'Emulators up-to-date';
      });
      _setProgress(0.95);

      await Future.delayed(const Duration(milliseconds: 400));

      setState(() {
        _message = 'Done';
        _summary = UpdateSummary(
          systems: systemsResult,
          emulators: emulatorsResult,
        );
      });
      _setProgress(1.0);

      // give the user a moment to enjoy the animation
      await Future.delayed(const Duration(milliseconds: 700));
      // write a small log file for debugging (optional)
      try {
        final log = File('data/update_log.json');
        await log.create(recursive: true);
        await log.writeAsString(
          '{"systems": ${systemsResult.toString()}, "emulators": ${emulatorsResult.toString()}}',
        );
      } catch (_) {}

      widget.onComplete?.call(_summary!);
    } catch (e) {
      setState(() {
        _message = 'Update failed: $e';
      });
      widget.onComplete?.call(
        UpdateSummary(
          systems: FileUpdateResult<SystemsIndex>(
            updated: false,
            localPath: 'data/systems.json',
            remotePath: 'data/systems.json',
          ),
          emulators: FileUpdateResult<EmulatorsIndex>(
            updated: false,
            localPath: 'data/emulators.json',
            remotePath: 'data/emulators.json',
          ),
        ),
      );
    } finally {
      updater.dispose();
    }
  }

  void _animateTo(double target, {int duration = 400}) {
    // cancel any existing timers for previous animations
    for (final t in _progressTimers) {
      try {
        t.cancel();
      } catch (_) {}
    }
    _progressTimers.clear();

    final start = _progress;
    final steps = 8;
    for (var i = 1; i <= steps; i++) {
      final delay = Duration(milliseconds: (duration / steps * i).round());
      late Timer t;
      t = Timer(delay, () {
        final value = start + (target - start) * (i / steps);
        if (mounted) setState(() => _progress = value.clamp(0.0, 1.0));
        // remove this timer from the active list
        _progressTimers.remove(t);
      });
      _progressTimers.add(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.blueGrey.shade50;
    final accent = isDark ? Colors.cyanAccent : Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Polaris Updater',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              CoolProgressBar(value: _progress, shimmer: _shimmerController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  if (_summary != null) Icon(Icons.check_circle, color: accent),
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Fetching latest definitions from ${widget.owner}/${widget.repo}@${widget.branch}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoolProgressBar extends StatelessWidget {
  final double value; // 0..1
  final AnimationController shimmer;

  const CoolProgressBar({
    super.key,
    required this.value,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bg = isDark ? Colors.grey[850] : Colors.grey[300];
    final start = isDark
        ? Colors.cyanAccent.shade200
        : Colors.deepPurpleAccent.shade200;
    final end = isDark
        ? Colors.tealAccent.shade100
        : Colors.purpleAccent.shade100;

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * value.clamp(0.0, 1.0);
          return Stack(
            children: [
              // filled portion
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [start, end]),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // shimmer overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: shimmer,
                    builder: (ctx, child) {
                      final shimmerWidth = constraints.maxWidth * 0.25;
                      final dx =
                          (constraints.maxWidth + shimmerWidth) *
                              shimmer.value -
                          shimmerWidth;
                      return ClipRect(
                        child: Stack(
                          children: [
                            Positioned(
                              left: dx - (constraints.maxWidth - width),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: shimmerWidth,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromRGBO(255, 255, 255, 0.15),
                                      Color.fromRGBO(255, 255, 255, 0.0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
