class ApiConstants {
  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for web browser and iOS simulator
  // For physical devices, use your machine's IP address
  static const String baseUrl = 'http://10.0.2.2:3000/api'; 
  
  static const String user = '/user';
  static const String friends = '/friends';
  static const String trending = '/trending';
  static const String featured = '/featured';
  static const String clips = '/clips';
  static const String lives = '/lives';
  static const String feed = '/feed';
}
