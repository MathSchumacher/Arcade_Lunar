class User {
  final String id;
  final String username;
  final String displayName;
  final String avatar;
  final int level;
  final int coins;
  final bool isOnline;
  final String status;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.level,
    required this.coins,
    required this.isOnline,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      avatar: json['avatar'],
      level: json['level'],
      coins: json['coins'],
      isOnline: json['isOnline'],
      status: json['status'],
    );
  }
}
