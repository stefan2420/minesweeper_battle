import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_board.dart';

enum BattleStatus { waiting, playing, finished }

class PlayerState {
  final String playerId;
  final String displayName;
  final String? gridData; // Serialized grid (hidden from opponent)
  final int revealedCells;
  final int flaggedCells;
  final String status; // 'playing', 'won', 'lost', 'betting', 'bet_success', 'bet_failed'
  final int? finishTime; // Time in seconds when finished
  final bool isReady;
  final bool isBetting; // True if player chose to bet and continue
  final DateTime? betStartTime; // When betting phase started (for timeout)
  final String? betOutcome; // 'success', 'failed', 'declined', null

  const PlayerState({
    required this.playerId,
    required this.displayName,
    this.gridData,
    this.revealedCells = 0,
    this.flaggedCells = 0,
    this.status = 'waiting',
    this.finishTime,
    this.isReady = false,
    this.isBetting = false,
    this.betStartTime,
    this.betOutcome,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'gridData': gridData,
      'revealedCells': revealedCells,
      'flaggedCells': flaggedCells,
      'status': status,
      'finishTime': finishTime,
      'isReady': isReady,
      'isBetting': isBetting,
      'betStartTime': betStartTime != null ? Timestamp.fromDate(betStartTime!) : null,
      'betOutcome': betOutcome,
    };
  }

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      playerId: json['playerId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      gridData: json['gridData'] as String?,
      revealedCells: json['revealedCells'] as int? ?? 0,
      flaggedCells: json['flaggedCells'] as int? ?? 0,
      status: json['status'] as String? ?? 'waiting',
      finishTime: json['finishTime'] as int?,
      isReady: json['isReady'] as bool? ?? false,
      isBetting: json['isBetting'] as bool? ?? false,
      betStartTime: (json['betStartTime'] as Timestamp?)?.toDate(),
      betOutcome: json['betOutcome'] as String?,
    );
  }

  PlayerState copyWith({
    String? playerId,
    String? displayName,
    String? gridData,
    int? revealedCells,
    int? flaggedCells,
    String? status,
    int? finishTime,
    bool? isReady,
    bool? isBetting,
    DateTime? betStartTime,
    String? betOutcome,
  }) {
    return PlayerState(
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      gridData: gridData ?? this.gridData,
      revealedCells: revealedCells ?? this.revealedCells,
      flaggedCells: flaggedCells ?? this.flaggedCells,
      status: status ?? this.status,
      finishTime: finishTime ?? this.finishTime,
      isReady: isReady ?? this.isReady,
      isBetting: isBetting ?? this.isBetting,
      betStartTime: betStartTime ?? this.betStartTime,
      betOutcome: betOutcome ?? this.betOutcome,
    );
  }

  double getProgress(Difficulty difficulty) {
    final config = GameBoardConfig.fromDifficulty(difficulty);
    final totalNonMines = (config.rows * config.cols) - config.mines;
    if (totalNonMines == 0) return 0;
    return revealedCells / totalNonMines;
  }
}

class BattleSession {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final BattleStatus status;
  final Difficulty difficulty;
  final DateTime createdAt;
  final DateTime? startedAt;
  final String? winnerId;
  final Map<String, PlayerState> players;

  const BattleSession({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    this.status = BattleStatus.waiting,
    this.difficulty = Difficulty.beginner,
    required this.createdAt,
    this.startedAt,
    this.winnerId,
    this.players = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'guestId': guestId,
      'status': status.name,
      'difficulty': difficulty.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'winnerId': winnerId,
      'players': players.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory BattleSession.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as Map<String, dynamic>? ?? {};
    return BattleSession(
      roomCode: json['roomCode'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      guestId: json['guestId'] as String?,
      status: BattleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BattleStatus.waiting,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.beginner,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (json['startedAt'] as Timestamp?)?.toDate(),
      winnerId: json['winnerId'] as String?,
      players: playersJson.map(
        (key, value) => MapEntry(key, PlayerState.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  BattleSession copyWith({
    String? roomCode,
    String? hostId,
    String? guestId,
    BattleStatus? status,
    Difficulty? difficulty,
    DateTime? createdAt,
    DateTime? startedAt,
    String? winnerId,
    Map<String, PlayerState>? players,
  }) {
    return BattleSession(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      winnerId: winnerId ?? this.winnerId,
      players: players ?? this.players,
    );
  }

  bool get isFull => guestId != null;
  bool get allPlayersReady => players.values.every((p) => p.isReady);

  PlayerState? getOpponent(String myId) {
    for (final entry in players.entries) {
      if (entry.key != myId) {
        return entry.value;
      }
    }
    return null;
  }
}
