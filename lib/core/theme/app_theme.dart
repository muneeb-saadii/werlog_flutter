import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  WerlogColors — single source of truth
// ─────────────────────────────────────────────
class WerlogColors {
  WerlogColors._();

  // Brand primaries
  static const Color darkTeal      = Color(0xFF0F2A2E); // phone-outer / hero bg
  static const Color teal          = Color(0xFF1D9E75); // primary CTA green
  static const Color tealLight     = Color(0xFF5DCAA5); // accent/highlight
  static const Color tealSurface   = Color(0xFFE1F5EE); // green tinted bg
  static const Color tealLightSurface   = Color(0xFFF5FAF8); // light green tinted bg

  // Accent — amber / warning
  static const Color amber         = Color(0xFFBA7517);
  static const Color amberSurface  = Color(0xFFFAEEDA);
  static const Color amberDark     = Color(0xFF854F0B);
  static const Color amberDeep     = Color(0xFF633806);

  // Accent — coral / expense
  static const Color coral         = Color(0xFFD85A30);
  static const Color coralSurface  = Color(0xFFFAECE7);
  static const Color coralDark     = Color(0xFF993C1D);

  // Neutrals
  static const Color transparent   = Color(0x00000000); // app-wide bg
  static const Color background    = Color(0xFFFAFAF7);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceAlt    = Color(0xFFF1EFE8);
  static const Color border        = Color(0xFFE5E3DB);
  static const Color borderLight   = Color(0xFFEEECE4);

  // Text
  static const Color textPrimary   = Color(0xFF0F2A2E);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textTertiary  = Color(0xFF888780);
  static const Color textDisabled  = Color(0xFFB4B2A9);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // Semantic
  static const Color success       = teal;
  static const Color successSurface = tealSurface;
  static const Color warning       = amber;
  static const Color warningSurface = amberSurface;
  static const Color danger        = coral;
  static const Color dangerSurface = coralSurface;

  // Tab bar
  static const Color tabActive     = teal;
  static const Color tabInactive   = Color(0xFF888780);

  // Subscription badge
  static const Color proBadgeBg   = Color(0xFF2A4A46); // rgba(93,202,165,0.2) approx
  static const Color proBadgeText = tealLight;
}

// ─────────────────────────────────────────────
//  WerlogTextStyles
// ─────────────────────────────────────────────
class WerlogTextStyles {
  WerlogTextStyles._();

  // Display / hero
  static TextStyle heroTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: WerlogColors.background,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle heroSubtitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    color: Color(0xBFfafaf7),
    height: 1.6,
  );

  // Page / section titles
  static TextStyle pageTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle sectionTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle dashboardGreeting = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    color: WerlogColors.textSecondary,
  );

  static TextStyle dashboardName = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Balance / big numbers
  static TextStyle balanceAmount = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
    letterSpacing: -0.6,
  );

  static TextStyle balanceLabel = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: Color(0x99FFFFFF),
    letterSpacing: 1.0,
  );

  static TextStyle balanceSub = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: Color(0x8CFFFFFF),
  );

  // Plan pricing
  static TextStyle planPrice = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle planPricePer = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    color: WerlogColors.textSecondary,
  );

  // Body
  static TextStyle body = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 14,
    color: WerlogColors.textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    color: WerlogColors.textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle captionBold = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
  );

  static TextStyle label = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
    letterSpacing: 0.4,
  );

  static TextStyle labelUppercase = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
    letterSpacing: 0.9,
  );

  // Transaction
  static TextStyle txTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle txMeta = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle txAmount = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle txDate = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 9,
    color: WerlogColors.textTertiary,
  );

  // Buttons
  static TextStyle button = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
  );

  static TextStyle buttonGhost = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle link = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.teal,
  );

  static TextStyle featureTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle featureDesc = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.textSecondary,
    height: 1.4,
  );

  // Plan names
  static TextStyle planName = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle planDesc = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle planFeature = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.textPrimary,
    height: 1.3,
  );

  // Status / type badges
  static TextStyle badgeText = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 8,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // Quick-access card
  static TextStyle quickTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle quickDetail = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 9,
    color: WerlogColors.textSecondary,
  );

  // Alert
  static TextStyle alertTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.amberDeep,
  );

  static TextStyle alertSub = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.amberDark,
  );

  // Tab bar
  static TextStyle tabLabel = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Checkout
  static TextStyle checkoutPlanLabel = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: WerlogColors.tealLight,
    letterSpacing: 0.9,
    fontWeight: FontWeight.w500,
  );

  static TextStyle checkoutPlanName = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
  );

  static TextStyle checkoutAmount = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
    letterSpacing: -0.5,
  );

  static TextStyle checkoutSub = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    color: Color(0x99FFFFFF),
  );

  // Status-bar
  static TextStyle statusBar = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );
}



// ─────────────────────────────────────────────
//  WerlogGradients — reusable gradient factory
//  Base: extremely light teal-green (#E8FAF4)
//  Paired with a slightly deeper teal (#C0EFE0)
//  for a calm, fresh, on-brand feel across all
//  page headers and card surfaces.
// ─────────────────────────────────────────────
class WerlogGradients {
  WerlogGradients._();

  // Lightest green — used as page / screen background wash
  static const Color _mint       = Color(0xFFE8FAF4); // very light teal-green
  static const Color _mintMid    = Color(0xFFCDF0E1); // slightly richer
  static const Color _mintDeep   = Color(0xFFB0E8D0); // contrast end

  // ── Page-header gradients (top-of-screen tinted header) ───
  /// Default: light mint top → white bottom — use on most screens
  static LinearGradient pageHeader({
    Alignment begin = Alignment.topCenter,
    Alignment end   = Alignment.bottomCenter,
  }) =>
      LinearGradient(
        begin: begin, end: end,
        colors: const [_mint, Color(0xFFF5FBF8)],
      );

  /// Slightly richer — for invoice / detail headers
  static LinearGradient pageHeaderRich({
    Alignment begin = Alignment.topLeft,
    Alignment end   = Alignment.bottomRight,
  }) =>
      LinearGradient(
        begin: begin, end: end,
        colors: const [_mintMid, _mint, Color(0xFFF5FBF8)],
        stops: const [0.0, 0.5, 1.0],
      );

  // ── Card surface gradients ────────────────────────────────
  /// Card with subtle mint wash — e.g. OCR confidence chip
  static LinearGradient cardMint() => LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [_mintMid, const Color(0xFFF5FBF8)],
  );

  /// Dark hero card (balance, checkout plan) — unchanged dark teal
  static LinearGradient darkHero() => const LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [WerlogColors.darkTeal, Color(0xFF1A3C42)],
  );

  // ── Scanning / camera overlay gradient ───────────────────
  /// Dark translucent overlay behind the camera viewfinder
  static LinearGradient cameraOverlay() => LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [
      const Color(0xFF1A3438),
      const Color(0xFF0D2427),
    ],
  );

  // ── Processing spinner background ─────────────────────────
  static LinearGradient processingBg() => const LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [Color(0xFFF5FBF8), WerlogColors.background],
  );

  // ── Reports header card ───────────────────────────────────
  static LinearGradient reportsCard() => LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [
      WerlogColors.darkTeal,
      const Color(0xFF1D3E43),
    ],
  );

  // ── Bottom-sheet scan type sheet ──────────────────────────
  static LinearGradient sheetDimmedBg() => LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [
      WerlogColors.darkTeal.withOpacity(0.55),
      WerlogColors.darkTeal.withOpacity(0.42),
    ],
  );

  // ── Expense detail header (coral tint) ────────────────────
  static LinearGradient expenseHeader() => const LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [WerlogColors.darkTeal, Color(0xFF241A18)],
  );

  // ── Warranty detail header (amber tint) ───────────────────
  static LinearGradient warrantyHeader() => const LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [WerlogColors.darkTeal, Color(0xFF24200F)],
  );

  // ── Profile avatar ────────────────────────────────────────
  static LinearGradient avatar() => const LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [WerlogColors.teal, Color(0xFF0F6E56)],
  );
}

/*class WerlogTextStyles {
  WerlogTextStyles._();

  // Display / hero
  static TextStyle heroTitle = GoogleFonts.dmSans(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: WerlogColors.background,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle heroSubtitle = GoogleFonts.dmSans(
    fontSize: 12,
    color: Color(0xBFfafaf7),
    height: 1.6,
  );

  // Page / section titles
  static TextStyle pageTitle = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle sectionTitle = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle dashboardGreeting = GoogleFonts.dmSans(
    fontSize: 11,
    color: WerlogColors.textSecondary,
  );

  static TextStyle dashboardName = GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Balance / big numbers
  static TextStyle balanceAmount = GoogleFonts.dmSans(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
    letterSpacing: -0.6,
  );

  static TextStyle balanceLabel = GoogleFonts.dmSans(
    fontSize: 10,
    color: Color(0x99FFFFFF),
    letterSpacing: 1.0,
  );

  static TextStyle balanceSub = GoogleFonts.dmSans(
    fontSize: 10,
    color: Color(0x8CFFFFFF),
  );

  // Plan pricing
  static TextStyle planPrice = GoogleFonts.dmSans(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle planPricePer = GoogleFonts.dmSans(
    fontSize: 11,
    color: WerlogColors.textSecondary,
  );

  // Body
  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 12,
    color: WerlogColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 11,
    color: WerlogColors.textSecondary,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle captionBold = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
    letterSpacing: 0.4,
  );

  static TextStyle labelUppercase = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textSecondary,
    letterSpacing: 0.9,
  );

  // Transaction
  static TextStyle txTitle = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle txMeta = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle txAmount = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle txDate = GoogleFonts.dmSans(
    fontSize: 9,
    color: WerlogColors.textTertiary,
  );

  // Buttons
  static TextStyle button = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
  );

  static TextStyle buttonGhost = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle link = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.teal,
  );

  static TextStyle featureTitle = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle featureDesc = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.textSecondary,
    height: 1.4,
  );

  // Plan names
  static TextStyle planName = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle planDesc = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.textSecondary,
  );

  static TextStyle planFeature = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.textPrimary,
    height: 1.3,
  );

  // Status / type badges
  static TextStyle badgeText = GoogleFonts.dmSans(
    fontSize: 8,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // Quick-access card
  static TextStyle quickTitle = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );

  static TextStyle quickDetail = GoogleFonts.dmSans(
    fontSize: 9,
    color: WerlogColors.textSecondary,
  );

  // Alert
  static TextStyle alertTitle = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.amberDeep,
  );

  static TextStyle alertSub = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.amberDark,
  );

  // Tab bar
  static TextStyle tabLabel = GoogleFonts.dmSans(
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );

  // Checkout
  static TextStyle checkoutPlanLabel = GoogleFonts.dmSans(
    fontSize: 10,
    color: WerlogColors.tealLight,
    letterSpacing: 0.9,
    fontWeight: FontWeight.w500,
  );

  static TextStyle checkoutPlanName = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
  );

  static TextStyle checkoutAmount = GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: WerlogColors.surface,
    letterSpacing: -0.5,
  );

  static TextStyle checkoutSub = GoogleFonts.dmSans(
    fontSize: 10,
    color: Color(0x99FFFFFF),
  );

  // Status-bar
  static TextStyle statusBar = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: WerlogColors.textPrimary,
  );
}*/

// ─────────────────────────────────────────────
//  WerlogTheme — ThemeData
// ─────────────────────────────────────────────
class WerlogTheme {
  WerlogTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: WerlogColors.background,
    colorScheme: const ColorScheme.light(
      primary:   WerlogColors.teal,
      secondary: WerlogColors.amber,
      error:     WerlogColors.coral,
      surface:   WerlogColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    // textTheme: GoogleFonts.dmSansTextTheme(),
    fontFamily: 'DMSans',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WerlogColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: WerlogColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: WerlogColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: WerlogColors.teal, width: 1.5),
      ),
      labelStyle: WerlogTextStyles.label,
      hintStyle: WerlogTextStyles.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WerlogColors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: WerlogTextStyles.button,
        elevation: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: WerlogColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: WerlogColors.borderLight,
      thickness: 0.5,
      space: 0,
    ),
  );
}
