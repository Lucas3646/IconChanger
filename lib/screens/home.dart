import 'dart:io';
import 'package:flutter/material.dart';
import '../models/design.dart';
import '../models/priority_apps.dart';
import '../services/priority_art.dart';
import 'priority_catalog.dart';
import '../services/store.dart';
import '../widgets/icon_art.dart';
import '../widgets/studio_ui.dart';
import 'editor.dart';

class Onboarding extends StatefulWidget {
  final StudioStore store;
  const Onboarding(this.store, {super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: IconArt(
                IconDesign(
                  gradient: true,
                  background: 0xff007aff,
                  background2: 0xffaf52de,
                  layers: [IconLayer()],
                ),
                size: 116,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'Votre écran.\nVotre signature.',
              style: TextStyle(
                fontSize: 40,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Créez des icônes qui vous ressemblent, simplement.',
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 30),
            const StudioCard(
              child: Column(
                children: [
                  _OnboardRow(
                    Icons.add_to_home_screen_rounded,
                    'Un raccourci sur votre écran d’accueil',
                    'L’icône originale reste dans la liste des applications.',
                  ),
                  SizedBox(height: 20),
                  _OnboardRow(
                    Icons.touch_app_rounded,
                    'Vous confirmez l’ajout',
                    'Android peut afficher une confirmation et un petit badge.',
                  ),
                  SizedBox(height: 20),
                  _OnboardRow(
                    Icons.lock_outline_rounded,
                    'Tout reste sur votre téléphone',
                    'Sans compte, sans publicité et sans collecte de données.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await widget.store.finishOnboarding();
                        } catch (e) {
                          if (context.mounted) {
                            notice(context, friendlyError(e));
                            setState(() => busy = false);
                          }
                        }
                      },
                child: Text(busy ? 'Ouverture…' : 'Créer ma première icône'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardRow extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _OnboardRow(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: accent, size: 26),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class HomeScreen extends StatefulWidget {
  final StudioStore store;
  const HomeScreen(this.store, {super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool openingApp = false;
  int index = 0;
  String search = '', filter = 'Toutes';
  StudioStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.refreshApps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshApps();
  }

  Future<void> edit(IconDesign d) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EditorScreen(store, d)),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: [_applications(), _explore(), _studio(), _gallery()][index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apps_rounded),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Explorer',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_rounded),
            label: 'Mes icônes',
          ),
        ],
      ),
    ),
  );
  Future<void> openApp(InstalledApp app) async {
    if (openingApp) return;
    openingApp = true;
    try {
      final profile = priorityForApp(app);
      final d = profile == null
          ? designForApp(app)
          : await PriorityArt.build(
              store.platform,
              profile,
              app,
              PriorityStyle.signature,
            );
      if (mounted) await edit(d);
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    } finally {
      openingApp = false;
    }
  }

  Widget _applications() {
    final saved = store.designs.map((d) => d.package).toSet();
    final apps = store.apps
        .where(
          (a) =>
              ('${a.name} ${a.package}').toLowerCase().contains(
                search.toLowerCase(),
              ) &&
              (filter != 'Personnalisées' || saved.contains(a.package)) &&
              (filter != 'Votre sélection' || priorityForApp(a) != null) &&
              (filter != 'Téléchargées' || !a.system),
        )
        .toList();
    return Column(
      children: [
        PageTitle(
          'Applications',
          'Une nouvelle allure, en quelques gestes.',
          trailing: IconButton(
            tooltip: 'Réglages',
            onPressed: _settings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher une application',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children:
                ['Toutes', 'Votre sélection', 'Téléchargées', 'Personnalisées']
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: filter == f,
                          onSelected: (_) => setState(() => filter = f),
                          showCheckmark: false,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: store.loadingApps && store.apps.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : store.appsError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(store.appsError!),
                      TextButton(
                        onPressed: store.refreshApps,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : apps.isEmpty
              ? const Center(child: Text('Aucune application trouvée.'))
              : RefreshIndicator(
                  onRefresh: store.refreshApps,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: apps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final a = apps[i];
                      return StudioCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(a.icon),
                              width: 48,
                              height: 48,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.android_rounded),
                            ),
                          ),
                          title: Text(
                            a.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            saved.contains(a.package)
                                ? 'Création enregistrée'
                                : 'Personnaliser l’icône',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => openApp(a),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _explore() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PriorityCatalogScreen(store)),
            ),
            child: StudioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Votre sélection',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '31 applications · 4 compositions chacune',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['instagram', 'youtube', 'shazam', 'spotify'].map(
                      (id) {
                        final p = priorityApps.firstWhere((p) => p.id == id);
                        return IconArt(p.preview(PriorityStyle.neon), size: 56);
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(
        child: PageTitle(
          'Explorer',
          'Des collections à adapter à votre style.',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        sliver: SliverList.separated(
          itemCount: packs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final p = packs[i];
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PackScreen(store, p)),
              ),
              child: StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['instagram', 'youtube', 'spotify', 'tiktok']
                          .map((b) {
                            final d = IconDesign(
                              layers: [IconLayer(kind: 'brand', value: b)],
                            );
                            p.apply(d);
                            return IconArt(d, size: 58);
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
  Widget _studio() => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      const PageTitle('Studio', 'Une idée. Une icône. À vous de créer.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            StudioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: IconArt(
                        IconDesign(
                          background: 0xffdce9fa,
                          background2: 0xffebe0fa,
                          gradient: true,
                          layers: [IconLayer(color: 0xff007aff, glow: .15)],
                        ),
                        size: 130,
                      ),
                    ),
                  ),
                  const Text(
                    'Une page blanche,\ninfiniment personnelle.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Composez avec des images, du texte et des symboles. Ajustez chaque détail.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => edit(IconDesign()),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Créer une icône'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            StudioCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: accent,
                ),
                title: const Text(
                  'Partir d’une image',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Importer, recadrer, transformer'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  try {
                    final path = await store.platform.importImage();
                    if (path != null && mounted) {
                      edit(
                        IconDesign(
                          layers: [
                            IconLayer(
                              kind: 'image',
                              value: path,
                              sourcePath: path,
                              tint: false,
                              size: .85,
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) notice(context, friendlyError(e));
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Les créations sont sauvegardées localement.\nVous pouvez les exporter en PNG jusqu’à 2048 px.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _gallery() => Column(
    children: [
      const PageTitle(
        'Mes icônes',
        'Votre collection, toujours à portée de main.',
      ),
      Expanded(
        child: store.designs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.collections_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('Votre collection commence ici.'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => edit(IconDesign()),
                      child: const Text('Créer une icône'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 205,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: store.designs.length,
                itemBuilder: (context, i) {
                  final d = store.designs[i];
                  final missing =
                      d.package.isNotEmpty &&
                      !store.apps.any((a) => a.package == d.package);
                  return InkWell(
                    onTap: () => edit(d.copy()),
                    borderRadius: BorderRadius.circular(24),
                    child: StudioCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 28,
                              child: PopupMenuButton<String>(
                                tooltip: 'Options',
                                padding: EdgeInsets.zero,
                                onSelected: (v) => _galleryAction(v, d),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'duplicate',
                                    child: Text('Dupliquer'),
                                  ),
                                  PopupMenuItem(
                                    value: 'original',
                                    child: Text('Créer l’icône originale'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer la création'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconArt(d, size: 80),
                          const SizedBox(height: 10),
                          Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            missing
                                ? 'Application absente'
                                : d.pinState == 'pinned'
                                ? 'Raccourci ajouté'
                                : d.pinState == 'pending'
                                ? 'Ajout à confirmer'
                                : 'Enregistrée',
                            style: TextStyle(
                              fontSize: 11,
                              color: missing
                                  ? Colors.orange
                                  : Theme.of(
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
  );
  Future<void> _galleryAction(String action, IconDesign d) async {
    try {
      if (action == 'duplicate') {
        final copy = d.copy(newIdentity: true)..name = '${d.name} · variante';
        await store.save(copy);
      }
      if (action == 'original') {
        final matches = store.apps.where((a) => a.package == d.package);
        if (matches.isEmpty) {
          if (mounted) {
            notice(
              context,
              'Associez cette création à une application installée.',
            );
          }
          return;
        }
        final a = matches.first;
        await edit(
          IconDesign(
            name: a.name,
            package: a.package,
            appName: a.name,
            backgroundOpacity: 0,
            radius: 0,
            layers: [
              IconLayer(
                kind: 'image',
                value: a.icon,
                sourcePath: a.icon,
                tint: false,
                size: 1,
              ),
            ],
          ),
        );
      }
      if (action == 'delete' && mounted) {
        final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer cette création ?'),
            content: const Text(
              'Le raccourci déjà ajouté à l’écran d’accueil reste en place. Vous pouvez le retirer depuis cet écran.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (yes == true) await store.delete(d.id);
      }
    } catch (e) {
      if (mounted) notice(context, friendlyError(e));
    }
  }

  void _settings() => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Icon Studio',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('Version 1.0.1 · Votre studio privé'),
            const SizedBox(height: 20),
            const Text('Apparence'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children:
                  {'system': 'Automatique', 'light': 'Clair', 'dark': 'Sombre'}
                      .entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.value),
                          selected: store.theme == e.key,
                          onSelected: (_) async {
                            try {
                              await store.setTheme(e.key);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (err) {
                              if (ctx.mounted) notice(ctx, friendlyError(err));
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Icon Studio ajoute des raccourcis : les icônes système ne sont pas remplacées. Le badge et la forme finale dépendent de l’écran d’accueil.\n\nRetirez les anciens raccourcis depuis votre écran d’accueil. Une application désinstallée ne pourra plus être ouverte.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            if (store.loadWarning != null) Text(store.loadWarning!),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

class PackScreen extends StatelessWidget {
  final StudioStore store;
  final IconPack pack;
  const PackScreen(this.store, this.pack, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(pack.name)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${pack.subtitle}\nChoisissez une icône, puis personnalisez-la.',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisExtent: 130,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: brands.length,
            itemBuilder: (ctx, i) {
              final entry = brands.entries.elementAt(i);
              final apps = store.apps.where(
                (a) => brandPackages[a.package] == entry.key,
              );
              final d = IconDesign(
                name: entry.value,
                package: apps.isEmpty ? '' : apps.first.package,
                appName: apps.isEmpty ? '' : apps.first.name,
                layers: [IconLayer(kind: 'brand', value: entry.key)],
              );
              pack.apply(d);
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditorScreen(store, d)),
                ),
                borderRadius: BorderRadius.circular(20),
                child: StudioCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconArt(d, size: 62),
                      const SizedBox(height: 12),
                      Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
