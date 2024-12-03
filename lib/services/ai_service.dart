import '../models/game_state.dart';
import '../models/settings_state.dart';

class AIService {
  static const int maxDepth = 3;
  static const int winScore = 1000000;
  static const int fourScore = 100000;
  static const int threeScore = 10000;
  static const int twoScore = 100;
  static const int oneScore = 10;
  
  static const int maxValue = 1000000;
  static const int minValue = -1000000;

  // 添加缓存
  static final Map<String, int> _evaluationCache = {};
  static const int maxCacheSize = 10000;

  static (int, int) getBestMove(
    List<List<PieceType>> board, 
    PieceType aiPlayer,
    AIDifficulty difficulty,
  ) {
    final depth = switch (difficulty) {
      AIDifficulty.easy => 1,
      AIDifficulty.medium => 2,
      AIDifficulty.hard => 2,
    };

    // 先检查紧急情况
    final emergencyMove = _checkEmergencyMove(board, aiPlayer);
    if (emergencyMove != null) {
      return emergencyMove;
    }

    // 优化移动生成
    final moves = _getSmartMoves(board, aiPlayer);
    
    int bestScore = minValue;
    int bestRow = -1;
    int bestCol = -1;
    
    if (difficulty == AIDifficulty.easy) {
      moves.shuffle();
    }
    
    for (final move in moves) {
      final row = move.$1;
      final col = move.$2;
      
      board[row][col] = aiPlayer;
      final score = _minimax(
        board,
        depth,
        minValue,
        maxValue,
        false,
        aiPlayer,
        difficulty,
      );
      board[row][col] = PieceType.empty;

      if (difficulty == AIDifficulty.easy && score > 0) {
        if (_randomChance(0.2)) {
          continue;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestRow = row;
        bestCol = col;
      }
    }

    return (bestRow, bestCol);
  }

  static bool _randomChance(double probability) {
    return DateTime.now().millisecondsSinceEpoch % 100 < (probability * 100);
  }

  // 智能移动生成：只考虑有价值的位置
  static List<(int, int)> _getSmartMoves(
    List<List<PieceType>> board,
    PieceType aiPlayer,
  ) {
    final moves = <(int, int)>[];
    final visited = List.generate(
      GameState.boardSize,
      (_) => List.filled(GameState.boardSize, false),
    );

    // 先检查紧急位置
    final emergencyMoves = _getEmergencyMoves(board, aiPlayer);
    if (emergencyMoves.isNotEmpty) {
      return emergencyMoves;
    }

    // 只检查已有棋子周围2格范围内的位置
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] != PieceType.empty) {
          for (int di = -2; di <= 2; di++) {
            for (int dj = -2; dj <= 2; dj++) {
              final ni = i + di;
              final nj = j + dj;
              if (ni >= 0 && ni < GameState.boardSize &&
                  nj >= 0 && nj < GameState.boardSize &&
                  board[ni][nj] == PieceType.empty &&
                  !visited[ni][nj]) {
                moves.add((ni, nj));
                visited[ni][nj] = true;
              }
            }
          }
        }
      }
    }

    // 如果棋盘为空或没有找到合适的位置
    if (moves.isEmpty) {
      final center = GameState.boardSize ~/ 2;
      return [(center, center)];
    }

    // 对移动进行评分并排序
    moves.sort((a, b) {
      final scoreA = _quickEvaluatePosition(board, a.$1, a.$2, aiPlayer);
      final scoreB = _quickEvaluatePosition(board, b.$1, b.$2, aiPlayer);
      return scoreB.compareTo(scoreA);
    });

    // 只返回最好的前12个位置
    return moves.take(12).toList();
  }

  // 快速评估位置价值
  static int _quickEvaluatePosition(
    List<List<PieceType>> board,
    int row,
    int col,
    PieceType player,
  ) {
    int score = 0;
    final center = GameState.boardSize ~/ 2;
    
    // 计算到中心的���离
    score += 10 - ((row - center).abs() + (col - center).abs());

    // 检查周围是否有己方棋子
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        final ni = row + i;
        final nj = col + j;
        if (ni >= 0 && ni < GameState.boardSize &&
            nj >= 0 && nj < GameState.boardSize) {
          if (board[ni][nj] == player) {
            score += 5;
          }
        }
      }
    }

    return score;
  }

  static int _minimax(
    List<List<PieceType>> board,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
    PieceType aiPlayer,
    AIDifficulty difficulty,
  ) {
    if (depth == 0) {
      return _evaluateBoard(board, aiPlayer, difficulty);
    }

    final moves = _getSmartMoves(board, aiPlayer);
    final humanPlayer = 
        aiPlayer == PieceType.black ? PieceType.white : PieceType.black;
    
    if (isMaximizing) {
      int maxScore = minValue;
      for (final move in moves) {
        board[move.$1][move.$2] = aiPlayer;
        final score = _minimax(board, depth - 1, alpha, beta, false, aiPlayer, difficulty);
        board[move.$1][move.$2] = PieceType.empty;
        
        maxScore = maxScore > score ? maxScore : score;
        alpha = alpha > maxScore ? alpha : maxScore;
        if (beta <= alpha) break;
      }
      return maxScore;
    } else {
      int minScore = maxValue;
      for (final move in moves) {
        board[move.$1][move.$2] = humanPlayer;
        final score = _minimax(board, depth - 1, alpha, beta, true, aiPlayer, difficulty);
        board[move.$1][move.$2] = PieceType.empty;
        
        minScore = minScore < score ? minScore : score;
        beta = beta < minScore ? beta : minScore;
        if (beta <= alpha) break;
      }
      return minScore;
    }
  }

  // 优化评估函数
  static int _evaluateBoard(
    List<List<PieceType>> board,
    PieceType aiPlayer,
    AIDifficulty difficulty,
  ) {
    // 使用缓存
    final key = _getBoardKey(board, aiPlayer);
    if (_evaluationCache.containsKey(key)) {
      return _evaluationCache[key]!;
    }

    int score = 0;
    final humanPlayer = 
        aiPlayer == PieceType.black ? PieceType.white : PieceType.black;

    // 提高防守权重
    final defenseWeight = switch (difficulty) {
      AIDifficulty.easy => 1.0,    // 提高简单模式的防守意识
      AIDifficulty.medium => 1.3,  // 提高中等模式的防守意识
      AIDifficulty.hard => 1.5,    // 提高困难模式的防守意识
    };

    // 检查紧急威胁
    bool hasEmergencyThreat = _checkEmergencyThreat(board, humanPlayer);
    if (hasEmergencyThreat) {
      return -winScore * 2;  // 发现紧急威胁时，优先防守
    }

    // 评估所有方向
    final directions = [
      [1, 0], // 水平
      [0, 1], // 垂直
      [1, 1], // 对角线
      [1, -1], // 反对角线
    ];

    // 获取每个方向的连续棋子
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] != PieceType.empty) {
          for (final direction in directions) {
            final line = _getLine(board, i, j, direction[0], direction[1]);
            if (line.length >= 5) {
              final value = _evaluatePattern(line, board[i][j]);
              if (board[i][j] == aiPlayer) {
                score += value;
              } else {
                score -= (value * defenseWeight).toInt(); // 使用防守权重
              }
            }
          }
        }
      }
    }

    // 位置评估权重也随难度调整
    final positionWeight = switch (difficulty) {
      AIDifficulty.easy => 0.5,
      AIDifficulty.medium => 1.0,
      AIDifficulty.hard => 1.5,
    };
    
    score += (_evaluatePosition(board, aiPlayer) * positionWeight).toInt();

    // 缓存结果
    if (_evaluationCache.length >= maxCacheSize) {
      _evaluationCache.clear();
    }
    _evaluationCache[key] = score;
    return score;
  }

  // 生成棋盘状态的唯一���
  static String _getBoardKey(List<List<PieceType>> board, PieceType aiPlayer) {
    return board.map((row) => row.map((p) => p.index).join())
        .join() + aiPlayer.index.toString();
  }

  // 获取一条线上的所有棋子
  static List<PieceType> _getLine(
    List<List<PieceType>> board,
    int startRow,
    int startCol,
    int dRow,
    int dCol,
  ) {
    List<PieceType> line = [];
    int row = startRow;
    int col = startCol;

    while (row >= 0 && row < GameState.boardSize &&
           col >= 0 && col < GameState.boardSize) {
      line.add(board[row][col]);
      row += dRow;
      col += dCol;
    }

    return line;
  }

  // 优化评估棋型函数
  static int _evaluatePattern(List<PieceType> line, PieceType player) {
    String pattern = line.map((p) => 
      p == PieceType.empty ? '0' : 
      p == player ? '1' : '2'
    ).join();
    
    // 连五
    if (pattern.contains('11111')) return winScore;
    
    // 活四或双四
    if (pattern.contains('011110')) return fourScore * 3;
    if (pattern.contains('11110') && pattern.contains('01111')) return fourScore * 2;
    
    // 活三
    if (pattern.contains('01110')) return threeScore * 2;
    if (pattern.contains('010110') || 
        pattern.contains('011010')) return (threeScore * 3) ~/ 2;
    
    // 眠四
    if (pattern.contains('11110') || 
        pattern.contains('01111') ||
        pattern.contains('11011')) return fourScore;
    
    // 眠三
    if (pattern.contains('11100') || 
        pattern.contains('00111') ||
        pattern.contains('11010') ||
        pattern.contains('01011')) return threeScore;
    
    // 活二
    if (pattern.contains('01100') ||
        pattern.contains('00110')) return (twoScore * 3) ~/ 2;
    
    return 0;
  }

  // 评估位置价值
  static int _evaluatePosition(List<List<PieceType>> board, PieceType aiPlayer) {
    int score = 0;
    final center = GameState.boardSize ~/ 2;
    
    // 位置权重矩阵
    final weights = List.generate(GameState.boardSize, (i) {
      return List.generate(GameState.boardSize, (j) {
        final distToCenter = (i - center).abs() + (j - center).abs();
        return (10 - distToCenter) * 2; // 越靠近中心权重越高
      });
    });

    // 计算位置分数
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == aiPlayer) {
          score += weights[i][j];
        } else if (board[i][j] != PieceType.empty) {
          score -= weights[i][j];
        }
      }
    }

    return score;
  }

  // 动态调整搜索深度
  static int getSearchDepth(List<List<PieceType>> board) {
    int emptyCount = 0;
    int threatCount = 0;
    
    for (var row in board) {
      emptyCount += row.where((cell) => cell == PieceType.empty).length;
    }
    
    // 计算威胁局面
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] != PieceType.empty) {
          final pattern = _getLine(board, i, j, 1, 0);
          if (_evaluatePattern(pattern, board[i][j]) >= threeScore) {
            threatCount++;
          }
        }
      }
    }
    
    // 根据局面复杂度调整深度
    if (threatCount > 3) return 4;
    if (emptyCount > 200) return 2;
    if (emptyCount > 150) return 3;
    return 3;
  }

  // 添加紧急威胁检查
  static bool _checkEmergencyThreat(List<List<PieceType>> board, PieceType player) {
    // 检查是否有活四或双活三
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == player) {
          // 检查四个方向
          final directions = [
            [1, 0], [0, 1], [1, 1], [1, -1]
          ];
          
          for (final dir in directions) {
            final line = _getLine(board, i, j, dir[0], dir[1]);
            final pattern = line.map((p) => 
              p == PieceType.empty ? '0' : 
              p == player ? '1' : '2'
            ).join();
            
            // 检查活四
            if (pattern.contains('011110')) return true;
            
            // 检查双活三
            int openThreeCount = 0;
            if (pattern.contains('01110')) openThreeCount++;
            if (openThreeCount >= 2) return true;
          }
        }
      }
    }
    return false;
  }

  // 添加紧急位置检查
  static List<(int, int)> _getEmergencyMoves(
    List<List<PieceType>> board,
    PieceType aiPlayer,
  ) {
    final moves = <(int, int)>[];
    final humanPlayer = 
        aiPlayer == PieceType.black ? PieceType.white : PieceType.black;

    // 检查己方胜利机会
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == PieceType.empty) {
          board[i][j] = aiPlayer;
          if (_checkWinningMove(board, i, j, aiPlayer)) {
            moves.add((i, j));
          }
          board[i][j] = PieceType.empty;
        }
      }
    }
    if (moves.isNotEmpty) return moves;

    // 检查对手胜利机会
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == PieceType.empty) {
          board[i][j] = humanPlayer;
          if (_checkWinningMove(board, i, j, humanPlayer)) {
            moves.add((i, j));
          }
          board[i][j] = PieceType.empty;
        }
      }
    }
    return moves;
  }

  // 检查是否是制胜移动
  static bool _checkWinningMove(
    List<List<PieceType>> board,
    int row,
    int col,
    PieceType player,
  ) {
    final directions = [[1, 0], [0, 1], [1, 1], [1, -1]];
    
    for (final dir in directions) {
      int count = 1;
      
      // 正向检查
      int r = row + dir[0];
      int c = col + dir[1];
      while (r >= 0 && r < GameState.boardSize && 
             c >= 0 && c < GameState.boardSize && 
             board[r][c] == player) {
        count++;
        r += dir[0];
        c += dir[1];
      }
      
      // 反向检查
      r = row - dir[0];
      c = col - dir[1];
      while (r >= 0 && r < GameState.boardSize && 
             c >= 0 && c < GameState.boardSize && 
             board[r][c] == player) {
        count++;
        r -= dir[0];
        c -= dir[1];
      }
      
      if (count >= 5) return true;
    }
    return false;
  }

  // 修改紧急情况检查的优先级
  static (int, int)? _checkEmergencyMove(
    List<List<PieceType>> board,
    PieceType aiPlayer,
  ) {
    final humanPlayer = 
        aiPlayer == PieceType.black ? PieceType.white : PieceType.black;

    // 1. 首先检查自己的连四机会
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == PieceType.empty) {
          board[i][j] = aiPlayer;
          if (_checkWinningMove(board, i, j, aiPlayer)) {
            board[i][j] = PieceType.empty;
            return (i, j);
          }
          board[i][j] = PieceType.empty;
        }
      }
    }

    // 2. 检查对手的连四机会
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == PieceType.empty) {
          board[i][j] = humanPlayer;
          if (_checkWinningMove(board, i, j, humanPlayer)) {
            board[i][j] = PieceType.empty;
            return (i, j);
          }
          board[i][j] = PieceType.empty;
        }
      }
    }

    // 3. 检查自己的活三能否形成活四
    var ownThreats = _findThreats(board, aiPlayer);
    if (ownThreats.isNotEmpty) {
      return ownThreats.first;
    }

    // 4. 检查并阻止对手的活三
    var opponentThreats = _findThreats(board, humanPlayer);
    if (opponentThreats.isNotEmpty) {
      return opponentThreats.first;
    }

    return null;
  }

  // 添加查找活三威胁的方法
  static List<(int, int)> _findThreats(
    List<List<PieceType>> board,
    PieceType player,
  ) {
    List<(int, int)> threats = [];
    
    // 遍历所有空位
    for (int i = 0; i < GameState.boardSize; i++) {
      for (int j = 0; j < GameState.boardSize; j++) {
        if (board[i][j] == PieceType.empty) {
          // 检查这个位置是否能形成活四
          board[i][j] = player;
          if (_hasOpenFour(board, i, j, player)) {
            threats.add((i, j));
          }
          board[i][j] = PieceType.empty;
        }
      }
    }
    
    return threats;
  }

  // 添加活四检测方法
  static bool _hasOpenFour(
    List<List<PieceType>> board,
    int row,
    int col,
    PieceType player,
  ) {
    final directions = [[1, 0], [0, 1], [1, 1], [1, -1]];
    
    for (final dir in directions) {
      List<PieceType> line = [];
      int r = row - dir[0] * 4;
      int c = col - dir[1] * 4;
      
      for (int i = 0; i < 9; i++) {
        if (r >= 0 && r < GameState.boardSize && 
            c >= 0 && c < GameState.boardSize) {
          line.add(board[r][c]);
        } else {
          line.add(PieceType.empty);
        }
        r += dir[0];
        c += dir[1];
      }
      
      String pattern = line.map((p) => 
        p == PieceType.empty ? '0' : 
        p == player ? '1' : '2'
      ).join();

      // 检查活四模式
      if (pattern.contains('011110')) {
        return true;
      }
    }
    return false;
  }
} 