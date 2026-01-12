import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _userModel = await _userService.getUser(user.uid);
      // Create user profile if it doesn't exist
      if (_userModel == null) {
        await _userService.createUser(
          user.uid,
          user.email ?? '',
          user.displayName ?? 'Player',
        );
        _userModel = await _userService.getUser(user.uid);
      }
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return credential != null;
    } catch (e) {
      _error = 'Failed to sign in with Google';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      _userModel = await _userService.getUser(_firebaseUser!.uid);
      notifyListeners();
    }
  }
}
