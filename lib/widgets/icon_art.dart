import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/design.dart';

class ArtImages {
  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<ui.Image>> _pending = {};
  static String key(IconLayer l) => '${l.kind}:${l.value}';
  static ui.Image? get(IconLayer l) => _images[key(l)];
  static Future<void> load(IconDesign d) async {
    await Future.wait(
      d.layers.where((l) => l.kind == 'image' || l.kind == 'brand').map((
        l,
      ) async {
        final k = key(l);
        if (_images.containsKey(k)) return;
        final image = await (_pending[k] ??= _load(l));
        _images[k] = image;
      }),
    );
  }

  static Future<ui.Image> _load(IconLayer l) async {
    if (l.kind == 'brand') {
      final picture = await vg.loadPicture(
        SvgAssetLoader('assets/brands/${l.value}.svg'),
        null,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Transparent padding prevents texture-edge seams when tinting and blurring.
      canvas.drawColor(Colors.transparent, BlendMode.src);
      canvas.translate(8, 8);
      canvas.scale(496 / picture.size.width, 496 / picture.size.height);
      canvas.drawPicture(picture.picture);
      final recorded = recorder.endRecording();
      final image = await recorded.toImage(512, 512);
      recorded.dispose();
      picture.picture.dispose();
      return image;
    }
    final bytes = await File(l.value).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1024,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<Uint8List> png(
    IconDesign d, {int resolution = 1024, bool launcherForeground = false}
  ) async {
    await load(d);
    final recorder = ui.PictureRecorder();
    IconArtPainter(
      d, launcherForeground: launcherForeground,
    ).paint(Canvas(recorder), Size.square(resolution.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(resolution, resolution);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw StateError('Export PNG impossible');
    return bytes.buffer.asUint8List();
  }
}

class IconArt extends StatefulWidget {
  final IconDesign design;
  final double size;
  const IconArt(this.design, {super.key, this.size = 64});
  @override
  State<IconArt> createState() => _IconArtState();
}

class _IconArtState extends State<IconArt> {
  String signature = '';
  bool failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(IconArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() {
    final next = widget.design.layers.map(ArtImages.key).join('|');
    if (next == signature) return;
    signature = next;
    failed = false;
    ArtImages.load(widget.design)
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) {
          if (mounted) setState(() => failed = true);
        });
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: failed
        ? const Icon(Icons.broken_image_outlined)
        : CustomPaint(painter: IconArtPainter(widget.design)),
  );
}

class IconArtPainter extends CustomPainter {
  final IconDesign design;
  final bool launcherForeground;
  IconArtPainter(this.design, {this.launcherForeground = false});
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final bounds = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(s * design.radius),
    );
    canvas.save();
    if (!launcherForeground) canvas.clipRRect(shape);
    final bg = Paint()
      ..color = Color(
        design.background,
      ).withValues(alpha: design.backgroundOpacity);
    if (design.gradient) {
      final a = design.gradientAngle * math.pi * 2;
      bg.shader = ui.Gradient.linear(
        Offset(s / 2 - math.cos(a) * s / 2, s / 2 - math.sin(a) * s / 2),
        Offset(s / 2 + math.cos(a) * s / 2, s / 2 + math.sin(a) * s / 2),
        [
          Color(design.background).withValues(alpha: design.backgroundOpacity),
          Color(design.background2).withValues(alpha: design.backgroundOpacity),
        ],
      );
    }
    if (!launcherForeground) canvas.drawRect(bounds, bg);
    for (final l in design.layers) {
      canvas.save();
      canvas.translate(l.x * s, l.y * s);
      canvas.rotate(l.rotation * math.pi / 180);
      final dim = s * l.size;
      final color = Color(l.color).withValues(alpha: l.opacity);
      final image = ArtImages.get(l);
      if (l.kind == 'brand' || l.kind == 'image') {
        if (image != null) {
          final source = Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          );
          final ratio = image.width / image.height;
          final target = Rect.fromCenter(
            center: Offset.zero,
            width: ratio >= 1 ? dim : dim * ratio,
            height: ratio >= 1 ? dim / ratio : dim,
          );
          void draw(Paint p) => canvas.drawImageRect(
            image,
            source,
            target,
            p..filterQuality = FilterQuality.low,
          );
          if (l.shadow > 0) {
            canvas.save();
            canvas.translate(0, s * .025);
            draw(
              Paint()
                ..colorFilter = ColorFilter.mode(
                  Colors.black.withValues(alpha: .65 * l.opacity),
                  BlendMode.srcIn,
                )
                ..imageFilter = ui.ImageFilter.blur(
                  sigmaX: s * l.shadow * .035,
                  sigmaY: s * l.shadow * .035,
                ),
            );
            canvas.restore();
          }
          if (l.glow > 0) {
            for (final scale in [1.0, .35]) {
              draw(
                Paint()
                  ..colorFilter = ColorFilter.mode(
                    color.withValues(alpha: l.opacity * .85),
                    BlendMode.srcIn,
                  )
                  ..imageFilter = ui.ImageFilter.blur(
                    sigmaX: s * l.glow * .065 * scale,
                    sigmaY: s * l.glow * .065 * scale,
                  ),
              );
            }
          }
          if (l.stroke > 0) {
            draw(
              Paint()
                ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
                ..imageFilter = ui.ImageFilter.dilate(
                  radiusX: s * l.stroke * .025,
                  radiusY: s * l.stroke * .025,
                ),
            );
          }
          draw(
            Paint()
              ..color = Colors.white.withValues(alpha: l.opacity)
              ..colorFilter = l.tint || l.kind == 'brand'
                  ? ColorFilter.mode(color, BlendMode.srcIn)
                  : null,
          );
        }
      } else {
        final symbol = symbols[l.value] ?? Icons.auto_awesome_rounded;
        final text = l.kind == 'text'
            ? l.value
            : String.fromCharCode(symbol.codePoint);
        final style = TextStyle(
          color: color,
          fontSize: l.kind == 'text' ? dim * .6 : dim,
          fontWeight: l.bold ? FontWeight.w700 : FontWeight.w400,
          fontFamily: l.kind == 'symbol' ? symbol.fontFamily : null,
          package: l.kind == 'symbol' ? symbol.fontPackage : null,
          shadows: [
            if (l.shadow > 0)
              Shadow(
                color: Colors.black.withValues(alpha: .6),
                offset: Offset(0, s * .025),
                blurRadius: s * l.shadow * .07,
              ),
            if (l.glow > 0) ...[
              Shadow(color: color, blurRadius: s * l.glow * .13),
              Shadow(color: color, blurRadius: s * l.glow * .035),
            ],
          ],
        );
        if (l.stroke > 0) {
          final outline = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(
                color: null,
                foreground: Paint()
                  ..color = color
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = s * l.stroke * .04,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(maxWidth: s * 2);
          outline.paint(
            canvas,
            Offset(-outline.width / 2, -outline.height / 2),
          );
        }
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: s * 2);
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      }
      canvas.restore();
    }
    if (design.border > 0) {
      canvas.drawRRect(
        shape.deflate(s * design.border / 2),
        Paint()
          ..color = Color(design.borderColor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * design.border,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(IconArtPainter oldDelegate) => true;
}
