import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Sign in error: $e');
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      print('Attempting to create user: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('User created successfully: ${result.user?.uid}');
      
      // Update display name
      await result.user?.updateDisplayName('$firstName $lastName');
      print('Display name updated: $firstName $lastName');
      
      return result;
    } catch (e) {
      print('Registration error: $e');
      throw _handleAuthException(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Password reset error: $e');
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print('Sign out error: $e');
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      print('FirebaseAuthException code: ${e.code}');
      switch (e.code) {
        case 'weak-password':
          return Exception('The password provided is too weak.');
        case 'email-already-in-use':
          return Exception('An account already exists for this email.');
        case 'user-not-found':
          return Exception('No user found for this email.');
        case 'wrong-password':
          return Exception('Wrong password provided.');
        case 'invalid-email':
          return Exception('The email address is not valid.');
        case 'user-disabled':
          return Exception('This user account has been disabled.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later.');
        case 'operation-not-allowed':
          return Exception('Email & Password authentication is not enabled.');
        default:
          return Exception('An error occurred: ${e.message}');
      }
    }
    return Exception('An error occurred: $e');
  }
}