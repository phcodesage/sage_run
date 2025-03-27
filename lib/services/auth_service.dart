import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final SharedPreferences _prefs;

  AuthService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get current user
  Future<AppUser?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      authProvider: firebaseUser.providerData.first.providerId,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  // Stream of auth state changes
  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().map((firebaseUser) {
    if (firebaseUser == null) return null;
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      authProvider: firebaseUser.providerData.first.providerId,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  });

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) return null;

      // Save user data to SharedPreferences
      final user = AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        authProvider: 'google',
        createdAt: DateTime.now(),
      );
      
      await _prefs.setString('user', user.toJson().toString());
      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign in with Facebook
  Future<AppUser?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.token,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final firebaseUser = userCredential.user;
        
        if (firebaseUser == null) return null;

        final user = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          authProvider: 'facebook',
          createdAt: DateTime.now(),
        );
        
        await _prefs.setString('user', user.toJson().toString());
        return user;
      }
      return null;
    } catch (e) {
      print('Error signing in with Facebook: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Facebook
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        print('Error signing out from Facebook: $e');
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Clear local storage
      await _prefs.remove('user');
    } catch (e) {
      print('Error during sign out: $e');
      // Even if there's an error, try to sign out from Firebase
      await _auth.signOut();
      await _prefs.remove('user');
    }
  }

  // Get saved user
  Future<AppUser?> getSavedUser() async {
    final userJson = _prefs.getString('user');
    if (userJson == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(userJson as Map));
  }

  // Update user profile
  Future<void> updateUser(AppUser user) async {
    try {
      // Update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(user.name);
      
      // Update local storage
      await _prefs.setString('user', user.toJson().toString());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
} 