import 'package:flutter/material.dart';

/// Only colours supplied in the NOVA identity, including its companion palette.
///
/// Netflix UI port: the dark canvas is pure black (#000), cards sit on
/// #161616, controls use the #323232 Netflix grey, and the accent is the
/// Netflix red (#E50914) with white foregrounds. Light mode keeps the NOVA
/// neutrals with a deepened Netflix red for AA contrast.
abstract final class NovaColors {
  // Netflix signature palette.
  static const red = Color(0xFFE50914);
  static const redDeep = Color(0xFFB00710);
  static const redSoft = Color(0xFFE5E5E5);
  static const netflixBlue = Color(0xFF0071EB);
  static const netflixTile = Color(0xFF1A1A1A);
  static const netflixLine = Color(0xFF222222);
  static const blush = Color(0xFF2C241E);
  static const ink = Color(0xFF000000);
  static const oledBlack = Color(0xFF000000);
  static const graphite = Color(0xFF161616);
  static const surfaceHigh = Color(0xFF262626);
  static const raised = Color(0xFF323232);
  static const divider = Color(0xFF2E2E2E);
  static const edgeSoft = Color(0x33FFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const mist = Color(0xFFA0A0A0);
  static const textDisabled = Color(0xFF6B6B6B);
  static const success = Color(0xFF45B164);
  static const warning = Color(0xFFF5C451);
  static const info = Color(0xFF4C8DE0);
  static const error = Color(0xFFC53637);
  static const rating = Color(0xFFF5C451);
  static const lightBackground = Color(0xFFF4F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111213);
  static const lightTextSecondary = Color(0xFF52555A);
  static const lightAccent = Color(0xFFC11119);
  static const lightDivider = Color(0xFFDCDFE2);
  static const scrim = Color(0xBF000000);

  // Harbor semantic tokens
  static const harborCanvas = ink;
  static const harborSurface = graphite;
  static const harborElevated = surfaceHigh;
  static const harborRaised = raised;
  static const harborAccent = red;
  static const harborInk = white;
  static const harborInkMuted = mist;
  static const harborInkSubtle = textDisabled;
  static const harborEdge = Color(0x8C3C3D3F);
  static const harborEdgeSoft = Color(0x403C3D3F);
}

abstract final class HarborRadii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const pill = 9999.0;
}

abstract final class NovaSpace {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
  static double gutter(double width) => width >= 840
      ? 32
      : width >= 600
          ? 24
          : 16;
}

abstract final class NovaMotion {
  static const press = Duration(milliseconds: 120);
  static const state = Duration(milliseconds: 180);
  static const route = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// Context-bound roles update in every screen when appearance changes.
class NovaPalette {
  const NovaPalette(this.theme);
  final ThemeData theme;
  bool get dark => theme.brightness == Brightness.dark;
  Color get canvas => theme.scaffoldBackgroundColor;
  Color get surface => theme.colorScheme.surface;
  Color get raised => theme.colorScheme.surfaceContainerHigh;
  Color get line => theme.colorScheme.outlineVariant;
  Color get gold => theme.colorScheme.secondary;
  Color get ink => theme.colorScheme.onSurface;
  Color get muted => theme.colorScheme.onSurfaceVariant;
}

abstract final class NovaTheme {
  static NovaPalette of(BuildContext context) => NovaPalette(Theme.of(context));
  static final dark = build(Brightness.dark);
  static final darkOled = build(Brightness.dark, oled: true);
  static final light = build(Brightness.light);

  static ThemeData build(Brightness brightness,
      {bool arabic = false, bool oled = false}) {
    final dark = brightness == Brightness.dark;
    final oledDark = dark && oled;
    final canvas = oledDark ? NovaColors.oledBlack : NovaColors.ink;
    final surface = oledDark ? NovaColors.oledBlack : NovaColors.graphite;
    final text = dark ? NovaColors.white : NovaColors.ink;
    final muted = dark ? NovaColors.mist : NovaColors.lightTextSecondary;
    final accent = dark ? NovaColors.redSoft : NovaColors.lightAccent;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? NovaColors.red : NovaColors.lightAccent,
      // Netflix buttons: white text on the red fill in both modes.
      onPrimary: NovaColors.white,
      primaryContainer: dark ? NovaColors.white : NovaColors.ink,
      onPrimaryContainer: dark ? NovaColors.ink : NovaColors.white,
      secondary: accent,
      onSecondary: dark ? NovaColors.ink : NovaColors.white,
      secondaryContainer: dark ? NovaColors.surfaceHigh : const Color(0xFFE8EAED),
      onSecondaryContainer: text,
      tertiary: accent,
      onTertiary: dark ? NovaColors.ink : NovaColors.white,
      error: dark ? const Color(0xFFE05252) : const Color(0xFFBA1A1A),
      onError: dark ? NovaColors.ink : NovaColors.white,
      errorContainer: dark ? const Color(0xFF38181A) : const Color(0xFFFFDAD6),
      onErrorContainer: dark ? const Color(0xFFF8B4B4) : const Color(0xFF410002),
      surface: dark ? surface : NovaColors.white,
      onSurface: text,
      surfaceContainerLowest: dark ? canvas : NovaColors.white,
      surfaceContainerLow: dark ? surface : NovaColors.lightBackground,
      surfaceContainer: dark
          ? (oledDark ? NovaColors.ink : NovaColors.graphite)
          : NovaColors.lightBackground,
      surfaceContainerHigh:
          dark ? NovaColors.surfaceHigh : const Color(0xFFE8EAED),
      surfaceContainerHighest:
          dark ? NovaColors.raised : const Color(0xFFDCDFE2),
      onSurfaceVariant: muted,
      outline: dark ? NovaColors.divider.withValues(alpha: .55) : NovaColors.lightDivider,
      outlineVariant: dark ? NovaColors.divider.withValues(alpha: .25) : NovaColors.lightDivider,
      shadow: canvas,
      scrim: canvas,
      inverseSurface: dark ? NovaColors.white : NovaColors.graphite,
      onInverseSurface: dark ? NovaColors.ink : NovaColors.white,
      inversePrimary: dark ? NovaColors.lightAccent : NovaColors.redSoft,
      surfaceTint: Colors.transparent,
    );
    final family = arabic ? 'IBMPlexSansArabic' : 'Poppins';
    TextStyle type(double size, FontWeight weight,
            {Color? color, double height = 1.5}) =>
        TextStyle(
            fontFamily: family,
            fontFamilyFallback: const ['IBMPlexSansArabic', 'Poppins'],
            fontSize: size,
            fontWeight: weight,
            height: arabic ? height + .1 : height,
            color: color ?? text);
    final textTheme = TextTheme(
      displayLarge: type(48, FontWeight.w700, height: 1.15),
      displayMedium: type(40, FontWeight.w700, height: 1.15),
      displaySmall: type(32, FontWeight.w700, height: 1.2),
      headlineLarge: type(32, FontWeight.w700, height: 1.2),
      headlineMedium: type(28, FontWeight.w700, height: 1.25),
      headlineSmall: type(24, FontWeight.w600, height: 1.3),
      titleLarge: type(20, FontWeight.w600, height: 1.3),
      titleMedium: type(16, FontWeight.w600),
      titleSmall: type(14, FontWeight.w600),
      bodyLarge: type(16, FontWeight.w400),
      bodyMedium: type(14, FontWeight.w400),
      bodySmall: type(12, FontWeight.w400, color: muted),
      labelLarge: type(14, FontWeight.w600, height: 1.3),
      labelMedium: type(12, FontWeight.w500, height: 1.3),
      labelSmall: type(11, FontWeight.w500, height: 1.3),
    );
    // Netflix component geometry: 4dp control corners, 8dp cards.
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
      shape: WidgetStatePropertyAll(buttonShape),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? NovaColors.redDeep.withValues(alpha: .18)
              : states.contains(WidgetState.focused)
                  ? accent.withValues(alpha: .18)
                  : null),
    );
    // Netflix inputs: flat 4dp corners on the #323232 grey.
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: scheme.outline));
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: family,
      fontFamilyFallback: const ['IBMPlexSansArabic', 'Poppins'],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: dark ? canvas : NovaColors.lightBackground,
      canvasColor: scheme.surface,
      cardColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: text, size: 22),
      appBarTheme: AppBarTheme(
          backgroundColor: dark ? canvas : NovaColors.lightBackground,
          foregroundColor: text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: textTheme.titleLarge),
      cardTheme:
          CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: shape),
      filledButtonTheme: FilledButtonThemeData(
          style: button.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.disabled)
                      ? scheme.surfaceContainerHighest
                      : s.contains(WidgetState.pressed)
                          ? NovaColors.redDeep
                          : NovaColors.red),
              foregroundColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.disabled)
                      ? muted
                      : NovaColors.white))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: button.copyWith(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(NovaColors.red),
              foregroundColor: const WidgetStatePropertyAll(NovaColors.white))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: button.copyWith(
              side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
              foregroundColor: WidgetStatePropertyAll(text))),
      textButtonTheme: TextButtonThemeData(
          style:
              button.copyWith(foregroundColor: WidgetStatePropertyAll(accent))),
      iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
              foregroundColor: WidgetStatePropertyAll(text))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
          labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
          hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
          border: border,
          enabledBorder: border,
          focusedBorder:
              border.copyWith(borderSide: BorderSide(color: accent, width: 2)),
          errorBorder:
              border.copyWith(borderSide: BorderSide(color: scheme.error)),
          errorMaxLines: 3),
      // Netflix filter chips: transparent fill, 30% white ring, solid
      // white (dark) / ink (light) active pill with inverted label.
      chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          backgroundColor: Colors.transparent,
          selectedColor: dark ? NovaColors.white : NovaColors.ink,
          side: BorderSide(
              color: dark
                  ? Colors.white.withValues(alpha: .30)
                  : NovaColors.ink.withValues(alpha: .30)),
          labelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? (dark ? NovaColors.ink : NovaColors.white)
                    : text,
              )),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      tabBarTheme: TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: muted,
          labelStyle: textTheme.labelLarge,
          indicatorColor: accent,
          dividerColor: scheme.outlineVariant),
      switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? NovaColors.white : muted),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? NovaColors.red
                  : scheme.surfaceContainerHighest)),
      checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? NovaColors.red : null),
          checkColor: const WidgetStatePropertyAll(NovaColors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      sliderTheme: SliderThemeData(
          activeTrackColor: accent,
          thumbColor: accent,
          inactiveTrackColor: scheme.outlineVariant,
          trackHeight: 4,
          overlayColor: accent.withValues(alpha: .12)),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: accent, linearTrackColor: scheme.surfaceContainerHighest),
      dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titleTextStyle: textTheme.titleLarge,
          contentTextStyle: textTheme.bodyMedium),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          modalBackgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          elevation: 0,
          modalBarrierColor: scheme.scrim.withValues(alpha: .72),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadiusDirectional.vertical(top: Radius.circular(20)))),
      listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          minVerticalPadding: 12,
          iconColor: muted,
          textColor: text,
          selectedColor: accent,
          titleTextStyle: textTheme.titleMedium,
          subtitleTextStyle: textTheme.bodySmall),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primaryContainer,
          selectedIconTheme: IconThemeData(color: accent),
          unselectedIconTheme: IconThemeData(color: muted),
          selectedLabelTextStyle:
              textTheme.labelMedium?.copyWith(color: accent)),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          contentTextStyle:
              textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
          shape: shape),
      tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(8)),
          textStyle:
              textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface)),
    );
  }
}
