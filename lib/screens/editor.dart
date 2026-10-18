import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/design.dart';
import '../models/priority_apps.dart';
import '../widgets/priority_styles.dart';
import '../services/store.dart';
import '../widgets/icon_art.dart';
import '../widgets/studio_ui.dart';

class EditorScreen extends StatefulWidget {
  final StudioStore store;
  final IconDesign initial;
  const EditorScreen(this.store, this.initial, {super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late IconDesign d;
  int selected = 0, tab = 0;
  bool busy = false, dirty = false;
  final List<String> undo = [], redo = [];
  double startSize = 1, startRotation = 0;
  IconLayer? get layer => d.layers.isEmpty
      ? null
      : d.layers[selected.clamp(0, d.layers.length - 1)];
  @override
  void initState() {
    super.initState();
    d = widget.initial.copy();
  }

  String snapshot() => jsonEncode(d.toJson());
  void checkpoint() {
    undo.add(snapshot());
    if (undo.length > 40) undo.removeAt(0);
    redo.clear();
  }

  void change(VoidCallback mutation, {bool remember = true}) {
    if (remember) checkpoint();
    setState(() {
      mutation();
      dirty = true;
    });
  }

  void restore(bool backwards) {
    final from = backwards ? undo : redo;
    final to = backwards ? redo : undo;
    if (from.isEmpty) return;
    to.add(snapshot());
    setState(() {
      d = IconDesign.fromJson(jsonDecode(from.removeLast()));
      selected = selected.clamp(0, math.max(0, d.layers.length - 1));
      dirty = true;
    });
  }

  Future<bool> canLeave() async {
    if (!dirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer votre création ?'),
        content: const Text('Gardez vos modifications dans Mes icônes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Quitter'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == 'save') return save();
    return result == 'discard';
  }

  Future<bool> save({bool announce = true}) async {
    final saved = d.copy();
    try {
      await ArtImages.load(saved);
      await widget.store.save(saved);
      if (await widget.store.platform.hasWidget(saved.id)) {
        await widget.store.platform.updateWidget(
          saved,
          await ArtImages.png(
            saved, resolution: 512, launcherForeground: true,
          ),
        );
      }
      if (mounted) {
        if (jsonEncode(saved.toJson()) == snapshot()) {
          setState(() => dirty = false);
        }
        if (announce) notice(context, 'Création enregistrée dans Mes icônes.');
      }
      return true;
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
      return false;
    }
  }

  Future<void> export() async {
    final resolution = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Exporter en PNG',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Les zones transparentes sont conservées.'),
            ),
            for (final n in [512, 1024, 2048])
              ListTile(
                title: Text('$n × $n px'),
                subtitle: n == 1024 ? const Text('Recommandé') : null,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, n),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (resolution == null || !mounted) return;
    setState(() => busy = true);
    try {
      final bytes = await ArtImages.png(d, resolution: resolution);
      final name = d.name.replaceAll(RegExp(r'[^\wÀ-ÿ -]'), '').trim();
      final done = await widget.store.platform.exportPng(
        bytes,
        name.isEmpty ? 'Icon Studio' : name,
      );
      if (done && mounted) notice(context, 'PNG exporté.');
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> apply() async {
    if (d.package.isEmpty) {
      final app = await chooseApp();
      if (app == null || !mounted) return;
      change(() {
        d.package = app.package;
        d.appName = app.name;
        if (d.name == 'Nouvelle icône') d.name = app.name;
      });
    }
    if (!mounted) return;

    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Ajouter sur l’écran d’accueil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Choisissez le rendu de votre icône.'),
              ),
              ListTile(
                leading: const Icon(Icons.apps_rounded),
                title: const Text('Raccourci natif'),
                subtitle: const Text(
                  'Taille Android et nom natif · badge Icon Studio possible',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, 'shortcut'),
              ),
              ListTile(
                leading: const Icon(Icons.hide_image_outlined),
                title: const Text('Sans badge · widget 1×1'),
                subtitle: const Text(
                  'Icône et nom sous le logo · le launcher peut modifier les marges',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, 'widget'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null || !mounted) return;
    setState(() => busy = true);
    try {
      if (mode == 'shortcut' &&
          !await widget.store.platform.shortcutSupport()) {
        if (mounted) {
          notice(context,
              'Cet écran d’accueil ne permet pas les raccourcis natifs. Essayez le mode sans badge.');
        }
        return;
      }

      // Both modes share the same artwork. Android applies an adaptive mask
      // to native shortcuts; the widget emulates it without a publisher badge.
      final bytes = await ArtImages.png(
        d,
        resolution: 512,
        launcherForeground: true,
      );
      if (!await save(announce: false)) return;
      if (mode == 'widget') {
        final state = await widget.store.platform.pinWidget(d, bytes);
        if (mounted) {
          setState(() => dirty = false);
          notice(context,
              state == 'manual'
                  ? 'Ajoutez manuellement le widget Icon Studio 1×1 depuis les widgets du launcher, puis choisissez votre création.'
                  : 'Confirmez l’ajout du widget sans badge. Choisissez votre création si Android ouvre sa configuration.');
        }
      } else {
        final state = await widget.store.platform.pin(d, bytes);
        if (state == 'unsupported') {
          if (mounted) notice(context, 'L’écran d’accueil a refusé la demande.');
          return;
        }
        d.pinState = state == 'updated' ? 'pinned' : 'pending';
        await widget.store.save(d);
        if (mounted) {
          setState(() => dirty = false);
          notice(context,
              state == 'updated'
                  ? 'Raccourci natif mis à jour avec son nom.'
                  : 'Confirmez le raccourci avec son nom. Le badge Icon Studio dépend du launcher.');
        }
      }
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<InstalledApp?> chooseApp() async {
    await widget.store.refreshApps();
    if (!mounted) return null;
    return showModalBottomSheet<InstalledApp>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AppPicker(widget.store),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      final yes = await canLeave();
      if (yes && context.mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Studio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Annuler la modification',
            onPressed: busy || undo.isEmpty ? null : () => restore(true),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Rétablir',
            onPressed: busy || redo.isEmpty ? null : () => restore(false),
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: busy ? null : () => save(),
            icon: const Icon(Icons.check_rounded),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            tooltip: 'Autres actions',
            onSelected: (v) async {
              if (v == 'export') export();
              if (v == 'duplicate') {
                final next = d.copy(newIdentity: true)
                  ..name = '${d.name} · variante';
                change(() => d = next);
                notice(
                  context,
                  'Nouvelle variante. Enregistrez-la pour la conserver.',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Exporter en PNG')),
              PopupMenuItem(
                value: 'duplicate',
                child: Text('Créer une variante'),
              ),
            ],
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: busy,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final dim = (constraints.maxHeight * .29).clamp(110.0, 220.0);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onScaleStart: (_) {
                          if (layer == null) return;
                          checkpoint();
                          startSize = layer!.size;
                          startRotation = layer!.rotation;
                        },
                        onScaleUpdate: (details) {
                          if (layer == null) return;
                          change(() {
                            layer!.x =
                                (layer!.x + details.focalPointDelta.dx / dim)
                                    .clamp(-.2, 1.2);
                            layer!.y =
                                (layer!.y + details.focalPointDelta.dy / dim)
                                    .clamp(-.2, 1.2);
                            layer!.size = (startSize * details.scale).clamp(
                              .05,
                              2.5,
                            );
                            layer!.rotation =
                                (startRotation +
                                        details.rotation * 180 / math.pi)
                                    .clamp(-180, 180);
                          }, remember: false);
                        },
                        child: Semantics(
                          label:
                              'Aperçu de l’icône. Déplacez le calque sélectionné avec un doigt, zoomez avec deux doigts.',
                          child: Container(
                            width: dim,
                            height: dim,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(dim * .23),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: IconArt(d, size: dim),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final name = await askText(
                      context,
                      title: 'Nom sous l’icône',
                      initial: d.name,
                    );
                    if (name != null) change(() => d.name = name);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      for (final entry in [
                        'Fond',
                        'Calques',
                        'Réglages',
                        'Effets',
                      ].asMap().entries)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              selected: tab == entry.key,
                              onSelected: (_) =>
                                  setState(() => tab = entry.key),
                              showCheckmark: false,
                              labelPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      switch (tab) {
                        0 => backgroundPanel(),
                        1 => layersPanel(),
                        2 => geometryPanel(),
                        _ => effectsPanel(),
                      },
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : apply,
                            icon: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_to_home_screen_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              busy
                                  ? 'Un instant…'
                                  : 'Appliquer sur l’écran d’accueil',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Raccourci natif ou widget sans badge · choisissez après avoir appuyé sur Appliquer.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  );
  Widget colorRow(String title, int color, ValueChanged<int> setter) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: .4)),
          ),
        ),
        onTap: () async {
          final next = await pickColor(context, color);
          if (next != null) change(() => setter(next));
        },
      );
  Widget slider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> setter, {
    String? label,
  }) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          Text(
            label ?? '${(value * 100).round()} %',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChangeStart: (_) => checkpoint(),
        onChanged: (v) => change(() => setter(v), remember: false),
      ),
    ],
  );
  PriorityApp? get priority => priorityForDesign(d);
  InstalledApp? get installedTarget {
    for (final a in widget.store.apps) {
      if (a.package == d.package) return a;
    }
    return null;
  }

  void applyPriority(IconDesign next) {
    final id = d.id,
        name = d.name,
        pkg = d.package,
        app = d.appName,
        pin = d.pinState;
    change(
      () => d = next.copy()
        ..id = id
        ..name = name
        ..package = pkg
        ..appName = app
        ..pinState = pin,
    );
    selected = 0;
  }

  Widget backgroundPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (priority != null) ...[
        heading('Compositions pour ${priority!.name}'),
        PriorityStyles(
          profile: priority!,
          app: installedTarget,
          platform: widget.store.platform,
          onSelected: applyPriority,
        ),
      ],
      heading('Styles rapides'),
      SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: packs
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p.name),
                    onPressed: () => change(() => p.apply(d)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      heading('Surface'),
      StudioCard(
        child: Column(
          children: [
            colorRow('Couleur de fond', d.background, (c) => d.background = c),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dégradé', style: TextStyle(fontSize: 14)),
              value: d.gradient,
              onChanged: (v) => change(() => d.gradient = v),
            ),
            if (d.gradient) ...[
              colorRow(
                'Deuxième couleur',
                d.background2,
                (c) => d.background2 = c,
              ),
              slider(
                'Direction du dégradé',
                d.gradientAngle,
                0,
                1,
                (v) => d.gradientAngle = v,
                label: '${(d.gradientAngle * 360).round()}°',
              ),
            ],
            slider(
              'Opacité du fond',
              d.backgroundOpacity,
              0,
              1,
              (v) => d.backgroundOpacity = v,
            ),
            slider('Angles arrondis', d.radius, 0, .5, (v) => d.radius = v),
            slider(
              'Bordure',
              d.border,
              0,
              .08,
              (v) => d.border = v,
              label: '${(d.border * 1024).round()} px',
            ),
            if (d.border > 0)
              colorRow(
                'Couleur de bordure',
                d.borderColor,
                (c) => d.borderColor = c,
              ),
          ],
        ),
      ),
      heading('Application associée'),
      StudioCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          title: Text(
            d.appName.isEmpty ? 'Choisir une application' : d.appName,
          ),
          subtitle: const Text('Le raccourci ouvrira cette application'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final a = await chooseApp();
            if (a != null) {
              change(() {
                d.package = a.package;
                d.appName = a.name;
              });
            }
          },
        ),
      ),
      if (d.package.isNotEmpty)
        TextButton.icon(
          onPressed: () async {
            try {
              await widget.store.platform.launch(d.package);
            } catch (e) {
              if (mounted) notice(context, friendlyError(e));
            }
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Vérifier l’ouverture de l’application'),
        ),
    ],
  );
  String layerName(IconLayer l) => switch (l.kind) {
    'image' => 'Image importée',
    'text' => l.value,
    'brand' => brands[l.value] ?? l.value,
    _ => 'Symbole · ${l.value}',
  };
  Widget layersPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: addLayer,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un élément'),
        ),
      ),
      heading('Composition · ${d.layers.length} calques'),
      const Text(
        'Le dernier calque est au premier plan.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 10),
      for (final entry in d.layers.asMap().entries.toList().reversed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudioCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              selected: selected == entry.key,
              selectedTileColor: accent.withValues(alpha: .08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              leading: Icon(
                entry.value.kind == 'image'
                    ? Icons.image_outlined
                    : entry.value.kind == 'text'
                    ? Icons.text_fields_rounded
                    : Icons.auto_awesome_rounded,
              ),
              title: Text(
                layerName(entry.value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: selected == entry.key
                  ? const Text('Sélectionné', style: TextStyle(fontSize: 11))
                  : null,
              onTap: () => setState(() => selected = entry.key),
              trailing: PopupMenuButton<String>(
                tooltip: 'Actions du calque',
                onSelected: (action) {
                  if (action == 'delete') {
                    change(() {
                      d.layers.removeAt(entry.key);
                      selected = selected.clamp(
                        0,
                        math.max(0, d.layers.length - 1),
                      );
                    });
                  }
                  if (action == 'duplicate') {
                    change(() {
                      final l = IconLayer.fromJson(entry.value.toJson())
                        ..id = newId();
                      d.layers.add(l);
                      selected = d.layers.length - 1;
                    });
                  }
                  if (action == 'up' && entry.key < d.layers.length - 1) {
                    change(() {
                      final l = d.layers.removeAt(entry.key);
                      d.layers.insert(entry.key + 1, l);
                      selected = entry.key + 1;
                    });
                  }
                  if (action == 'down' && entry.key > 0) {
                    change(() {
                      final l = d.layers.removeAt(entry.key);
                      d.layers.insert(entry.key - 1, l);
                      selected = entry.key - 1;
                    });
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Dupliquer'),
                  ),
                  if (entry.key < d.layers.length - 1)
                    const PopupMenuItem(
                      value: 'up',
                      child: Text('Passer devant'),
                    ),
                  if (entry.key > 0)
                    const PopupMenuItem(
                      value: 'down',
                      child: Text('Passer derrière'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (layer?.kind == 'text')
        TextButton.icon(
          onPressed: () async {
            final text = await askText(
              context,
              title: 'Modifier le texte',
              initial: layer!.value,
              maxLength: 24,
            );
            if (text != null) change(() => layer!.value = text);
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Modifier le texte'),
        ),
      if (layer != null)
        TextButton.icon(
          onPressed: () => setState(() => tab = 2),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Régler le calque sélectionné'),
        ),
    ],
  );
  Widget noLayer() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Text('Ajoutez un élément pour commencer.'),
        const SizedBox(height: 12),
        TextButton(onPressed: addLayer, child: const Text('Ajouter un calque')),
      ],
    ),
  );
  Widget geometryPanel() {
    final l = layer;
    if (l == null) return noLayer();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(layerName(l)),
        StudioCard(
          child: Column(
            children: [
              slider('Taille / zoom', l.size, .05, 2.5, (v) => l.size = v),
              slider('Position horizontale', l.x, -.2, 1.2, (v) => l.x = v),
              slider('Position verticale', l.y, -.2, 1.2, (v) => l.y = v),
              slider(
                'Rotation',
                l.rotation,
                -180,
                180,
                (v) => l.rotation = v,
                label: '${l.rotation.round()}°',
              ),
              slider('Opacité', l.opacity, 0, 1, (v) => l.opacity = v),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => change(() {
                        l.x = .5;
                        l.y = .5;
                        l.rotation = 0;
                      }),
                      child: const Text('Centrer'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => change(() => l.size = .65),
                      child: const Text('Taille standard'),
                    ),
                  ),
                ],
              ),
              if (l.kind == 'text')
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Texte en gras',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: l.bold,
                  onChanged: (v) => change(() => l.bold = v),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'L’aperçu découpe les éléments aux limites de l’icône. Agrandissez et déplacez votre image pour choisir le cadrage.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget effectsPanel() {
    final l = layer;
    if (l == null) return noLayer();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(layerName(l)),
        StudioCard(
          child: Column(
            children: [
              if (l.kind == 'image')
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Coloriser l’image',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: l.tint,
                  onChanged: (v) => change(() => l.tint = v),
                ),
              colorRow('Couleur / lumière', l.color, (c) => l.color = c),
              slider('Intensité du néon', l.glow, 0, 1, (v) => l.glow = v),
              slider('Ombre', l.shadow, 0, 1, (v) => l.shadow = v),
              slider('Contour', l.stroke, 0, 1, (v) => l.stroke = v),
            ],
          ),
        ),
        if (l.kind == 'image') ...[
          heading('Transformer l’image'),
          const Text(
            'Pour un néon sur le dessin, utilisez Contours lumineux. Pour garder la photo, réglez seulement la lueur.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Contours lumineux'),
                onPressed: () => processImage('edges'),
              ),
              ActionChip(
                label: const Text('Retirer le fond noir'),
                onPressed: () => processImage('removeBlack'),
              ),
              ActionChip(
                label: const Text('Retirer le fond blanc'),
                onPressed: () => processImage('removeWhite'),
              ),
              ActionChip(
                label: const Text('Image originale'),
                onPressed: () => change(() {
                  l.value = l.sourcePath.isEmpty ? l.value : l.sourcePath;
                  l.tint = false;
                }),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Le retrait du fond utilise sa luminosité ; ce n’est pas un détourage automatique du sujet.',
              style: TextStyle(fontSize: 11, height: 1.5, color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> processImage(String mode) async {
    final l = layer;
    if (l == null) return;
    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ThresholdSheet(mode),
    );
    if (amount == null || !mounted) return;
    setState(() => busy = true);
    try {
      final path = await widget.store.platform.process(
        l.sourcePath.isEmpty ? l.value : l.sourcePath,
        mode,
        amount,
      );
      if (mounted) {
        change(() {
          l.value = path;
          if (mode == 'edges') {
            l.tint = true;
            l.glow = .6;
            l.color = 0xffff375f;
          }
        });
      }
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addLayer() async {
    if (d.layers.length >= 20) {
      notice(context, '20 calques maximum par icône.');
      return;
    }
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Ajouter un élément',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final e in {
              'image': 'Image de la galerie',
              'brand': 'Logo d’application',
              'symbol': 'Symbole',
              'text': 'Texte ou initiales',
            }.entries)
              ListTile(
                title: Text(e.value),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    try {
      IconLayer? next;
      if (type == 'image') {
        setState(() => busy = true);
        final path = await widget.store.platform.importImage();
        if (path != null) {
          next = IconLayer(
            kind: 'image',
            value: path,
            sourcePath: path,
            tint: false,
          );
        }
      }
      if (!mounted) return;
      if (type == 'text') {
        final text = await askText(
          context,
          title: 'Texte ou initiales',
          initial: '',
          maxLength: 24,
        );
        if (text != null) next = IconLayer(kind: 'text', value: text, size: .7);
      }
      if ((type == 'brand' || type == 'symbol') && mounted) {
        final value = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) => SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    type == 'brand' ? 'Logos d’applications' : 'Symboles',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 105,
                          mainAxisExtent: 100,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: type == 'brand' ? brands.length : symbols.length,
                    itemBuilder: (ctx, i) {
                      final key = (type == 'brand' ? brands.keys : symbols.keys)
                          .elementAt(i);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(ctx, key),
                        child: StudioCard(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (type == 'brand')
                                IconArt(
                                  IconDesign(
                                    backgroundOpacity: 0,
                                    layers: [
                                      IconLayer(
                                        kind: 'brand',
                                        value: key,
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.onSurface.toARGB32(),
                                        size: .9,
                                      ),
                                    ],
                                  ),
                                  size: 38,
                                )
                              else
                                Icon(symbols[key], size: 34),
                              const SizedBox(height: 8),
                              Text(
                                type == 'brand' ? brands[key]! : key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        if (value != null) next = IconLayer(kind: type, value: value);
      }
      if (next != null && mounted) {
        change(() {
          d.layers.add(next!);
          selected = d.layers.length - 1;
          tab = 2;
        });
      }
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class ThresholdSheet extends StatefulWidget {
  final String mode;
  const ThresholdSheet(this.mode, {super.key});
  @override
  State<ThresholdSheet> createState() => _ThresholdSheetState();
}

class _ThresholdSheetState extends State<ThresholdSheet> {
  double value = .25;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.mode == 'edges' ? 'Contours lumineux' : 'Retirer un fond',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ajustez la sensibilité. Vous pouvez annuler la transformation ou revenir à l’image originale.',
          ),
          const SizedBox(height: 16),
          Text('Sensibilité : ${(value * 100).round()} %'),
          Slider(
            value: value,
            min: .03,
            max: 1,
            onChanged: (v) => setState(() => value = v),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Transformer'),
            ),
          ),
        ],
      ),
    ),
  );
}

class AppPicker extends StatefulWidget {
  final StudioStore store;
  const AppPicker(this.store, {super.key});
  @override
  State<AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<AppPicker> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final apps = widget.store.apps
        .where((a) => a.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Associer une application',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: apps.isEmpty
                  ? const Center(child: Text('Aucune application trouvée.'))
                  : ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(apps[i].name),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(ctx, apps[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
