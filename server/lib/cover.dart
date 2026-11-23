import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

final Map<String, Uint8List> _cache = {};

/// Abstract cover art for a story: a soft two-colour gradient with a few
/// blurred circles. Deterministic per [id], ~1200x800, small JPEG.
Uint8List coverJpg(String id) => _cache.putIfAbsent(id, () => _draw(id));

Uint8List _draw(String id) {
  final rng = Random(_stableHash(id));
  final palette = _palettes[rng.nextInt(_palettes.length)];
  final a = palette[0], b = palette[1], accent = palette[2];

  // Paint small, blur, then scale up: cheap, and naturally soft.
  const w = 240, h = 160;
  final canvas = img.Image(width: w, height: h);
  final angle = rng.nextDouble() * pi;
  final dx = cos(angle), dy = sin(angle);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = (((x / w - 0.5) * dx + (y / h - 0.5) * dy) + 0.75) / 1.5;
      final c = t.clamp(0.0, 1.0);
      canvas.setPixelRgb(
        x,
        y,
        (a[0] + (b[0] - a[0]) * c).round(),
        (a[1] + (b[1] - a[1]) * c).round(),
        (a[2] + (b[2] - a[2]) * c).round(),
      );
    }
  }
  final shapes = 3 + rng.nextInt(3);
  for (var i = 0; i < shapes; i++) {
    final colour = i.isEven ? accent : (i % 3 == 0 ? a : b);
    img.fillCircle(
      canvas,
      x: rng.nextInt(w),
      y: rng.nextInt(h),
      radius: 18 + rng.nextInt(52),
      color: img.ColorRgba8(colour[0], colour[1], colour[2], 90 + rng.nextInt(80)),
      antialias: true,
    );
  }
  final soft = img.gaussianBlur(canvas, radius: 6);
  final big = img.copyResize(soft,
      width: 1200, height: 800, interpolation: img.Interpolation.linear);
  return img.encodeJpg(big, quality: 78);
}

int _stableHash(String s) {
  var h = 17;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// Calm, editorial palettes: [from, to, accent].
const _palettes = [
  [[242, 224, 205], [196, 92, 72], [250, 190, 120]],
  [[214, 228, 225], [52, 96, 110], [238, 200, 150]],
  [[236, 230, 246], [92, 78, 140], [240, 160, 150]],
  [[248, 236, 214], [176, 132, 64], [120, 150, 120]],
  [[222, 234, 214], [70, 112, 80], [236, 212, 140]],
  [[230, 230, 236], [40, 48, 70], [210, 120, 90]],
  [[250, 226, 226], [150, 60, 80], [255, 200, 170]],
];
