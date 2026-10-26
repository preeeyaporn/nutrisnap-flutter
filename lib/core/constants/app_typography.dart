import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography helper supporting Prompt & Sarabun fonts for Thai and Latin text.
class AppTypography {
  AppTypography._();

  static TextStyle get heading1 => GoogleFonts.prompt(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get heading2 => GoogleFonts.prompt(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading3 => GoogleFonts.prompt(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get subtitle => GoogleFonts.prompt(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: 0.2,
  );

  static TextStyle get bodyLarge => GoogleFonts.sarabun(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.sarabun(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => GoogleFonts.sarabun(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle get buttonText => GoogleFonts.prompt(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static TextStyle get chipText =>
      GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle get barcodeDisplay => GoogleFonts.spaceMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textPrimary,
  );
}
