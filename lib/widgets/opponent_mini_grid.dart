import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
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

    final progress = opponent!.getProgress(difficulty);
    final status = opponent!.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Opponent name and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 20,
                      color: _getBorderColor(context, status),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      opponent!.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getBorderColor(context, status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Linear progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBorderColor(context, status),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  context,
                  Icons.check_circle_outline,
                  'Revealed',
                  opponent!.revealedCells.toString(),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Theme.of(context).colorScheme.outline,
                ),
                _buildStat(
                  context,
                  Icons.flag_outlined,
                  'Flags',
                  opponent!.flaggedCells.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(BuildContext context, String status) {
    switch (status) {
      case 'won':
        return Colors.green;
      case 'lost':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.primary;
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
