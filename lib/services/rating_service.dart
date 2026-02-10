import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for calculating and updating Elo ratings
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate expected score for player A against player B
  /// Formula: E_a = 1 / (1 + 10^((R_b - R_a) / 400))
  double _calculateExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10, (ratingB - ratingA) / 400.0));
  }

  /// Determine K-factor based on games played and current rating
  /// - Provisional (< 20 games): K = 40 (rapid adjustment)
  /// - Regular (≥ 20 games): K = 24 (moderate adjustments)
  /// - High-rated (≥ 1800): K = 16 (stability at top)
  int _getKFactor(int rankedGamesPlayed, int rating) {
    if (rankedGamesPlayed < 20) {
      return 40; // Provisional period - rapid skill assessment
    } else if (rating >= 1800) {
      return 16; // High-rated players - slower changes for stability
    } else {
      return 24; // Regular players - moderate adjustments
    }
  }

  /// Apply rating floor constraint (minimum rating: 100)
  int _applyRatingFloor(int rating) {
    return max(100, rating);
  }

  /// Update both players' ratings atomically after a match
  /// Only call this from the winner's perspective to avoid double updates
  Future<void> updateRatings({
    required String winnerId,
    required String loserId,
  }) async {
    try {
      // Fetch both players' stats
      final winnerStats = await _getUserStats(winnerId);
      final loserStats = await _getUserStats(loserId);

      // Calculate expected scores
      final winnerExpected = _calculateExpectedScore(
        winnerStats.eloRating,
        loserStats.eloRating,
      );
      final loserExpected = _calculateExpectedScore(
        loserStats.eloRating,
        winnerStats.eloRating,
      );

      // Determine K-factors
      final winnerK = _getKFactor(
        winnerStats.rankedGamesPlayed,
        winnerStats.eloRating,
      );
      final loserK = _getKFactor(
        loserStats.rankedGamesPlayed,
        loserStats.eloRating,
      );

      // Calculate new ratings
      // R' = R + K * (S - E) where S = 1 for win, 0 for loss
      final winnerNewRating = _applyRatingFloor(
        (winnerStats.eloRating + winnerK * (1.0 - winnerExpected)).round(),
      );
      final loserNewRating = _applyRatingFloor(
        (loserStats.eloRating + loserK * (0.0 - loserExpected)).round(),
      );

      // Update peak ratings if necessary
      final winnerPeakRating = max(winnerNewRating, winnerStats.peakEloRating);
      final loserPeakRating = loserStats.peakEloRating; // Loser's peak doesn't change on loss

      // Use batch write to update both players atomically
      final batch = _firestore.batch();

      // Update winner
      final winnerRef = _firestore.collection('users').doc(winnerId);
      batch.update(winnerRef, {
        'stats.eloRating': winnerNewRating,
        'stats.peakEloRating': winnerPeakRating,
        'stats.rankedGamesPlayed': FieldValue.increment(1),
      });

      // Update loser
      final loserRef = _firestore.collection('users').doc(loserId);
      batch.update(loserRef, {
        'stats.eloRating': loserNewRating,
        'stats.peakEloRating': loserPeakRating,
        'stats.rankedGamesPlayed': FieldValue.increment(1),
      });

      // Commit both updates atomically
      await batch.commit();

      print('Rating update: Winner ${winnerStats.eloRating} → $winnerNewRating (+${winnerNewRating - winnerStats.eloRating})');
      print('Rating update: Loser ${loserStats.eloRating} → $loserNewRating (${loserNewRating - loserStats.eloRating})');
    } catch (e) {
      print('Error updating ratings: $e');
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
      // Return default stats if none exist
      return const UserStats();
    }

    return UserStats.fromJson(statsData);
  }
}
