/// Mock Data Service
/// Provides mock data for testing all app interactions
/// Default test account: admin@arcade.lunar / lunar2026

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Current logged in user
  static final MockUser currentUser = MockUser(
    id: 1,
    username: 'miguel',
    displayName: 'Miguel Gamer',
    email: 'admin@arcade.lunar',
    avatarUrl: null,
    bio: '🎮 Valorant streamer | Top 500 player',
    followers: 15420,
    following: 234,
    isVerified: true,
  );

  // Mock streamers to follow
  static final List<MockStreamer> streamers = [
    MockStreamer(
      id: 2,
      username: 'cosmicplayer',
      displayName: 'CosmicPlayer',
      avatarInitial: 'C',
      game: 'Valorant',
      viewers: 12543,
      isLive: true,
      isFollowed: true,
      title: '🔥 Ranked Grind to Immortal!',
    ),
    MockStreamer(
      id: 3,
      username: 'lunargirl',
      displayName: 'LunarGirl',
      avatarInitial: 'L',
      game: 'League of Legends',
      viewers: 8921,
      isLive: true,
      isFollowed: true,
      title: 'Diamond promos today! 💎',
    ),
    MockStreamer(
      id: 4,
      username: 'stargamer99',
      displayName: 'StarGamer99',
      avatarInitial: 'S',
      game: 'Minecraft',
      viewers: 5432,
      isLive: true,
      isFollowed: false,
      title: 'Building a mega castle 🏰',
    ),
    MockStreamer(
      id: 5,
      username: 'prosniper',
      displayName: 'ProSniper',
      avatarInitial: 'P',
      game: 'Counter-Strike 2',
      viewers: 21098,
      isLive: true,
      isFollowed: true,
      title: 'AWP Only Challenge 🎯',
    ),
    MockStreamer(
      id: 6,
      username: 'gamequeen',
      displayName: 'GameQueen',
      avatarInitial: 'G',
      game: 'Fortnite',
      viewers: 3210,
      isLive: false,
      isFollowed: false,
      title: 'Last stream: Victory Royale x5',
    ),
    MockStreamer(
      id: 7,
      username: 'chill_vibes',
      displayName: 'ChillVibes',
      avatarInitial: 'V',
      game: 'Just Chatting',
      viewers: 1876,
      isLive: true,
      isFollowed: true,
      title: 'Late night chat 🌙 AMA',
    ),
  ];

  // Mock gifts available
  static final List<MockGift> gifts = [
    MockGift(id: 1, name: 'Star', emoji: '⭐', cost: 10),
    MockGift(id: 2, name: 'Heart', emoji: '❤️', cost: 50),
    MockGift(id: 3, name: 'Diamond', emoji: '💎', cost: 100),
    MockGift(id: 4, name: 'Rocket', emoji: '🚀', cost: 500),
    MockGift(id: 5, name: 'Crown', emoji: '👑', cost: 1000),
  ];

  // User's coin balance
  static int userCoins = 5000;

  // Interaction methods
  static void toggleFollow(int streamerId) {
    final streamer = streamers.firstWhere((s) => s.id == streamerId);
    streamer.isFollowed = !streamer.isFollowed;
  }

  static void toggleLike(int streamerId) {
    final streamer = streamers.firstWhere((s) => s.id == streamerId);
    streamer.isLiked = !streamer.isLiked;
  }

  static bool sendGift(int streamerId, MockGift gift) {
    if (userCoins >= gift.cost) {
      userCoins -= gift.cost;
      return true;
    }
    return false;
  }

  static List<MockStreamer> get followedStreamers =>
      streamers.where((s) => s.isFollowed).toList();

  static List<MockStreamer> get liveStreamers =>
      streamers.where((s) => s.isLive).toList();

  static List<MockStreamer> get favoriteLiveStreamers =>
      streamers.where((s) => s.isFollowed && s.isLive).toList();
}

class MockUser {
  final int id;
  final String username;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String bio;
  final int followers;
  final int following;
  final bool isVerified;

  MockUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.bio,
    required this.followers,
    required this.following,
    required this.isVerified,
  });
}

class MockStreamer {
  final int id;
  final String username;
  final String displayName;
  final String avatarInitial;
  final String game;
  int viewers;
  bool isLive;
  bool isFollowed;
  bool isLiked;
  final String title;

  MockStreamer({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarInitial,
    required this.game,
    required this.viewers,
    required this.isLive,
    required this.isFollowed,
    this.isLiked = false,
    required this.title,
  });
}

class MockGift {
  final int id;
  final String name;
  final String emoji;
  final int cost;

  MockGift({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
  });
}
