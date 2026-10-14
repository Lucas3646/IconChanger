import 'package:flutter/material.dart';
import '../models/design.dart';
import '../models/priority_apps.dart';
import '../services/platform_service.dart';
import '../services/priority_art.dart';
import 'icon_art.dart';
import 'studio_ui.dart';

class PriorityStyles extends StatefulWidget {
  final PriorityApp profile;
  final InstalledApp? app;
  final AndroidService platform;
  final ValueChanged<IconDesign> onSelected;
  const PriorityStyles({
    super.key,
    required this.profile,
    required this.platform,
    required this.onSelected,
    this.app,
  });
  @override
  State<PriorityStyles> createState() => _PriorityStylesState();
}

class _PriorityStylesState extends State<PriorityStyles> {
  late Future<PreparedPriorityArt> prepared;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(PriorityStyles old) {
    super.didUpdateWidget(old);
    if (old.profile.id != widget.profile.id ||
        old.app?.package != widget.app?.package ||
        old.app?.icon != widget.app?.icon) {
      _prepare();
    }
  }

  void _prepare() {
    prepared = PriorityArt.prepare(widget.platform, widget.profile, widget.app);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PreparedPriorityArt>(
    future: prepared,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return StudioCard(
          child: Column(
            children: [
              const Text('Impossible de préparer les contours de cette image.'),
              TextButton(
                onPressed: () => setState(_prepare),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Préparation du logo et de ses contours…',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }
      final art = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.profile.detail,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.profile.brand == null && widget.app == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Aperçu avec initiales. Associez l’application ou importez son logo pour obtenir le dessin exact.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .91,
            children: PriorityStyle.values.map((style) {
              final d = widget.profile.preview(
                style,
                app: widget.app,
                edgePath: art.edges,
                logoPath: art.logo,
              );
              return Semantics(
                button: true,
                label:
                    'Choisir ${priorityStyleLabels[style]} pour ${widget.profile.name}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => widget.onSelected(d),
                  child: StudioCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconArt(d, size: 58),
                        const SizedBox(height: 12),
                        Text(
                          priorityStyleLabels[style]!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          style == PriorityStyle.signature &&
                                  widget.profile.illustrated
                              ? 'Illustration préservée'
                              : style == PriorityStyle.neon
                              ? 'Contours & halo'
                              : style == PriorityStyle.duo
                              ? 'Deux couleurs'
                              : style == PriorityStyle.porcelain
                              ? 'Surface claire'
                              : 'Palette dédiée',
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
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tous les calques restent modifiables. Ces styles remplacent la composition actuelle ; Annuler permet de la retrouver.',
            style: TextStyle(fontSize: 11, height: 1.5, color: Colors.grey),
          ),
        ],
      );
    },
  );
}
