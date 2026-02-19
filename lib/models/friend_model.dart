import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String userId;
  final String displayName;
  final String status; // 'pending' | 'accepted'
  final DateTime addedAt;
  final String direction; // 'sent' | 'received' (on requester's side)

  const FriendModel({
    required this.userId,
    required this.displayName,
    required this.status,
    required this.addedAt,
    required this.direction,
  });

  factory FriendModel.fromJson(String id, Map<String, dynamic> json) {
    return FriendModel(
      userId: id,
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      addedAt: (json['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      direction: json['direction'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'status': status,
        'addedAt': Timestamp.fromDate(addedAt),
        'direction': direction,
      };
}
