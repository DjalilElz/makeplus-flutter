// lib/core/constants/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Central color palette.
///
/// Prefer the context-aware statics at the bottom (`AppColors.textPrimary(context)`,
/// `AppColors.surface(context)`, ...) over the raw `xxxLight`/`xxxDark` constants
/// directly — they pick the right tone for the current [Brightness] automatically,
/// which is what actually makes dark mode work. A bare `AppColors.textPrimaryLight`
/// reference is a dark-mode bug waiting to happen: it never changes.
class AppColors {
  AppColors._();

  // ==================== Brand ====================
  static const Color primary = Color(0xFF9C27B0); // Purple/Magenta
  static const Color primaryDark = Color(0xFF7B1FA2);
  static const Color primaryLight = Color(0xFFBA68C8);

  static const Color accent = Color(0xFFE91E63); // Pink accent
  static const Color accentLight = Color(0xFFF48FB1);

  // ==================== Surfaces — Light ====================
  // A Material 3-style tonal ladder: each step is a little further from the
  // page background, giving cards/sheets/app bars real depth instead of every
  // surface being the same flat white.
  static const Color backgroundLight = Color(0xFFF6F3F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF3EEF4);
  static const Color surfaceContainerHighLight = Color(0xFFECE5EE);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ==================== Surfaces — Dark ====================
  // Material 3 dark surfaces are never pure black (#000) and never a single
  // flat grey either — each tier lifts slightly with a hint of the brand hue,
  // which is what makes a dark UI read as "designed" rather than "inverted".
  static const Color backgroundDark = Color(0xFF15121A);
  static const Color surfaceDark = Color(0xFF1D1922);
  static const Color surfaceContainerDark = Color(0xFF241F2B);
  static const Color surfaceContainerHighDark = Color(0xFF2C2733);
  static const Color cardDark = Color(0xFF241F2B);

  // ==================== Text — Light ====================
  static const Color textPrimaryLight = Color(0xFF1B1620);
  static const Color textSecondaryLight = Color(0xFF6C6673);
  static const Color textHintLight = Color(0xFFA39DAC);

  // ==================== Text — Dark ====================
  static const Color textPrimaryDark = Color(0xFFF2EEF5);
  static const Color textSecondaryDark = Color(0xFFC7C0D0);
  static const Color textHintDark = Color(0xFF837C8E);

  // ==================== Semantic ====================
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);

  // ==================== Neutral ====================
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);

  // ==================== Border & Divider ====================
  static const Color borderLight = Color(0xFFE3DEE6);
  static const Color borderDark = Color(0xFF3A3441);
  static const Color dividerLight = Color(0xFFE3DEE6);
  static const Color dividerDark = Color(0xFF3A3441);

  // Legacy aliases — several screens still reference these directly.
  static const Color border = borderLight;
  static const Color divider = dividerLight;

  // ==================== Shadow ====================
  static const Color shadow = Color(0x1A000000);

  // ==================== QR Scanner ====================
  static const Color qrOverlay = Color(0xCC000000);
  static const Color qrFrame = Color(0xFF9C27B0);

  // ==================== Status ====================
  static const Color accepted = Color(0xFF43A047);
  static const Color rejected = Color(0xFFE53935);
  static const Color pending = Color(0xFFFB8C00);

  // ==================== Context-aware accessors ====================
  // These are what screens should actually call. Each picks the Light/Dark
  // constant above based on the current theme brightness, so the same call
  // site is correct in both modes without an if/else at every use.

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Page/Scaffold background.
  static Color background(BuildContext context) =>
      _isDark(context) ? backgroundDark : backgroundLight;

  /// Default surface (app bars, sheets).
  static Color surface(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceLight;

  /// Card / tile background — one step up from `surface`.
  static Color cardBackground(BuildContext context) =>
      _isDark(context) ? cardDark : cardLight;

  /// A subtly-raised container, one tone above the page background — for
  /// grouped rows, chips, and section backgrounds that shouldn't look like a
  /// full card.
  static Color surfaceContainer(BuildContext context) =>
      _isDark(context) ? surfaceContainerDark : surfaceContainerLight;

  /// A further-raised container — for the active/selected state of a
  /// surfaceContainer element.
  static Color surfaceContainerHigh(BuildContext context) =>
      _isDark(context) ? surfaceContainerHighDark : surfaceContainerHighLight;

  /// Primary text — headings, titles, body copy.
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;

  /// Secondary text — subtitles, captions, muted labels.
  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;

  /// Hint / disabled / tertiary text.
  static Color textHint(BuildContext context) =>
      _isDark(context) ? textHintDark : textHintLight;

  /// Borders and hairline dividers.
  static Color borderColor(BuildContext context) =>
      _isDark(context) ? borderDark : borderLight;

  /// Dividers (alias of [borderColor] — kept separate for call-site clarity).
  static Color dividerColor(BuildContext context) =>
      _isDark(context) ? dividerDark : dividerLight;

  /// Icon color for icons that aren't semantically colored (not
  /// primary/error/etc.) — e.g. a chevron, a muted leading icon.
  static Color iconMuted(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;
}
