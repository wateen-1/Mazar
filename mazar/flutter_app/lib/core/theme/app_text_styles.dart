import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// أنماط النصوص الموحّدة في تطبيق مزار، تعتمد خط "Amiri" العربي الفخم للعناوين
/// الكبيرة، وخط "Cairo" الحديث والمقروء لباقي النصوص.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get splashTitle => GoogleFonts.amiri(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        letterSpacing: 1.2,
      );

  static TextStyle get splashSlogan => GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.goldLight,
        letterSpacing: 0.4,
      );

  static TextStyle get heading1 => GoogleFonts.cairo(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );
}
