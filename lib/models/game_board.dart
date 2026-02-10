import 'dart:convert';
import 'dart:math';
import 'cell.dart';

enum Difficulty { beginner, intermediate, expert }

/// Extension to provide consistent difficulty naming across the app
extension DifficultyExtension on Difficulty {
  /// Get the display name for this difficulty level
  String get displayName {
    switch (this) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  /// Get the display name with board size (e.g., "Beginner (9×9)")
  String get displayNameWithSize {
    final config = GameBoardConfig.fromDifficulty(this);
    return '$displayName (${config.cols}×${config.rows})';
  }
}

class GameBoardConfig {
  final int rows;
  final int cols;
  final int mines;

  const GameBoardConfig({
    required this.rows,
    required this.cols,
    required this.mines,
  });

  static GameBoardConfig fromDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return const GameBoardConfig(rows: 9, cols: 9, mines: 10);
      case Difficulty.intermediate:
        return const GameBoardConfig(rows: 16, cols: 16, mines: 40);
      case Difficulty.expert:
        return const GameBoardConfig(rows: 16, cols: 30, mines: 99);
    }
  }
}

class GameBoard {
  final int rows;
  final int cols;
  final int totalMines;
  late List<List<Cell>> grid;
  bool minesPlaced = false;
  int revealedCount = 0;
  int flaggedCount = 0;

  GameBoard({
    required this.rows,
    required this.cols,
    required this.totalMines,
  }) {
    _initializeGrid();
  }

  factory GameBoard.fromDifficulty(Difficulty difficulty) {
    final config = GameBoardConfig.fromDifficulty(difficulty);
    return GameBoard(
      rows: config.rows,
      cols: config.cols,
      totalMines: config.mines,
    );
  }

  void _initializeGrid() {
    grid = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) => Cell(row: row, col: col),
      ),
    );
  }

  Cell getCell(int row, int col) => grid[row][col];

  bool isValidCell(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  List<Cell> getNeighbors(int row, int col) {
    final neighbors = <Cell>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (isValidCell(nr, nc)) {
          neighbors.add(grid[nr][nc]);
        }
      }
    }
    return neighbors;
  }

  void placeMines(int safeRow, int safeCol) {
    if (minesPlaced) return;

    final random = Random();
    final safeZone = <String>{};

    // Create safe zone around first click (3x3 area)
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = safeRow + dr;
        final nc = safeCol + dc;
        if (isValidCell(nr, nc)) {
          safeZone.add('$nr,$nc');
        }
      }
    }

    int placedMines = 0;
    while (placedMines < totalMines) {
      final row = random.nextInt(rows);
      final col = random.nextInt(cols);
      final key = '$row,$col';

      if (!safeZone.contains(key) && !grid[row][col].hasMine) {
        grid[row][col].hasMine = true;
        placedMines++;
      }
    }

    // Calculate adjacent mine counts
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (!grid[row][col].hasMine) {
          int count = 0;
          for (final neighbor in getNeighbors(row, col)) {
            if (neighbor.hasMine) count++;
          }
          grid[row][col].adjacentMines = count;
        }
      }
    }

    minesPlaced = true;
  }

  // Returns true if hit mine
  bool revealCell(int row, int col) {
    if (!isValidCell(row, col)) return false;

    final cell = grid[row][col];
    if (cell.isRevealed || cell.isFlagged) return false;

    if (!minesPlaced) {
      placeMines(row, col);
    }

    cell.state = CellState.revealed;
    revealedCount++;

    if (cell.hasMine) {
      return true; // Hit mine
    }

    // Flood fill for empty cells
    if (cell.adjacentMines == 0) {
      for (final neighbor in getNeighbors(row, col)) {
        if (neighbor.isHidden && !neighbor.hasMine) {
          revealCell(neighbor.row, neighbor.col);
        }
      }
    }

    return false;
  }

  void toggleFlag(int row, int col) {
    if (!isValidCell(row, col)) return;

    final cell = grid[row][col];
    if (cell.isRevealed) return;

    if (cell.isFlagged) {
      cell.state = CellState.hidden;
      flaggedCount--;
    } else {
      cell.state = CellState.flagged;
      flaggedCount++;
    }
  }

  /// Chord clicking: Reveals all unflagged neighbors if enough flags are placed
  /// Returns true if any mine was hit during chording
  bool chordCell(int row, int col) {
    if (!isValidCell(row, col)) return false;

    final cell = grid[row][col];

    // Can only chord on revealed cells with numbers
    if (!cell.isRevealed || cell.adjacentMines == 0) return false;

    // Count flagged neighbors
    final neighbors = getNeighbors(row, col);
    final flaggedNeighbors = neighbors.where((n) => n.isFlagged).length;

    // Only chord if flagged count matches adjacent mines count
    if (flaggedNeighbors != cell.adjacentMines) return false;

    // Reveal all unflagged neighbors
    bool hitMine = false;
    for (final neighbor in neighbors) {
      if (!neighbor.isRevealed && !neighbor.isFlagged) {
        final result = revealCell(neighbor.row, neighbor.col);
        if (result) hitMine = true;
      }
    }

    return hitMine;
  }

  void revealAllMines() {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (grid[row][col].hasMine) {
          grid[row][col].state = CellState.revealed;
        }
      }
    }
  }

  bool checkWin() {
    final totalCells = rows * cols;
    final nonMineCells = totalCells - totalMines;
    return revealedCount == nonMineCells;
  }

  int get remainingMines => totalMines - flaggedCount;

  String serialize() {
    final data = {
      'rows': rows,
      'cols': cols,
      'totalMines': totalMines,
      'minesPlaced': minesPlaced,
      'revealedCount': revealedCount,
      'flaggedCount': flaggedCount,
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    };
    return jsonEncode(data);
  }

  factory GameBoard.deserialize(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final board = GameBoard(
      rows: data['rows'] as int,
      cols: data['cols'] as int,
      totalMines: data['totalMines'] as int,
    );
    board.minesPlaced = data['minesPlaced'] as bool;
    board.revealedCount = data['revealedCount'] as int;
    board.flaggedCount = data['flaggedCount'] as int;

    final gridData = data['grid'] as List<dynamic>;
    board.grid = gridData.map((rowData) {
      return (rowData as List<dynamic>).map((cellData) {
        return Cell.fromJson(cellData as Map<String, dynamic>);
      }).toList();
    }).toList();

    return board;
  }
}
