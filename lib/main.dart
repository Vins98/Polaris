import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:polaris/ui/setup/setup_wizard.dart';
import 'package:polaris/ui/update/update_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polaris',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SetupLauncher(),
    );
  }
}

class SetupLauncher extends StatefulWidget {
  const SetupLauncher({super.key});

  @override
  State<SetupLauncher> createState() => _SetupLauncherState();
}

class _SetupLauncherState extends State<SetupLauncher> {
  bool? _done;
  String? _updateOwner;
  String? _updateRepo;
  String _updateBranch = 'main';

  @override
  void initState() {
    super.initState();
    _checkDone();
  }

  Future<void> _checkDone() async {
    final cfgFile = File('data/updater_config.json');
    String? owner;
    String? repo;
    String branch = 'main';
    if (await cfgFile.exists()) {
      try {
        final cfg =
            json.decode(await cfgFile.readAsString()) as Map<String, dynamic>;
        owner = cfg['owner'] as String?;
        repo = cfg['repo'] as String?;
        branch = cfg['branch'] as String? ?? 'main';
      } catch (e) {
        // ignore parse errors
        // ignore: avoid_print
        print('Failed to read updater_config.json: $e');
      }
    }

    final f = File('data/setup_done');
    final exists = await f.exists();
    setState(() {
      _done = exists;
      // if update config was present and setup not done, we'll show UpdateScreen
      if (owner != null && repo != null && !exists) {
        _updateOwner = owner;
        _updateRepo = repo;
        _updateBranch = branch;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_done == false) {
      if (_updateOwner != null && _updateRepo != null) {
        return UpdateScreen(
          owner: _updateOwner!,
          repo: _updateRepo!,
          branch: _updateBranch,
          onComplete: (summary) {
            // after updater completes, proceed to setup
            setState(() {
              _updateOwner = null;
              _updateRepo = null;
              _updateBranch = 'main';
            });
          },
        );
      }
      return const SetupWizard();
    }

    return const Scaffold(
      body: Center(child: Text('Polaris is ready. (Main UI placeholder)')),
    );
  }
}
