import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logBattleStarted({required String difficulty}) async {
    await _analytics.logEvent(
      name: 'battle_started',
      parameters: {'difficulty': difficulty},
    );
  }

  Future<void> logBattleWon({required String difficulty, required int finishTime}) async {
    await _analytics.logEvent(
      name: 'battle_won',
      parameters: {'difficulty': difficulty, 'finish_time': finishTime},
    );
  }

  Future<void> logBattleLost({required String difficulty}) async {
    await _analytics.logEvent(
      name: 'battle_lost',
      parameters: {'difficulty': difficulty},
    );
  }

  Future<void> logBattleDraw({required String difficulty}) async {
    await _analytics.logEvent(
      name: 'battle_draw',
      parameters: {'difficulty': difficulty},
    );
  }

  Future<void> logBetOutcome({required String result}) async {
    await _analytics.logEvent(
      name: 'bet_outcome',
      parameters: {'result': result},
    );
  }

  Future<void> logQualifierCompleted() async {
    await _analytics.logEvent(name: 'qualifier_completed');
  }

  Future<void> logDailyChallengeStarted() async {
    await _analytics.logEvent(name: 'daily_challenge_started');
  }

  Future<void> logDailyChallengeCompleted({required int completionTime}) async {
    await _analytics.logEvent(
      name: 'daily_challenge_completed',
      parameters: {'completion_time': completionTime},
    );
  }

  Future<void> logAchievementUnlocked({required String id}) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {'achievement_id': id},
    );
  }
}
