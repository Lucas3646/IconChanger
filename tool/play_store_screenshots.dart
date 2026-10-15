// Render the real Flutter screens with local example creations for Play Store.
// Run: flutter test tool/play_store_screenshots.dart --no-pub
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icon_studio/main.dart';
import 'package:icon_studio/models/design.dart';
import 'package:icon_studio/screens/editor.dart';
import 'package:icon_studio/screens/home.dart';
import 'package:icon_studio/services/platform_service.dart';
import 'package:icon_studio/services/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Render Play Store examples from the application widgets', (
    tester,
  ) async {
    final output = Directory('build/play-store')..createSync(recursive: true);
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('icon-studio-store-'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = Platform.environment['FLUTTER_ROOT']!;
    await tester.runAsync(() async {
      for (final entry in {
        'sans-serif': 'Roboto-Regular.ttf',
        'Roboto': 'Roboto-Regular.ttf',
        'MaterialIcons': 'MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key);
        loader.addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/${entry.value}',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
        await loader.load();
      }
    });
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
    final store = StudioStore(AndroidService());
    await tester.runAsync(() => store.init());
    store.onboarded = true;
    final samples = <IconDesign>[];
    for (final entry in {
      'Instagram': 'instagram',
      'YouTube': 'youtube',
      'Spotify': 'spotify',
      'WhatsApp': 'whatsapp',
      'Discord': 'discord',
      'Gmail': 'gmail',
    }.entries) {
      final design = IconDesign(
        name: entry.key,
        layers: [IconLayer(kind: 'brand', value: entry.value)],
      );
      packs[samples.length % packs.length].apply(design);
      samples.add(design);
    }
    store.designs = samples;
    final key = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Widget app(Widget screen) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: studioTheme(Brightness.light).copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              textStyle: const TextStyle(fontFamily: 'sans-serif'),
            ),
          ),
        ),
        home: screen,
      ),
    );
    await tester.pumpWidget(app(HomeScreen(store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorer').last);
    await capture('01-explorer');
    await tester.tap(find.text('Mes icônes').last);
    await capture('02-mes-icones');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(EditorScreen(store, samples.first)));
    await capture('03-editeur');
    await tester.tap(find.text('Effets'));
    await capture('04-effets');
  });
}
