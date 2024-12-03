import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import 'settings_state.dart';

enum PieceType { empty, black, white }
enum GameMode { playerVsPlayer, playerVsAI }

class GameState {
  final List<List<PieceType>> board;
  final PieceType currentPlayer;
  final bool isGameOver;
  final PieceType? winner;
  final GameMode gameMode;
  final List<(int, int)> moveHistory;
  final bool isThinking;

  static const boardSize = 15;

  GameState({
    List<List<PieceType>>? board,
    this.currentPlayer = PieceType.black,
    this.isGameOver = false,
    this.winner,
    this.gameMode = GameMode.playerVsAI,
    this.moveHistory = const [],
    this.isThinking = false,
  }) : board = board ??
            List.generate(
              boardSize,
              (_) => List.filled(boardSize, PieceType.empty),
            );

  GameState copyWith({
    List<List<PieceType>>? board,
    PieceType? currentPlayer,
    bool? isGameOver,
    PieceType? winner,
    GameMode? gameMode,
    List<(int, int)>? moveHistory,
    bool? isThinking,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      isGameOver: isGameOver ?? this.isGameOver,
      winner: winner ?? this.winner,
      gameMode: gameMode ?? this.gameMode,
      moveHistory: moveHistory ?? this.moveHistory,
      isThinking: isThinking ?? this.isThinking,
    );
  }

  void undoMove() {
    if (moveHistory.isEmpty) return;
    final lastMove = moveHistory.last;
    // 实现悔棋逻辑
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(ref),
);

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(this.ref) : super(GameState());

  final Ref ref;

  void placePiece(int row, int col) {
    if (state.gameMode == GameMode.playerVsAI && 
        state.currentPlayer == PieceType.white) {
      return;
    }

    if (state.board[row][col] != PieceType.empty || state.isGameOver) {
      return;
    }

    final newBoard = List<List<PieceType>>.generate(
      GameState.boardSize,
      (i) => List<PieceType>.from(state.board[i]),
    );
    
    newBoard[row][col] = state.currentPlayer;
    final winner = checkWinner(row, col, newBoard);
    
    final newHistory = List<(int, int)>.from(state.moveHistory)
      ..add((row, col));
    
    state = state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceType.black
          ? PieceType.white
          : PieceType.black,
      isGameOver: winner != null,
      winner: winner,
      moveHistory: newHistory,
    );

    if (state.gameMode == GameMode.playerVsAI && 
        !state.isGameOver && 
        state.currentPlayer == PieceType.white) {
      _makeAIMove();
    }
  }

  void _makeAIMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!state.isGameOver && state.currentPlayer == PieceType.white) {
        final settings = ref.read(settingsProvider);
        
        final (row, col) = AIService.getBestMove(
          state.board,
          PieceType.white,
          settings.aiDifficulty,
        );
        
        if (row != -1 && col != -1) {
          final newBoard = List<List<PieceType>>.generate(
            GameState.boardSize,
            (i) => List<PieceType>.from(state.board[i]),
          );
          
          newBoard[row][col] = state.currentPlayer;
          final winner = checkWinner(row, col, newBoard);
          
          final newHistory = List<(int, int)>.from(state.moveHistory)
            ..add((row, col));
          
          state = state.copyWith(
            board: newBoard,
            currentPlayer: PieceType.black,
            isGameOver: winner != null,
            winner: winner,
            moveHistory: newHistory,
          );
        }
      }
    });
  }

  void resetGame() {
    state = GameState(gameMode: state.gameMode);
  }

  void setGameMode(GameMode mode) {
    state = GameState(gameMode: mode);
  }

  PieceType? checkWinner(int row, int col, List<List<PieceType>> board) {
    final directions = [
      [1, 0], // 水平
      [0, 1], // 垂直
      [1, 1], // 对角线
      [1, -1], // 反对角线
    ];

    final piece = board[row][col];
    
    for (final direction in directions) {
      int count = 1;
      
      // 正向检查
      count += countPieces(row, col, direction[0], direction[1], piece, board);
      // 反向检查
      count += countPieces(row, col, -direction[0], -direction[1], piece, board);

      if (count >= 5) {
        return piece;
      }
    }
    return null;
  }

  int countPieces(int row, int col, int dx, int dy, PieceType piece,
      List<List<PieceType>> board) {
    int count = 0;
    int currentRow = row + dx;
    int currentCol = col + dy;

    while (currentRow >= 0 &&
        currentRow < GameState.boardSize &&
        currentCol >= 0 &&
        currentCol < GameState.boardSize &&
        board[currentRow][currentCol] == piece) {
      count++;
      currentRow += dx;
      currentCol += dy;
    }

    return count;
  }

  void undoMove() {
    // 如果是AI模式且不是玩家回合，不允许悔棋
    if (state.gameMode == GameMode.playerVsAI && 
        state.currentPlayer == PieceType.white) {
      return;
    }

    // 如果没有历史记录，直接返回
    if (state.moveHistory.isEmpty) return;
    
    // 创建新的棋盘状态
    final newBoard = List<List<PieceType>>.generate(
      GameState.boardSize,
      (i) => List<PieceType>.from(state.board[i]),
    );
    
    List<(int, int)> newHistory = List.from(state.moveHistory);
    
    // 在AI模式下撤销两步
    if (state.gameMode == GameMode.playerVsAI) {
      // 确保有至少两步可以撤销
      if (newHistory.length < 2) return;
      
      // 移除AI的最后一步
      final aiMove = newHistory.removeLast();
      newBoard[aiMove.$1][aiMove.$2] = PieceType.empty;
      
      // 移除玩家的最后一步
      final playerMove = newHistory.removeLast();
      newBoard[playerMove.$1][playerMove.$2] = PieceType.empty;
    } else {
      // 人人对战模式只撤销一步
      final lastMove = newHistory.removeLast();
      newBoard[lastMove.$1][lastMove.$2] = PieceType.empty;
    }
    
    state = state.copyWith(
      board: newBoard,
      currentPlayer: state.gameMode == GameMode.playerVsAI ? 
          PieceType.black :  // AI模式下总是回到玩家回合
          (state.currentPlayer == PieceType.black ? 
              PieceType.white : 
              PieceType.black),
      isGameOver: false,
      winner: null,
      moveHistory: newHistory,
    );
  }
} 