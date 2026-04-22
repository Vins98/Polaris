import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:polaris/ui/setup/setup_wizard.dart';
import 'package:polaris/ui/update/update_screen.dart';
import 'package:polaris/services/scan_service.dart';
import 'package:polaris/ui/main/main_screen.dart';

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
      if (owner != null && repo != null) {
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
    if (_updateOwner != null && _updateRepo != null) {
      return UpdateScreen(
        owner: _updateOwner!,
        repo: _updateRepo!,
        branch: _updateBranch,
        onComplete: (summary) {
          setState(() {
            _updateOwner = null;
            _updateRepo = null;
            _updateBranch = 'main';
          });

          final messenger = ScaffoldMessenger.of(context);
          ScanService.scanFromSetupResult().then((written) {
            messenger.showSnackBar(
              SnackBar(content: Text('Scan complete: $written databases written')),
            );
          }).catchError((e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Scan failed: $e')),
            );
          });
        },
      );
    }

    if (_done == false) {
      return const SetupWizard();
    }

    return const MainScreen();
  }
}
