/**
 * Redis Configuration
 * Connection to Redis for caching, sessions, and pub/sub
 */

const Redis = require('ioredis');

// Redis configuration
const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT) || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  lazyConnect: true,
};

// Create Redis client
const redis = new Redis(redisConfig);

// Connection events
redis.on('connect', () => {
  console.log('🔴 Redis connected successfully');
});

redis.on('error', (err) => {
  console.error('❌ Redis connection error:', err.message);
});

redis.on('close', () => {
  console.log('🔴 Redis connection closed');
});

/**
 * Cache helper functions
 */

// Default TTL: 5 minutes
const DEFAULT_TTL = 300;

/**
 * Get cached data or fetch from source
 * @param {string} key - Cache key
 * @param {Function} fetchFn - Function to fetch data if cache miss
 * @param {number} ttl - Time to live in seconds
 */
const getOrSet = async (key, fetchFn, ttl = DEFAULT_TTL) => {
  try {
    // Try to get from cache
    const cached = await redis.get(key);
    if (cached) {
      console.log(`📦 Cache HIT: ${key}`);
      return JSON.parse(cached);
    }

    // Cache miss - fetch data
    console.log(`📦 Cache MISS: ${key}`);
    const data = await fetchFn();
    
    // Store in cache
    if (data) {
      await redis.setex(key, ttl, JSON.stringify(data));
    }
    
    return data;
  } catch (error) {
    console.error('Redis getOrSet error:', error);
    // Fallback to direct fetch if Redis fails
    return await fetchFn();
  }
};

/**
 * Set cache value
 */
const set = async (key, value, ttl = DEFAULT_TTL) => {
  try {
    await redis.setex(key, ttl, JSON.stringify(value));
    return true;
  } catch (error) {
    console.error('Redis set error:', error);
    return false;
  }
};

/**
 * Get cache value
 */
const get = async (key) => {
  try {
    const value = await redis.get(key);
    return value ? JSON.parse(value) : null;
  } catch (error) {
    console.error('Redis get error:', error);
    return null;
  }
};

/**
 * Delete cache key(s)
 */
const del = async (...keys) => {
  try {
    await redis.del(...keys);
    return true;
  } catch (error) {
    console.error('Redis del error:', error);
    return false;
  }
};

/**
 * Delete all keys matching pattern
 */
const delPattern = async (pattern) => {
  try {
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
    return true;
  } catch (error) {
    console.error('Redis delPattern error:', error);
    return false;
  }
};

/**
 * Check if Redis is connected
 */
const isConnected = () => {
  return redis.status === 'ready';
};

/**
 * Connect to Redis (call on app startup)
 */
const connect = async () => {
  try {
    await redis.connect();
    return true;
  } catch (error) {
    console.error('Failed to connect to Redis:', error.message);
    return false;
  }
};

module.exports = {
  redis,
  getOrSet,
  set,
  get,
  del,
  delPattern,
  isConnected,
  connect,
  DEFAULT_TTL,
};
