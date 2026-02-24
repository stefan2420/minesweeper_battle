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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AnimatedCounter(
            icon: Icons.flag_rounded,
            value: mineCount.clamp(-99, 999).toString().padLeft(3, '0'),
            color: mineCount < 0 ? AppColors.warning : AppColors.danger,
          ),
          Semantics(
            label: _getSemanticLabel(),
            button: true,
            hint: 'Tap to restart game',
            child: GestureDetector(
              onTap: onRestart,
              child: AnimatedSwitcher(
                duration: DesignTokens.animationNormal,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Container(
                  key: ValueKey(status),
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getFaceEmoji(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
          ),
          _AnimatedCounter(
            icon: Icons.timer_rounded,
            value: _formatTime(elapsedSeconds),
            color: colors.primary,
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

/// Counter widget that animates when its value changes.
class _AnimatedCounter extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _AnimatedCounter({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: DesignTokens.animationFast,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
