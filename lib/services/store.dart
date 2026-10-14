import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/design.dart';
import 'platform_service.dart';

class StudioStore extends ChangeNotifier {
  final AndroidService platform;
  StudioStore(this.platform);
  List<IconDesign> designs = [];
  List<InstalledApp> apps = [];
  bool onboarded = false, loadingApps = false;
  String theme = 'system';
  String? appsError, loadWarning;
  late String directory;
  Future<void> _writes = Future.value();
  Future<void> init() async {
    directory = await platform.storageDirectory();
    final file = File('$directory/studio.json');
    if (await file.exists()) {
      try {
        _decode(await file.readAsString());
      } catch (_) {
        final backup = File('$directory/studio.backup.json');
        try {
          _decode(await backup.readAsString());
          loadWarning = 'Une sauvegarde locale a été restaurée.';
        } catch (_) {
          loadWarning =
              'La bibliothèque locale est illisible. Les fichiers images sont conservés.';
        }
      }
    }
  }

  void _decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    designs = (j['designs'] as List? ?? [])
        .map((d) => IconDesign.fromJson(Map<String, dynamic>.from(d)))
        .toList();
    onboarded = j['onboarded'] == true;
    theme = j['theme'] ?? 'system';
  }

  Future<void> persist() {
    final data = jsonEncode({
      'version': 1,
      'designs': designs.map((d) => d.toJson()).toList(),
      'onboarded': onboarded,
      'theme': theme,
    });
    final write = _writes.catchError((_) {}).then((_) async {
      final target = File('$directory/studio.json');
      final temp = File('$directory/studio.tmp');
      await temp.writeAsString(data, flush: true);
      if (await target.exists()) {
        await target.copy('$directory/studio.backup.json');
      }
      await temp.rename(target.path);
    });
    _writes = write;
    return write;
  }

  Future<void> refreshApps() async {
    loadingApps = true;
    appsError = null;
    notifyListeners();
    try {
      apps = await platform.listApps();
      await refreshPins();
    } catch (_) {
      appsError = 'Impossible de charger les applications. Réessayez.';
    } finally {
      loadingApps = false;
      notifyListeners();
    }
  }

  Future<void> refreshPins() async {
    try {
      final states = await platform.shortcutStates();
      bool changed = false;
      for (final d in designs) {
        final state = states['icon-${d.id}'];
        if (state != null && d.pinState != state) {
          d.pinState = state;
          changed = true;
        } else if (state == null && d.pinState == 'pinned') {
          d.pinState = 'none';
          changed = true;
        }
      }
      if (changed) {
        await persist();
        notifyListeners();
      }
    } catch (_) {
      /* Launcher status unavailable: preserve local state. */
    }
  }

  Future<void> save(IconDesign d) async {
    final before = designs.toList();
    final index = designs.indexWhere((x) => x.id == d.id);
    if (index < 0) {
      designs = [d.copy(), ...designs];
    } else {
      designs = [...designs];
      designs[index] = d.copy();
    }
    try {
      await persist();
      notifyListeners();
    } catch (_) {
      designs = before;
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final before = designs;
    designs = designs.where((d) => d.id != id).toList();
    try {
      await persist();
      notifyListeners();
    } catch (_) {
      designs = before;
      rethrow;
    }
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await persist();
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await persist();
    notifyListeners();
  }
}
