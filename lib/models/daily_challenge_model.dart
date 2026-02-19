import 'package:cloud_firestore/cloud_firestore.dart';

class DailyChallenge {
  final String date; // 'YYYY-MM-DD'
  final int seed;
  final String difficulty;
  final DateTime timestamp;

  const DailyChallenge({
    required this.date,
    required this.seed,
    required this.difficulty,
    required this.timestamp,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      date: json['date'] as String? ?? '',
      seed: json['seed'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'seed': seed,
        'difficulty': difficulty,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class DailyChallengeResult {
  final String userId;
  final String displayName;
  final int completionTime; // seconds
  final DateTime completedAt;
  final int xpEarned;

  const DailyChallengeResult({
    required this.userId,
    required this.displayName,
    required this.completionTime,
    required this.completedAt,
    required this.xpEarned,
  });

  factory DailyChallengeResult.fromJson(Map<String, dynamic> json) {
    return DailyChallengeResult(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      completionTime: json['completionTime'] as int? ?? 0,
      completedAt: (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      xpEarned: json['xpEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'completionTime': completionTime,
        'completedAt': Timestamp.fromDate(completedAt),
        'xpEarned': xpEarned,
      };
}
