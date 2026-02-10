import 'package:flutter/material.dart';

/// Rank tier enumeration
enum RankTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
}

/// Helper class for calculating and displaying rank tiers based on Elo rating
class RankTierHelper {
  /// Get tier from rating
  static RankTier getTier(int rating) {
    if (rating >= 2000) return RankTier.grandmaster;
    if (rating >= 1800) return RankTier.master;
    if (rating >= 1600) return RankTier.diamond;
    if (rating >= 1400) return RankTier.platinum;
    if (rating >= 1200) return RankTier.gold;
    if (rating >= 1000) return RankTier.silver;
    return RankTier.bronze;
  }

  /// Get tier display name
  static String getTierName(int rating) {
    final tier = getTier(rating);
    return tier.name[0].toUpperCase() + tier.name.substring(1);
  }

  /// Get tier color
  static Color getTierColor(int rating) {
    switch (getTier(rating)) {
      case RankTier.grandmaster:
        return const Color(0xFFFF4500); // Orange-red
      case RankTier.master:
        return const Color(0xFF9370DB); // Purple
      case RankTier.diamond:
        return const Color(0xFFB9F2FF); // Light blue
      case RankTier.platinum:
        return const Color(0xFF00CED1); // Cyan
      case RankTier.gold:
        return const Color(0xFFFFD700); // Gold
      case RankTier.silver:
        return const Color(0xFFC0C0C0); // Silver
      case RankTier.bronze:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  /// Get tier icon
  static IconData getTierIcon(int rating) {
    switch (getTier(rating)) {
      case RankTier.grandmaster:
      case RankTier.master:
        return Icons.emoji_events; // Trophy
      case RankTier.diamond:
        return Icons.diamond;
      case RankTier.platinum:
      case RankTier.gold:
        return Icons.workspace_premium; // Medal
      case RankTier.silver:
      case RankTier.bronze:
        return Icons.military_tech; // Badge
    }
  }

  /// Get rating range description for a tier
  static String getTierRange(RankTier tier) {
    switch (tier) {
      case RankTier.bronze:
        return '100-999';
      case RankTier.silver:
        return '1000-1199';
      case RankTier.gold:
        return '1200-1399';
      case RankTier.platinum:
        return '1400-1599';
      case RankTier.diamond:
        return '1600-1799';
      case RankTier.master:
        return '1800-1999';
      case RankTier.grandmaster:
        return '2000+';
    }
  }
}
