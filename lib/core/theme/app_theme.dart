import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF1E88E5); // Emerald Green / Dark Blue
  static const Color accentColor = Color(0xFFC5A059);  // Sand / Gold
  static const Color incomeColor = Color(0xFF2E7D32);  // Rich Green
  static const Color expenseColor = Color(0xFFC62828); // Rich Red
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFFBF4DF), // Matches sand/paper background of main app
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFFF4ECD8),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFF4ECD8),
        elevation: 2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep black/grey
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFF1E1E1E),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white70,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
}
