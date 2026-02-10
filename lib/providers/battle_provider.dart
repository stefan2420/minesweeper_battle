import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/battle_session.dart';
import '../models/game_board.dart';
import '../models/game_state.dart';
import '../services/battle_service.dart';
import '../services/user_service.dart';
import '../services/rating_service.dart';
import '../services/xp_service.dart';

class BattleProvider extends ChangeNotifier {
  final BattleService _battleService = BattleService();
  final UserService _userService = UserService();
  final RatingService _ratingService = RatingService();
  final XPService _xpService = XPService();

  BattleSession? _session;
  GameBoard? _board;
  GameState _gameState = const GameState();
  StreamSubscription? _sessionSubscription;
  Timer? _timer;
  String? _error;
  bool _isLoading = false;

  // Debouncing for progress updates
  Timer? _progressUpdateTimer;
  int? _pendingRevealedCells;
  int? _pendingFlaggedCells;

  // Betting state
  bool _isBettingPhase = false;
  bool _playerDecidedToBet = false;
  String? _winnerId;
  String? _loserId;
  int? _winnerFinishTime;
  int? _loserFinishTime;

  BattleSession? get session => _session;
  GameBoard? get board => _board;
  GameState get gameState => _gameState;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isBettingPhase => _isBettingPhase;
  bool get playerDecidedToBet => _playerDecidedToBet;

  Future<String?> createRoom({
    required String hostId,
    required String hostDisplayName,
    required Difficulty difficulty,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _battleService.createRoom(
        hostId: hostId,
        hostDisplayName: hostDisplayName,
        difficulty: difficulty,
      );
      _session = session;
      _listenToRoom(session.roomCode);
      _isLoading = false;
      notifyListeners();
      return session.roomCode;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinRoom({
    required String roomCode,
    required String guestId,
    required String guestDisplayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _battleService.joinRoom(
        roomCode: roomCode.toUpperCase(),
        guestId: guestId,
        guestDisplayName: guestDisplayName,
      );
      if (session != null) {
        _session = session;
        _listenToRoom(roomCode.toUpperCase());
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to join room';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _listenToRoom(String roomCode) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _battleService.getRoomStream(roomCode).listen(
      (session) {
        final wasWaiting = _session?.status == BattleStatus.waiting;
        _session = session;

        // Game just started
        if (wasWaiting && session?.status == BattleStatus.playing) {
          _initializeBoard();
        }

        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> setReady(String playerId, bool ready) async {
    if (_session == null) {
      _error = 'No active session';
      notifyListeners();
      throw Exception('No active session');
    }

    try {
      await _battleService.setPlayerReady(_session!.roomCode, playerId, ready);
    } catch (e) {
      _error = 'Failed to update ready status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startGame() async {
    if (_session == null) return;
    await _battleService.startGame(_session!.roomCode);
  }

  void _initializeBoard() {
    if (_session == null) return;
    _board = GameBoard.fromDifficulty(_session!.difficulty);
    _gameState = const GameState(
      status: GameStatus.playing,
    );
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameState.isPlaying) {
        _gameState = _gameState.copyWith(
          elapsedSeconds: _gameState.elapsedSeconds + 1,
        );
        notifyListeners();
      }
    });
  }

  void _scheduleProgressUpdate(String playerId) {
    if (_session == null || _board == null) return;

    // Store latest values
    _pendingRevealedCells = _board!.revealedCount;
    _pendingFlaggedCells = _board!.flaggedCount;

    // Cancel existing timer
    _progressUpdateTimer?.cancel();

    // Schedule update after 300ms of no activity
    _progressUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      if (_pendingRevealedCells != null && _pendingFlaggedCells != null) {
        _battleService.updatePlayerProgress(
          roomCode: _session!.roomCode,
          playerId: playerId,
          revealedCells: _pendingRevealedCells!,
          flaggedCells: _pendingFlaggedCells!,
        );
        _pendingRevealedCells = null;
        _pendingFlaggedCells = null;
      }
    });
  }

  Future<void> revealCell(int row, int col, String playerId) async {
    if (_board == null || _session == null || _gameState.isGameOver) return;

    // Haptic feedback for tap
    HapticFeedback.lightImpact();

    final hitMine = _board!.revealCell(row, col);

    // Schedule debounced progress update to server
    _scheduleProgressUpdate(playerId);

    if (hitMine) {
      HapticFeedback.heavyImpact();
      // If betting, this counts as bet failure
      if (_playerDecidedToBet) {
        await completeBet(success: false);
      } else {
        await _finishGame(playerId, won: false);
      }
    } else if (_board!.checkWin()) {
      HapticFeedback.mediumImpact();
      // If betting, this counts as bet success
      if (_playerDecidedToBet) {
        await completeBet(success: true);
      } else {
        await _finishGame(playerId, won: true);
      }
    }

    notifyListeners();
  }

  Future<void> chordCell(int row, int col, String playerId) async {
    if (_board == null || _session == null || _gameState.isGameOver) return;

    // Haptic feedback for chord
    HapticFeedback.mediumImpact();

    final hitMine = _board!.chordCell(row, col);

    // Schedule debounced progress update to server
    _scheduleProgressUpdate(playerId);

    if (hitMine) {
      HapticFeedback.heavyImpact();
      // If betting, this counts as bet failure
      if (_playerDecidedToBet) {
        await completeBet(success: false);
      } else {
        await _finishGame(playerId, won: false);
      }
    } else if (_board!.checkWin()) {
      HapticFeedback.mediumImpact();
      // If betting, this counts as bet success
      if (_playerDecidedToBet) {
        await completeBet(success: true);
      } else {
        await _finishGame(playerId, won: true);
      }
    }

    notifyListeners();
  }

  Future<void> toggleFlag(int row, int col, String playerId) async {
    if (_board == null || _session == null || _gameState.isGameOver) return;

    // Haptic feedback for flag toggle
    HapticFeedback.mediumImpact();

    _board!.toggleFlag(row, col);

    // Schedule debounced progress update to server
    _scheduleProgressUpdate(playerId);

    notifyListeners();
  }

  Future<void> _finishGame(String playerId, {required bool won}) async {
    _timer?.cancel();

    if (!won) {
      _board!.revealAllMines();
    }

    _gameState = _gameState.copyWith(
      status: won ? GameStatus.won : GameStatus.lost,
    );

    await _battleService.setPlayerFinished(
      roomCode: _session!.roomCode,
      playerId: playerId,
      status: won ? 'won' : 'lost',
      finishTime: _gameState.elapsedSeconds,
    );

    // Update user stats and ratings
    if (won) {
      await _userService.recordBattleWin(playerId);

      // Determine opponent ID
      final opponentId = _session!.players.keys
          .firstWhere((id) => id != playerId, orElse: () => '');

      if (opponentId.isNotEmpty) {
        // Update Elo ratings atomically
        try {
          await _ratingService.updateRatings(
            winnerId: playerId,
            loserId: opponentId,
          );
        } catch (e) {
          print('Error updating ratings: $e');
          // Continue even if rating update fails
        }

        // Store XP info for later award (after betting decision)
        _winnerId = playerId;
        _loserId = opponentId;
        _winnerFinishTime = _session!.players[playerId]?.finishTime ?? _gameState.elapsedSeconds;
        _loserFinishTime = _session!.players[opponentId]?.finishTime ?? _gameState.elapsedSeconds;

        // Enter betting phase instead of awarding XP immediately
        // XP will be awarded after winner makes betting decision
        _isBettingPhase = true;
        notifyListeners();
      }
    } else {
      await _userService.recordBattleLoss(playerId);
      // Rating and XP updates handled by winner's side
    }
  }

  /// Player chose to cash out (safe option)
  Future<void> handleCashOut() async {
    if (!_isBettingPhase || _winnerId == null) return;

    _isBettingPhase = false;
    _playerDecidedToBet = false;
    notifyListeners();

    // Award normal XP (declined bet)
    await _awardWinnerXP(betOutcome: 'declined');
  }

  /// Player chose to bet and continue
  void handleBetDecision() {
    if (!_isBettingPhase) return;

    _isBettingPhase = false;
    _playerDecidedToBet = true;

    // Reset game state to allow continued play
    _gameState = _gameState.copyWith(
      status: GameStatus.playing,
    );

    // Restart timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _gameState = _gameState.copyWith(
        elapsedSeconds: _gameState.elapsedSeconds + 1,
      );
      notifyListeners();
    });

    notifyListeners();
  }

  /// Handle bet outcome after player continues
  Future<void> completeBet({required bool success}) async {
    if (!_playerDecidedToBet || _winnerId == null) return;

    _playerDecidedToBet = false;
    _timer?.cancel();

    final betOutcome = success ? 'success' : 'failed';

    // Award XP with betting multiplier/penalty
    await _awardWinnerXP(betOutcome: betOutcome);

    // Update game state
    _gameState = _gameState.copyWith(
      status: success ? GameStatus.won : GameStatus.lost,
    );

    if (!success) {
      _board!.revealAllMines();
    }

    notifyListeners();
  }

  /// Award XP to winner with optional betting outcome
  Future<void> _awardWinnerXP({required String betOutcome}) async {
    if (_winnerId == null || _loserId == null) return;

    try {
      await _xpService.awardMatchXP(
        winnerId: _winnerId!,
        loserId: _loserId!,
        winnerFinishTime: _winnerFinishTime!,
        loserFinishTime: _loserFinishTime!,
        difficulty: _session!.difficulty,
        winnerBetOutcome: betOutcome,
      );
    } catch (e) {
      print('Error awarding winner XP: $e');
    }
  }

  Future<void> leaveRoom(String playerId) async {
    if (_session == null) return;
    _timer?.cancel();
    _sessionSubscription?.cancel();
    await _battleService.leaveRoom(_session!.roomCode, playerId);
    _session = null;
    _board = null;
    _gameState = const GameState();
    _isBettingPhase = false;
    _playerDecidedToBet = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _sessionSubscription?.cancel();
    _session = null;
    _board = null;
    _gameState = const GameState();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressUpdateTimer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
