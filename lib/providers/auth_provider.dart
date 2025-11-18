import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? firebaseUser;
  UserModel? userModel;

  AuthProvider() {
    // 🔹 Listen for Firebase Auth changes
    _authService.userChanges.listen((user) async {
      debugPrint('[AuthProvider] userChanges event → user=${user?.uid ?? 'null'} email=${user?.email ?? 'null'}');
      firebaseUser = user;

      if (user != null) {
        // 🔹 Fetch user profile from Firestore
        debugPrint('[AuthProvider] fetching user profile from Firestore for uid=${user.uid}');
        userModel = await _firestoreService.getUserProfile(user.uid);
        debugPrint('[AuthProvider] profile fetch result → isNull=${userModel == null} onboardingCompleted=${userModel?.onboardingCompleted}');

        // 🔹 If no profile exists, create a new one
        if (userModel == null) {
          debugPrint('[AuthProvider] profile missing → creating default profile');
          userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'Learner',
            email: user.email ?? '',
            provider: user.providerData.isNotEmpty
                ? user.providerData.first.providerId
                : null,
            totalPoints: 0,
            lessonsCompleted: 0,
            enrolledCourses: const [],
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            onboardingCompleted: false,
          );

          await _firestoreService.saveUserProfile(userModel!);
          debugPrint('[AuthProvider] default profile saved for uid=${user.uid}');
        } else {
          // 🔹 Update last login timestamp
          userModel = userModel!.copyWith(lastLogin: DateTime.now());
          await _firestoreService.updateUserProfile(userModel!);
          debugPrint('[AuthProvider] updated lastLogin for uid=${user.uid} onboardingCompleted=${userModel?.onboardingCompleted}');
        }
      } else {
        debugPrint('[AuthProvider] user signed out → clearing model');
        userModel = null;
      }

      notifyListeners();
      debugPrint('[AuthProvider] notifyListeners() dispatched');
    });
  }

  /// 🔹 Expose Firebase user stream
  Stream<User?> get userChanges => _authService.userChanges;

  /// 🔹 Google Sign-In
  Future<void> signInWithGoogle() async {
    debugPrint('[AuthProvider] signInWithGoogle() invoked');
    await _authService.signInWithGoogle();
  }

  /// 🔹 Apple Sign-In
  Future<void> signInWithApple() async {
    debugPrint('[AuthProvider] signInWithApple() invoked');
    await _authService.signInWithApple();
  }

  /// 🔹 Sign Out
  Future<void> signOut() async {
    debugPrint('[AuthProvider] signOut() invoked');
    await _authService.signOut();
    firebaseUser = null;
    userModel = null;
    notifyListeners();
    debugPrint('[AuthProvider] signOut complete, listeners notified');
  }

  /// 🔹 Helper: check login state
  bool get isLoggedIn => firebaseUser != null;
}
