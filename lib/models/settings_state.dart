import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AIDifficulty { easy, medium, hard }
enum GameTheme { classic, modern, dark }

class SettingsState {
  final AIDifficulty aiDifficulty;
  final bool soundEnabled;
  final GameTheme theme;
  final bool showLastMove;
  final bool showMoveNumber;

  const SettingsState({
    this.aiDifficulty = AIDifficulty.medium,
    this.soundEnabled = true,
    this.theme = GameTheme.classic,
    this.showLastMove = false,
    this.showMoveNumber = false,
  });

  SettingsState copyWith({
    AIDifficulty? aiDifficulty,
    bool? soundEnabled,
    GameTheme? theme,
    bool? showLastMove,
    bool? showMoveNumber,
  }) {
    return SettingsState(
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      theme: theme ?? this.theme,
      showLastMove: showLastMove ?? this.showLastMove,
      showMoveNumber: showMoveNumber ?? this.showMoveNumber,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setAIDifficulty(AIDifficulty difficulty) {
    state = state.copyWith(aiDifficulty: difficulty);
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
  }

  void setTheme(GameTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void toggleLastMove() {
    state = state.copyWith(showLastMove: !state.showLastMove);
  }

  void toggleMoveNumber() {
    state = state.copyWith(showMoveNumber: !state.showMoveNumber);
  }
} 