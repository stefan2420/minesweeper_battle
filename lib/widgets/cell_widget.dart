import 'package:flutter/material.dart';
import '../models/cell.dart';

class CellWidget extends StatelessWidget {
  final Cell cell;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool gameOver;

  const CellWidget({
    super.key,
    required this.cell,
    required this.size,
    required this.onTap,
    required this.onLongPress,
    this.gameOver = false,
  });

  static const _numberColors = [
    Colors.transparent, // 0 - not used
    Colors.blue,        // 1
    Colors.green,       // 2
    Colors.red,         // 3
    Colors.purple,      // 4
    Colors.brown,       // 5
    Colors.cyan,        // 6
    Colors.black,       // 7
    Colors.grey,        // 8
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gameOver ? null : onTap,
      onLongPress: gameOver ? null : onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: Colors.grey.shade400,
            width: 0.5,
          ),
          boxShadow: cell.isHidden || cell.isFlagged
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-1, -1),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.grey.shade600,
                    offset: const Offset(1, 1),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (cell.isRevealed) {
      if (cell.hasMine) {
        return Colors.red.shade300;
      }
      return Colors.grey.shade300;
    }
    return Colors.grey.shade400;
  }

  Widget? _buildContent() {
    if (cell.isFlagged) {
      return Icon(
        Icons.flag,
        color: Colors.red,
        size: size * 0.6,
      );
    }

    if (cell.isRevealed) {
      if (cell.hasMine) {
        return Icon(
          Icons.brightness_7,
          color: Colors.black,
          size: size * 0.7,
        );
      }

      if (cell.adjacentMines > 0) {
        return Text(
          '${cell.adjacentMines}',
          style: TextStyle(
            color: _numberColors[cell.adjacentMines],
            fontWeight: FontWeight.bold,
            fontSize: size * 0.6,
          ),
        );
      }
    }

    return null;
  }
}
