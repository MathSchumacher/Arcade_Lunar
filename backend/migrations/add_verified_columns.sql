-- Migration: Add missing verified columns to users table
-- Run this if you get error: column 'phone_verified' does not exist

ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS facebook_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email';

-- Update existing users to have verified columns
UPDATE users SET phone_verified = FALSE WHERE phone_verified IS NULL;
UPDATE users SET email_verified = FALSE WHERE email_verified IS NULL;

-- Fix verification_codes check constraint (drop old, add new with all types)
ALTER TABLE verification_codes DROP CONSTRAINT IF EXISTS verification_codes_type_check;
ALTER TABLE verification_codes ADD CONSTRAINT verification_codes_type_check 
  CHECK (type IN ('email', 'phone', 'sms', 'whatsapp'));

-- Create password_resets table if not exists
CREATE TABLE IF NOT EXISTS password_resets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

