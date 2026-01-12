import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_battle/models/game_board.dart';
import 'package:minesweeper_battle/models/cell.dart';

void main() {
  group('GameBoard', () {
    test('creates board with correct dimensions', () {
      final board = GameBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.rows, 9);
      expect(board.cols, 9);
      expect(board.totalMines, 10);
    });

    test('places mines after first click', () {
      final board = GameBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.minesPlaced, false);

      board.revealCell(4, 4);
      expect(board.minesPlaced, true);

      int mineCount = 0;
      for (int r = 0; r < board.rows; r++) {
        for (int c = 0; c < board.cols; c++) {
          if (board.getCell(r, c).hasMine) mineCount++;
        }
      }
      expect(mineCount, 10);
    });

    test('first click area is safe', () {
      final board = GameBoard(rows: 9, cols: 9, totalMines: 10);
      board.revealCell(4, 4);

      // Check 3x3 area around first click is mine-free
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          expect(board.getCell(4 + dr, 4 + dc).hasMine, false);
        }
      }
    });

    test('toggle flag works correctly', () {
      final board = GameBoard(rows: 9, cols: 9, totalMines: 10);

      expect(board.getCell(0, 0).isFlagged, false);
      board.toggleFlag(0, 0);
      expect(board.getCell(0, 0).isFlagged, true);
      board.toggleFlag(0, 0);
      expect(board.getCell(0, 0).isFlagged, false);
    });
  });

  group('Cell', () {
    test('creates cell with default values', () {
      final cell = Cell(row: 0, col: 0);
      expect(cell.hasMine, false);
      expect(cell.adjacentMines, 0);
      expect(cell.state, CellState.hidden);
    });

    test('cell states work correctly', () {
      final cell = Cell(row: 0, col: 0);
      expect(cell.isHidden, true);
      expect(cell.isRevealed, false);
      expect(cell.isFlagged, false);

      cell.state = CellState.flagged;
      expect(cell.isFlagged, true);

      cell.state = CellState.revealed;
      expect(cell.isRevealed, true);
    });
  });

  group('Difficulty configurations', () {
    test('beginner config is correct', () {
      final config = GameBoardConfig.fromDifficulty(Difficulty.beginner);
      expect(config.rows, 9);
      expect(config.cols, 9);
      expect(config.mines, 10);
    });

    test('intermediate config is correct', () {
      final config = GameBoardConfig.fromDifficulty(Difficulty.intermediate);
      expect(config.rows, 16);
      expect(config.cols, 16);
      expect(config.mines, 40);
    });

    test('expert config is correct', () {
      final config = GameBoardConfig.fromDifficulty(Difficulty.expert);
      expect(config.rows, 16);
      expect(config.cols, 30);
      expect(config.mines, 99);
    });
  });
}
