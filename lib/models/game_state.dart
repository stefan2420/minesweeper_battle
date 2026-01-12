enum GameStatus { ready, playing, won, lost }

class GameState {
  final GameStatus status;
  final int elapsedSeconds;
  final DateTime? startTime;

  const GameState({
    this.status = GameStatus.ready,
    this.elapsedSeconds = 0,
    this.startTime,
  });

  GameState copyWith({
    GameStatus? status,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return GameState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }

  bool get isPlaying => status == GameStatus.playing;
  bool get isGameOver => status == GameStatus.won || status == GameStatus.lost;
}
