import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icon_studio/main.dart';
import 'package:icon_studio/models/design.dart';
import 'package:icon_studio/screens/editor.dart';
import 'package:icon_studio/screens/home.dart';
import 'package:icon_studio/services/platform_service.dart';
import 'package:icon_studio/services/store.dart';
import 'package:icon_studio/widgets/icon_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('icon-studio-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidService.channel, (call) async {
          switch (call.method) {
            case 'storageDirectory':
              return temp.path;
            case 'listApps':
              return <dynamic>[];
            case 'shortcutStates':
              return <String, String>{};
            case 'shortcutSupport':
              return true;
          }
          return null;
        });
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });
  test(
    'Variants retain composition and have independent shortcut identities',
    () {
      final original = IconDesign(
        package: 'com.instagram.android',
        layers: [IconLayer(kind: 'brand', value: 'instagram')],
      );
      packs.first.apply(original);
      final variant = original.copy(newIdentity: true);
      variant.layers.first.color = 0xff007aff;
      expect(variant.id, isNot(original.id));
      expect(original.layers.first.color, 0xffff375f);
      expect(variant.package, original.package);
      expect(variant.pinState, 'none');
      expect(
        IconDesign.fromJson(original.toJson()).toJson(),
        original.toJson(),
      );
    },
  );
  test(
    'Local library survives restart, deletion and recovery from corrupted data',
    () async {
      final store = StudioStore(AndroidService());
      await store.init();
      final first = IconDesign(name: 'Première');
      await store.save(first);
      final second = first.copy(newIdentity: true)..name = 'Variante';
      await store.save(second);
      final reload = StudioStore(AndroidService());
      await reload.init();
      expect(reload.designs.map((d) => d.name), ['Variante', 'Première']);
      await reload.delete(first.id);
      final afterDelete = StudioStore(AndroidService());
      await afterDelete.init();
      expect(afterDelete.designs.length, 1);
      await File('${temp.path}/studio.json').writeAsString('broken');
      final restored = StudioStore(AndroidService());
      await restored.init();
      expect(restored.loadWarning, isNotNull);
      expect(restored.designs, isNotEmpty);
    },
  );
  test(
    'PNG export has real dimensions, transparent corners and a rendered brand',
    () async {
      final d = IconDesign(
        background: 0xff000000,
        layers: [
          IconLayer(
            kind: 'brand',
            value: 'instagram',
            color: 0xffff375f,
            glow: .6,
          ),
        ],
      );
      final png = await ArtImages.png(d, resolution: 512);
      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 512);
      expect(image.height, 512);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(pixels[3], 0);
      int colored = 0;
      for (int i = 0; i < pixels.length; i += 4) {
        if (pixels[i] > 100 && pixels[i] > pixels[i + 1] * 1.5) colored++;
      }
      expect(colored, greaterThan(4000));
      image.dispose();
      codec.dispose();
    },
  );
  testWidgets('Editor works on a compact display without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = StudioStore(AndroidService());
    await tester.runAsync(() => store.init());
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: EditorScreen(store, IconDesign()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Effets'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Calques'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un élément'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Onboarding remains usable with large text on a compact display',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = StudioStore(AndroidService());
      await tester.runAsync(() => store.init());
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Onboarding(store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Créer ma première icône'),
        200,
      );
      expect(find.text('Créer ma première icône'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Apply offers native and badge-free widget modes', (tester) async {
    final calls = <String>[];
    final store = StudioStore(AndroidService());
    await tester.runAsync(() => store.init());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidService.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'shortcutSupport') return false;
      return null;
    });
    await tester.pumpWidget(MaterialApp(
      theme: studioTheme(Brightness.light),
      home: EditorScreen(store, IconDesign(
        package: 'com.instagram.android', appName: 'Instagram', name: 'Instagram',
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer sur l’écran d’accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Raccourci natif'), findsOneWidget);
    expect(find.text('Sans badge · widget 1×1'), findsOneWidget);
    expect(calls, isNot(contains('shortcutSupport')));
    await tester.tap(find.text('Raccourci natif'));
    await tester.pumpAndSettle();
    expect(calls, contains('shortcutSupport'));
    expect(calls, isNot(contains('pinWidget')));
    expect(find.textContaining('ne permet pas les raccourcis natifs'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Widget mode does not require native shortcut support', (tester) async {
    final calls = <String>[];
    final store = StudioStore(AndroidService());
    await tester.runAsync(() => store.init());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidService.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'hasWidgetDesign') return false;
      if (call.method == 'pinWidget') return 'manual';
      return null;
    });
    await tester.pumpWidget(MaterialApp(
      theme: studioTheme(Brightness.light),
      home: EditorScreen(store, IconDesign(
        package: 'com.instagram.android', appName: 'Instagram', name: 'Instagram',
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer sur l’écran d’accueil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sans badge · widget 1×1'));
    await tester.pumpAndSettle();
    expect(calls, contains('pinWidget'));
    expect(calls, isNot(contains('shortcutSupport')));
    expect(tester.takeException(), isNull);
  });

  test('Native pin keeps custom labels and falls back to the real app name', () async {
    final payloads = <Map<dynamic, dynamic>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidService.channel, (call) async {
      if (call.method == 'pinShortcut') {
        payloads.add(call.arguments as Map);
        return 'pending';
      }
      return null;
    });
    final d = IconDesign(package: 'com.instagram.android', appName: 'Instagram', name: '');
    final bytes = await ArtImages.png(d, resolution: 512, launcherForeground: true);
    await AndroidService().pin(d, bytes);
    d.name = 'Mon Instagram';
    await AndroidService().pin(d, bytes);
    expect(payloads[0]['name'], 'Instagram');
    expect(payloads[1]['name'], 'Mon Instagram');
    expect(payloads[0]['package'], 'com.instagram.android');
    expect(payloads[0]['id'], payloads[1]['id']);
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect(data.getUint8(3), 0);
    expect(image.width, 512);
    image.dispose(); codec.dispose();
  });
}
