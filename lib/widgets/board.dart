import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../utils/theme_manager.dart';

class Board extends ConsumerWidget {
  const Board({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final settings = ref.watch(settingsProvider);
    
    // 计算棋盘大小
    final size = MediaQuery.of(context).size.shortestSide * 
        (MediaQuery.of(context).size.width > 600 ? 0.6 : 0.9);
    
    // 为了确保棋子完整显示，增加边距
    final boardPadding = size * 0.05;  // 5% 的边距
    final effectiveSize = size - (boardPadding * 2);  // 实际棋盘大小
    final cellSize = effectiveSize / (GameState.boardSize - 1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ThemeManager.getBoardColor(settings.theme),
        border: Border.all(
          color: ThemeManager.getGridColor(settings.theme),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 棋盘网格
          Positioned(
            left: boardPadding,
            top: boardPadding,
            child: CustomPaint(
              size: Size(effectiveSize, effectiveSize),
              painter: BoardPainter(settings),
            ),
          ),
          // 棋子层
          for (var i = 0; i < GameState.boardSize; i++)
            for (var j = 0; j < GameState.boardSize; j++)
              if (gameState.board[i][j] != PieceType.empty)
                Positioned(
                  left: boardPadding + (j * cellSize) - (cellSize * 0.4),
                  top: boardPadding + (i * cellSize) - (cellSize * 0.4),
                  child: Stack(
                    children: [
                      Container(
                        width: cellSize * 0.8,
                        height: cellSize * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gameState.board[i][j] == PieceType.black
                              ? ThemeManager.getBlackPieceColor(settings.theme)
                              : ThemeManager.getWhitePieceColor(settings.theme),
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      // 最后一手提示
                      if (settings.showLastMove &&
                          gameState.moveHistory.isNotEmpty &&
                          gameState.moveHistory.last == (i, j))
                        Center(
                          child: Container(
                            width: cellSize * 0.3,
                            height: cellSize * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.5),
                            ),
                          ),
                        ),
                      // 手数显示
                      if (settings.showMoveNumber)
                        Center(
                          child: Text(
                            '${gameState.moveHistory.indexWhere((move) => move == (i, j)) + 1}',
                            style: TextStyle(
                              color: gameState.board[i][j] == PieceType.black
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: cellSize * 0.3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          // 点击检测层
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) {
                // 计算相对于棋盘的坐标
                final x = details.localPosition.dx - boardPadding;
                final y = details.localPosition.dy - boardPadding;
                
                // 计算最近的交叉点
                final col = ((x / cellSize).round()).clamp(0, GameState.boardSize - 1);
                final row = ((y / cellSize).round()).clamp(0, GameState.boardSize - 1);
                
                ref.read(gameStateProvider.notifier).placePiece(row, col);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter(this.settings);
  final SettingsState settings;

  @override
  void paint(Canvas canvas, Size size) {
    final gridColor = ThemeManager.getGridColor(settings.theme);
    
    final borderPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final cellSize = size.width / (GameState.boardSize - 1);

    for (var i = 0; i < GameState.boardSize; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    for (var i = 0; i < GameState.boardSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
    }

    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    void drawDot(int row, int col) {
      canvas.drawCircle(
        Offset(col * cellSize, row * cellSize),
        4,
        dotPaint,
      );
    }

    drawDot(7, 7);
    drawDot(3, 3);
    drawDot(3, 11);
    drawDot(11, 3);
    drawDot(11, 11);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 