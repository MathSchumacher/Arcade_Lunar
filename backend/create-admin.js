/**
 * Create Admin Test Account Script
 * Run: node create-admin.js
 */
const bcrypt = require('bcrypt');
const db = require('./src/config/database');

const SALT_ROUNDS = 10;

async function createAdmin() {
  try {
    const email = 'admin@arcade.lunar';
    const password = 'lunar2026';
    const username = 'AdminLunar';
    
    // Generate real bcrypt hash
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    console.log('Generated hash:', passwordHash);
    
    // Check if user exists
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    
    if (existing.rows.length > 0) {
      // Update existing user's password
      await db.query(
        'UPDATE users SET password_hash = $1, is_verified = true, email_verified = true WHERE email = $2',
        [passwordHash, email]
      );
      console.log('✅ Admin account password updated!');
    } else {
      // Create new user
      await db.query(
        `INSERT INTO users (email, password_hash, username, avatar_url, is_verified, email_verified, created_at)
         VALUES ($1, $2, $3, $4, true, true, NOW())`,
        [email, passwordHash, username, 'https://picsum.photos/seed/admin/150/150']
      );
      console.log('✅ Admin account created!');
    }
    
    console.log('');
    console.log('Login credentials:');
    console.log('  Email: admin@arcade.lunar');
    console.log('  Password: lunar2026');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createAdmin();
