class FeaturedEvent {
  final String id;
  final String title;
  final String subtitle;
  final String backgroundImage;
  final DateTime endTime;
  final List<String> prizes;

  FeaturedEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.backgroundImage,
    required this.endTime,
    required this.prizes,
  });

  factory FeaturedEvent.fromJson(Map<String, dynamic> json) {
    return FeaturedEvent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      backgroundImage: json['backgroundImage'],
      endTime: DateTime.parse(json['endTime']),
      prizes: List<String>.from(json['prizes']),
    );
  }
}
