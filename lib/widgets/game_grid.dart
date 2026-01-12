import 'package:flutter/material.dart';
import '../models/game_board.dart';
import 'cell_widget.dart';

class GameGrid extends StatelessWidget {
  final GameBoard board;
  final bool gameOver;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellLongPress;
  final double? maxHeight;

  const GameGrid({
    super.key,
    required this.board,
    required this.onCellTap,
    required this.onCellLongPress,
    this.gameOver = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cell size for perfect fit
        final availableWidth = constraints.maxWidth;
        final availableHeight = maxHeight ?? constraints.maxHeight;

        // Calculate cell size based on grid dimensions
        final cellWidth = availableWidth / board.cols;
        final cellHeight = availableHeight / board.rows;
        final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

        // Calculate total grid dimensions
        final gridWidth = cellSize * board.cols;
        final gridHeight = cellSize * board.rows;

        return Center(
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(board.rows, (row) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.cols, (col) {
                    final cell = board.getCell(row, col);
                    return CellWidget(
                      cell: cell,
                      size: cellSize,
                      gameOver: gameOver,
                      onTap: () => onCellTap(row, col),
                      onLongPress: () => onCellLongPress(row, col),
                    );
                  }),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
