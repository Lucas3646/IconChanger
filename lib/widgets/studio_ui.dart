import 'package:flutter/material.dart';

const accent = Color(0xff007aff);

class StudioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class PageTitle extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const PageTitle(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

void notice(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

String friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('MISSING_APP')) {
    return 'Cette application n’est plus installée. Choisissez une autre application.';
  }
  if (text.contains('RATE_LIMIT')) {
    return 'Android limite les mises à jour. Réessayez dans un instant.';
  }
  if (text.contains('UNSUPPORTED')) {
    return 'Votre écran d’accueil ne permet pas l’ajout de raccourcis.';
  }
  if (text.contains('FILE') || text.contains('IMAGE')) {
    return 'Impossible de lire cette image. Essayez un fichier PNG ou JPG.';
  }
  return 'L’opération n’a pas abouti. Réessayez.';
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  int maxLength = 40,
}) async {
  final controller = TextEditingController(text: initial);
  final answer = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Votre texte'),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: const Text('Valider'),
        ),
      ],
    ),
  );
  // Dialog routes animate after the result; the controller is released next frame.
  Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  return answer;
}

const palette = [
  0xffffffff,
  0xff000000,
  0xff1c1c1e,
  0xff636366,
  0xff007aff,
  0xff40a9ff,
  0xff5856d6,
  0xffbf72ff,
  0xffff375f,
  0xffff453a,
  0xffff9f0a,
  0xffffd60a,
  0xff30d158,
  0xff64d2ff,
  0xffe9dcff,
  0xffffe6dc,
  0xffc9eadb,
];
Future<int?> pickColor(BuildContext context, int initial) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ColorPickerSheet(initial),
    );

class ColorPickerSheet extends StatefulWidget {
  final int initial;
  const ColorPickerSheet(this.initial, {super.key});
  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late HSVColor hsv;
  late TextEditingController hex;
  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(Color(widget.initial));
    hex = TextEditingController(
      text: widget.initial
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase(),
    );
  }

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void update(HSVColor next) {
    setState(() {
      hsv = next;
      hex.text = hsv
          .toColor()
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre couleur',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: hsv.toColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: .3)),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: palette
                .map(
                  (c) => Semantics(
                    label: 'Couleur ${c.toRadixString(16)}',
                    button: true,
                    child: InkWell(
                      onTap: () => update(HSVColor.fromColor(Color(c))),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hsv.toColor().toARGB32() == c
                                ? accent
                                : Colors.grey.withValues(alpha: .3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _slider('Teinte', hsv.hue, 360, (v) => update(hsv.withHue(v))),
          _slider(
            'Saturation',
            hsv.saturation,
            1,
            (v) => update(hsv.withSaturation(v)),
          ),
          _slider('Luminosité', hsv.value, 1, (v) => update(hsv.withValue(v))),
          TextField(
            controller: hex,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Code couleur',
              prefixText: '#',
            ),
            onChanged: (v) {
              if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v)) {
                setState(
                  () => hsv = HSVColor.fromColor(
                    Color(int.parse('ff$v', radix: 16)),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, hsv.toColor().toARGB32()),
              child: const Text('Choisir cette couleur'),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _slider(
    String title,
    double value,
    double max,
    ValueChanged<double> change,
  ) => Row(
    children: [
      SizedBox(width: 90, child: Text(title)),
      Expanded(
        child: Slider(value: value.clamp(0, max), max: max, onChanged: change),
      ),
    ],
  );
}
