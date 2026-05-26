// lib/core/theme/app_colors.dart — Mindful Flow Dark Premium Palette

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0E21);
  static const Color bgSecondary = Color(0xFF0D1520);
  static const Color surface = Color(0xFF141B2D);
  static const Color surfaceLight = Color(0xFF1A2332);
  static const Color cardBorder = Color(0xFF1E293B);

  // ── Primary Teal System ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryDark = Color(0xFF00A88A);
  static const Color primaryLight = Color(0xFF33DDBB);
  static const Color primaryGlow = Color(0x3300D4AA); // 20% opacity
  static const Color primarySubtle = Color(0x1A00D4AA); // 10% opacity

  // ── Accent Cyan ───────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentGlow = Color(0x3300BCD4);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFFF5252);
  static const Color energy = Color(0xFFFF6B35);

  // ── XP / Gamification ─────────────────────────────────────────────────────
  static const Color xpGold = Color(0xFFFFD700);
  static const Color streak = Color(0xFFFF6B35);
  static const Color badge = Color(0xFF7C4DFF);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textMuted = Color(0xFF556677);
  static const Color textAccent = Color(0xFF00D4AA);

  // ── Chat ───────────────────────────────────────────────────────────────────
  static const Color chatUser = Color(0xFF1A3A4A);
  static const Color chatAI = Color(0xFF141B2D);
  static const Color chatAIBorder = Color(0xFF00D4AA);

  // ── Heatmap Intensity ─────────────────────────────────────────────────────
  static const Color heatmap0 = Color(0xFF1A2332);
  static const Color heatmap1 = Color(0xFF004D40);
  static const Color heatmap2 = Color(0xFF00796B);
  static const Color heatmap3 = Color(0xFF00897B);
  static const Color heatmap4 = Color(0xFF00BFA5);
  static const Color heatmap5 = Color(0xFF00D4AA);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141B2D), Color(0xFF1A2332)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x3300D4AA), Color(0x0000D4AA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Helper ────────────────────────────────────────────────────────────────
  static Color withAlpha(Color color, double opacity) =>
      color.withOpacity(opacity);
}
