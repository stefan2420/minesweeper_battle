import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _friendsOf(String userId) =>
      _firestore.collection('users').doc(userId).collection('friends');

  /// Send a friend request from [fromId] to [toId].
  Future<void> sendRequest({
    required String fromId,
    required String fromDisplayName,
    required String toId,
    required String toDisplayName,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Sender's side: direction = 'sent'
    batch.set(_friendsOf(fromId).doc(toId), {
      'displayName': toDisplayName,
      'status': 'pending',
      'addedAt': Timestamp.fromDate(now),
      'direction': 'sent',
    });

    // Receiver's side: direction = 'received'
    batch.set(_friendsOf(toId).doc(fromId), {
      'displayName': fromDisplayName,
      'status': 'pending',
      'addedAt': Timestamp.fromDate(now),
      'direction': 'received',
    });

    await batch.commit();
  }

  /// Accept an incoming friend request.
  Future<void> acceptRequest({
    required String myId,
    required String requesterId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_friendsOf(myId).doc(requesterId), {'status': 'accepted'});
    batch.update(_friendsOf(requesterId).doc(myId), {'status': 'accepted'});
    await batch.commit();
  }

  /// Reject or remove a friend.
  Future<void> removeRelationship({
    required String myId,
    required String otherId,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_friendsOf(myId).doc(otherId));
    batch.delete(_friendsOf(otherId).doc(myId));
    await batch.commit();
  }

  /// Get accepted friends list.
  Future<List<FriendModel>> getFriends(String userId) async {
    final snapshot = await _friendsOf(userId)
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs
        .map((d) => FriendModel.fromJson(d.id, d.data()))
        .toList();
  }

  /// Get incoming (pending) friend requests.
  Future<List<FriendModel>> getIncomingRequests(String userId) async {
    final snapshot = await _friendsOf(userId)
        .where('status', isEqualTo: 'pending')
        .where('direction', isEqualTo: 'received')
        .get();
    return snapshot.docs
        .map((d) => FriendModel.fromJson(d.id, d.data()))
        .toList();
  }

  /// Search users by display name prefix.
  Future<List<UserModel>> searchUsersByName(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs
        .map((d) => UserModel.fromJson(d.id, d.data()))
        .toList();
  }
}
