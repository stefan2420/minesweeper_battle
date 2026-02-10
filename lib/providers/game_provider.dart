import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/game_board.dart';
import '../models/game_state.dart';

class GameProvider extends ChangeNotifier {
  GameBoard? _board;
  GameState _state = const GameState();
  Timer? _timer;
  Difficulty _difficulty = Difficulty.beginner;

  GameBoard? get board => _board;
  GameState get state => _state;
  Difficulty get difficulty => _difficulty;
  int get remainingMines => _board?.remainingMines ?? 0;

  void setDifficulty(Difficulty difficulty) {
    _difficulty = difficulty;
    notifyListeners();
  }

  void newGame([Difficulty? difficulty]) {
    _timer?.cancel();
    _difficulty = difficulty ?? _difficulty;
    _board = GameBoard.fromDifficulty(_difficulty);
    _state = const GameState(status: GameStatus.ready);
    notifyListeners();
  }

  void revealCell(int row, int col) {
    if (_board == null || _state.isGameOver) return;

    // Haptic feedback for tap
    HapticFeedback.lightImpact();

    // Start game on first click
    if (_state.status == GameStatus.ready) {
      _state = _state.copyWith(
        status: GameStatus.playing,
        startTime: DateTime.now(),
      );
      _startTimer();
    }

    final hitMine = _board!.revealCell(row, col);

    if (hitMine) {
      HapticFeedback.heavyImpact();
      _gameOver(won: false);
    } else if (_board!.checkWin()) {
      HapticFeedback.mediumImpact();
      _gameOver(won: true);
    }

    notifyListeners();
  }

  void chordCell(int row, int col) {
    if (_board == null || _state.isGameOver) return;

    // Haptic feedback for chord
    HapticFeedback.mediumImpact();

    // Start game on first chord (though unlikely)
    if (_state.status == GameStatus.ready) {
      _state = _state.copyWith(
        status: GameStatus.playing,
        startTime: DateTime.now(),
      );
      _startTimer();
    }

    final hitMine = _board!.chordCell(row, col);

    if (hitMine) {
      HapticFeedback.heavyImpact();
      _gameOver(won: false);
    } else if (_board!.checkWin()) {
      HapticFeedback.mediumImpact();
      _gameOver(won: true);
    }

    notifyListeners();
  }

  void toggleFlag(int row, int col) {
    if (_board == null || _state.isGameOver) return;

    // Haptic feedback for flag toggle
    HapticFeedback.mediumImpact();

    // Can flag in ready state without starting timer
    _board!.toggleFlag(row, col);
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isPlaying) {
        _state = _state.copyWith(
          elapsedSeconds: _state.elapsedSeconds + 1,
        );
        notifyListeners();
      }
    });
  }

  void _gameOver({required bool won}) {
    _timer?.cancel();
    if (!won) {
      _board!.revealAllMines();
    }
    _state = _state.copyWith(
      status: won ? GameStatus.won : GameStatus.lost,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
