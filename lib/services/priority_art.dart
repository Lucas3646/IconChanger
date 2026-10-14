import 'dart:io';
import '../models/design.dart';
import '../models/priority_apps.dart';
import 'platform_service.dart';

class PreparedPriorityArt {
  final String? logo, edges;
  const PreparedPriorityArt({this.logo, this.edges});
}

class PriorityArt {
  static final Map<String, Future<PreparedPriorityArt>> _cache = {};
  static Future<PreparedPriorityArt> prepare(
    AndroidService platform,
    PriorityApp profile,
    InstalledApp? app,
  ) async {
    if (app == null || profile.brand != null) {
      return const PreparedPriorityArt();
    }
    final stamp = (await File(app.icon).stat()).modified.millisecondsSinceEpoch;
    final key = '${profile.id}:${app.package}:${app.icon}:$stamp';
    return _cache[key] ??= _prepare(platform, profile, app).catchError((
      Object error,
    ) {
      _cache.remove(key);
      throw error;
    });
  }

  static Future<PreparedPriorityArt> _prepare(
    AndroidService platform,
    PriorityApp profile,
    InstalledApp app,
  ) async {
    final logo = profile.illustrated
        ? app.icon
        : await platform.process(app.icon, 'autoLogo', .25);
    final edges = await platform.process(logo, 'edges', .18);
    return PreparedPriorityArt(logo: logo, edges: edges);
  }

  static Future<IconDesign> build(
    AndroidService platform,
    PriorityApp profile,
    InstalledApp? app,
    PriorityStyle style,
  ) async {
    final art = await prepare(platform, profile, app);
    return profile.preview(
      style,
      app: app,
      edgePath: art.edges,
      logoPath: art.logo,
    );
  }
}
