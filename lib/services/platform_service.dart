import 'package:flutter/services.dart';
import '../models/design.dart';

class AndroidService {
  static const channel = MethodChannel('iconstudio/android');
  Future<void> openPrivacyPolicy() => channel.invokeMethod('openPrivacyPolicy');
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
        'background':
            (d.background & 0x00ffffff) |
            ((d.backgroundOpacity * 255).round() << 24),
        'package': d.package,
        'name': d.name.trim().isEmpty || d.name == 'Nouvelle icône'
            ? d.appName
            : d.name,
        'background2': d.background2,
        'gradient': d.gradient,
        'gradientAngle': d.gradientAngle,
        'bytes': bytes,
      }))!;
  Future<bool> hasWidget(String id) async =>
      await channel.invokeMethod<bool>('hasWidgetDesign', {'id': id}) ?? false;
  // Widgets receive the same transparent foreground and background settings
  // as native adaptive shortcuts, with their own badge-free circular mask.
  Map<String, dynamic> widgetArgs(IconDesign d, Uint8List bytes) => {
    'id': d.id,
    'package': d.package,
    'name': d.name.trim().isEmpty || d.name == 'Nouvelle icône'
        ? d.appName
        : d.name,
    'bytes': bytes,
    'background': (d.background & 0x00ffffff) |
        ((d.backgroundOpacity * 255).round() << 24),
    'background2': d.background2,
    'gradient': d.gradient,
    'gradientAngle': d.gradientAngle,
  };
  Future<void> updateWidget(IconDesign d, Uint8List bytes) =>
      channel.invokeMethod('updateWidgetDesign', widgetArgs(d, bytes));
  Future<String> pinWidget(IconDesign d, Uint8List bytes) async =>
      (await channel.invokeMethod<String>(
          'pinWidget', widgetArgs(d, bytes)))!;
  Future<void> launch(String package) =>
      channel.invokeMethod('launchApp', {'package': package});
  Future<String> process(String path, String mode, double tolerance) async =>
      (await channel.invokeMethod<String>('processImage', {
        'path': path,
        'mode': mode,
        'tolerance': tolerance,
      }))!;
}
