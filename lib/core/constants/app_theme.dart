import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette (Primary Premium Dark)
  static const Color darkBackground = Color(0xFF0F172A); // Deep Slate Blue
  static const Color darkSurface = Color(0xFF1E293B);    // Slate Blue Surface
  static const Color darkPrimary = Color(0xFF8B5CF6);    // Vibrant Violet
  static const Color darkSecondary = Color(0xFF10B981);  // Emerald Green
  static const Color darkAccent = Color(0xFFF43F5E);     // Rose Red
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Off-White
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Muted Blue-Gray
  
  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6D28D9); // Rich Purple
  static const Color lightSecondary = Color(0xFF059669);
  static const Color lightAccent = Color(0xFFE11D48);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Mood Color Mapping
  static const Map<String, Color> moodColors = {
    'Happy': Color(0xFFFBBF24),    // Warm Amber
    'Excited': Color(0xFFEC4899),  // Pink Rose
    'Neutral': Color(0xFF64748B),  // Steel Slate
    'Sad': Color(0xFF3B82F6),      // Sky Blue
    'Angry': Color(0xFFEF4444),    // Crimson Red
  };

  // Mood Emoji Mapping
  static const Map<String, String> moodEmojis = {
    'Happy': '😊',
    'Excited': '😍',
    'Neutral': '😐',
    'Sad': '😔',
    'Angry': '😡',
  };
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        error: AppColors.darkAccent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkTextPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface.withAlpha(204), // 0.8 opacity
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(25), width: 1), // subtle border
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        error: AppColors.lightAccent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightTextPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withAlpha(13), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Glassmorphic background decoration
  static BoxDecoration glassDecoration({required BuildContext context, double opacity = 0.1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withAlpha((opacity * 255).round()) 
          : Colors.black.withAlpha((opacity * 255 * 0.5).round()),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark 
            ? Colors.white.withAlpha(25) 
            : Colors.black.withAlpha(13),
        width: 1,
      ),
    );
  }
}
