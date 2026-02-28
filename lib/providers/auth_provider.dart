import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      if (!_isLoading) {
        await loadUserData(user.uid);
      }
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      } else {
        if (_auth.currentUser != null) {
          await _createUserDocument(uid);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    notifyListeners();
  }

  Future<void> _createUserDocument(String uid, {String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final nameToSave = displayName ?? user.displayName ?? user.email?.split('@')[0] ?? 'User';

    final userModel = UserModel(
      uid: uid,
      email: user.email ?? '',
      displayName: nameToSave,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      settings: {
        'currency': 'USD',
        'currencySymbol': '\$',
        'language': 'en',
        'theme': 'system',
      },
    );

    await _firestore.collection('users').doc(uid).set(userModel.toMap());
    _userModel = userModel;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'lastLogin': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        await loadUserData(result.user!.uid); 
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String? name) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        if (name != null) {
          await result.user!.updateDisplayName(name);
        }
        await _createUserDocument(result.user!.uid, displayName: name);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': _error = 'No user found with this email'; break;
      case 'wrong-password': _error = 'Wrong password provided'; break;
      case 'email-already-in-use': _error = 'Email already in use'; break;
      case 'weak-password': _error = 'Password is too weak'; break;
      case 'invalid-email': _error = 'Invalid email address'; break;
      default: _error = e.message ?? 'Authentication error';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateUserSettings(Map<String, dynamic> data) async {
    if (_user == null) return;
    try {
      await _firestore.collection('users').doc(_user!.uid).set(data, SetOptions(merge: true));
      await loadUserData(_user!.uid);
    } catch (e) {
      debugPrint('Error updating user settings: $e');
    }
  }
}
