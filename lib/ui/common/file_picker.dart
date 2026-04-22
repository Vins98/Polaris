import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Shows a bottom-sheet file picker and returns the selected file path
/// or `null` if cancelled.
Future<String?> showFilePicker(BuildContext context, {String? initialPath}) {
  final home = Platform.isWindows
      ? (Platform.environment['USERPROFILE'] ?? Directory.current.path)
      : (Platform.environment['HOME'] ?? Directory.current.path);
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _FilePickerWidget(initialPath ?? home),
  );
}

class _FilePickerWidget extends StatefulWidget {
  final String initialPath;

  const _FilePickerWidget(this.initialPath);

  @override
  State<_FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<_FilePickerWidget> {
  late String _currentPath;
  late TextEditingController _pathController;
  List<FileSystemEntity> _entries = [];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _pathController = TextEditingController(text: _currentPath);
    _refresh();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _refresh() {
    try {
      final dir = Directory(_currentPath);
      final list = dir.existsSync() ? dir.listSync() : <FileSystemEntity>[];
      list.sort((a, b) {
        final aDir = FileSystemEntity.isDirectorySync(a.path);
        final bDir = FileSystemEntity.isDirectorySync(b.path);
        if (aDir && !bDir) return -1;
        if (!aDir && bDir) return 1;
        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });
      setState(() {
        _entries = list;
      });
    } catch (_) {
      setState(() => _entries = []);
    }
  }

  void _setPath(String path) {
    if (path == _currentPath) return;
    _currentPath = path;
    _pathController.text = path;
    _refresh();
  }

  void _goToParent() {
    final parent = p.dirname(_currentPath);
    if (parent != _currentPath) _setPath(parent);
  }

  void _goToHome() {
    final home = Platform.isWindows
        ? (Platform.environment['USERPROFILE'] ?? Directory.current.path)
        : (Platform.environment['HOME'] ?? Directory.current.path);
    _setPath(home);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(hintText: 'Path'),
                    onSubmitted: (v) {
                      final dir = Directory(v.trim());
                      if (!dir.existsSync()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('That directory does not exist.'),
                          ),
                        );
                        return;
                      }
                      _setPath(dir.path);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _setPath(_pathController.text.trim()),
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _goToParent,
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Up'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _goToHome,
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: _entries.isEmpty
                ? const Center(child: Text('No entries'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      final isDir = FileSystemEntity.isDirectorySync(e.path);
                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder : Icons.insert_drive_file,
                        ),
                        title: Text(p.basename(e.path)),
                        subtitle: Text(e.path, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          if (isDir) {
                            _setPath(e.path);
                          } else {
                            Navigator.of(context).pop(e.path);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
