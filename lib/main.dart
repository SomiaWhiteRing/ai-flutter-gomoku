import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'models/settings_state.dart';
import 'utils/theme_manager.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GomokuApp(),
    ),
  );
}

class GomokuApp extends ConsumerWidget {
  const GomokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: '五子棋 AI',
      theme: ThemeManager.getTheme(settings.theme),
      home: const HomeScreen(),
    );
  }
} 