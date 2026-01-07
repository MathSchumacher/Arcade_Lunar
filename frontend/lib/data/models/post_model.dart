/// Post Author model
class PostAuthor {
  final dynamic id; // Can be int or String
  final String username;
  final String? displayName;
  final String avatar;
  final bool isVerified;
  final String? badge;

  PostAuthor({
    required this.id,
    required this.username,
    this.displayName,
    required this.avatar,
    required this.isVerified,
    this.badge,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? 'Unknown',
      displayName: json['displayName'],
      avatar: json['avatar'] ?? 'https://picsum.photos/150',
      isVerified: json['isVerified'] ?? false,
      badge: json['badge'],
    );
  }
}

/// Post model
class Post {
  final dynamic id; // Can be int or String
  final PostAuthor author;
  final String content;
  final List<String> images;
  final int likes;
  final int comments;
  final int shares;
  final int? views;
  final DateTime createdAt;
  final bool isLiked;
  final bool isSaved;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.shares,
    this.views,
    required this.createdAt,
    required this.isLiked,
    this.isSaved = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: PostAuthor.fromJson(json['author'] ?? {}),
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      views: json['views'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
    );
  }
  
  /// Create Post from API response data
  factory Post.fromApiData(Map<String, dynamic> data) {
    return Post(
      id: data['id'],
      author: PostAuthor(
        id: data['author']?['id'] ?? data['author_id'] ?? 0,
        username: data['author']?['username'] ?? data['username'] ?? 'Unknown',
        displayName: data['author']?['displayName'] ?? data['display_name'],
        avatar: data['author']?['avatar'] ?? data['avatar_url'] ?? 'https://picsum.photos/150',
        isVerified: data['author']?['isVerified'] ?? data['is_verified'] ?? false,
        badge: data['author']?['badge'] ?? data['badge'],
      ),
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      likes: data['likes'] ?? data['likes_count'] ?? 0,
      comments: data['comments'] ?? data['comments_count'] ?? 0,
      shares: data['shares'] ?? data['shares_count'] ?? 0,
      views: data['views'] ?? data['views_count'],
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isLiked: data['isLiked'] ?? data['is_liked'] ?? false,
      isSaved: data['isSaved'] ?? data['is_saved'] ?? false,
    );
  }
}
