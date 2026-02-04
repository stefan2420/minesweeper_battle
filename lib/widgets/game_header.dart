import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM, vertical: DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mine counter (clamp to 0 minimum to prevent negative display)
          _buildCounter(
            context,
            icon: Icons.flag,
            value: mineCount.clamp(0, 999).toString().padLeft(3, '0'),
            color: mineCount < 0 ? Colors.orange : Colors.red,
          ),

          // Face button / Restart
          Semantics(
            label: _getSemanticLabel(),
            button: true,
            hint: 'Tap to restart game',
            child: GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  _getFaceEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),

          // Timer
          _buildCounter(
            context,
            icon: Icons.timer,
            value: _formatTime(elapsedSeconds),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(
    BuildContext context, {
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS + 4, vertical: DesignTokens.spacingXs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              color: color,
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

  String _getSemanticLabel() {
    switch (status) {
      case GameStatus.won:
        return 'Game won';
      case GameStatus.lost:
        return 'Game lost';
      default:
        return 'Game in progress';
    }
  }
}
