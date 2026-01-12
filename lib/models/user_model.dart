import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int gamesPlayed;
  final int gamesWon;
  final Map<String, int?> bestTimes; // beginner, intermediate, expert
  final int battleWins;
  final int battleLosses;

  const UserStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.bestTimes = const {},
    this.battleWins = 0,
    this.battleLosses = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'bestTimes': bestTimes,
      'battleWins': battleWins,
      'battleLosses': battleLosses,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      bestTimes: Map<String, int?>.from(json['bestTimes'] as Map? ?? {}),
      battleWins: json['battleWins'] as int? ?? 0,
      battleLosses: json['battleLosses'] as int? ?? 0,
    );
  }

  UserStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    Map<String, int?>? bestTimes,
    int? battleWins,
    int? battleLosses,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      bestTimes: bestTimes ?? this.bestTimes,
      battleWins: battleWins ?? this.battleWins,
      battleLosses: battleLosses ?? this.battleLosses,
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final UserStats stats;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.stats = const UserStats(),
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'stats': stats.toJson(),
    };
  }

  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }
}
