class Trending {
  final String id;
  final String title;
  final String streamer;
  final String thumbnail;
  final int viewers;
  final bool isLive;
  final String game;
  final String duration;

  Trending({
    required this.id,
    required this.title,
    required this.streamer,
    required this.thumbnail,
    required this.viewers,
    required this.isLive,
    required this.game,
    required this.duration,
  });

  factory Trending.fromJson(Map<String, dynamic> json) {
    return Trending(
      id: json['id'],
      title: json['title'],
      streamer: json['streamer'],
      thumbnail: json['thumbnail'],
      viewers: json['viewers'],
      isLive: json['isLive'],
      game: json['game'],
      duration: json['duration'],
    );
  }
}
