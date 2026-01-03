class Friend {
  final String id;
  final String username;
  final String avatar;
  final bool isOnline;
  final String status;
  final String? game;

  Friend({
    required this.id,
    required this.username,
    required this.avatar,
    required this.isOnline,
    required this.status,
    this.game,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
      isOnline: json['isOnline'],
      status: json['status'],
      game: json['game'],
    );
  }
}
