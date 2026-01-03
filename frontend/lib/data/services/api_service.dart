import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../models/trending_model.dart';
import '../models/featured_model.dart';
import '../models/post_model.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.user);
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<List<Friend>> getFriends() async {
    try {
      final response = await _dio.get(ApiConstants.friends);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load friends: $e');
    }
  }

  Future<List<Trending>> getTrending() async {
    try {
      final response = await _dio.get(ApiConstants.trending);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Trending.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load trending content: $e');
    }
  }

  Future<FeaturedEvent> getFeaturedEvent() async {
    try {
      final response = await _dio.get(ApiConstants.featured);
      return FeaturedEvent.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load featured event: $e');
    }
  }

  Future<List<Post>> getFeed() async {
    try {
      final response = await _dio.get(ApiConstants.feed);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }
}
