import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Offline handwriting check — no API, no ML model download.
///
/// Rasterizes the target glyph and the user's strokes to identical low-res
/// ink masks, then scores how well they overlap (F1 of pixel coverage:
/// recall = did you cover the glyph, precision = did you stay on it).
///
/// ponytail: pixel overlap, not stroke-order recognition. It's forgiving and
/// font-shaped, good enough to gate practice. `passThreshold` is the tuning
/// knob — raise it for stricter matching, lower if honest attempts get rejected.
const int _res = 64;
const double passThreshold = 0.42;

Future<Uint8List> _maskWH(int w, int h, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final img = await recorder.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  final rgba = data!.buffer.asUint8List();
  final mask = Uint8List(w * h);
  for (var i = 0; i < mask.length; i++) {
    mask[i] = rgba[i * 4 + 3] > 40 ? 1 : 0; // alpha channel = ink
  }
  return mask;
}

/// F1 overlap of two ink masks, 0..1. Pure — unit-testable without rendering.
double maskF1(Uint8List target, Uint8List user) {
  var inter = 0, t = 0, u = 0;
  for (var i = 0; i < target.length; i++) {
    if (target[i] == 1) t++;
    if (user[i] == 1) u++;
    if (target[i] == 1 && user[i] == 1) inter++;
  }
  if (t == 0 || u == 0) return 0;
  final recall = inter / t, precision = inter / u;
  return 2 * recall * precision / (recall + precision);
}

/// Score in 0..1 for how well [strokes] (normalized 0..1) match [text].
/// [cells] widens the comparison canvas for multi-character words so the target
/// word and the user's writing are rasterized at the same aspect ratio.
Future<double> matchScore(String text, List<List<Offset>> strokes,
    {int cells = 1}) async {
  if (strokes.every((s) => s.isEmpty)) return 0;
  final w = _res * cells, h = _res;

  final target = await _maskWH(w, h, (c) {
    // One glyph per cell, matching how the user writes across the squares.
    for (var i = 0; i < text.length && i < cells; i++) {
      var tp = _layout(text[i], h * 0.82);
      if (tp.width > _res) tp = _layout(text[i], h * 0.82 * _res / tp.width);
      tp.paint(c, Offset(_res * i + (_res - tp.width) / 2, (h - tp.height) / 2));
    }
  });

  final user = await _maskWH(w, h, (c) {
    final p = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = h * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        c.drawCircle(Offset(s.first.dx * w, s.first.dy * h), p.strokeWidth / 2,
            Paint()..color = p.color);
        continue;
      }
      final path = Path()..moveTo(s.first.dx * w, s.first.dy * h);
      for (final pt in s.skip(1)) {
        path.lineTo(pt.dx * w, pt.dy * h);
      }
      c.drawPath(path, p);
    }
  });

  return maskF1(target, user);
}

TextPainter _layout(String text, double fontSize) => TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontSize: fontSize, color: const Color(0xFF000000), height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
