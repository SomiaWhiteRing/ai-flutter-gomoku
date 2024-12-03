import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../widgets/board.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getBoardState(GameState gameState) {
    StringBuffer output = StringBuffer();
    
    output.writeln('当前模式: ${gameState.gameMode == GameMode.playerVsAI ? "AI对战" : "双人对战"}');
    output.writeln('当前回合: ${gameState.currentPlayer == PieceType.black ? "黑棋" : "白棋"}');
    output.writeln('游戏状态: ${gameState.isGameOver ? "已结束" : "进行中"}');
    
    output.writeln('\n移动历史:');
    for (int i = 0; i < gameState.moveHistory.length; i++) {
      final move = gameState.moveHistory[i];
      output.writeln('${i + 1}. ${i % 2 == 0 ? "黑" : "白"}: (${move.$1}, ${move.$2})');
    }
    
    output.writeln('\n棋盘状态:');
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        switch (gameState.board[i][j]) {
          case PieceType.empty:
            output.write('0 ');
          case PieceType.black:
            output.write('1 ');
          case PieceType.white:
            output.write('2 ');
        }
      }
      output.writeln();
    }
    
    return output.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('五子棋'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                gameState.gameMode == GameMode.playerVsAI ? 'AI对战' : '双人对战',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '人人对战',
            onPressed: () {
              ref.read(gameStateProvider.notifier).setGameMode(GameMode.playerVsPlayer);
              ref.read(gameStateProvider.notifier).resetGame();
            },
          ),
          IconButton(
            icon: const Icon(Icons.computer),
            tooltip: 'AI对战',
            onPressed: () {
              ref.read(gameStateProvider.notifier).setGameMode(GameMode.playerVsAI);
              ref.read(gameStateProvider.notifier).resetGame();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新开始',
            onPressed: () {
              ref.read(gameStateProvider.notifier).resetGame();
            },
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: '打印棋谱',
              onPressed: () {
                final boardState = _getBoardState(gameState);
                print('\n=== 棋局信息 ===\n$boardState================\n');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('棋谱已打印到控制台')),
                );
              },
            ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gameState.isGameOver)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '游戏结束！${gameState.winner == PieceType.black ? "黑棋" : "白棋"}胜！',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          if (!gameState.isGameOver)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '当前回合: ${gameState.currentPlayer == PieceType.black ? "黑棋" : "白棋"}',
                          style: const TextStyle(fontSize: 24),
                        ),
                        if (gameState.gameMode == GameMode.playerVsAI)
                          Text(
                            '(${gameState.currentPlayer == PieceType.black ? "玩家" : "AI"})',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Expanded(
            child: Center(
              child: Board(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (gameState.moveHistory.isNotEmpty && 
              (gameState.gameMode == GameMode.playerVsPlayer || 
               (gameState.gameMode == GameMode.playerVsAI && 
                gameState.currentPlayer == PieceType.black &&
                gameState.moveHistory.length >= 2)))
            FloatingActionButton(
              onPressed: () => ref.read(gameStateProvider.notifier).undoMove(),
              child: const Icon(Icons.undo),
              tooltip: '悔棋',
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _showSettingsDialog(context, ref),
            child: const Icon(Icons.settings),
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          
          return AlertDialog(
            title: const Text('游戏设置'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI难度', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<AIDifficulty>(
                    segments: const [
                      ButtonSegment(
                        value: AIDifficulty.easy,
                        label: Text('简单'),
                      ),
                      ButtonSegment(
                        value: AIDifficulty.medium,
                        label: Text('中等'),
                      ),
                      ButtonSegment(
                        value: AIDifficulty.hard,
                        label: Text('困难'),
                      ),
                    ],
                    selected: {settings.aiDifficulty},
                    onSelectionChanged: (Set<AIDifficulty> newSelection) {
                      ref.read(settingsProvider.notifier)
                          .setAIDifficulty(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('音效'),
                    value: settings.soundEnabled,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).toggleSound();
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('显示最后一手'),
                    value: settings.showLastMove,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).toggleLastMove();
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('显示手数'),
                    value: settings.showMoveNumber,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).toggleMoveNumber();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('主题', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<GameTheme>(
                    segments: const [
                      ButtonSegment(
                        value: GameTheme.classic,
                        label: Text('经典'),
                      ),
                      ButtonSegment(
                        value: GameTheme.modern,
                        label: Text('现代'),
                      ),
                      ButtonSegment(
                        value: GameTheme.dark,
                        label: Text('暗黑'),
                      ),
                    ],
                    selected: {settings.theme},
                    onSelectionChanged: (Set<GameTheme> newSelection) {
                      ref.read(settingsProvider.notifier)
                          .setTheme(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
} 