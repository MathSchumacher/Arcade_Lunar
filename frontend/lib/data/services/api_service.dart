import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

/// Comprehensive API Service
/// Handles all backend API calls with authentication support
class ApiService {
  // Production server URL (ngrok tunnel for remote testing)
  static const String _productionUrl = 'https://03ceea548388.ngrok-free.app/api';
  
  // Development URL (localhost for web, IP for mobile)
  static const String _devWebUrl = 'http://localhost:3000/api';
  static const String _devMobileUrl = 'https://03ceea548388.ngrok-free.app/api';
  
  // Auto-detect the correct URL based on platform and build mode
  static String get _baseUrl {
    if (kDebugMode) {
      if (kIsWeb) {
        return _devWebUrl;
      } else {
        return _devMobileUrl;
      }
    } else {
      return _productionUrl;
    }
  }
  
  /// Get auth headers
  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw Exception('Authentication required');
    }
    
    return headers;
  }

  // ==========================================
  // SEARCH
  // ==========================================
  
  /// Search users
  /// [contactsOnly] - if true, only search in followed users
  static Future<List<Map<String, dynamic>>> searchUsers(String query, {bool contactsOnly = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&contactsOnly=$contactsOnly'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      print('searchUsers error: $e');
      return [];
    }
  }
  
  // ==========================================
  // PROFILES
  // ==========================================
  
  /// Get user profile by ID or username
  static Future<Map<String, dynamic>?> getProfile(String idOrUsername) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$idOrUsername/profile'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('getProfile error: $e');
      return null;
    }
  }
  
  /// Follow a user
  static Future<bool> followUser(int userId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('followUser error: $e');
      return false;
    }
  }
  
  /// Unfollow a user
  static Future<bool> unfollowUser(int userId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('unfollowUser error: $e');
      return false;
    }
  }

  // ==========================================
  // FEED & POSTS
  // ==========================================
  
  /// Get feed posts
  static Future<List<Map<String, dynamic>>> getFeed({int page = 1, int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/feed?page=$page&limit=$limit'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getFeed error: $e');
      return [];
    }
  }
  
  /// Toggle like on a post
  static Future<Map<String, dynamic>?> toggleLike(int postId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('toggleLike error: $e');
      return null;
    }
  }
  
  /// Add comment to a post
  static Future<Map<String, dynamic>?> addComment(int postId, String content) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comment'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('addComment error: $e');
      return null;
    }
  }
  
  /// Get comments for a post
  static Future<List<Map<String, dynamic>>> getComments(int postId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/comments?page=$page'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['comments'] ?? []);
      }
      return [];
    } catch (e) {
      print('getComments error: $e');
      return [];
    }
  }

  // ==========================================
  // SAVED POSTS
  // ==========================================
  
  /// Save a post
  static Future<bool> savePost(int postId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/save'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('savePost error: $e');
      return false;
    }
  }
  
  /// Unsave a post
  static Future<bool> unsavePost(int postId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/save'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('unsavePost error: $e');
      return false;
    }
  }
  
  /// Get saved posts
  static Future<List<Map<String, dynamic>>> getSavedPosts({String? searchQuery}) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      String url = '$_baseUrl/saved';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '?q=$searchQuery';
      }
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getSavedPosts error: $e');
      return [];
    }
  }

  // ==========================================
  // LIVES / STREAMS
  // ==========================================
  
  /// Get live streams
  static Future<List<Map<String, dynamic>>> getLives({String? category}) async {
    try {
      final headers = await _getHeaders();
      String url = '$_baseUrl/lives';
      if (category != null) {
        url += '?category=$category';
      }
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getLives error: $e');
      return [];
    }
  }
  
  /// Get following streams
  static Future<List<Map<String, dynamic>>> getFollowingStreams() async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.get(
        Uri.parse('$_baseUrl/lives/following'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getFollowingStreams error: $e');
      return [];
    }
  }
  
  /// Get stream by ID
  static Future<Map<String, dynamic>?> getStream(int streamId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/lives/$streamId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('getStream error: $e');
      return null;
    }
  }

  // ==========================================
  // TRENDING
  // ==========================================
  
  /// Get trending content
  static Future<List<Map<String, dynamic>>> getTrending({int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/trending?limit=$limit'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getTrending error: $e');
      return [];
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  
  /// Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications({int page = 1}) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications?page=$page'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getNotifications error: $e');
      return [];
    }
  }
  
  /// Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/count'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('getUnreadNotificationCount error: $e');
      return 0;
    }
  }
  
  /// Mark all notifications as read
  static Future<bool> markAllNotificationsRead() async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('markAllNotificationsRead error: $e');
      return false;
    }
  }

  // ==========================================
  // CHAT
  // ==========================================
  
  /// Get chat messages for a stream
  static Future<List<Map<String, dynamic>>> getChatMessages(int streamId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$streamId/chat?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getChatMessages error: $e');
      return [];
    }
  }
  
  /// Send chat message
  static Future<Map<String, dynamic>?> sendChatMessage(int streamId, String message) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/chat'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('sendChatMessage error: $e');
      return null;
    }
  }
  
  // ==========================================
  // FRIENDS
  // ==========================================
  
  /// Get friends list
  static Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/friends'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('getFriends error: $e');
      return [];
    }
  }
}
