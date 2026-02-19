import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_challenge_model.dart';

class DailyChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int baseXP = 75;
  static const int top10BonusXP = 50;

  String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Fetches (or lazily creates) today's daily challenge document.
  Future<DailyChallenge?> getTodaysChallenge() async {
    final key = _todayKey();
    final doc = await _firestore.collection('dailyChallenges').doc(key).get();
    if (doc.exists) {
      return DailyChallenge.fromJson(doc.data()!);
    }
    // If the challenge doesn't exist yet, create it deterministically from date hash
    final seed = key.hashCode.abs();
    final challenge = DailyChallenge(
      date: key,
      seed: seed,
      difficulty: 'intermediate',
      timestamp: DateTime.now().toUtc(),
    );
    await _firestore.collection('dailyChallenges').doc(key).set(challenge.toJson());
    return challenge;
  }

  /// Returns true if the user has already completed today's challenge.
  Future<bool> hasCompletedToday(String userId) async {
    final key = _todayKey();
    final doc = await _firestore
        .collection('dailyChallenges')
        .doc(key)
        .collection('results')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// Submits the user's result for today's challenge.
  /// Returns the XP earned (0 if already submitted).
  Future<int> submitResult({
    required String userId,
    required String displayName,
    required int completionTime,
  }) async {
    final key = _todayKey();
    final resultsRef = _firestore
        .collection('dailyChallenges')
        .doc(key)
        .collection('results');

    final existing = await resultsRef.doc(userId).get();
    if (existing.exists) return 0; // Already submitted

    // Count existing results to determine rank
    final countSnapshot = await resultsRef.count().get();
    final rank = (countSnapshot.count ?? 0) + 1;

    int xp = baseXP;
    if (rank <= 10) xp += top10BonusXP;

    final result = DailyChallengeResult(
      userId: userId,
      displayName: displayName,
      completionTime: completionTime,
      completedAt: DateTime.now().toUtc(),
      xpEarned: xp,
    );

    await resultsRef.doc(userId).set(result.toJson());

    // Award XP to user
    await _firestore.collection('users').doc(userId).update({
      'stats.totalXP': FieldValue.increment(xp),
    });

    return xp;
  }

  /// Gets the leaderboard for a specific date (top 20 by completion time).
  Future<List<DailyChallengeResult>> getLeaderboard(String date) async {
    final snapshot = await _firestore
        .collection('dailyChallenges')
        .doc(date)
        .collection('results')
        .orderBy('completionTime')
        .limit(20)
        .get();

    return snapshot.docs
        .map((d) => DailyChallengeResult.fromJson(d.data()))
        .toList();
  }
}
