import 'package:flutter/material.dart';
import '../models/settings_state.dart';

class ThemeManager {
  static ThemeData getTheme(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return _classicTheme;
      case GameTheme.modern:
        return _modernTheme;
      case GameTheme.dark:
        return _darkTheme;
    }
  }

  static final _classicTheme = ThemeData(
    primarySwatch: Colors.brown,
    scaffoldBackgroundColor: const Color(0xFFF5DEB3),
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.brown,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    useMaterial3: false,
  );

  static final _modernTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[700],
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    useMaterial3: true,
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D2D2D),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    useMaterial3: true,
  );

  static Color getBoardColor(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return const Color(0xFFDEB887);
      case GameTheme.modern:
        return Colors.blue[50]!;
      case GameTheme.dark:
        return const Color(0xFF2D2D2D);
    }
  }

  static Color getGridColor(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return Colors.black;
      case GameTheme.modern:
        return Colors.blue[900]!;
      case GameTheme.dark:
        return Colors.grey[400]!;
    }
  }

  static Color getWhitePieceColor(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return Colors.white;
      case GameTheme.modern:
        return Colors.white;
      case GameTheme.dark:
        return Colors.grey[300]!;
    }
  }

  static Color getBlackPieceColor(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return Colors.black;
      case GameTheme.modern:
        return Colors.blue[900]!;
      case GameTheme.dark:
        return Colors.grey[900]!;
    }
  }
} 