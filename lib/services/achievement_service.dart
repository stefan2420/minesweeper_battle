import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and unlock achievements for a user after a trigger event.
  /// [trigger] is one of: 'battle_win', 'elo_update', 'level_up',
  ///   'bet_win', 'qualifier_complete', 'daily_complete', 'friend_added',
  ///   'speed_win_beginner'
  /// [data] provides supporting values (e.g. {'eloRating': 1450})
  Future<List<String>> checkAchievements(
    String userId,
    String trigger,
    Map<String, dynamic> data,
  ) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return [];

    final stats = UserStats.fromJson(
      doc.data()!['stats'] as Map<String, dynamic>? ?? {},
    );

    final alreadyUnlocked = Set<String>.from(stats.unlockedAchievements);
    final progress = Map<String, int>.from(stats.achievementProgress);
    final newlyUnlocked = <String>[];
    final updates = <String, dynamic>{};

    void unlock(String id) {
      if (!alreadyUnlocked.contains(id)) {
        alreadyUnlocked.add(id);
        newlyUnlocked.add(id);
        updates['stats.unlockedAchievements'] = FieldValue.arrayUnion([id]);
      }
    }

    switch (trigger) {
      case 'battle_win':
        final wins = data['battleWins'] as int? ?? stats.battleWins;
        if (wins >= 1) unlock('first_win');
        if (wins >= 10) unlock('wins_10');
        if (wins >= 50) unlock('wins_50');
        if (wins >= 100) unlock('wins_100');

      case 'elo_update':
        final elo = data['eloRating'] as int? ?? stats.eloRating;
        if (elo >= 1400) unlock('elo_1400');
        if (elo >= 1600) unlock('elo_1600');
        if (elo >= 1800) unlock('elo_1800');

      case 'level_up':
        final level = data['level'] as int? ?? stats.level;
        if (level >= 10) unlock('level_10');
        if (level >= 25) unlock('level_25');

      case 'bet_win':
        unlock('bet_first');
        final betCount = (progress['bet_10'] ?? 0) + 1;
        progress['bet_10'] = betCount;
        updates['stats.achievementProgress.bet_10'] = betCount;
        if (betCount >= 10) unlock('bet_10');

      case 'qualifier_complete':
        unlock('qualifier_graduate');

      case 'daily_complete':
        unlock('daily_first');
        final streak = data['streak'] as int? ?? 1;
        if (streak >= 7) unlock('daily_streak_7');

      case 'friend_added':
        unlock('first_friend');

      case 'speed_win_beginner':
        final time = data['finishTime'] as int? ?? 999;
        if (time < 30) unlock('speed_beginner');
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);

      for (final id in newlyUnlocked) {
        await AnalyticsService.instance.logAchievementUnlocked(id: id);
      }
    }

    return newlyUnlocked;
  }
}
