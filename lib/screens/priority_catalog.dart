import 'package:flutter/material.dart';
import '../models/design.dart';
import '../models/priority_apps.dart';
import '../services/store.dart';
import '../widgets/icon_art.dart';
import '../widgets/priority_styles.dart';
import '../widgets/studio_ui.dart';
import 'editor.dart';

class PriorityCatalogScreen extends StatefulWidget {
  final StudioStore store;
  const PriorityCatalogScreen(this.store, {super.key});
  @override
  State<PriorityCatalogScreen> createState() => _PriorityCatalogScreenState();
}

class _PriorityCatalogScreenState extends State<PriorityCatalogScreen> {
  String search = '';
  bool onlyInstalled = false;
  @override
  Widget build(BuildContext context) {
    final entries = priorityApps
        .where(
          (p) =>
              normalizeAppName(p.name).contains(normalizeAppName(search)) &&
              (!onlyInstalled ||
                  widget.store.apps.any((a) => priorityForApp(a)?.id == p.id)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Votre sélection')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Text(
              '31 applications, chacune avec sa palette, ses proportions et quatre compositions modifiables.',
              style: TextStyle(height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Trouver une application',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Seulement celles installées',
                style: TextStyle(fontSize: 13),
              ),
              value: onlyInstalled,
              onChanged: (v) => setState(() => onlyInstalled = v),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Aucune application trouvée.'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 185,
                          mainAxisExtent: 176,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final p = entries[index];
                      final matches = widget.store.apps
                          .where((a) => priorityForApp(a)?.id == p.id)
                          .toList();
                      final d = p.preview(
                        PriorityStyle.signature,
                        app: matches.isEmpty ? null : matches.first,
                      );
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PriorityDetailScreen(widget.store, p),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: StudioCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconArt(d, size: 66),
                              const SizedBox(height: 12),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                matches.isEmpty
                                    ? 'À associer'
                                    : 'Application détectée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
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
    );
  }
}

class PriorityDetailScreen extends StatefulWidget {
  final StudioStore store;
  final PriorityApp profile;
  const PriorityDetailScreen(this.store, this.profile, {super.key});
  @override
  State<PriorityDetailScreen> createState() => _PriorityDetailScreenState();
}

class _PriorityDetailScreenState extends State<PriorityDetailScreen> {
  InstalledApp? app;
  @override
  void initState() {
    super.initState();
    final matches = widget.store.apps
        .where((a) => priorityForApp(a)?.id == widget.profile.id)
        .toList();
    if (matches.length == 1) app = matches.first;
  }

  Future<void> associate() async {
    await widget.store.refreshApps();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<InstalledApp>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AppPicker(widget.store),
    );
    if (chosen != null && mounted) setState(() => app = chosen);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.profile.name)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        StudioCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(app?.name ?? 'Associer une application'),
            subtitle: Text(
              app == null
                  ? 'L’icône du téléphone est utilisée pour les logos sans dessin intégré.'
                  : 'Le raccourci ou le widget ouvrira cette application.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: associate,
          ),
        ),
        const SizedBox(height: 24),
        PriorityStyles(
          profile: widget.profile,
          app: app,
          platform: widget.store.platform,
          onSelected: (d) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditorScreen(widget.store, d)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Les formats sans badge utilisent un widget. La création reste locale et fonctionne hors ligne.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );
}
