import '../models/post_model.dart';
import 'dart:math';

/// Trending service that calculates engagement scores for posts
class TrendingService {
  /// Calculate engagement score for a post
  /// Formula: (likes * 1.0 + comments * 2.5 + shares * 3.0 + views * 0.1) * recencyBonus
  static double calculateEngagementScore(Post post) {
    final hoursSincePost = DateTime.now().difference(post.createdAt).inHours;
    
    // Recency bonus: posts < 24h get 1.5x, < 6h get 2x
    double recencyBonus = 1.0;
    if (hoursSincePost < 6) {
      recencyBonus = 2.0;
    } else if (hoursSincePost < 24) {
      recencyBonus = 1.5;
    }
    
    // Engagement weights
    const likeWeight = 1.0;
    const commentWeight = 2.5;   // Comments are more valuable
    const shareWeight = 3.0;     // Shares are most valuable
    const viewWeight = 0.1;      // Views have low weight
    
    final baseScore = 
        (post.likes * likeWeight) + 
        (post.comments * commentWeight) + 
        (post.shares * shareWeight) +
        ((post.views ?? 0) * viewWeight);
    
    return baseScore * recencyBonus;
  }

  /// Sort posts by trending score
  static List<Post> sortByTrending(List<Post> posts) {
    final scoredPosts = posts.map((p) {
      return {'post': p, 'score': calculateEngagementScore(p)};
    }).toList();
    
    scoredPosts.sort((a, b) => 
        (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredPosts.map((m) => m['post'] as Post).toList();
  }

  /// Get trending hashtags from posts
  static List<String> getTrendingHashtags(List<Post> posts) {
    final hashtagCounts = <String, int>{};
    
    for (final post in posts) {
      final hashtags = RegExp(r'#\w+').allMatches(post.content);
      for (final match in hashtags) {
        final tag = match.group(0)!.toLowerCase();
        hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = hashtagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(10).map((e) => e.key).toList();
  }

  /// Generate mock trending posts with scores
  static List<Post> getMockTrendingPosts() {
    final random = Random();
    
    final posts = [
      Post(
        id: 'trend_1',
        author: PostAuthor(
          id: 'user_prog',
          username: 'ProGamer',
          avatar: 'https://picsum.photos/seed/prog/100/100',
          isVerified: true,
          badge: '🎮 TOP PLAYER',
        ),
        content: '🔥 Just hit Global Elite! Years of grinding finally paid off #valorant #gaming',
        likes: 2847 + random.nextInt(500),
        comments: 312 + random.nextInt(100),
        shares: 89 + random.nextInt(50),
        views: 15000 + random.nextInt(5000),
        images: ['https://picsum.photos/seed/valorant/400/300'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isLiked: false,
      ),
      Post(
        id: 'trend_2',
        author: PostAuthor(
          id: 'user_queen',
          username: 'StreamerQueen',
          avatar: 'https://picsum.photos/seed/queen/100/100',
          isVerified: true,
          badge: '👑 VERIFIED',
        ),
        content: '✨ New merch drop this Friday! Whos ready? #merch #giveaway',
        likes: 5621 + random.nextInt(1000),
        comments: 876 + random.nextInt(200),
        shares: 234 + random.nextInt(100),
        views: 32000 + random.nextInt(8000),
        images: ['https://picsum.photos/seed/merch/400/300'],
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isLiked: true,
      ),
      Post(
        id: 'trend_3',
        author: PostAuthor(
          id: 'user_news',
          username: 'GameNews',
          avatar: 'https://picsum.photos/seed/news/100/100',
          isVerified: true,
          badge: '📰 NEWS',
        ),
        content: '⚡ BREAKING: New game announcement at 8PM! Dont miss it! #gaming #announcement',
        likes: 8912 + random.nextInt(2000),
        comments: 1203 + random.nextInt(300),
        shares: 567 + random.nextInt(200),
        views: 85000 + random.nextInt(15000),
        images: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isLiked: false,
      ),
      Post(
        id: 'trend_4',
        author: PostAuthor(
          id: 'user_esports',
          username: 'EsportsPro',
          avatar: 'https://picsum.photos/seed/esports/100/100',
          isVerified: true,
          badge: '🏆 CHAMPION',
        ),
        content: 'What a match! GG to all teams 🎮 #esports #tournament',
        likes: 3456 + random.nextInt(800),
        comments: 423 + random.nextInt(100),
        shares: 123 + random.nextInt(50),
        views: 22000 + random.nextInt(5000),
        images: ['https://picsum.photos/seed/tournament/400/300'],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isLiked: false,
      ),
    ];
    
    return sortByTrending(posts);
  }
}
