import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/game_board.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUser(String id, String email, String displayName) async {
    final user = UserModel(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    await _usersCollection.doc(id).set(user.toJson());
  }

  Future<UserModel?> getUser(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(id, doc.data()!);
  }

  Stream<UserModel?> getUserStream(String id) {
    return _usersCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(id, doc.data()!);
    });
  }

  Future<void> updateDisplayName(String id, String displayName) async {
    await _usersCollection.doc(id).update({'displayName': displayName});
  }

  Future<void> recordGameWin(String id, Difficulty difficulty, int timeSeconds) async {
    final doc = await _usersCollection.doc(id).get();
    if (!doc.exists) return;

    final user = UserModel.fromJson(id, doc.data()!);
    final difficultyKey = difficulty.name;
    final currentBest = user.stats.bestTimes[difficultyKey];

    final newBestTimes = Map<String, int?>.from(user.stats.bestTimes);
    if (currentBest == null || timeSeconds < currentBest) {
      newBestTimes[difficultyKey] = timeSeconds;
    }

    await _usersCollection.doc(id).update({
      'stats.gamesPlayed': FieldValue.increment(1),
      'stats.gamesWon': FieldValue.increment(1),
      'stats.bestTimes': newBestTimes,
    });
  }

  Future<void> recordGameLoss(String id) async {
    await _usersCollection.doc(id).update({
      'stats.gamesPlayed': FieldValue.increment(1),
    });
  }

  Future<void> recordBattleWin(String id) async {
    await _usersCollection.doc(id).update({
      'stats.battleWins': FieldValue.increment(1),
    });
  }

  Future<void> recordBattleLoss(String id) async {
    await _usersCollection.doc(id).update({
      'stats.battleLosses': FieldValue.increment(1),
    });
  }

  Future<List<UserModel>> getLeaderboard({int limit = 20}) async {
    final snapshot = await _usersCollection
        .orderBy('stats.eloRating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.id, doc.data()))
        .toList();
  }
}
