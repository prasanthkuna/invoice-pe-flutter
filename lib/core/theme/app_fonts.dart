import 'package:flutter/material.dart';

/// InvoicePe Font System - User Specification Implementation
/// Based on provided JSON font configuration
class AppFonts {
  // Font Family (User Specification)
  static const String primaryFamily = 'Inter';
  static const String monospaceFamily = 'monospace';

  // Font Sizes (User Specification - converted from px to logical pixels)
  static const double xs = 12.0; // 12px
  static const double sm = 14.0; // 14px
  static const double base = 16.0; // 16px
  static const double lg = 20.0; // 20px
  static const double xl = 24.0; // 24px
  static const double xxl = 32.0; // 32px

  // Font Weights (User Specification)
  static const FontWeight light = FontWeight.w300; // 300
  static const FontWeight regular = FontWeight.w400; // 400
  static const FontWeight medium = FontWeight.w500; // 500
  static const FontWeight semibold = FontWeight.w600; // 600
  static const FontWeight bold = FontWeight.w700; // 700

  // Line Heights (User Specification)
  static const double tightLineHeight = 1.2; // tight
  static const double normalLineHeight = 1.5; // normal
  static const double relaxedLineHeight = 1.75; // relaxed

  // Letter Spacing (User Specification - converted from em to logical pixels)
  static const double tightLetterSpacing = -0.32; // -0.02em * 16px
  static const double normalLetterSpacing = 0.0; // 0em
  static const double wideLetterSpacing = 0.32; // 0.02em * 16px

  // Text Styles - Predefined combinations

  // Display Styles (Large headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xxl,
    fontWeight: bold,
    height: tightLineHeight,
    letterSpacing: tightLetterSpacing,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xl,
    fontWeight: bold,
    height: tightLineHeight,
    letterSpacing: tightLetterSpacing,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFamily,
    fontSize: lg,
    fontWeight: semibold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  // Headline Styles (Section headings)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFamily,
    fontSize: lg,
    fontWeight: semibold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFamily,
    fontSize: base,
    fontWeight: semibold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFamily,
    fontSize: sm,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  // Body Styles (Content text)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFamily,
    fontSize: base,
    fontWeight: regular,
    height: relaxedLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFamily,
    fontSize: sm,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xs,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  // Label Styles (UI elements)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFamily,
    fontSize: sm,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xs,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xs,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  // Monospace Style (Code/numbers)
  static const TextStyle monospace = TextStyle(
    fontFamily: monospaceFamily,
    fontSize: base,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: primaryFamily,
    fontSize: base,
    fontWeight: semibold,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: primaryFamily,
    fontSize: sm,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: primaryFamily,
    fontSize: xs,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
  );
}
