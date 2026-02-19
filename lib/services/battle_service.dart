import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battle_session.dart';
import '../models/game_board.dart';

class BattleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('battleRooms');

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Validates progress update values to prevent invalid data
  void _validateProgressUpdate({
    required Difficulty difficulty,
    required int revealedCells,
    required int flaggedCells,
    int? finishTime,
  }) {
    final config = GameBoardConfig.fromDifficulty(difficulty);
    final maxCells = config.rows * config.cols;
    final maxMines = config.mines;

    // Validate revealedCells
    if (revealedCells < 0 || revealedCells > maxCells) {
      throw ArgumentError(
        'Invalid revealedCells: $revealedCells. Must be between 0 and $maxCells',
      );
    }

    // Validate flaggedCells
    if (flaggedCells < 0 || flaggedCells > maxMines) {
      throw ArgumentError(
        'Invalid flaggedCells: $flaggedCells. Must be between 0 and $maxMines',
      );
    }

    // Validate finishTime if provided
    if (finishTime != null) {
      const maxTime = 86400; // 24 hours in seconds
      if (finishTime < 0 || finishTime > maxTime) {
        throw ArgumentError(
          'Invalid finishTime: $finishTime. Must be between 0 and $maxTime',
        );
      }
    }
  }

  Future<BattleSession> createRoom({
    required String hostId,
    required String hostDisplayName,
    required Difficulty difficulty,
  }) async {
    String roomCode;
    bool exists = true;

    // Ensure unique room code
    do {
      roomCode = _generateRoomCode();
      final doc = await _roomsCollection.doc(roomCode).get();
      exists = doc.exists;
    } while (exists);

    final session = BattleSession(
      roomCode: roomCode,
      hostId: hostId,
      difficulty: difficulty,
      createdAt: DateTime.now(),
      players: {
        hostId: PlayerState(
          playerId: hostId,
          displayName: hostDisplayName,
        ),
      },
    );

    await _roomsCollection.doc(roomCode).set(session.toJson());
    return session;
  }

  Future<BattleSession?> joinRoom({
    required String roomCode,
    required String guestId,
    required String guestDisplayName,
  }) async {
    final docRef = _roomsCollection.doc(roomCode.toUpperCase());

    return await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      // Use generic error message to prevent room enumeration
      if (!doc.exists) {
        throw Exception('Cannot join room');
      }

      final session = BattleSession.fromJson(doc.data()!);

      if (session.guestId != null) {
        throw Exception('Cannot join room');
      }

      if (session.status != BattleStatus.waiting) {
        throw Exception('Cannot join room');
      }

      final updatedPlayers = Map<String, PlayerState>.from(session.players);
      updatedPlayers[guestId] = PlayerState(
        playerId: guestId,
        displayName: guestDisplayName,
      );

      final updatedSession = session.copyWith(
        guestId: guestId,
        players: updatedPlayers,
      );

      transaction.update(docRef, updatedSession.toJson());
      return updatedSession;
    });
  }

  Future<void> setPlayerReady(String roomCode, String playerId, bool ready) async {
    final docRef = _roomsCollection.doc(roomCode);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('Room not found');
        }

        final session = BattleSession.fromJson(doc.data()!);
        final updatedPlayers = Map<String, PlayerState>.from(session.players);

        if (!updatedPlayers.containsKey(playerId)) {
          throw Exception('Player $playerId not found in room');
        }

        updatedPlayers[playerId] = updatedPlayers[playerId]!.copyWith(isReady: ready);

        transaction.update(docRef, {
          'players': updatedPlayers.map((k, v) => MapEntry(k, v.toJson())),
        });
      });
    } catch (e) {
      print('Failed to set player ready status: $e');
      rethrow;
    }
  }

  Future<void> startGame(String roomCode) async {
    final docRef = _roomsCollection.doc(roomCode);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final session = BattleSession.fromJson(doc.data()!);

      final updatedPlayers = session.players.map((id, player) {
        return MapEntry(
          id,
          player.copyWith(status: 'playing'),
        );
      });

      transaction.update(docRef, {
        'status': BattleStatus.playing.name,
        'startedAt': FieldValue.serverTimestamp(),
        'players': updatedPlayers.map((k, v) => MapEntry(k, v.toJson())),
      });
    });
  }

  Future<void> updatePlayerProgress({
    required String roomCode,
    required String playerId,
    required int revealedCells,
    required int flaggedCells,
    String? gridData,
  }) async {
    final docRef = _roomsCollection.doc(roomCode);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('Room not found');
        }

        final session = BattleSession.fromJson(doc.data()!);
        final player = session.players[playerId];

        if (player == null) {
          throw Exception('Player not found in room');
        }

        // Validate progress update values
        _validateProgressUpdate(
          difficulty: session.difficulty,
          revealedCells: revealedCells,
          flaggedCells: flaggedCells,
        );

        // Use field-level updates to avoid overwriting concurrent changes
        transaction.update(docRef, {
          'players.$playerId.revealedCells': revealedCells,
          'players.$playerId.flaggedCells': flaggedCells,
          if (gridData != null) 'players.$playerId.gridData': gridData,
        });
      });
    } catch (e) {
      print('Failed to update player progress: $e');
      rethrow;
    }
  }

  Future<void> setPlayerFinished({
    required String roomCode,
    required String playerId,
    required String status, // 'won' or 'lost'
    required int finishTime,
  }) async {
    final docRef = _roomsCollection.doc(roomCode);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final session = BattleSession.fromJson(doc.data()!);

      // Validate finish time
      _validateProgressUpdate(
        difficulty: session.difficulty,
        revealedCells: 0, // Not validating these here
        flaggedCells: 0,
        finishTime: finishTime,
      );

      // Update player status
      transaction.update(docRef, {
        'players.$playerId.status': status,
        'players.$playerId.finishTime': finishTime,
      });

      // Check if game should end
      if (status == 'won') {
        // This player won - they're the winner
        transaction.update(docRef, {
          'status': BattleStatus.finished.name,
          'winnerId': playerId,
        });
      } else if (status == 'lost') {
        // This player lost - check if other player also finished
        final otherPlayer = session.getOpponent(playerId);
        if (otherPlayer != null && otherPlayer.status == 'lost') {
          // Both lost - no winner
          transaction.update(docRef, {
            'status': BattleStatus.finished.name,
          });
        } else if (otherPlayer != null && otherPlayer.status == 'won') {
          // Other already won
          transaction.update(docRef, {
            'status': BattleStatus.finished.name,
            'winnerId': otherPlayer.playerId,
          });
        }
        // If other player still playing, they might still win
      }
    });
  }

  Stream<BattleSession?> getRoomStream(String roomCode) {
    return _roomsCollection.doc(roomCode).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BattleSession.fromJson(doc.data()!);
    });
  }

  Future<void> leaveRoom(String roomCode, String playerId) async {
    final docRef = _roomsCollection.doc(roomCode);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final session = BattleSession.fromJson(doc.data()!);

    if (session.hostId == playerId) {
      // Host leaving - delete room
      await docRef.delete();
    } else {
      // Guest leaving
      final updatedPlayers = Map<String, PlayerState>.from(session.players);
      updatedPlayers.remove(playerId);

      await docRef.update({
        'guestId': null,
        'players': updatedPlayers.map((k, v) => MapEntry(k, v.toJson())),
      });
    }
  }

  Future<void> deleteRoom(String roomCode) async {
    await _roomsCollection.doc(roomCode).delete();
  }

  /// Stores a rematch room code in the current room so the opponent can auto-join.
  Future<void> setRematchRoom(String roomCode, String rematchRoomCode) async {
    await _roomsCollection.doc(roomCode).update({
      'rematchRoomCode': rematchRoomCode,
    });
  }
}
