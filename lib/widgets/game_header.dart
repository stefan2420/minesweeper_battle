import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GameHeader extends StatelessWidget {
  final int mineCount;
  final int elapsedSeconds;
  final GameStatus status;
  final VoidCallback onRestart;

  const GameHeader({
    super.key,
    required this.mineCount,
    required this.elapsedSeconds,
    required this.status,
    required this.onRestart,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mine counter
          _buildCounter(
            icon: Icons.flag,
            value: mineCount.toString().padLeft(3, '0'),
            color: Colors.red,
          ),

          // Face button / Restart
          GestureDetector(
            onTap: onRestart,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Text(
                _getFaceEmoji(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          // Timer
          _buildCounter(
            icon: Icons.timer,
            value: _formatTime(elapsedSeconds),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildCounter({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _getFaceEmoji() {
    switch (status) {
      case GameStatus.won:
        return '😎';
      case GameStatus.lost:
        return '😵';
      default:
        return '🙂';
    }
  }
}
