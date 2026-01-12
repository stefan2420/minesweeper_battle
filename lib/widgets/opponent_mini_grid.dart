import 'package:flutter/material.dart';
import '../models/battle_session.dart';
import '../models/game_board.dart';

class OpponentMiniGrid extends StatelessWidget {
  final PlayerState? opponent;
  final Difficulty difficulty;

  const OpponentMiniGrid({
    super.key,
    required this.opponent,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    if (opponent == null) {
      return const SizedBox.shrink();
    }

    final config = GameBoardConfig.fromDifficulty(difficulty);
    final progress = opponent!.getProgress(difficulty);
    final status = opponent!.status;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(status),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Opponent name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(status),
                size: 16,
                color: _getBorderColor(status),
              ),
              const SizedBox(width: 4),
              Text(
                opponent!.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini grid visualization
          SizedBox(
            width: 80,
            height: 80 * (config.rows / config.cols),
            child: CustomPaint(
              painter: _MiniGridPainter(
                rows: config.rows,
                cols: config.cols,
                revealedPercent: progress,
                status: status,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Progress percentage
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getBorderColor(status),
            ),
          ),

          // Stats
          Text(
            'Revealed: ${opponent!.revealedCells} | Flags: ${opponent!.flaggedCells}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(String status) {
    switch (status) {
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'won':
        return Icons.emoji_events;
      case 'lost':
        return Icons.close;
      default:
        return Icons.play_arrow;
    }
  }
}

class _MiniGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double revealedPercent;
  final String status;

  _MiniGridPainter({
    required this.rows,
    required this.cols,
    required this.revealedPercent,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final hiddenPaint = Paint()..color = Colors.grey.shade400;
    final revealedPaint = Paint()..color = Colors.grey.shade300;
    final borderPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Calculate how many cells are revealed (simplified visualization)
    final totalCells = rows * cols;
    final revealedCells = (totalCells * revealedPercent).round();

    int cellIndex = 0;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );

        // Fill cell
        canvas.drawRect(
          rect,
          cellIndex < revealedCells ? revealedPaint : hiddenPaint,
        );

        // Draw border
        canvas.drawRect(rect, borderPaint);

        cellIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter oldDelegate) {
    return oldDelegate.revealedPercent != revealedPercent ||
        oldDelegate.status != status;
  }
}
