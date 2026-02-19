import 'dart:math';
import '../models/user_model.dart';

/// Service for calculating ELO rating changes (display only).
/// Actual ELO updates are performed server-side by the updateEloRatings Cloud Function.
class RatingService {
  /// Calculate expected score for player A against player B
  double calculateExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10, (ratingB - ratingA) / 400.0));
  }

  /// Determine K-factor based on games played and current rating
  int getKFactor(int rankedGamesPlayed, int rating) {
    if (rankedGamesPlayed < 20) return 40;
    if (rating >= 1800) return 16;
    return 24;
  }

  /// Preview how much ELO a player would gain/lose (for UI display only).
  /// Does NOT write to Firestore — the Cloud Function handles actual updates.
  int previewEloChange({
    required UserStats myStats,
    required int opponentRating,
    required bool won,
  }) {
    final expected = calculateExpectedScore(myStats.eloRating, opponentRating);
    final k = getKFactor(myStats.rankedGamesPlayed, myStats.eloRating);
    final score = won ? 1.0 : 0.0;
    return (k * (score - expected)).round();
  }
}
