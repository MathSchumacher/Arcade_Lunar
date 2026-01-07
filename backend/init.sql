-- Create users table (extended for registration + social auth)
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  username VARCHAR(50) UNIQUE,
  cpf VARCHAR(14) UNIQUE,
  date_of_birth DATE,
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  email_verified BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE,
  is_minor BOOLEAN DEFAULT FALSE,
  age_restricted BOOLEAN DEFAULT FALSE,
  google_id VARCHAR(255) UNIQUE,
  facebook_id VARCHAR(255) UNIQUE,
  auth_provider VARCHAR(20) DEFAULT 'email',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create verification codes table
CREATE TABLE IF NOT EXISTS verification_codes (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  type VARCHAR(20) CHECK (type IN ('email', 'phone', 'sms')),
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) UNIQUE NOT NULL,
  device_info TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User profiles with social links
CREATE TABLE IF NOT EXISTS user_profiles (
  id SERIAL PRIMARY KEY,
  user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  display_name VARCHAR(100),
  bio TEXT,
  banner_url TEXT,
  social_links JSONB DEFAULT '{}',
  is_profile_complete BOOLEAN DEFAULT FALSE,
  is_18_plus_content BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Phone history for ban tracking
CREATE TABLE IF NOT EXISTS phone_history (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  phone VARCHAR(20) NOT NULL,
  ip_address VARCHAR(45),
  verification_method VARCHAR(10) CHECK (verification_method IN ('sms')),
  verified_at TIMESTAMP DEFAULT NOW(),
  is_banned BOOLEAN DEFAULT FALSE
);

-- Stream configuration per user
CREATE TABLE IF NOT EXISTS stream_configs (
  id SERIAL PRIMARY KEY,
  user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  mic_device_id VARCHAR(255),
  mic_volume INT DEFAULT 100,
  screen_share_enabled BOOLEAN DEFAULT TRUE,
  stream_key VARCHAR(64) UNIQUE,
  default_title VARCHAR(200),
  default_category_id INT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Game categories (Twitch-style)
CREATE TABLE IF NOT EXISTS game_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  cover_url TEXT,
  viewer_count INT DEFAULT 0,
  streamer_count INT DEFAULT 0,
  is_18_plus BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default categories
INSERT INTO game_categories (name, slug, cover_url) VALUES
  ('Just Chatting', 'just-chatting', NULL),
  ('Valorant', 'valorant', NULL),
  ('League of Legends', 'league-of-legends', NULL),
  ('Minecraft', 'minecraft', NULL),
  ('GTA V', 'gta-v', NULL),
  ('Fortnite', 'fortnite', NULL),
  ('Counter-Strike 2', 'cs2', NULL),
  ('Apex Legends', 'apex-legends', NULL)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- MISSING TABLES (Critical fixes)
-- =============================================

-- Posts table (with embedded video support)
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  video_url TEXT,
  video_type VARCHAR(20) CHECK (video_type IN ('youtube', 'instagram', 'tiktok', 'twitch', 'other')),
  video_thumbnail TEXT,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  shares_count INT DEFAULT 0,
  views_count INT DEFAULT 0,
  is_deleted BOOLEAN DEFAULT FALSE,
  is_mock BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Post likes table
CREATE TABLE IF NOT EXISTS post_likes (
  id SERIAL PRIMARY KEY,
  post_id INT REFERENCES posts(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Post comments table
CREATE TABLE IF NOT EXISTS post_comments (
  id SERIAL PRIMARY KEY,
  post_id INT REFERENCES posts(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  likes_count INT DEFAULT 0,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Follows table (user A follows user B)
CREATE TABLE IF NOT EXISTS follows (
  id SERIAL PRIMARY KEY,
  follower_id INT REFERENCES users(id) ON DELETE CASCADE,
  following_id INT REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- Saved posts table (bookmarks)
CREATE TABLE IF NOT EXISTS saved_posts (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  post_id INT REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('live', 'follow', 'like', 'comment', 'mention', 'gift', 'system')),
  from_user_id INT REFERENCES users(id) ON DELETE SET NULL,
  reference_id INT,
  reference_type VARCHAR(50),
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Chat messages for streams
CREATE TABLE IF NOT EXISTS chat_messages (
  id SERIAL PRIMARY KEY,
  stream_id INT NOT NULL,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  emotes JSONB DEFAULT '[]',
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Live streams table
CREATE TABLE IF NOT EXISTS live_streams (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  category_id INT REFERENCES game_categories(id),
  thumbnail_url TEXT,
  viewer_count INT DEFAULT 0,
  is_live BOOLEAN DEFAULT FALSE,
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  is_mock BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Friends table (bidirectional friendship)
CREATE TABLE IF NOT EXISTS friends (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  friend_id INT REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Clips table (Moments from live streams)
CREATE TABLE IF NOT EXISTS clips (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  stream_id INT REFERENCES live_streams(id) ON DELETE SET NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  duration INT DEFAULT 0,
  start_timestamp INT DEFAULT 0,
  end_timestamp INT DEFAULT 0,
  views_count INT DEFAULT 0,
  likes_count INT DEFAULT 0,
  game_id INT REFERENCES game_categories(id),
  is_public BOOLEAN DEFAULT TRUE,
  is_mock BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Clip likes table
CREATE TABLE IF NOT EXISTS clip_likes (
  id SERIAL PRIMARY KEY,
  clip_id INT REFERENCES clips(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(clip_id, user_id)
);

-- Password reset tokens
CREATE TABLE IF NOT EXISTS password_resets (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for clips
CREATE INDEX IF NOT EXISTS idx_clips_user_id ON clips(user_id);
CREATE INDEX IF NOT EXISTS idx_clips_stream_id ON clips(stream_id);
CREATE INDEX IF NOT EXISTS idx_clips_game_id ON clips(game_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id);

-- =============================================
-- MOCK SEED DATA (Debug mode - is_mock = true)
-- Remove with: DELETE FROM table WHERE is_mock = true
-- =============================================

-- Insert mock users (Alanzoka, Gaulles, and test streamers)
-- ADMIN TEST ACCOUNT: admin@arcade.lunar / lunar2026 (bcrypt hash of 'lunar2026')
INSERT INTO users (email, phone, password_hash, username, avatar_url, is_verified, email_verified, created_at) VALUES
  ('admin@arcade.lunar', NULL, '$2b$10$FgL5FfDqU6r8mYq8.wQgzOWXlH0K1nRNj8eKVjYV2K5xm5C0mZQQC', 'AdminLunar', 'https://picsum.photos/seed/admin/150/150', true, true, NOW())
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (email, phone, password_hash, username, avatar_url, is_verified, created_at) VALUES
  ('alanzoka@mock.arcade', '+5511999990001', '$2b$10$mockhashalanzoka', 'Alanzoka', 'https://picsum.photos/seed/alanzoka/150/150', true, NOW()),
  ('gaulles@mock.arcade', '+5511999990002', '$2b$10$mockhashgaulles', 'Gaulles', 'https://picsum.photos/seed/gaulles/150/150', true, NOW()),
  ('cosmicplayer@mock.arcade', '+5511999990003', '$2b$10$mockhashcosmic', 'CosmicPlayer', 'https://picsum.photos/seed/cosmic/150/150', true, NOW()),
  ('lunargirl@mock.arcade', '+5511999990004', '$2b$10$mockhashlunar', 'LunarGirl', 'https://picsum.photos/seed/lunargirl/150/150', true, NOW()),
  ('prosniper@mock.arcade', '+5511999990005', '$2b$10$mockhashsniper', 'ProSniper', 'https://picsum.photos/seed/prosniper/150/150', true, NOW()),
  ('shadowriser@mock.arcade', '+5511999990006', '$2b$10$mockhashshadow', 'ShadowRiser', 'https://picsum.photos/seed/shadow/150/150', true, NOW())
ON CONFLICT (username) DO NOTHING;

-- Insert mock user profiles
INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'Alanzoka', '🎮 Streamer de Minecraft e muito mais! 10M+ seguidores', true FROM users WHERE username = 'Alanzoka'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'Gaulês', '🔥 CS2 Pro Player | Twitch Partner | Ex-SK Gaming', true FROM users WHERE username = 'Gaulles'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'CosmicPlayer', '🚀 Valorant Immortal | Daily Streams', true FROM users WHERE username = 'CosmicPlayer'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'LunarGirl', '💎 League of Legends Diamond | Chill Vibes', true FROM users WHERE username = 'LunarGirl'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'ProSniper', '🎯 AWP Master | CS2 Global Elite', true FROM users WHERE username = 'ProSniper'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, display_name, bio, is_profile_complete)
SELECT id, 'Shadow Riser', '🏆 Tournament Champion | 1° Lugar', true FROM users WHERE username = 'ShadowRiser'
ON CONFLICT (user_id) DO NOTHING;

-- Insert mock posts
INSERT INTO posts (user_id, content, images, likes_count, comments_count, shares_count, is_mock, created_at)
SELECT u.id, 
  'The energy at this tournament was absolutely unreal! 🔥💪 Can''t wait for the next season. #legends',
  ARRAY['https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80', 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=600&q=80'],
  2400, 227, 45, true, NOW() - INTERVAL '2 hours'
FROM users u WHERE u.username = 'ShadowRiser'
ON CONFLICT DO NOTHING;

INSERT INTO posts (user_id, content, images, likes_count, comments_count, shares_count, is_mock, created_at)
SELECT u.id, 
  'Finally hit Global Elite after 500 hours! The grind was real 💎',
  ARRAY[]::TEXT[], 892, 64, 12, true, NOW() - INTERVAL '4 hours'
FROM users u WHERE u.username = 'Gaulles'
ON CONFLICT DO NOTHING;

INSERT INTO posts (user_id, content, images, likes_count, comments_count, shares_count, is_mock, created_at)
SELECT u.id, 
  'Minecraft build challenge hoje às 20h! Quem topa? 🏰',
  ARRAY['https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=600&q=80'],
  1567, 89, 23, true, NOW() - INTERVAL '6 hours'
FROM users u WHERE u.username = 'Alanzoka'
ON CONFLICT DO NOTHING;

-- Insert mock live streams
INSERT INTO live_streams (user_id, title, category_id, viewer_count, is_live, is_mock, started_at)
SELECT u.id, '🔥 Ranked Grind to Immortal!', c.id, 12543, true, true, NOW() - INTERVAL '1 hour'
FROM users u, game_categories c WHERE u.username = 'CosmicPlayer' AND c.slug = 'valorant'
ON CONFLICT DO NOTHING;

INSERT INTO live_streams (user_id, title, category_id, viewer_count, is_live, is_mock, started_at)
SELECT u.id, 'Diamond promos today! 💎', c.id, 8921, true, true, NOW() - INTERVAL '2 hours'
FROM users u, game_categories c WHERE u.username = 'LunarGirl' AND c.slug = 'league-of-legends'
ON CONFLICT DO NOTHING;

INSERT INTO live_streams (user_id, title, category_id, viewer_count, is_live, is_mock, started_at)
SELECT u.id, 'AWP Only Challenge 🎯', c.id, 21098, true, true, NOW() - INTERVAL '30 minutes'
FROM users u, game_categories c WHERE u.username = 'ProSniper' AND c.slug = 'cs2'
ON CONFLICT DO NOTHING;

INSERT INTO live_streams (user_id, title, category_id, viewer_count, is_live, is_mock, started_at)
SELECT u.id, 'Construindo mega castelo! 🏰', c.id, 45000, true, true, NOW() - INTERVAL '3 hours'
FROM users u, game_categories c WHERE u.username = 'Alanzoka' AND c.slug = 'minecraft'
ON CONFLICT DO NOTHING;

INSERT INTO live_streams (user_id, title, category_id, viewer_count, is_live, is_mock, started_at)
SELECT u.id, 'Treino FPL - Road to Major', c.id, 32000, true, true, NOW() - INTERVAL '1 hour'
FROM users u, game_categories c WHERE u.username = 'Gaulles' AND c.slug = 'cs2'
ON CONFLICT DO NOTHING;

-- Insert mock clips (Moments)
INSERT INTO clips (user_id, stream_id, title, video_url, thumbnail_url, duration, views_count, likes_count, game_id, is_mock, created_at)
SELECT u.id, ls.id, 'INSANE AWP 4K clutch!', 
  'https://example.com/clips/awp-clutch.mp4',
  'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80',
  30, 15420, 2341, c.id, true, NOW() - INTERVAL '1 day'
FROM users u, live_streams ls, game_categories c 
WHERE u.username = 'ProSniper' AND ls.user_id = u.id AND c.slug = 'cs2'
ON CONFLICT DO NOTHING;

INSERT INTO clips (user_id, stream_id, title, video_url, thumbnail_url, duration, views_count, likes_count, game_id, is_mock, created_at)
SELECT u.id, ls.id, 'Mega construção épica do dragão 🐉', 
  'https://example.com/clips/dragon-build.mp4',
  'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=400&q=80',
  45, 89000, 12500, c.id, true, NOW() - INTERVAL '2 days'
FROM users u, live_streams ls, game_categories c 
WHERE u.username = 'Alanzoka' AND ls.user_id = u.id AND c.slug = 'minecraft'
ON CONFLICT DO NOTHING;

INSERT INTO clips (user_id, stream_id, title, video_url, thumbnail_url, duration, views_count, likes_count, game_id, is_mock, created_at)
SELECT u.id, ls.id, 'Ace com a Jett no Ascent!', 
  'https://example.com/clips/jett-ace.mp4',
  'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&q=80',
  25, 34000, 5600, c.id, true, NOW() - INTERVAL '3 hours'
FROM users u, live_streams ls, game_categories c 
WHERE u.username = 'CosmicPlayer' AND ls.user_id = u.id AND c.slug = 'valorant'
ON CONFLICT DO NOTHING;

INSERT INTO clips (user_id, stream_id, title, video_url, thumbnail_url, duration, views_count, likes_count, game_id, is_mock, created_at)
SELECT u.id, ls.id, 'Pentakill com Yasuo na ranked!', 
  'https://example.com/clips/yasuo-penta.mp4',
  'https://images.unsplash.com/photo-1560419015-7c427e8ae5ba?w=400&q=80',
  35, 22000, 3200, c.id, true, NOW() - INTERVAL '5 hours'
FROM users u, live_streams ls, game_categories c 
WHERE u.username = 'LunarGirl' AND ls.user_id = u.id AND c.slug = 'league-of-legends'
ON CONFLICT DO NOTHING;

-- =============================================
-- INDEXES
-- =============================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_cpf ON users(cpf);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_verification_user ON verification_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_history_phone ON phone_history(phone);
CREATE INDEX IF NOT EXISTS idx_phone_history_ip ON phone_history(ip_address);
CREATE INDEX IF NOT EXISTS idx_game_categories_slug ON game_categories(slug);

-- New table indexes
CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user ON post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_saved_posts_user ON saved_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_chat_messages_stream ON chat_messages(stream_id);
CREATE INDEX IF NOT EXISTS idx_live_streams_user ON live_streams(user_id);
CREATE INDEX IF NOT EXISTS idx_live_streams_live ON live_streams(is_live);
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);
