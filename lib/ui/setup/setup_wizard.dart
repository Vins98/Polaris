import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/models/models.dart';

enum MatchType { exact, partial, none }

const _createCustomSystemSentinel = '__create_custom_system__';

class FolderAssignment {
  final String path;
  SystemModel? assigned;
  MatchType match;

  FolderAssignment({
    required this.path,
    this.assigned,
    this.match = MatchType.none,
  });
}

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final List<FolderAssignment> _folders = [];
  final Map<String, EmulatorModel?> _emuSelections = {};
  final TextEditingController _pathController = TextEditingController();
  List<SystemModel> _systems = [];
  List<EmulatorModel> _emulators = [];
  int _step = 0;
  late String _browserHomePath;
  late String _browserCurrentPath;
  final Set<String> _browserSelectedPaths = <String>{};

  @override
  void initState() {
    super.initState();
    _browserHomePath = Platform.isWindows
        ? (Platform.environment['USERPROFILE'] ?? Directory.current.path)
        : (Platform.environment['HOME'] ?? Directory.current.path);
    _browserCurrentPath = _browserHomePath;
    _pathController.text = _browserCurrentPath;
    _loadIndexes();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadIndexes() async {
    try {
      final sysIndex = await loadSystemsIndexFromFile('data/systems.json');
      final emuIndex = await loadEmulatorsIndexFromFile('data/emulators.json');
      setState(() {
        _systems = sysIndex.systems;
        _emulators = emuIndex.emulators;
      });
    } catch (e) {
      // ignore; start with empty lists
    }
  }

  void _setBrowserPath(String path) {
    _browserCurrentPath = path;
    _pathController.text = path;
  }

  List<Directory> _visibleDirectories() {
    try {
      final dirs = Directory(_browserCurrentPath)
          .listSync()
          .where((e) => FileSystemEntity.isDirectorySync(e.path))
          .map((e) => Directory(e.path))
          .toList();
      dirs.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );
      return dirs;
    } catch (_) {
      return [];
    }
  }

  bool _wholeWordMatch(String text, String alias) {
    final a = alias.trim();
    if (a.isEmpty) return false;
    try {
      final pattern = RegExp(
        r'\b' + RegExp.escape(a) + r'\b',
        caseSensitive: false,
      );
      return pattern.hasMatch(text);
    } catch (_) {
      return text.toLowerCase().contains(a.toLowerCase());
    }
  }

  void _toggleFolderSelection(String path, bool selected) {
    if (selected) {
      if (_folders.any((f) => f.path == path)) {
        _browserSelectedPaths.add(path);
        return;
      }
      final assignment = FolderAssignment(path: path);
      assignment.match = _detectMatchType(path, assignment);
      assignment.assigned = _detectBestSystem(path);
      _folders.add(assignment);
      _browserSelectedPaths.add(path);
      return;
    }

    _folders.removeWhere((f) => f.path == path);
    _browserSelectedPaths.remove(path);
  }

  void _toggleSelectAllVisible() {
    final visiblePaths = _visibleDirectories().map((d) => d.path).toList();
    final allSelected =
        visiblePaths.isNotEmpty &&
        visiblePaths.every(_browserSelectedPaths.contains);

    setState(() {
      for (final path in visiblePaths) {
        _toggleFolderSelection(path, !allSelected);
      }
    });
  }

  void _goToParentDirectory() {
    final parent = p.dirname(_browserCurrentPath);
    if (parent != _browserCurrentPath) {
      setState(() => _setBrowserPath(parent));
    }
  }

  void _goToHomeDirectory() {
    setState(() => _setBrowserPath(_browserHomePath));
  }

  void _applyPathInput() {
    final nextPath = _pathController.text.trim();
    if (nextPath.isEmpty) return;
    final dir = Directory(nextPath);
    if (!dir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That directory does not exist.')),
      );
      return;
    }
    setState(() => _setBrowserPath(dir.path));
  }

  List<SystemModel> _selectedSystems() {
    return _folders
        .map((f) => f.assigned)
        .whereType<SystemModel>()
        .toSet()
        .toList();
  }

  void _goToNextStep() {
    if (_step == 0 && _folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one folder to continue.'),
        ),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
    }
  }

  void _goToPreviousStep() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  MatchType _detectMatchType(String folderPath, FolderAssignment assignment) {
    // Manual assignment by the user counts as an explicit match
    if (assignment.assigned != null) return MatchType.exact;

    final best = _detectBestSystem(folderPath);
    if (best == null) return MatchType.none;

    final folderName = p.basename(folderPath);
    for (final a in best.aliases) {
      final alias = a.trim();
      if (alias.isEmpty) continue;
      if (folderName.toLowerCase() == alias.toLowerCase()) {
        return MatchType.exact;
      }
      if (_wholeWordMatch(folderName, alias)) {
        return MatchType.partial;
      }

      final segments = p.split(folderPath);
      for (final seg in segments) {
        if (_wholeWordMatch(seg, alias)) return MatchType.partial;
      }

      try {
        final entries = Directory(folderPath)
            .listSync()
            .where((e) => FileSystemEntity.isFileSync(e.path))
            .map((e) => p.basename(e.path))
            .toList();
        if (entries.any((n) => _wholeWordMatch(n, alias))) {
          return MatchType.partial;
        }
      } catch (_) {}
    }

    return MatchType.partial;
  }

  SystemModel? _detectBestSystem(String folderPath) {
    final folderName = p.basename(folderPath);
    SystemModel? partial;
    for (final sys in _systems) {
      for (final a in sys.aliases) {
        final alias = a.trim();
        if (alias.isEmpty) continue;
        if (folderName.toLowerCase() == alias.toLowerCase()) return sys;

        if (_wholeWordMatch(folderName, alias)) {
          partial ??= sys;
          continue;
        }

        final segments = p.split(folderPath);
        var matchedInSegment = false;
        for (final seg in segments) {
          if (_wholeWordMatch(seg, alias)) {
            partial ??= sys;
            matchedInSegment = true;
            break;
          }
        }
        if (matchedInSegment) continue;

        try {
          final entries = Directory(folderPath)
              .listSync()
              .where((e) => FileSystemEntity.isFileSync(e.path))
              .map((e) => p.basename(e.path))
              .toList();
          if (entries.any((n) => _wholeWordMatch(n, alias))) partial ??= sys;
        } catch (_) {}
      }
    }
    return partial;
  }

  Future<void> _pickSystemForFolder(FolderAssignment f) async {
    final selection = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = TextEditingController();
        var filtered = _systems;
        return StatefulBuilder(
          builder: (c, setInner) {
            void applyFilter(String q) {
              final ql = q.toLowerCase();
              setInner(() {
                filtered = _systems.where((s) {
                  if (s.name.toLowerCase().contains(ql)) return true;
                  return s.aliases.any((a) => a.toLowerCase().contains(ql));
                }).toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Search system...',
                      ),
                      onChanged: applyFilter,
                    ),
                  ),
                  SizedBox(height: 300, child: _buildSystemList(filtered)),
                  ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: const Text('Create custom system'),
                    onTap: () {
                      Navigator.of(ctx).pop(_createCustomSystemSentinel);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selection == _createCustomSystemSentinel) {
      if (!mounted) return;
      final created = await _createCustomSystem();
      if (created != null) {
        setState(() {
          f.assigned = created;
          f.match = _detectMatchType(f.path, f);
        });
      }
      return;
    }

    if (selection is SystemModel) {
      setState(() {
        f.assigned = selection;
        f.match = _detectMatchType(f.path, f);
      });
    }
  }

  Widget _buildSystemList(List<SystemModel> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return ListTile(
          title: Text(s.name),
          subtitle: Text(s.aliases.join(', ')),
          onTap: () => Navigator.of(ctx).pop(s),
        );
      },
    );
  }

  Future<SystemModel?> _createCustomSystem() async {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    final aliasesC = TextEditingController();
    final manufacturerC = TextEditingController();
    final yearC = TextEditingController();
    final romC = TextEditingController();
    final result = await showDialog<SystemModel?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create custom system'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: idC,
                decoration: const InputDecoration(labelText: 'id'),
              ),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'name'),
              ),
              TextField(
                controller: aliasesC,
                decoration: const InputDecoration(labelText: 'aliases (comma)'),
              ),
              TextField(
                controller: manufacturerC,
                decoration: const InputDecoration(labelText: 'manufacturer'),
              ),
              TextField(
                controller: yearC,
                decoration: const InputDecoration(labelText: 'year'),
              ),
              TextField(
                controller: romC,
                decoration: const InputDecoration(
                  labelText: 'romFormats (comma)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = idC.text.trim();
              if (id.isEmpty) return;
              final sys = SystemModel(
                id: id,
                name: nameC.text.trim().isEmpty ? id : nameC.text.trim(),
                aliases: aliasesC.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                manufacturer: manufacturerC.text.trim(),
                year: int.tryParse(yearC.text.trim()),
                romFormats: romC.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              );
              Navigator.of(ctx).pop(sys);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _systems.insert(0, result));
    }
    return result;
  }

  // _pickEmulatorForSystem was intentionally removed — inline pickers
  // are used in the UI instead.

  Future<EmulatorModel?> _createCustomEmulator(SystemModel sys) async {
    final nameC = TextEditingController();
    final exeC = TextEditingController();
    final updaterC = TextEditingController();
    final result = await showDialog<EmulatorModel?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create custom emulator'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'name'),
              ),
              TextField(
                controller: exeC,
                decoration: const InputDecoration(labelText: 'executable path'),
              ),
              TextField(
                controller: updaterC,
                decoration: const InputDecoration(
                  labelText: 'updater executable (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();
              if (name.isEmpty) return;
              final emu = EmulatorModel(
                name: name,
                executable: exeC.text.trim().isEmpty ? null : exeC.text.trim(),
                updaterExecutable: updaterC.text.trim().isEmpty
                    ? null
                    : updaterC.text.trim(),
                launchParams: const LaunchParams(),
                supportedSystems: [sys.id],
              );
              Navigator.of(ctx).pop(emu);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) setState(() => _emulators.insert(0, result));
    return result;
  }

  Future<void> _saveSetup(Map<String, EmulatorModel?> emuSelections) async {
    final activeSystems = _selectedSystems().map((s) => s.id).toSet();
    final out = {
      'folders': _folders
          .map(
            (f) => {
              'path': f.path,
              'systemId': f.assigned?.id,
              'systemName': f.assigned?.name,
              'match': f.match.toString().split('.').last,
            },
          )
          .toList(),
      'emulators': emuSelections.entries
          .where((e) => activeSystems.contains(e.key))
          .map((e) {
            return {'systemId': e.key, 'emulator': e.value?.toJson()};
          })
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    final file = File('data/setup_result.json');
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(out));
    await File('data/setup_done').writeAsString('done');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Setup saved')));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final auraColors = {
      MatchType.exact: Colors.greenAccent.shade400,
      MatchType.partial: Colors.orangeAccent.shade200,
      MatchType.none: Colors.redAccent.shade200,
    };

    final colorBg = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Polaris Setup')),
      backgroundColor: colorBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(context),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStepPage(
                      context,
                      auraColors: auraColors,
                      cardColor: cardColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStepActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    const titles = ['Folders', 'Emulators', 'Finish'];
    const descriptions = [
      'Choose your ROM directories.',
      'Pick the emulator for each detected system.',
      'Review and save the configuration.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_step + 1} of 3',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(titles[_step], style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(descriptions[_step], style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (index) {
            final active = index == _step;
            final complete = index < _step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                height: 8,
                decoration: BoxDecoration(
                  color: complete || active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepPage(
    BuildContext context, {
    required Map<MatchType, Color> auraColors,
    required Color? cardColor,
  }) {
    switch (_step) {
      case 0:
        return _buildFoldersStep(
          context,
          auraColors: auraColors,
          cardColor: cardColor,
        );
      case 1:
        return _buildEmulatorsStep(context);
      default:
        return _buildFinishStep(context);
    }
  }

  Widget _buildFoldersStep(
    BuildContext context, {
    required Map<MatchType, Color> auraColors,
    required Color? cardColor,
  }) {
    final visibleDirs = _visibleDirectories();
    final allVisibleSelected =
        visibleDirs.isNotEmpty &&
        visibleDirs.every((d) => _browserSelectedPaths.contains(d.path));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pathController,
                          decoration: const InputDecoration(
                            labelText: 'Current path',
                            prefixIcon: Icon(Icons.folder_open),
                          ),
                          onSubmitted: (_) => _applyPathInput(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _applyPathInput,
                        child: const Text('Go'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _goToParentDirectory,
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Up'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _goToHomeDirectory,
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(
                            () => _toggleFolderSelection(
                              _browserCurrentPath,
                              true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Select current'),
                      ),
                      OutlinedButton.icon(
                        onPressed: visibleDirs.isEmpty
                            ? null
                            : _toggleSelectAllVisible,
                        icon: Icon(
                          allVisibleSelected
                              ? Icons.deselect
                              : Icons.select_all,
                        ),
                        label: Text(
                          allVisibleSelected ? 'Clear visible' : 'Select all',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visibleDirs.isEmpty
                        ? const Center(
                            child: Text('No directories found in this path.'),
                          )
                        : ListView.builder(
                            itemCount: visibleDirs.length,
                            itemBuilder: (ctx, index) {
                              final dir = visibleDirs[index];
                              final selected = _browserSelectedPaths.contains(
                                dir.path,
                              );
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  value: selected,
                                  onChanged: (value) {
                                    setState(() {
                                      _toggleFolderSelection(
                                        dir.path,
                                        value ?? false,
                                      );
                                    });
                                  },
                                ),
                                title: Text(p.basename(dir.path)),
                                subtitle: Text(
                                  dir.path,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    setState(() => _setBrowserPath(dir.path));
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _toggleFolderSelection(dir.path, !selected);
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected folders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _folders.isEmpty
                        ? const Center(
                            child: Text('Selected folders will appear here.'),
                          )
                        : ListView(
                            children: _folders.map((f) {
                              final aura = auraColors[f.match]!;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: aura.withAlpha(
                                        (0.25 * 255).round(),
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.folder, size: 32),
                                  title: Text(p.basename(f.path)),
                                  subtitle: Text(
                                    f.path,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            _pickSystemForFolder(f),
                                        child: Text(
                                          f.assigned?.name ?? 'Assign system',
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _toggleFolderSelection(
                                              f.path,
                                              false,
                                            );
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmulatorsStep(BuildContext context) {
    final systems = _selectedSystems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: systems.isEmpty
            ? const Center(child: Text('Assign at least one system in step 1.'))
            : ListView(
                children: systems.map((s) {
                  return Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.id),
                      trailing: FilledButton(
                        onPressed: () async {
                          final emu =
                              await showModalBottomSheet<EmulatorModel?>(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx2) {
                                  final q = TextEditingController();
                                  var filtered = _emulators;
                                  return StatefulBuilder(
                                    builder: (c2, setInner) {
                                      void applyFilter(String qv) => setInner(
                                        () => filtered = _emulators
                                            .where(
                                              (e) => e.name
                                                  .toLowerCase()
                                                  .contains(qv.toLowerCase()),
                                            )
                                            .toList(),
                                      );

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(
                                            ctx2,
                                          ).viewInsets.bottom,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: TextField(
                                                controller: q,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          'Search emulator...',
                                                    ),
                                                onChanged: applyFilter,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 300,
                                              child: ListView.builder(
                                                itemCount: filtered.length,
                                                itemBuilder: (c, i) => ListTile(
                                                  title: Text(filtered[i].name),
                                                  onTap: () => Navigator.of(
                                                    ctx2,
                                                  ).pop(filtered[i]),
                                                ),
                                              ),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.add),
                                              title: const Text(
                                                'Create custom emulator',
                                              ),
                                              onTap: () =>
                                                  Navigator.of(ctx2).pop(null),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                          if (emu != null) {
                            setState(() => _emuSelections[s.id] = emu);
                          } else {
                            if (!mounted) return;
                            final created = await _createCustomEmulator(s);
                            if (created != null) {
                              setState(() => _emuSelections[s.id] = created);
                            }
                          }
                        },
                        child: Text(
                          _emuSelections[s.id]?.name ?? 'Select emulator',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildFinishStep(BuildContext context) {
    final systems = _selectedSystems();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to save',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Folders selected: ${_folders.length}'),
            Text('Systems assigned: ${systems.length}'),
            Text(
              'Emulators chosen: ${_emuSelections.entries.where((e) => systems.any((s) => s.id == e.key && e.value != null)).length}',
            ),
            const SizedBox(height: 20),
            const Text(
              'When you save the setup it will be stored in data/setup_result.json and a marker will be created so the setup does not run again.',
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _saveSetup(_emuSelections),
              icon: const Icon(Icons.save),
              label: const Text('Save setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepActions() {
    final hasUnmatched = _folders.any((f) => f.match == MatchType.none);
    final canContinue = _step == 0
        ? (_folders.isNotEmpty && !hasUnmatched)
        : true;
    return Row(
      children: [
        if (_step > 0)
          OutlinedButton(
            onPressed: _goToPreviousStep,
            child: const Text('Back'),
          ),
        const Spacer(),
        if (_step < 2)
          FilledButton(
            onPressed: canContinue ? _goToNextStep : null,
            child: const Text('Continue'),
          ),
      ],
    );
  }
}
