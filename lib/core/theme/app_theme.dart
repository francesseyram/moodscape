import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF880E4F);
  static const primaryLight = Color(0xFFC2185B);
  static const accent = Color(0xFFF48FB1);
  static const background = Color(0xFFFFF8F9);
  static const surface = Color(0xFFFFFFFF);
  static const cardPink = Color(0xFFFCE4EC);
  static const textDark = Color(0xFF2D2D2D);
  static const textMedium = Color(0xFF757575);
  static const textLight = Color(0xFFBDBDBD);
  static const error = Color(0xFFD32F2F);

  // Mood colours
  static const happy = Color(0xFFFFD54F);
  static const sad = Color(0xFF90CAF9);
  static const calm = Color(0xFFA5D6A7);
  static const angry = Color(0xFFEF9A9A);
  static const nutcracker = Color(0xFFCE93D8);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
              fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
          displayMedium: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
          headlineMedium: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark),
          titleLarge: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
          titleMedium: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
          bodyLarge: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textDark),
          bodyMedium: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textMedium),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: GoogleFonts.poppins(color: AppColors.textMedium),
          hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: AppColors.accent.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      );
}