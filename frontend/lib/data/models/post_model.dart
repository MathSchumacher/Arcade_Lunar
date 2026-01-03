class PostAuthor {
  final String id;
  final String username;
  final String avatar;
  final bool isVerified;
  final String? badge;

  PostAuthor({
    required this.id,
    required this.username,
    required this.avatar,
    required this.isVerified,
    this.badge,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
      isVerified: json['isVerified'],
      badge: json['badge'],
    );
  }
}

class Post {
  final String id;
  final PostAuthor author;
  final String content;
  final List<String> images;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;
  final bool isLiked;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
    required this.isLiked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: PostAuthor.fromJson(json['author']),
      content: json['content'],
      images: List<String>.from(json['images']),
      likes: json['likes'],
      comments: json['comments'],
      shares: json['shares'],
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'],
    );
  }
}
