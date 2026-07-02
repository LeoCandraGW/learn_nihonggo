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

Future<Uint8List> _mask(void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final img = await recorder.endRecording().toImage(_res, _res);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  final rgba = data!.buffer.asUint8List();
  final mask = Uint8List(_res * _res);
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

/// Score in 0..1 for how well [strokes] (normalized 0..1) match [glyph].
Future<double> matchScore(String glyph, List<List<Offset>> strokes) async {
  if (strokes.every((s) => s.isEmpty)) return 0;

  final target = await _mask((c) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: const TextStyle(fontSize: _res * 0.82, color: Color(0xFF000000), height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((_res - tp.width) / 2, (_res - tp.height) / 2));
  });

  final user = await _mask((c) {
    final p = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = _res * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        c.drawCircle(Offset(s.first.dx * _res, s.first.dy * _res), p.strokeWidth / 2,
            Paint()..color = p.color);
        continue;
      }
      final path = Path()..moveTo(s.first.dx * _res, s.first.dy * _res);
      for (final pt in s.skip(1)) {
        path.lineTo(pt.dx * _res, pt.dy * _res);
      }
      c.drawPath(path, p);
    }
  });

  return maskF1(target, user);
}
