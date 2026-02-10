import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/game_board.dart';

/// Service for calculating and awarding XP (experience points) and player levels
class XPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // XP Constants
  static const int baseMatchXP = 50; // Participation reward for completing a match
  static const int winBonusXP = 100; // Additional XP for winning
  static const int maxPerformanceBonusXP = 50; // Max bonus for fast completion
  static const int minimumMatchDuration = 30; // Seconds - prevents instant farming

  /// Calculate level from total XP
  /// Formula: Level = floor((totalXP / 100) ^ (1/1.5))
  /// Inverse of: XP = 100 * level^1.5
  static int calculateLevel(int totalXP) {
    if (totalXP < 0) return 1;
    // Level formula: find N where 100 * N^1.5 = totalXP
    // Solve: N = (totalXP / 100) ^ (1/1.5)
    final level = pow(totalXP / 100, 1 / 1.5).floor();
    return max(1, level); // Minimum level is 1
  }

  /// Calculate total XP required to reach a specific level
  /// Formula: XP = 100 * level^1.5
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * pow(level, 1.5)).round();
  }

  /// Calculate XP needed for next level
  static int xpToNextLevel(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final nextLevelXP = xpForLevel(currentLevel + 1);
    return nextLevelXP - totalXP;
  }

  /// Calculate XP progress within current level (0.0 to 1.0)
  static double levelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final currentLevelXP = xpForLevel(currentLevel);
    final nextLevelXP = xpForLevel(currentLevel + 1);
    final xpInLevel = totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;

    if (xpNeededForLevel <= 0) return 1.0;
    return (xpInLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Calculate performance bonus XP based on finish time and difficulty
  /// Faster completion = more bonus XP
  int _calculatePerformanceBonus(int finishTimeSeconds, Difficulty difficulty) {
    // Define target times for each difficulty (in seconds)
    final targetTimes = {
      Difficulty.beginner: 60, // 1 minute
      Difficulty.intermediate: 120, // 2 minutes
      Difficulty.expert: 180, // 3 minutes
    };

    final targetTime = targetTimes[difficulty] ?? 120;

    // If finished faster than target, award bonus proportional to time saved
    if (finishTimeSeconds < targetTime) {
      final timeSaved = targetTime - finishTimeSeconds;
      final bonusRatio = (timeSaved / targetTime).clamp(0.0, 1.0);
      return (maxPerformanceBonusXP * bonusRatio).round();
    }

    return 0; // No bonus if slower than target
  }

  /// Calculate total XP to award for a match
  int calculateMatchXP({
    required bool won,
    required int finishTimeSeconds,
    required Difficulty difficulty,
  }) {
    // Anti-abuse: No XP for matches shorter than minimum duration
    if (finishTimeSeconds < minimumMatchDuration) {
      return 0;
    }

    int totalXP = baseMatchXP;

    if (won) {
      totalXP += winBonusXP;
      // Only winners get performance bonus (incentivize winning fast)
      totalXP += _calculatePerformanceBonus(finishTimeSeconds, difficulty);
    }

    return totalXP;
  }

  /// Award XP to both players after a match and update levels
  /// Call this from the winner's perspective to award XP to both players atomically
  Future<void> awardMatchXP({
    required String winnerId,
    required String loserId,
    required int winnerFinishTime,
    required int loserFinishTime,
    required Difficulty difficulty,
  }) async {
    try {
      // Calculate XP for both players
      final winnerXP = calculateMatchXP(
        won: true,
        finishTimeSeconds: winnerFinishTime,
        difficulty: difficulty,
      );

      final loserXP = calculateMatchXP(
        won: false,
        finishTimeSeconds: loserFinishTime,
        difficulty: difficulty,
      );

      // Fetch current stats to calculate new levels
      final winnerStats = await _getUserStats(winnerId);
      final loserStats = await _getUserStats(loserId);

      final winnerNewTotalXP = winnerStats.totalXP + winnerXP;
      final loserNewTotalXP = loserStats.totalXP + loserXP;

      final winnerNewLevel = calculateLevel(winnerNewTotalXP);
      final loserNewLevel = calculateLevel(loserNewTotalXP);

      // Use batch write to update both players atomically
      final batch = _firestore.batch();

      // Update winner
      final winnerRef = _firestore.collection('users').doc(winnerId);
      batch.update(winnerRef, {
        'stats.totalXP': winnerNewTotalXP,
        'stats.level': winnerNewLevel,
      });

      // Update loser
      final loserRef = _firestore.collection('users').doc(loserId);
      batch.update(loserRef, {
        'stats.totalXP': loserNewTotalXP,
        'stats.level': loserNewLevel,
      });

      // Commit both updates atomically
      await batch.commit();

      print('XP awarded: Winner +$winnerXP XP (Level $winnerNewLevel), Loser +$loserXP XP (Level $loserNewLevel)');
    } catch (e) {
      print('Error awarding XP: $e');
      rethrow;
    }
  }

  /// Fetch user stats from Firestore
  Future<UserStats> _getUserStats(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      throw Exception('User not found: $userId');
    }

    final data = doc.data()!;
    final statsData = data['stats'] as Map<String, dynamic>?;

    if (statsData == null) {
      return const UserStats();
    }

    return UserStats.fromJson(statsData);
  }
}
