import 'package:flutter/services.dart';
import '../models/design.dart';

class AndroidService {
  static const channel = MethodChannel('iconstudio/android');
  Future<String> storageDirectory() async =>
      (await channel.invokeMethod<String>('storageDirectory'))!;
  Future<List<InstalledApp>> listApps() async =>
      ((await channel.invokeMethod<List>('listApps')) ?? [])
          .map((a) => InstalledApp.fromJson(a))
          .toList();
  Future<String?> importImage() => channel.invokeMethod<String>('importImage');
  Future<bool> exportPng(Uint8List bytes, String name) async =>
      await channel.invokeMethod<bool>('exportPng', {
        'bytes': bytes,
        'name': '$name.png',
      }) ??
      false;
  Future<bool> shortcutSupport() async =>
      await channel.invokeMethod<bool>('shortcutSupport') ?? false;
  Future<Map<String, String>> shortcutStates() async =>
      Map<String, String>.from(
        await channel.invokeMethod<Map>('shortcutStates') ?? {},
      );
  Future<String> pin(IconDesign d, Uint8List bytes) async =>
      (await channel.invokeMethod<String>('pinShortcut', {
        'id': 'icon-${d.id}',
        'package': d.package,
        'name': d.name,
        'bytes': bytes,
      }))!;
  Future<void> launch(String package) =>
      channel.invokeMethod('launchApp', {'package': package});
  Future<String> process(String path, String mode, double tolerance) async =>
      (await channel.invokeMethod<String>('processImage', {
        'path': path,
        'mode': mode,
        'tolerance': tolerance,
      }))!;
}
