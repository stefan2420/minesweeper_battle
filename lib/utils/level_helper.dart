import 'package:flutter/material.dart';
import '../services/xp_service.dart';

/// Helper class for level display and XP visualization
class LevelHelper {
  /// Get level badge color based on level ranges
  static Color getLevelColor(int level) {
    if (level >= 100) return const Color(0xFFFF1493); // Deep pink - Legendary
    if (level >= 75) return const Color(0xFFFF4500); // Orange-red - Master
    if (level >= 50) return const Color(0xFF9370DB); // Purple - Expert
    if (level >= 30) return const Color(0xFF00CED1); // Cyan - Advanced
    if (level >= 15) return const Color(0xFFFFD700); // Gold - Intermediate
    if (level >= 5) return const Color(0xFFC0C0C0); // Silver - Beginner
    return const Color(0xFFCD7F32); // Bronze - Novice
  }

  /// Get level tier name based on level ranges
  static String getLevelTier(int level) {
    if (level >= 100) return 'Legendary';
    if (level >= 75) return 'Master';
    if (level >= 50) return 'Expert';
    if (level >= 30) return 'Advanced';
    if (level >= 15) return 'Intermediate';
    if (level >= 5) return 'Beginner';
    return 'Novice';
  }

  /// Get level icon
  static IconData getLevelIcon(int level) {
    if (level >= 100) return Icons.auto_awesome; // Sparkle - Legendary
    if (level >= 75) return Icons.emoji_events; // Trophy - Master
    if (level >= 50) return Icons.stars; // Stars - Expert
    if (level >= 30) return Icons.star; // Star - Advanced
    if (level >= 15) return Icons.workspace_premium; // Medal - Intermediate
    if (level >= 5) return Icons.shield; // Shield - Beginner
    return Icons.person; // Person - Novice
  }

  /// Format XP with thousands separator (e.g., 1,234 XP)
  static String formatXP(int xp) {
    return xp.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Get XP progress information for a given total XP
  static XPProgressInfo getProgressInfo(int totalXP) {
    final currentLevel = XPService.calculateLevel(totalXP);
    final currentLevelXP = XPService.xpForLevel(currentLevel);
    final nextLevelXP = XPService.xpForLevel(currentLevel + 1);
    final xpInLevel = totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;
    final progress = XPService.levelProgress(totalXP);

    return XPProgressInfo(
      currentLevel: currentLevel,
      totalXP: totalXP,
      xpInCurrentLevel: xpInLevel,
      xpNeededForNextLevel: xpNeededForLevel,
      xpToNextLevel: nextLevelXP - totalXP,
      progressPercent: (progress * 100).round(),
      progress: progress,
    );
  }

  /// Build a visual XP progress bar widget
  static Widget buildProgressBar({
    required int totalXP,
    double height = 8,
    bool showLabel = false,
  }) {
    final info = getProgressInfo(totalXP);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${info.xpInCurrentLevel} / ${info.xpNeededForNextLevel} XP (${info.progressPercent}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: info.progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              getLevelColor(info.currentLevel),
            ),
            minHeight: height,
          ),
        ),
      ],
    );
  }

  /// Build a level badge widget with icon and level number
  static Widget buildLevelBadge({
    required int level,
    double size = 32,
    bool showTier = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: getLevelColor(level),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: getLevelColor(level).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
        if (showTier)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              getLevelTier(level),
              style: TextStyle(
                fontSize: 10,
                color: getLevelColor(level),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Data class for XP progress information
class XPProgressInfo {
  final int currentLevel;
  final int totalXP;
  final int xpInCurrentLevel;
  final int xpNeededForNextLevel;
  final int xpToNextLevel;
  final int progressPercent;
  final double progress;

  XPProgressInfo({
    required this.currentLevel,
    required this.totalXP,
    required this.xpInCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.xpToNextLevel,
    required this.progressPercent,
    required this.progress,
  });
}
