import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// Dialog that shows game instructions for new players
class GameInstructionsDialog extends StatelessWidget {
  const GameInstructionsDialog({super.key});

  /// Show the instructions dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const GameInstructionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to Play Minesweeper'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInstruction(
              context,
              Icons.touch_app,
              'Tap',
              'Reveal a cell to see what\'s underneath',
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildInstruction(
              context,
              Icons.flag,
              'Long press',
              'Place or remove a flag to mark suspected mines',
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'Goal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Numbers show how many mines are in adjacent cells. Use this information to deduce where mines are hidden. Clear all non-mine cells to win!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'Tips',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            _buildTip(context, 'Start with corners and edges'),
            _buildTip(context, 'Flag suspected mines to track them'),
            _buildTip(context, 'Empty cells reveal surrounding cells'),
            _buildTip(context, 'Use logic, not luck!'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildInstruction(
    BuildContext context,
    IconData icon,
    String action,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
