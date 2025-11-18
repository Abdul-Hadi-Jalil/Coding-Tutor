import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

import 'navbar_screen.dart';
import 'sign_in.dart';
import 'onboarding_screens.dart';

class AuthWrapper extends StatefulWidget {
  final bool isHome;
  const AuthWrapper({super.key, this.isHome = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;
  final Map<String, Future<UserModel?>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    debugPrint('[AuthWrapper] initState → subscribed to authStateChanges()');
  }

  Future<UserModel?> _loadUserData(String uid) async {
    debugPrint('[AuthWrapper] _loadUserData(uid=$uid) → begin');
    return _userCache.putIfAbsent(uid, () async {
      final firestoreService = FirestoreService();
      final profile = await firestoreService.getUserProfile(uid);
      debugPrint('[AuthWrapper] _loadUserData(uid=$uid) → completed, found=${profile != null}');
      return profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snap) {
        debugPrint('[AuthWrapper] auth stream state=${snap.connectionState} hasError=${snap.hasError}');
        if (snap.hasError) {
          debugPrint('[AuthWrapper] ❌ auth stream error: ${snap.error}');
        }

        // While checking auth after splash, show a lightweight loader
        if (snap.connectionState == ConnectionState.waiting) {
          debugPrint('[AuthWrapper] authStateChanges → waiting');
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final user = snap.data;
        debugPrint('[AuthWrapper] authStateChanges → user=${user?.uid ?? 'null'} email=${user?.email ?? 'null'}');

        // 🔹 Not logged in → go to login
        if (user == null) {
          debugPrint('[AuthWrapper] user=null → navigating to LoginScreen');
          return const SignInScreen();
        }

        // 🔹 Logged in → Load user profile
        debugPrint('[AuthWrapper] user!=null → loading profile for uid=${user.uid} cacheHas=${_userCache.containsKey(user.uid)}');
        return FutureBuilder<UserModel?>(
          future: _loadUserData(user.uid),
          builder: (context, fs) {
            debugPrint('[AuthWrapper] FutureBuilder(state=${fs.connectionState}, hasError=${fs.hasError})');
            // Show loader for any waiting state to avoid flicker
            if (fs.connectionState == ConnectionState.waiting) {
              debugPrint('[AuthWrapper] profile load waiting → showing loader');
              return Center(
                child: const Scaffold(
                  body: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF5766F3)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Loading your profile...",
                          style: TextStyle(
                            fontSize: 14,
                            // color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (fs.hasError) {
              debugPrint('[AuthWrapper] ❌ Error loading user profile: ${fs.error}');
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Failed to load profile. Please retry.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }

            final userModel = fs.data;
            debugPrint('[AuthWrapper] profile result → isNull=${userModel == null} onboardingCompleted=${userModel?.onboardingCompleted}');

            // 🧩 If user data not found → create new default user
            if (userModel == null) {
              debugPrint('[AuthWrapper] ⚠️ User profile not found for uid=${user.uid}. Creating default profile and navigating to onboarding');
              final newUser = UserModel(
                uid: user.uid,
                email: user.email ?? '',
                name: user.displayName ?? '',
                createdAt: DateTime.now(),
                lastLogin: DateTime.now(),
                onboardingCompleted: false,
              );

              FirestoreService().saveUserProfile(newUser);
              return const OnboardingScreen();
            }

            // 🚀 If onboarding not complete → show onboarding
            if (!userModel.onboardingCompleted) {
              debugPrint('[AuthWrapper] onboardingCompleted=false → navigating to OnboardingScreen');
              return const OnboardingScreen();
            }

            // ✅ User ready → update provider and go home
            authProvider.userModel = userModel;
            debugPrint('[AuthWrapper] ✅ user ready → navigating to HomeScreen');
            // Use global key to allow programmatic tab switching
            return Navbarscreen(key: navBarKey);
          },
        );
      },
    );
  }
}
