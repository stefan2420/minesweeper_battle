import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for admin/dev operations and configuration management
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a user has developer permissions (dev or admin role)
  Future<bool> isDevUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final user = UserModel.fromJson(userId, doc.data()!);
      return user.isDev;
    } catch (e) {
      print('Error checking dev user: $e');
      return false;
    }
  }

  /// Update the qualifier match count in app config
  /// Validates that count is between 0 and 10
  /// Returns true on success, false on validation failure
  Future<bool> updateQualifierCount(int count, String updatedBy) async {
    // Validate range
    if (count < 0 || count > 10) {
      print('Invalid qualifier count: $count (must be 0-10)');
      return false;
    }

    try {
      await _firestore.collection('appConfig').doc('ranked').set({
        'qualifierMatchCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      }, SetOptions(merge: true));

      print('Updated qualifier count to $count');
      return true;
    } catch (e) {
      print('Error updating qualifier count: $e');
      return false;
    }
  }

  /// Get current config snapshot with metadata
  Future<Map<String, dynamic>?> getConfigSnapshot() async {
    try {
      final doc = await _firestore.collection('appConfig').doc('ranked').get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting config snapshot: $e');
      return null;
    }
  }
}
