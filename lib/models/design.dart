import 'dart:convert';
import 'package:flutter/material.dart';

String newId() => '${DateTime.now().microsecondsSinceEpoch}';

class InstalledApp {
  final String package, name, icon;
  final bool system;
  InstalledApp({
    required this.package,
    required this.name,
    required this.icon,
    this.system = false,
  });
  factory InstalledApp.fromJson(Map<dynamic, dynamic> j) => InstalledApp(
    package: j['package'],
    name: j['name'],
    icon: j['icon'],
    system: j['system'] == true,
  );
}

class IconLayer {
  String id, kind, value, sourcePath;
  double x, y, size, rotation, opacity, glow, shadow, stroke;
  int color;
  bool tint, bold;
  IconLayer({
    String? id,
    this.kind = 'symbol',
    this.value = 'sparkles',
    this.sourcePath = '',
    this.x = .5,
    this.y = .5,
    this.size = .6,
    this.rotation = 0,
    this.opacity = 1,
    this.glow = 0,
    this.shadow = 0,
    this.stroke = 0,
    this.color = 0xffffffff,
    this.tint = true,
    this.bold = true,
  }) : id = id ?? newId();
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'value': value,
    'sourcePath': sourcePath,
    'x': x,
    'y': y,
    'size': size,
    'rotation': rotation,
    'opacity': opacity,
    'glow': glow,
    'shadow': shadow,
    'stroke': stroke,
    'color': color,
    'tint': tint,
    'bold': bold,
  };
  factory IconLayer.fromJson(Map<String, dynamic> j) => IconLayer(
    id: j['id'],
    kind: j['kind'] ?? 'symbol',
    value: j['value'] ?? 'sparkles',
    sourcePath: j['sourcePath'] ?? '',
    x: (j['x'] as num? ?? .5).toDouble(),
    y: (j['y'] as num? ?? .5).toDouble(),
    size: (j['size'] as num? ?? .6).toDouble(),
    rotation: (j['rotation'] as num? ?? 0).toDouble(),
    opacity: (j['opacity'] as num? ?? 1).toDouble(),
    glow: (j['glow'] as num? ?? 0).toDouble(),
    shadow: (j['shadow'] as num? ?? 0).toDouble(),
    stroke: (j['stroke'] as num? ?? 0).toDouble(),
    color: j['color'] ?? 0xffffffff,
    tint: j['tint'] ?? true,
    bold: j['bold'] ?? true,
  );
}

class IconDesign {
  String id, name, package, appName, pinState;
  int background, background2, borderColor;
  double radius, border, gradientAngle, backgroundOpacity;
  bool gradient;
  List<IconLayer> layers;
  IconDesign({
    String? id,
    this.name = 'Nouvelle icône',
    this.package = '',
    this.appName = '',
    this.pinState = 'none',
    this.background = 0xff161618,
    this.background2 = 0xff41414a,
    this.borderColor = 0xffffffff,
    this.radius = .23,
    this.border = 0,
    this.gradientAngle = .75,
    this.backgroundOpacity = 1,
    this.gradient = false,
    List<IconLayer>? layers,
  }) : id = id ?? newId(),
       layers = layers ?? [IconLayer()];
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'package': package,
    'appName': appName,
    'pinState': pinState,
    'background': background,
    'background2': background2,
    'borderColor': borderColor,
    'radius': radius,
    'border': border,
    'gradientAngle': gradientAngle,
    'backgroundOpacity': backgroundOpacity,
    'gradient': gradient,
    'layers': layers.map((l) => l.toJson()).toList(),
  };
  factory IconDesign.fromJson(Map<String, dynamic> j) => IconDesign(
    id: j['id'],
    name: j['name'] ?? 'Icône',
    package: j['package'] ?? '',
    appName: j['appName'] ?? '',
    pinState: j['pinState'] ?? 'none',
    background: j['background'] ?? 0xff161618,
    background2: j['background2'] ?? 0xff41414a,
    borderColor: j['borderColor'] ?? 0xffffffff,
    radius: (j['radius'] as num? ?? .23).toDouble(),
    border: (j['border'] as num? ?? 0).toDouble(),
    gradientAngle: (j['gradientAngle'] as num? ?? .75).toDouble(),
    backgroundOpacity: (j['backgroundOpacity'] as num? ?? 1).toDouble(),
    gradient: j['gradient'] ?? false,
    layers: (j['layers'] as List? ?? [])
        .map((l) => IconLayer.fromJson(Map<String, dynamic>.from(l)))
        .toList(),
  );
  IconDesign copy({bool newIdentity = false}) {
    final d = IconDesign.fromJson(jsonDecode(jsonEncode(toJson())));
    if (newIdentity) {
      d.id = newId();
      d.pinState = 'none';
    }
    return d;
  }
}

const brands = <String, String>{
  'shazam': 'Shazam',
  'roblox': 'Roblox',
  'vinted': 'Vinted',
  'duolingo': 'Duolingo',
  'waze': 'Waze',
  'googlegemini': 'Gemini',
  'youtubemusic': 'YouTube Music',
  'chessdotcom': 'Chess.com',
  'instagram': 'Instagram',
  'youtube': 'YouTube',
  'tiktok': 'TikTok',
  'whatsapp': 'WhatsApp',
  'snapchat': 'Snapchat',
  'spotify': 'Spotify',
  'facebook': 'Facebook',
  'messenger': 'Messenger',
  'telegram': 'Telegram',
  'discord': 'Discord',
  'netflix': 'Netflix',
  'google': 'Google',
  'gmail': 'Gmail',
  'googlemaps': 'Google Maps',
  'googlechrome': 'Chrome',
  'googledrive': 'Google Drive',
  'googlephotos': 'Google Photos',
  'pinterest': 'Pinterest',
  'reddit': 'Reddit',
  'twitch': 'Twitch',
  'x': 'X',
  'signal': 'Signal',
  'threads': 'Threads',
};
const brandPackages = <String, String>{
  'com.shazam.android': 'shazam',
  'com.roblox.client': 'roblox',
  'fr.vinted': 'vinted',
  'com.duolingo': 'duolingo',
  'com.waze': 'waze',
  'com.google.android.apps.bard': 'googlegemini',
  'com.google.android.apps.youtube.music': 'youtubemusic',
  'com.instagram.android': 'instagram',
  'com.google.android.youtube': 'youtube',
  'com.zhiliaoapp.musically': 'tiktok',
  'com.ss.android.ugc.trill': 'tiktok',
  'com.whatsapp': 'whatsapp',
  'com.snapchat.android': 'snapchat',
  'com.spotify.music': 'spotify',
  'com.facebook.katana': 'facebook',
  'com.facebook.orca': 'messenger',
  'org.telegram.messenger': 'telegram',
  'com.discord': 'discord',
  'com.netflix.mediaclient': 'netflix',
  'com.google.android.googlequicksearchbox': 'google',
  'com.google.android.gm': 'gmail',
  'com.google.android.apps.maps': 'googlemaps',
  'com.android.chrome': 'googlechrome',
  'com.google.android.apps.docs': 'googledrive',
  'com.google.android.apps.photos': 'googlephotos',
  'com.pinterest': 'pinterest',
  'com.reddit.frontpage': 'reddit',
  'tv.twitch.android.app': 'twitch',
  'com.twitter.android': 'x',
  'org.thoughtcrime.securesms': 'signal',
  'com.instagram.barcelona': 'threads',
};
const symbols = <String, IconData>{
  'sparkles': Icons.auto_awesome_rounded,
  'heart': Icons.favorite_rounded,
  'star': Icons.star_rounded,
  'moon': Icons.dark_mode_rounded,
  'sun': Icons.wb_sunny_rounded,
  'bolt': Icons.bolt_rounded,
  'music': Icons.music_note_rounded,
  'camera': Icons.camera_alt_rounded,
  'chat': Icons.chat_bubble_rounded,
  'home': Icons.home_rounded,
  'flower': Icons.local_florist_rounded,
  'game': Icons.sports_esports_rounded,
  'planet': Icons.public_rounded,
  'cloud': Icons.cloud_rounded,
  'lock': Icons.lock_rounded,
  'mail': Icons.mail_rounded,
  'phone': Icons.phone_rounded,
  'leaf': Icons.eco_rounded,
  'diamond': Icons.diamond_rounded,
  'coffee': Icons.coffee_rounded,
  'book': Icons.menu_book_rounded,
  'check': Icons.check_circle_rounded,
  'person': Icons.person_rounded,
  'settings': Icons.settings_rounded,
};

class IconPack {
  final String name, subtitle;
  final int bg, fg, second;
  final double glow;
  final bool gradient;
  const IconPack(
    this.name,
    this.subtitle,
    this.bg,
    this.fg, {
    this.glow = 0,
    this.second = 0xff30303a,
    this.gradient = false,
  });
  void apply(IconDesign d) {
    d.background = bg;
    d.background2 = second;
    d.gradient = gradient;
    d.backgroundOpacity = 1;
    d.border = name == 'Glass' ? .012 : 0;
    d.borderColor = 0x77ffffff;
    for (final l in d.layers) {
      l.color = fg;
      l.glow = glow;
      l.tint = true;
    }
  }
}

const packs = [
  IconPack(
    'Neon Red',
    'Un rouge lumineux, un fond profond.',
    0xff09090c,
    0xffff375f,
    glow: .6,
  ),
  IconPack(
    'Neon Blue',
    'La lumière électrique.',
    0xff09090c,
    0xff40a9ff,
    glow: .6,
  ),
  IconPack(
    'Neon Purple',
    'Une touche de violet.',
    0xff09090c,
    0xffbf72ff,
    glow: .6,
  ),
  IconPack(
    'Minimal Dark',
    'L’essentiel en noir et blanc.',
    0xff1c1c1e,
    0xfff5f5f7,
  ),
  IconPack(
    'Minimal Light',
    'Clair, simple, intemporel.',
    0xfff2f2f7,
    0xff1c1c1e,
  ),
  IconPack(
    'Pastel',
    'Des couleurs qui respirent.',
    0xffe9dcff,
    0xff78639c,
    second: 0xffffe6dc,
    gradient: true,
  ),
  IconPack(
    'Glass',
    'Une surface satinée et lumineuse.',
    0xff637fa7,
    0xffffffff,
    second: 0xffc3d9ec,
    gradient: true,
  ),
  IconPack(
    'Monochrome',
    'Une couleur, votre signature.',
    0xff243b36,
    0xffc9eadb,
  ),
];
IconDesign designForApp(InstalledApp app) => IconDesign(
  name: app.name,
  package: app.package,
  appName: app.name,
  layers: [
    brandPackages.containsKey(app.package)
        ? IconLayer(kind: 'brand', value: brandPackages[app.package]!)
        : IconLayer(
            kind: 'image',
            value: app.icon,
            sourcePath: app.icon,
            tint: false,
          ),
  ],
);
