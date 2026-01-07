// import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

/// Google Sign-In Service (Stubbed for Debugging)
class GoogleAuthService {
  // static final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   scopes: ['email', 'profile'],
  // );

  /// Sign in with Google
  static Future<Map<String, dynamic>> signIn() async {
    // throw Exception('Google Sign-In is temporarily disabled for debugging.');
    
    // Simulate a delay
    await Future.delayed(const Duration(seconds: 1));
    throw Exception('Google Sign-In Disabled');
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    // await _googleSignIn.signOut();
  }

  /// Check if user is already signed in
  static Future<bool> isSignedIn() async {
    return false;
    // return await _googleSignIn.isSignedIn();
  }

  /// Get current Google user (if signed in)
  static dynamic get currentUser => null; // GoogleSignInAccount?
}
