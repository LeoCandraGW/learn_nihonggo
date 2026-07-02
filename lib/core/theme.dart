import 'package:flutter/material.dart';

/// 墨と紙 — "Ink & Paper" design system.
///
/// Traditional Japanese pigments, one per writing system so color itself
/// tells you which script you're looking at.
class Sumi {
  Sumi._();

  static const sumi = Color(0xFF1A1613); // 墨 ink — text & brush
  static const washi = Color(0xFFEDEAE1); // 紙 paper — background
  static const washiDeep = Color(0xFFE3DED1); // pressed / card edge
  static const grid = Color(0xFFC9C1B0); // faint genkō-yōshi rule
  static const muted = Color(0xFF6B655A); // secondary text

  static const shu = Color(0xFFC8451D); // 朱 vermilion — hiragana
  static const ai = Color(0xFF2E4A62); // 藍 indigo — katakana
  static const yamabuki = Color(0xFFB8842B); // 山吹 gold — kanji

  /// Accent for a script type ('hiragana' | 'katakana' | 'kanji').
  static Color accent(String type) => switch (type) {
        'hiragana' => shu,
        'katakana' => ai,
        _ => yamabuki,
      };

  /// Native Japanese label for a script type.
  static String label(String type) => switch (type) {
        'hiragana' => 'ひらがな',
        'katakana' => 'カタカナ',
        _ => '漢字',
      };
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  const seed = ColorScheme.light(
    primary: Sumi.shu,
    surface: Sumi.washi,
    onSurface: Sumi.sumi,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Sumi.washi,
    colorScheme: seed,
    splashFactory: InkRipple.splashFactory,
    // System font, but shaped deliberately: tight display tracking, airy labels.
    textTheme: base.textTheme
        .apply(bodyColor: Sumi.sumi, displayColor: Sumi.sumi)
        .copyWith(
          displayLarge: const TextStyle(
              fontSize: 96, height: 1.0, fontWeight: FontWeight.w300),
          headlineMedium: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          titleMedium: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          labelSmall: const TextStyle(
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: Sumi.muted),
        ),
  );
}
