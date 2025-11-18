import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Controller to encapsulate authentication actions
class AuthController {
  final AuthService _authService = AuthService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<User?> signInWithGoogle() async {
    return _authService.signInWithGoogle();
  }

  Future<User?> signInWithApple() async {
    return _authService.signInWithApple();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}