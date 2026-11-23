import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Brief's palette. Warm "paper" in light mode, warm charcoal in dark mode,
/// one accent: deep vermilion.
@immutable
class BriefColors extends ThemeExtension<BriefColors> {
  const BriefColors({
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.hairline,
    required this.shadow,
    required this.skeleton,
  });

  final Color paper;
  final Color card;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color hairline;
  final Color shadow;
  final Color skeleton;

  static const light = BriefColors(
    paper: Color(0xFFF7F3EC),
    card: Color(0xFFFFFDF9),
    ink: Color(0xFF1C1A17),
    muted: Color(0xFF6B655C), // 5.6:1 on paper
    accent: Color(0xFFC23A26), // 5.3:1 on paper
    hairline: Color(0xFFE6DFD3),
    shadow: Color(0x1A3A2A12),
    skeleton: Color(0xFFEAE3D7),
  );

  static const dark = BriefColors(
    paper: Color(0xFF141311),
    card: Color(0xFF1E1C19),
    ink: Color(0xFFEDE8E1),
    muted: Color(0xFFA59E93), // 7:1 on paper
    accent: Color(0xFFF2765F), // 6.6:1 on paper
    hairline: Color(0xFF2E2B26),
    shadow: Color(0x66000000),
    skeleton: Color(0xFF2A2723),
  );

  /// Works even without the Brief theme (e.g. in widget tests).
  static BriefColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BriefColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  BriefColors copyWith() => this;

  @override
  BriefColors lerp(BriefColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BriefColors(
      paper: l(paper, other.paper),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      accent: l(accent, other.accent),
      hairline: l(hairline, other.hairline),
      shadow: l(shadow, other.shadow),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}

/// Spacing on an 8-pt grid.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

abstract final class BriefTheme {
  static ThemeData light() => _build(BriefColors.light, Brightness.light);
  static ThemeData dark() => _build(BriefColors.dark, Brightness.dark);

  static ThemeData _build(BriefColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
        primary: c.accent,
        // Text on the accent: white on deep vermilion (5.3:1), near-black on
        // the lighter dark-mode vermilion (6.9:1).
        onPrimary: brightness == Brightness.dark ? c.paper : Colors.white,
        surface: c.paper,
      ),
      scaffoldBackgroundColor: c.paper,
    );
    // Fraunces (serif) for headlines, Inter for everything you read or tap.
    final sans = GoogleFonts.interTextTheme(base.textTheme);
    final serif = GoogleFonts.frauncesTextTheme(base.textTheme);
    final text = sans
        .copyWith(
          displayLarge: serif.displayLarge,
          displayMedium: serif.displayMedium,
          displaySmall: serif.displaySmall,
          headlineLarge: serif.headlineLarge,
          headlineMedium: serif.headlineMedium,
          headlineSmall: serif.headlineSmall,
          titleLarge: serif.titleLarge,
        )
        .apply(bodyColor: c.ink, displayColor: c.ink);

    return base.copyWith(
      textTheme: text,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
    );
  }
}
