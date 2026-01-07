import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication Service
/// Handles login, register, verify, and session management
class AuthService {
  // ============================================
  // 🔧 API URL CONFIGURATION:
  // ============================================
  
  // Production server URL (ngrok tunnel for remote testing)
  static const String _productionUrl = 'https://03ceea548388.ngrok-free.app/api';
  
  // Development URL (localhost for web, IP for mobile)
  static const String _devWebUrl = 'http://localhost:3000/api';
  static const String _devMobileUrl = 'https://03ceea548388.ngrok-free.app/api';
  
  // Auto-detect the correct URL based on platform and build mode
  static String get _baseUrl {
    if (kDebugMode) {
      // Debug/Development mode
      if (kIsWeb) {
        return _devWebUrl; // Web uses localhost
      } else {
        return _devMobileUrl; // Mobile uses IP
      }
    } else {
      // Release/Production mode
      return _productionUrl;
    }
  }
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';


  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save token and user data
  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String password,
    String? username,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
        if (username != null) 'username': username,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrPhone': emailOrPhone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      // If login successful and doesn't require verification, save session
      if (data['success'] == true && data['requiresVerification'] != true) {
        await saveSession(data['data']['token'], data['data']['user']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  /// Verify account
  static Future<Map<String, dynamic>> verify({
    required int userId,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'code': code,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      // Save session after verification
      await saveSession(data['data']['token'], data['data']['user']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Verification failed');
    }
  }

  /// Resend verification code
  static Future<Map<String, dynamic>> resendCode({
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/resend-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to resend code');
    }
  }

  /// Logout
  static Future<void> logout() async {
    final token = await getToken();
    
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // Ignore logout API errors
      }
    }
    
    await clearSession();
  }

  /// Get current user from API
  static Future<Map<String, dynamic>?> getMe() async {
    final token = await getToken();
    
    if (token == null) return null;
    
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    
    return null;
  }

  /// Request email verification (for deferred verification from settings)
  static Future<Map<String, dynamic>> requestEmailVerification() async {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Authentication required');
    }
    
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/request-email-verification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to request email verification');
    }
  }

  /// Check if user has pending email verification
  static Future<bool> hasPendingEmailVerification() async {
    final user = await getUser();
    if (user != null) {
      return user['pendingEmailVerification'] == true;
    }
    return false;
  }

  /// Forgot password - sends reset code via email or SMS
  static Future<Map<String, dynamic>> forgotPassword({
    required String emailOrPhone,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'emailOrPhone': emailOrPhone}),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to send reset code');
    }
  }

  /// Reset password with code
  static Future<Map<String, dynamic>> resetPassword({
    required int userId,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to reset password');
    }
  }

  /// Social login (Google/Facebook)
  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required Map<String, dynamic> profile,
    String? accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'profile': profile,
        if (accessToken != null) 'accessToken': accessToken,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      // Save session
      if (data['success'] == true) {
        await saveSession(data['data']['token'], data['data']['user']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'Social login failed');
    }
  }
}
