import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // ホーム画面で使用するためのエイリアス
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    if (kDebugMode) {
      print('UserProvider: Initializing auth...');
    }
    
    _isLoading = true;
    notifyListeners();

    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (kDebugMode) {
        print('UserProvider: Auth state changed - User: ${firebaseUser?.uid}');
      }
      
      if (firebaseUser != null) {
        try {
          if (kDebugMode) {
            print('UserProvider: Fetching user data for ${firebaseUser.uid}');
          }
          
          final userData = await _databaseService.getUser(firebaseUser.uid);
          
          if (kDebugMode) {
            print('UserProvider: User data fetched - ${userData?.displayName}');
          }
          
          _currentUser = userData;
        } catch (e) {
          if (kDebugMode) {
            print('UserProvider: Error fetching user data: $e');
          }
          _errorMessage = 'ユーザーデータの取得に失敗しました: $e';
          _currentUser = null;
        }
      } else {
        if (kDebugMode) {
          print('UserProvider: User signed out');
        }
        _currentUser = null;
      }
      
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('UserProvider: Auth initialization complete - Authenticated: ${_currentUser != null}');
      }
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (kDebugMode) {
        print('UserProvider: Starting sign in for $email');
      }
      
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.signInWithEmailAndPassword(email, password);
      
      if (kDebugMode) {
        print('UserProvider: Sign in result - User: ${result?.user?.uid}');
      }
      
      if (result?.user != null) {
        // auth state changesで自動的にユーザーデータが設定されるので、ここでは追加の取得は不要
        // final userData = await _databaseService.getUser(result!.user!.uid);
        // _currentUser = userData;
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'ログインに失敗しました';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('UserProvider: Sign in error: $e');
      }
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    String? profileImageUrl,
  }) async {
    try {
      if (kDebugMode) {
        print('UserProvider: Starting registration for $email');
      }
      
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
        userType,
        profileImageUrl: profileImageUrl,
      );
      
      if (kDebugMode) {
        print('UserProvider: Registration result - User: ${result?.user?.uid}');
      }
      
      if (result?.user != null) {
        // auth state changesで自動的にユーザーデータが設定されるので、ここでは追加の取得は不要
        // final userData = await _databaseService.getUser(result!.user!.uid);
        // _currentUser = userData;
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = '登録に失敗しました';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('UserProvider: Registration error: $e');
      }
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('UserProvider: Signing out');
      }
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('UserProvider: Sign out error: $e');
      }
      _errorMessage = 'ログアウトに失敗しました: $e';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'プロフィールの更新に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUser(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _errorMessage = 'パスワードリセットに失敗しました: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Switch user type for demo purposes (remove in production)
  void switchUserType() {
    if (_currentUser != null) {
      final newUserType = _currentUser!.userType == UserType.client 
          ? UserType.professional 
          : UserType.client;
      
      _currentUser = _currentUser!.copyWith(userType: newUserType);
      notifyListeners();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'このメールアドレスで登録されたアカウントが見つかりません';
        case 'wrong-password':
          return 'パスワードが間違っています';
        case 'invalid-email':
          return '無効なメールアドレスです';
        case 'user-disabled':
          return 'このアカウントは無効になっています';
        case 'too-many-requests':
          return 'ログイン試行回数が多すぎます。しばらく時間をおいてからお試しください';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'weak-password':
          return 'パスワードが弱すぎます。6文字以上で設定してください';
        case 'network-request-failed':
          return 'ネットワークエラーが発生しました。インターネット接続を確認してください';
        default:
          return 'エラーが発生しました: ${error.message}';
      }
    }
    return 'エラーが発生しました: $error';
  }
} 