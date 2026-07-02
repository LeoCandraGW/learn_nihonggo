import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 落款 hanko — a carved seal stamp. Our "mastered" mark instead of a checkmark.
/// A rough square stamp in vermilion with a centered kanji.
class SealBadge extends StatelessWidget {
  const SealBadge({super.key, this.size = 22, this.glyph = '済'});

  final double size;
  final String glyph; // 済 = "done"

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Sumi.shu,
        borderRadius: BorderRadius.circular(size * 0.16),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          color: Sumi.washi,
          fontSize: size * 0.6,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
