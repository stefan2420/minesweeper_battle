import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing app-wide configuration loaded from Firestore.
/// Singleton pattern ensures configuration is loaded once and shared across the app.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;

  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cached configuration values
  int? _qualifierMatchCount;
  bool _isLoaded = false;

  /// Loads configuration from Firestore /appConfig/ranked document.
  /// This should be called during app initialization.
  Future<void> loadConfig() async {
    try {
      final doc = await _firestore.collection('appConfig').doc('ranked').get();

      if (doc.exists) {
        final data = doc.data();
        _qualifierMatchCount = data?['qualifierMatchCount'] as int?;
      }

      _isLoaded = true;
    } catch (e) {
      // If config loading fails, continue with defaults
      print('Error loading config: $e');
      _isLoaded = true;
    }
  }

  /// Refreshes configuration from Firestore.
  /// Call this after config updates to get latest values.
  Future<void> refreshConfig() async {
    _isLoaded = false;
    await loadConfig();
  }

  /// Gets the number of qualifier matches required before showing rank.
  /// Returns cached value if loaded, otherwise returns default of 3.
  /// A value of 0 means no qualifiers (instant ranking).
  int get qualifierMatchCount {
    if (!_isLoaded) {
      // If config hasn't loaded yet, return default
      return 3;
    }
    return _qualifierMatchCount ?? 3;
  }

  /// Checks if configuration has been loaded from Firestore.
  bool get isLoaded => _isLoaded;
}
