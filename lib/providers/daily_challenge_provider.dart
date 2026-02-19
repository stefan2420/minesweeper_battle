import 'package:flutter/foundation.dart';
import '../models/daily_challenge_model.dart';
import '../models/game_board.dart';
import '../models/game_state.dart';
import '../services/daily_challenge_service.dart';
import '../services/achievement_service.dart';
import '../services/analytics_service.dart';

class DailyChallengeProvider extends ChangeNotifier {
  final DailyChallengeService _service = DailyChallengeService();
  final AchievementService _achievementService = AchievementService();

  DailyChallenge? _challenge;
  GameBoard? _board;
  GameState _gameState = const GameState();
  List<DailyChallengeResult> _leaderboard = [];
  bool _isLoading = false;
  bool _alreadyCompleted = false;
  int? _xpEarned;
  String? _error;

  DailyChallenge? get challenge => _challenge;
  GameBoard? get board => _board;
  GameState get gameState => _gameState;
  List<DailyChallengeResult> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  bool get alreadyCompleted => _alreadyCompleted;
  int? get xpEarned => _xpEarned;
  String? get error => _error;

  Future<void> load(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _challenge = await _service.getTodaysChallenge();
      _alreadyCompleted = await _service.hasCompletedToday(userId);
      await _loadLeaderboard();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void startChallenge() {
    if (_challenge == null || _alreadyCompleted) return;
    final difficulty = Difficulty.values.firstWhere(
      (d) => d.name == _challenge!.difficulty,
      orElse: () => Difficulty.intermediate,
    );
    _board = GameBoard.seeded(difficulty, _challenge!.seed);
    _gameState = const GameState(status: GameStatus.playing);
    AnalyticsService.instance.logDailyChallengeStarted();
    notifyListeners();
  }

  bool revealCell(int row, int col) {
    if (_board == null || _gameState.isGameOver) return false;
    final hitMine = _board!.revealCell(row, col);
    if (hitMine) {
      _board!.revealAllMines();
      _gameState = _gameState.copyWith(status: GameStatus.lost);
    } else if (_board!.checkWin()) {
      _gameState = _gameState.copyWith(status: GameStatus.won);
    }
    notifyListeners();
    return hitMine;
  }

  void toggleFlag(int row, int col) {
    if (_board == null || _gameState.isGameOver) return;
    _board!.toggleFlag(row, col);
    notifyListeners();
  }

  bool chordCell(int row, int col) {
    if (_board == null || _gameState.isGameOver) return false;
    final hitMine = _board!.chordCell(row, col);
    if (hitMine) {
      _board!.revealAllMines();
      _gameState = _gameState.copyWith(status: GameStatus.lost);
    } else if (_board!.checkWin()) {
      _gameState = _gameState.copyWith(status: GameStatus.won);
    }
    notifyListeners();
    return hitMine;
  }

  void tick() {
    if (_gameState.isPlaying) {
      _gameState = _gameState.copyWith(
        elapsedSeconds: _gameState.elapsedSeconds + 1,
      );
      notifyListeners();
    }
  }

  Future<void> submitResult({
    required String userId,
    required String displayName,
  }) async {
    if (_gameState.status != GameStatus.won) return;
    try {
      _xpEarned = await _service.submitResult(
        userId: userId,
        displayName: displayName,
        completionTime: _gameState.elapsedSeconds,
      );
      _alreadyCompleted = true;
      await _loadLeaderboard();

      AnalyticsService.instance.logDailyChallengeCompleted(
        completionTime: _gameState.elapsedSeconds,
      );

      await _achievementService.checkAchievements(
        userId,
        'daily_complete',
        {'streak': 1},
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_challenge == null) return;
    _leaderboard = await _service.getLeaderboard(_challenge!.date);
  }

  void reset() {
    _board = null;
    _gameState = const GameState();
    _xpEarned = null;
    notifyListeners();
  }
}
