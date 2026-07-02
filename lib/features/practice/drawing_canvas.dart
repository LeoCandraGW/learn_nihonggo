import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// Genkō-yōshi (原稿用紙) practice square: the crosshair grid Japanese
/// students write inside. The user inks strokes over an optional faint
/// tracing guide; strokes are captured normalized (0..1) so they persist
/// across any screen size.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.accent,
    this.guide,
    this.initial,
    this.controller,
  });

  /// Script accent color for the ink.
  final Color accent;

  /// Faint glyph drawn behind the grid to trace over (e.g. あ). Null = blank.
  final String? guide;

  /// A previous attempt to preload.
  final DrawingData? initial;

  final DrawingController? controller;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

/// Lets the parent clear / undo / read the current drawing without a setState
/// dance. ChangeNotifier is stdlib — no state-management package needed.
class DrawingController extends ChangeNotifier {
  _DrawingCanvasState? _state;
  void _bind(_DrawingCanvasState s) => _state = s;

  bool get isEmpty => _state?._strokes.every((s) => s.isEmpty) ?? true;
  void clear() => _state?._clear();
  void undo() => _state?._undo();
  DrawingData current() => DrawingData(
      _state?._strokes.where((s) => s.isNotEmpty).toList() ?? const []);

  void _notify() => notifyListeners(); // bridge for the private State
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(this);
    if (widget.initial != null) {
      _strokes.addAll(widget.initial!.strokes.map((s) => List<Offset>.from(s)));
    }
  }

  void _clear() {
    setState(_strokes.clear);
    widget.controller?._notify();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(_strokes.removeLast);
    widget.controller?._notify();
  }

  Offset _norm(Offset local) => _size == Size.zero
      ? Offset.zero
      : Offset((local.dx / _size.width).clamp(0.0, 1.0),
          (local.dy / _size.height).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, c) {
        _size = Size(c.maxWidth, c.maxHeight);
        // Listener (raw pointer) not GestureDetector: pointer events bypass the
        // gesture arena, so drawing here is never stolen by the parent ListView.
        return Listener(
          onPointerDown: (e) => setState(() {
            _strokes.add([_norm(e.localPosition)]);
            widget.controller?._notify();
          }),
          onPointerMove: (e) =>
              setState(() => _strokes.last.add(_norm(e.localPosition))),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Sumi.grid, width: 1.5),
            ),
            child: CustomPaint(
              painter: _CanvasPainter(
                strokes: _strokes,
                guide: widget.guide,
                accent: widget.accent,
              ),
              size: Size.infinite,
            ),
          ),
        );
      }),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({required this.strokes, required this.guide, required this.accent});

  final List<List<Offset>> strokes;
  final String? guide;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    if (guide != null) _paintGuide(canvas, size);
    _paintStrokes(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Sumi.grid.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    // Dashed crosshair through the center — the defining genkō-yōshi mark.
    const dash = 7.0, gap = 6.0;
    final cx = size.width / 2, cy = size.height / 2;
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(cx, y), Offset(cx, (y + dash).clamp(0, size.height)), line);
    }
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, cy), Offset((x + dash).clamp(0, size.width), cy), line);
    }
  }

  void _paintGuide(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: guide,
        style: TextStyle(
          fontSize: size.height * 0.82,
          color: Sumi.grid.withValues(alpha: 0.55),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  void _paintStrokes(Canvas canvas, Size size) {
    final brush = Paint()
      ..color = accent
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      final first = _denorm(stroke.first, size);
      path.moveTo(first.dx, first.dy);
      if (stroke.length == 1) {
        // A tap = a dot.
        canvas.drawCircle(first, brush.strokeWidth / 2, brush..style = PaintingStyle.fill);
        brush.style = PaintingStyle.stroke;
        continue;
      }
      for (var i = 1; i < stroke.length; i++) {
        final pt = _denorm(stroke[i], size);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, brush);
    }
  }

  Offset _denorm(Offset n, Size size) =>
      Offset(n.dx * size.width, n.dy * size.height);

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
