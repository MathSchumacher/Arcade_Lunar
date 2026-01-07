import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'auth_service.dart';

/// Facebook Authentication Service
/// Handles Facebook OAuth login and backend integration
class FacebookAuthService {
  /// Sign in with Facebook
  /// Returns user data on success, throws on failure
  static Future<Map<String, dynamic>> signIn() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        // Wait a bit for SDK to be ready on web
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Trigger Facebook Sign-In flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw Exception('Login cancelado pelo usuário');
      }

      if (result.status == LoginStatus.failed) {
        // More descriptive error for web
        String errorMessage = result.message ?? 'Falha no login com Facebook';
        if (kIsWeb && errorMessage.contains('undefined')) {
          errorMessage = 'Facebook SDK não carregou corretamente. Por favor, recarregue a página e tente novamente.';
        }
        throw Exception(errorMessage);
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw Exception('Falha no login com Facebook');
      }

      // Get user data from Facebook
      final userData = await FacebookAuth.instance.getUserData(
        fields: 'id,name,email,picture.width(200)',
      );

      // Build profile for backend
      final profile = {
        'id': userData['id'],
        'email': userData['email'],
        'name': userData['name'],
        'picture': userData['picture']?['data']?['url'],
      };

      // Send to backend
      final response = await AuthService.socialLogin(
        provider: 'facebook',
        profile: profile,
        accessToken: result.accessToken?.tokenString,
      );

      return response;

    } catch (e) {
      print('Facebook Sign-In error: $e');
      
      // Handle specific web errors
      if (kIsWeb) {
        String errorStr = e.toString().toLowerCase();
        if (errorStr.contains('fb') && errorStr.contains('undefined') ||
            errorStr.contains('window.fb')) {
          throw Exception('Facebook SDK não está disponível. Certifique-se de que popups estão permitidos e recarregue a página.');
        }
        if (errorStr.contains('popup')) {
          throw Exception('Popup bloqueado! Permita popups para este site e tente novamente.');
        }
      }
      
      rethrow;
    }
  }

  /// Sign out from Facebook
  static Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }

  /// Check current access token
  static Future<bool> isLoggedIn() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    return accessToken != null;
  }

  /// Get current Facebook user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    if (accessToken != null) {
      return await FacebookAuth.instance.getUserData();
    }
    return null;
  }
}
