import 'package:flutter/material.dart';

/// Central color palette for the admin panel.
/// Colors are derived from the dashboard / users / user-detail mockups:
/// deep green header, mint background, white cards, and status pills.
class AppColors {
  AppColors._();

  // Brand / header
  static const Color darkGreen = Color(0xFF0E3B2A);
  static const Color darkGreenLight = Color(0xFF15503A);

  // Surfaces
  static const Color background = Color(0xFFE7F3EC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE7ECE9);

  // Text
  static const Color textPrimary = Color(0xFF14251E);
  static const Color textSecondary = Color(0xFF6B8579);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFB9CFC4);

  // Accent
  static const Color accentGreen = Color(0xFF2FAE67);
  static const Color liveDotGreen = Color(0xFF4ED08A);

  // Status: Active
  static const Color activeBg = Color(0xFFDCF3E3);
  static const Color activeText = Color(0xFF1F8A54);

  // Status: Suspended
  static const Color suspendedBg = Color(0xFFFBE6C8);
  static const Color suspendedText = Color(0xFFC77B1F);

  // Status: Deleted
  static const Color deletedBg = Color(0xFFE7E9E8);
  static const Color deletedText = Color(0xFF7C8985);

  // Plan: PRO
  static const Color proBg = Color(0xFFE3E8FF);
  static const Color proText = Color(0xFF4C5FD5);

  // Verified
  static const Color verifiedBg = Color(0xFFDCF3E3);
  static const Color verifiedText = Color(0xFF1F8A54);

  // Danger (Suspend / Delete actions)
  static const Color dangerRed = Color(0xFFD9534F);
  static const Color dangerBorder = Color(0xFFF0BDBA);
  static const Color dangerBg = Color(0xFFFFFFFF);

  // Failed jobs highlight (on dark card)
  static const Color failedHighlight = Color(0xFFF29489);

  // Avatar background palette, cycled by user index
  static const List<Color> avatarPalette = [
    Color(0xFF2FAE67), // green
    Color(0xFF8A6FE0), // purple
    Color(0xFFCB8A2E), // amber
    Color(0xFF1F9E6E), // teal green
    Color(0xFF3E6FE0), // blue
    Color(0xFF3E9BE0), // sky blue
  ];
}
