/**
 * Mock Data for Gaming Social App API
 * Contains all mocked data for feeds, lives, trending, clips, users, and friends
 */

const currentUser = {
  id: 'user_001',
  username: 'Miguel',
  displayName: 'Hi, Miguel',
  avatar: 'https://picsum.photos/seed/miguel/150/150',
  level: 42,
  coins: 2500,
  isOnline: true,
  status: '🎮 Gaming'
};

const friends = [
  {
    id: 'friend_001',
    username: 'Alex',
    avatar: 'https://picsum.photos/seed/alex/150/150',
    isOnline: true,
    status: 'Playing Valorant',
    game: 'Valorant'
  },
  {
    id: 'friend_002',
    username: 'Luna',
    avatar: 'https://picsum.photos/seed/luna/150/150',
    isOnline: true,
    status: 'Streaming',
    game: 'Just Chatting'
  },
  {
    id: 'friend_003',
    username: 'Max',
    avatar: 'https://picsum.photos/seed/max/150/150',
    isOnline: true,
    status: 'In Queue',
    game: 'League of Legends'
  },
  {
    id: 'friend_004',
    username: 'Zara',
    avatar: 'https://picsum.photos/seed/zara/150/150',
    isOnline: false,
    status: 'Offline',
    game: null
  },
  {
    id: 'friend_005',
    username: 'Ryan',
    avatar: 'https://picsum.photos/seed/ryan/150/150',
    isOnline: true,
    status: 'In Match',
    game: 'CS2'
  },
  {
    id: 'friend_006',
    username: 'Sophie',
    avatar: 'https://picsum.photos/seed/sophie/150/150',
    isOnline: true,
    status: 'Watching Stream',
    game: null
  }
];

const featuredEvent = {
  id: 'event_001',
  title: 'Cosmic Cup Finals',
  subtitle: 'Win exclusive badges & XP boost',
  backgroundImage: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80',
  endTime: new Date(Date.now() + 2 * 60 * 60 * 1000 + 45 * 60 * 1000 + 12 * 1000).toISOString(),
  prizes: ['Exclusive Badge', '500 XP', 'Cosmic Skin']
};

const trending = [
  {
    id: 'trend_001',
    title: 'FPS Tournament Finals',
    streamer: 'ProGamer',
    thumbnail: 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=400&q=80',
    viewers: 15420,
    isLive: true,
    game: 'Valorant',
    duration: '2:34:15'
  },
  {
    id: 'trend_002',
    title: 'Speedrun Challenge',
    streamer: 'FastHands',
    thumbnail: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&q=80',
    viewers: 12300,
    isLive: true,
    game: 'Elden Ring',
    duration: '45:20'
  },
  {
    id: 'trend_003',
    title: 'Just Chatting & Chill',
    streamer: 'ChillVibes',
    thumbnail: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=400&q=80',
    viewers: 8750,
    isLive: true,
    game: 'Just Chatting',
    duration: '1:15:42'
  },
  {
    id: 'trend_004',
    title: 'Ranked Grind',
    streamer: 'TryHard',
    thumbnail: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80',
    viewers: 6200,
    isLive: false,
    game: 'League of Legends',
    duration: '3:20:00'
  }
];

const quickClips = [
  {
    id: 'clip_001',
    title: 'Insane Flick! 🎯',
    creator: 'HeadshotKing',
    thumbnail: 'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=300&q=80',
    views: 45200,
    likes: 3200,
    duration: '0:15',
    game: 'CS2'
  },
  {
    id: 'clip_002',
    title: 'Setup Reveal ✨',
    creator: 'TechGuru',
    thumbnail: 'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=300&q=80',
    views: 32100,
    likes: 2800,
    duration: '0:30',
    game: 'Setup Tour'
  },
  {
    id: 'clip_003',
    title: 'GG WP',
    creator: 'ProPlayer',
    thumbnail: 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=300&q=80',
    views: 28500,
    likes: 1950,
    duration: '0:22',
    game: 'Valorant'
  },
  {
    id: 'clip_004',
    title: '1v5 Clutch 🔥',
    creator: 'ClutchMaster',
    thumbnail: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=300&q=80',
    views: 67800,
    likes: 5400,
    duration: '0:45',
    game: 'CS2'
  },
  {
    id: 'clip_005',
    title: 'Perfect Timing',
    creator: 'LuckyShot',
    thumbnail: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&q=80',
    views: 19200,
    likes: 1200,
    duration: '0:18',
    game: 'Fortnite'
  }
];

const feed = [
  {
    id: 'post_001',
    author: {
      id: 'user_shadow',
      username: 'Shadow Riser',
      avatar: 'https://picsum.photos/seed/shadow/150/150',
      isVerified: true,
      badge: '1 Lugar'
    },
    content: 'The energy at this tournament was absolutely unreal! 🔥💪 Can\'t wait for the next season. #legends',
    images: [
      'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80',
      'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=600&q=80',
      'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=600&q=80',
      'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80'
    ],
    likes: 2400,
    comments: 227,
    shares: 45,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    isLiked: false
  },
  {
    id: 'post_002',
    author: {
      id: 'user_pixel',
      username: 'PixelRunner',
      avatar: 'https://picsum.photos/seed/pixel/150/150',
      isVerified: false,
      badge: null
    },
    content: 'Finally hit GM after 500 hours! The grind was real 💎',
    images: [],
    likes: 892,
    comments: 64,
    shares: 12,
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
    isLiked: true
  },
  {
    id: 'post_003',
    author: {
      id: 'user_light',
      username: 'Light Yagami',
      avatar: 'https://picsum.photos/seed/light/150/150',
      isVerified: true,
      badge: 'Streamer'
    },
    content: 'Late night grind with the new setup 🖥️',
    images: [
      'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=600&q=80',
      'https://images.unsplash.com/photo-1598550476439-6847785fcea6?w=600&q=80'
    ],
    likes: 1567,
    comments: 89,
    shares: 23,
    createdAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
    isLiked: false
  },
  {
    id: 'post_004',
    author: {
      id: 'user_nova',
      username: 'NovaStrike',
      avatar: 'https://picsum.photos/seed/nova/150/150',
      isVerified: false,
      badge: 'Rising Star'
    },
    content: 'Who else is hyped for the new season? Drop your predictions below! 👇🎮',
    images: [],
    likes: 445,
    comments: 156,
    shares: 8,
    createdAt: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString(),
    isLiked: false
  }
];

const lives = {
  message: 'Coming Soon',
  description: 'Live streaming feature is under development',
  placeholder: [
    {
      id: 'live_placeholder_001',
      title: 'Live Feature Coming Soon',
      thumbnail: 'https://images.unsplash.com/photo-1493711662062-fa541f7f70cf?w=400&q=80',
      isPlaceholder: true
    }
  ]
};

module.exports = {
  currentUser,
  friends,
  featuredEvent,
  trending,
  quickClips,
  feed,
  lives
};
