import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:icon_studio/models/design.dart';
import 'package:icon_studio/models/priority_apps.dart';
import 'package:icon_studio/widgets/icon_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Every requested application has four dedicated, independent compositions',
    () {
      const requested = [
        'YouTube',
        'Shazam',
        'Roblox',
        'WhatsApp',
        'Vinted',
        'ChatGPT',
        'Duolingo',
        'CapCut',
        'ColorPuz',
        'Wilgo',
        'Instagram',
        'Waze',
        'Pinterest',
        'Gmail',
        'Gemini',
        'Maps',
        'PRONOTE',
        'Chrome',
        'Yuka',
        'TikTok',
        'Spotify',
        'Samsung Browser',
        'NGL',
        'Brawl Stars',
        'Échecs',
        'MyRecorder',
        'Samsung Notes',
        'Word Search',
        'Life360',
        'YouTube Music',
        'Snapchat',
      ];
      expect(priorityApps.map((p) => p.name).toList(), requested);
      expect(priorityApps.map((p) => p.id).toSet().length, 31);
      for (final p in priorityApps) {
        final designs = PriorityStyle.values.map((s) => p.preview(s)).toList();
        expect(designs[0].gradient, true, reason: p.name);
        expect(designs[1].layers.first.glow, greaterThan(0), reason: p.name);
        expect(designs[2].layers.length, 2, reason: p.name);
        expect(
          designs[2].layers[0].color,
          isNot(designs[2].layers[1].color),
          reason: p.name,
        );
        expect(designs[3].background, 0xfff7f7fb, reason: p.name);
        expect(
          designs.every(
            (d) =>
                d.layers.isNotEmpty &&
                d.layers.every((l) => l.size > .4 && l.size < .9),
          ),
          true,
          reason: p.name,
        );
      }
    },
  );
  test(
    'Exact installed package wins over ambiguous YouTube/Music and browser names',
    () {
      InstalledApp app(String pkg, String name) =>
          InstalledApp(package: pkg, name: name, icon: '/unused.png');
      expect(
        priorityForApp(
          app('com.google.android.apps.youtube.music', 'YouTube Music'),
        )?.id,
        'youtubemusic',
      );
      expect(
        priorityForApp(app('ai.wilgo.android', 'Wilgo : Quiz et révision'))?.id,
        'wilgo',
      );
      expect(
        priorityForApp(app('com.sec.android.app.sbrowser', 'Internet'))?.id,
        'samsungbrowser',
      );
      expect(priorityForApp(app('unrelated.browser', 'Internet')), isNull);
      expect(priorityForApp(app('some.chess.app', 'Échecs'))?.id, 'chess');
      expect(
        priorityForApp(app('some.word.game', 'Word Search - Daily puzzle'))?.id,
        'wordsearch',
      );
    },
  );
  test(
    'Illustrated games preserve original detail and use prepared edges only in neon styles',
    () {
      final p = priorityApps.firstWhere((p) => p.id == 'brawlstars');
      final app = InstalledApp(
        package: 'com.supercell.brawlstars',
        name: 'Brawl Stars',
        icon: '/real-original.png',
      );
      final signature = p.preview(
        PriorityStyle.signature,
        app: app,
        edgePath: '/prepared-edges.png',
        logoPath: app.icon,
      );
      expect(signature.layers.first.value, app.icon);
      expect(signature.layers.first.tint, false);
      final neon = p.preview(
        PriorityStyle.neon,
        app: app,
        edgePath: '/prepared-edges.png',
        logoPath: app.icon,
      );
      expect(neon.layers.first.value, '/prepared-edges.png');
      expect(neon.layers.first.sourcePath, app.icon);
      expect(neon.layers.first.tint, true);
      expect(neon.package, app.package);
    },
  );
  test(
    'Every integrated priority vector actually renders to a nonempty transparent PNG',
    () async {
      for (final p in priorityApps.where((p) => p.brand != null)) {
        expect(
          File('assets/brands/${p.brand}.svg').existsSync(),
          true,
          reason: p.name,
        );
        final d = p.preview(PriorityStyle.neon);
        final png = await ArtImages.png(d, resolution: 128);
        final codec = await ui.instantiateImageCodec(png);
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        int bright = 0;
        for (int i = 0; i < rgba.length; i += 4) {
          if (rgba[i] > 80 || rgba[i + 1] > 80 || rgba[i + 2] > 80) bright++;
        }
        expect(bright, greaterThan(80), reason: p.name);
        expect(rgba[3], 0, reason: p.name);
        image.dispose();
        codec.dispose();
      }
    },
  );
}
