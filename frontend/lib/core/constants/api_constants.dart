/// API Constants
/// Centralized configuration for all API endpoints
class ApiConstants {
  // ============================================
  // 🔧 BASE URL CONFIGURATION
  // ============================================
  // For Chrome/Web testing:
  //   static const String baseUrl = 'http://localhost:3000/api';
  //
  // For Android emulator:
  //   static const String baseUrl = 'http://10.0.2.2:3000/api';
  //
  // For physical device (same WiFi) - use your PC's IP:
  //   static const String baseUrl = 'http://192.168.X.X:3000/api';
  // ============================================
  
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authVerify = '/auth/verify';
  static const String authResendCode = '/auth/resend-code';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  
  // User & Profile
  static const String user = '/user';
  static const String users = '/users';
  
  // Friends
  static const String friends = '/friends';
  
  // Search
  static const String search = '/search';
  static const String searchPosts = '/search/posts';
  
  // Feed & Posts
  static const String feed = '/feed';
  static const String posts = '/posts';
  
  // Trending & Featured
  static const String trending = '/trending';
  static const String featured = '/featured';
  
  // Lives
  static const String lives = '/lives';
  static const String livesFollowing = '/lives/following';
  
  // Clips
  static const String clips = '/clips';
  
  // Saved Posts
  static const String saved = '/saved';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsCount = '/notifications/count';
  static const String notificationsReadAll = '/notifications/read-all';
  
  // Streams (Chat)
  static const String streams = '/streams';
}
