import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.35,
      child: Card(
        elevation: unlocked ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (unlocked) ...[
                const SizedBox(height: 6),
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
