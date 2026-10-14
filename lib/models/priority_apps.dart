import 'package:flutter/material.dart';
import 'design.dart';

class PriorityApp {
  final String id, name, detail;
  final List<String> packages, aliases;
  final String? brand;
  final int primary, secondary;
  final double scale, light;
  final bool illustrated;
  const PriorityApp(
    this.id,
    this.name,
    this.primary,
    this.secondary,
    this.detail, {
    this.packages = const [],
    this.aliases = const [],
    this.brand,
    this.scale = .62,
    this.light = .38,
    this.illustrated = false,
  });
  bool packageMatches(String value) =>
      packages.any((p) => p.toLowerCase() == value.toLowerCase());
  int nameScore(String value) {
    final n = normalizeAppName(value);
    int score = 0;
    for (final a in [name, ...aliases]) {
      final key = normalizeAppName(a);
      if (n == key || n.startsWith('$key ')) {
        if (key.length > score) score = key.length;
      }
    }
    return score;
  }

  IconLayer logo(InstalledApp? app) => brand != null
      ? IconLayer(kind: 'brand', value: brand!, size: scale)
      : app != null
      ? IconLayer(
          kind: 'image',
          value: app.icon,
          sourcePath: app.icon,
          size: illustrated ? .76 : scale,
          tint: false,
        )
      : IconLayer(
          kind: 'text',
          value: name
              .replaceAll('Samsung ', '')
              .split(' ')
              .map((w) => w[0])
              .take(2)
              .join(),
          size: .65,
        );
  IconDesign preview(
    PriorityStyle style, {
    InstalledApp? app,
    String? edgePath,
    String? logoPath,
  }) {
    final d = IconDesign(
      name: name,
      package: app?.package ?? '',
      appName: app?.name ?? '',
      radius: .24,
    );
    final original = logo(app);
    final cleaned = logoPath != null && app != null && logoPath != app.icon;
    if (logoPath != null && original.kind == 'image') original.value = logoPath;
    final accent = Color(primary);
    final subdued = Color.lerp(
      const Color(0xff07090e),
      accent,
      .14,
    )!.toARGB32();
    d.background = 0xff080a10;
    d.background2 = subdued;
    d.gradient = true;
    d.gradientAngle = .12;
    d.borderColor = accent.withValues(alpha: .28).toARGB32();
    d.border = .008;
    if (style == PriorityStyle.signature) {
      original.color = primary;
      original.tint = original.kind != 'image' || cleaned;
      original.glow = original.kind == 'image' ? .12 : light * .45;
      original.shadow = .35;
      d.layers = [original];
    } else if (style == PriorityStyle.porcelain) {
      d.background = 0xfff7f7fb;
      d.background2 = Color.lerp(Colors.white, accent, .11)!.toARGB32();
      d.border = 0;
      original.color = Color.lerp(accent, Colors.black, .22)!.toARGB32();
      original.tint = original.kind != 'image' || cleaned;
      original.glow = 0;
      original.shadow = .16;
      d.layers = [original];
    } else {
      final lightLogo = IconLayer.fromJson(original.toJson());
      if (edgePath != null && lightLogo.kind == 'image') {
        lightLogo.value = edgePath;
        lightLogo.tint = true;
      }
      lightLogo.color = primary;
      lightLogo.glow = light;
      lightLogo.shadow = 0;
      if (style == PriorityStyle.neon) {
        d.gradient = false;
        d.background = 0xff06070a;
        d.border = 0;
        d.layers = [lightLogo];
      } else {
        final back = IconLayer.fromJson(lightLogo.toJson())
          ..id = newId()
          ..color = secondary
          ..x = .518
          ..y = .509
          ..glow = light * .65
          ..opacity = .8;
        lightLogo.x = .488;
        lightLogo.y = .493;
        lightLogo.glow = light * .55;
        d.borderColor = Color(secondary).withValues(alpha: .3).toARGB32();
        d.layers = [back, lightLogo];
      }
    }
    return d;
  }
}

String normalizeAppName(String text) => text
    .toLowerCase()
    .replaceAll('é', 'e')
    .replaceAll('è', 'e')
    .replaceAll('ê', 'e')
    .replaceAll('à', 'a')
    .replaceAll('ô', 'o')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

enum PriorityStyle { signature, neon, duo, porcelain }

const priorityStyleLabels = {
  PriorityStyle.signature: 'Signature',
  PriorityStyle.neon: 'Néon précis',
  PriorityStyle.duo: 'Duo lumineux',
  PriorityStyle.porcelain: 'Porcelaine',
};
const priorityStyleDescriptions = {
  PriorityStyle.signature:
      'Couleur dédiée, profondeur discrète et logo reconnaissable.',
  PriorityStyle.neon:
      'Fond noir et lumière dosée. Les images sont transformées en contours.',
  PriorityStyle.duo:
      'Deux couleurs superposées avec un décalage chromatique subtil.',
  PriorityStyle.porcelain:
      'Surface claire satinée, teinte douce et ombre légère.',
};

const priorityApps = <PriorityApp>[
  PriorityApp(
    'youtube',
    'YouTube',
    0xffff344e,
    0xffffb36b,
    'Rouge vidéo, symbole aéré et halo contenu.',
    packages: ['com.google.android.youtube'],
    brand: 'youtube',
    scale: .66,
  ),
  PriorityApp(
    'shazam',
    'Shazam',
    0xff29a9ff,
    0xff7bdcff,
    'Bleu électrique et courbes nettes, sans noyer le symbole.',
    packages: ['com.shazam.android'],
    brand: 'shazam',
    scale: .64,
  ),
  PriorityApp(
    'roblox',
    'Roblox',
    0xffeaf1ff,
    0xff78a4ff,
    'Géométrie franche, découpe centrale lisible et lumière froide.',
    packages: ['com.roblox.client'],
    brand: 'roblox',
    scale: .57,
    light: .28,
  ),
  PriorityApp(
    'whatsapp',
    'WhatsApp',
    0xff34df8b,
    0xffb8ffe0,
    'Vert lumineux, bulle équilibrée et marges généreuses.',
    packages: ['com.whatsapp'],
    brand: 'whatsapp',
    scale: .63,
  ),
  PriorityApp(
    'vinted',
    'Vinted',
    0xff38d2c7,
    0xffa1fff0,
    'Turquoise profond et dessin préservé pour rester identifiable.',
    packages: ['fr.vinted'],
    brand: 'vinted',
    scale: .65,
    light: .3,
  ),
  PriorityApp(
    'chatgpt',
    'ChatGPT',
    0xff79e7c4,
    0xffd9fff1,
    'Entrelacs d’origine, menthe satinée et contours fins.',
    packages: ['com.openai.chatgpt'],
    scale: .69,
    light: .28,
  ),
  PriorityApp(
    'duolingo',
    'Duolingo',
    0xff9dec39,
    0xffd6ff73,
    'Vert vif et silhouette de Duo bien détachée du fond.',
    packages: ['com.duolingo'],
    brand: 'duolingo',
    scale: .63,
    light: .3,
  ),
  PriorityApp(
    'capcut',
    'CapCut',
    0xffedf2ff,
    0xff8bb5ff,
    'Croisement précis, blanc froid et ombre sobre.',
    packages: ['com.lemon.lvoverseas'],
    scale: .69,
    light: .28,
  ),
  PriorityApp(
    'colorpuz',
    'ColorPuz',
    0xffffa665,
    0xffc182ff,
    'Les couleurs du jeu en Signature ; tracé lumineux en Néon.',
    aliases: ['color puz'],
    illustrated: true,
    light: .28,
  ),
  PriorityApp(
    'wilgo',
    'Wilgo',
    0xffab87ff,
    0xff6edee1,
    'Violet doux, relief léger et identité de l’application conservée.',
    packages: ['ai.wilgo.android'],
    scale: .7,
    light: .32,
  ),
  PriorityApp(
    'instagram',
    'Instagram',
    0xffff375f,
    0xffba68ff,
    'Contour emblématique, rouge rosé et duo magenta-violet.',
    packages: ['com.instagram.android'],
    brand: 'instagram',
    scale: .62,
    light: .46,
  ),
  PriorityApp(
    'waze',
    'Waze',
    0xff5bd3ff,
    0xffb1edff,
    'Bleu ciel et silhouette expressive, lisible même en petit.',
    packages: ['com.waze'],
    brand: 'waze',
    scale: .66,
    light: .3,
  ),
  PriorityApp(
    'pinterest',
    'Pinterest',
    0xffff4568,
    0xffff9aa8,
    'Lettrage iconique, rouge velouté et halo fin.',
    packages: ['com.pinterest'],
    brand: 'pinterest',
    scale: .59,
  ),
  PriorityApp(
    'gmail',
    'Gmail',
    0xffff6b64,
    0xffffbd70,
    'Le M garde ses proportions, avec des accents chauds.',
    packages: ['com.google.android.gm'],
    brand: 'gmail',
    scale: .66,
    light: .3,
  ),
  PriorityApp(
    'gemini',
    'Gemini',
    0xff84a9ff,
    0xffcd8cff,
    'Étoile nette, bleu pervenche et reflet violet.',
    packages: ['com.google.android.apps.bard'],
    aliases: ['google gemini'],
    brand: 'googlegemini',
    scale: .64,
  ),
  PriorityApp(
    'maps',
    'Maps',
    0xff62b8ff,
    0xff66e1a8,
    'Repère géographique équilibré, palette bleu-vert.',
    packages: ['com.google.android.apps.maps'],
    aliases: ['google maps'],
    brand: 'googlemaps',
    scale: .61,
    light: .32,
  ),
  PriorityApp(
    'pronote',
    'PRONOTE',
    0xff71d290,
    0xffc4ef93,
    'Logo réellement installé, vert calme et finesse des détails.',
    packages: ['com.IndexEducation.Pronote'],
    scale: .7,
    light: .28,
  ),
  PriorityApp(
    'chrome',
    'Chrome',
    0xff8dbaff,
    0xfff3d38c,
    'Découpe circulaire nette et lumière froide bien contenue.',
    packages: ['com.android.chrome'],
    aliases: ['google chrome'],
    brand: 'googlechrome',
    scale: .62,
    light: .3,
  ),
  PriorityApp(
    'yuka',
    'Yuka',
    0xff81d88d,
    0xffffb775,
    'Carotte d’origine, vert végétal et accent abricot.',
    packages: ['io.yuka.android'],
    scale: .7,
    light: .3,
  ),
  PriorityApp(
    'tiktok',
    'TikTok',
    0xff48e9e5,
    0xffff507c,
    'Duo cyan-rose, décalage discret et note bien dessinée.',
    packages: ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill'],
    brand: 'tiktok',
    scale: .59,
    light: .38,
  ),
  PriorityApp(
    'spotify',
    'Spotify',
    0xff48e88c,
    0xffb8ff9b,
    'Trois ondes lisibles, vert précis et halo sans excès.',
    packages: ['com.spotify.music'],
    brand: 'spotify',
    scale: .63,
  ),
  PriorityApp(
    'samsungbrowser',
    'Samsung Browser',
    0xffb49aff,
    0xff829bff,
    'Planète d’origine, violet cosmique et bleu doux.',
    packages: ['com.sec.android.app.sbrowser'],
    aliases: ['samsung internet', 'internet samsung'],
    scale: .68,
    light: .32,
  ),
  PriorityApp(
    'ngl',
    'NGL',
    0xffff697e,
    0xffffad63,
    'Dégradé chaud et lettres conservées, sans simplification générique.',
    packages: ['com.nglreactnative'],
    scale: .72,
    light: .3,
  ),
  PriorityApp(
    'brawlstars',
    'Brawl Stars',
    0xffffcc57,
    0xffff8b63,
    'Visuel du jeu préservé en Signature, gravure lumineuse en Néon.',
    packages: ['com.supercell.brawlstars'],
    illustrated: true,
    light: .28,
  ),
  PriorityApp(
    'chess',
    'Échecs',
    0xffdbcfac,
    0xff8ed8c2,
    'Pièce et détails de votre jeu, ivoire doux et accent jade.',
    aliases: ['chess', 'chess com', 'lichess', 'jeu d echecs'],
    illustrated: true,
    light: .24,
  ),
  PriorityApp(
    'myrecorder',
    'MyRecorder',
    0xffff7d87,
    0xffbd8eff,
    'Micro d’origine et lumière rose-violette, bien centrés.',
    aliases: ['my recorder'],
    scale: .67,
    light: .3,
  ),
  PriorityApp(
    'samsungnotes',
    'Samsung Notes',
    0xffff947b,
    0xffffc59b,
    'Dessin d’origine, corail lumineux et bordure délicate.',
    packages: ['com.samsung.android.app.notes'],
    aliases: ['notes samsung'],
    scale: .69,
    light: .28,
  ),
  PriorityApp(
    'wordsearch',
    'Word Search',
    0xff8ae5cf,
    0xff8fb5ff,
    'Grille et lettres conservées, contours nets et vert aquatique.',
    aliases: ['wordsearch', 'mots meles'],
    illustrated: true,
    light: .25,
  ),
  PriorityApp(
    'life360',
    'Life360',
    0xffbc9bff,
    0xffffc2ee,
    'Repère d’origine, violet apaisé et accent rosé.',
    packages: ['com.life360.android.safetymapd'],
    scale: .65,
    light: .3,
  ),
  PriorityApp(
    'youtubemusic',
    'YouTube Music',
    0xffff5d72,
    0xffffa3ba,
    'Anneau musical, centre net et rouge lumineux.',
    packages: ['com.google.android.apps.youtube.music'],
    brand: 'youtubemusic',
    scale: .64,
  ),
  PriorityApp(
    'snapchat',
    'Snapchat',
    0xffffdf50,
    0xfffff3ab,
    'Fantôme bien découpé, jaune lumineux sur un fond profond.',
    packages: ['com.snapchat.android'],
    brand: 'snapchat',
    scale: .65,
    light: .32,
  ),
];
PriorityApp? priorityForApp(InstalledApp app) {
  for (final p in priorityApps) {
    if (p.packageMatches(app.package)) return p;
  }
  PriorityApp? match;
  int score = 0;
  for (final p in priorityApps) {
    final s = p.nameScore(app.name);
    if (s > score) {
      score = s;
      match = p;
    }
  }
  return match;
}

PriorityApp? priorityForDesign(IconDesign d) {
  if (d.package.isEmpty && d.appName.isEmpty) return null;
  return priorityForApp(
    InstalledApp(package: d.package, name: d.appName, icon: ''),
  );
}
