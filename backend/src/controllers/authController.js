/**
 * Auth Controller
 * Handles user authentication: register, login, verify
 */

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { sendSMS } = require('../services/smsService');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../services/emailService');

const JWT_SECRET = process.env.JWT_SECRET;
const SALT_ROUNDS = 10;

/**
 * Validate email format
 */
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate phone format (international format)
 */
const isValidPhone = (phone) => {
  // Must start with + and have 10-15 digits
  const phoneRegex = /^\+[1-9]\d{9,14}$/;
  return phoneRegex.test(phone.replace(/\s/g, ''));
};

/**
 * Generate random verification code
 */
const generateVerificationCode = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

/**
 * Generate JWT token
 */
const generateToken = (userId) => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
};

/**
 * Register new user
 * POST /api/auth/register
 */
const register = async (req, res) => {
  try {
    const { email, phone, password, username } = req.body;

    // Validate input
    if (!password || password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'Password must be at least 6 characters'
      });
    }

    if (!email && !phone) {
      return res.status(400).json({
        success: false,
        error: 'Email or phone is required'
      });
    }

    if (email && !isValidEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }

    if (phone && !isValidPhone(phone)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid phone format. Use international format: +5511999999999'
      });
    }

    // Check if user exists
    const existingUser = await db.query(
      'SELECT id, is_verified, phone_verified, email_verified FROM users WHERE email = $1 OR phone = $2',
      [email || null, phone || null]
    );

    if (existingUser.rows.length > 0) {
      const existing = existingUser.rows[0];
      
      // If account exists but is NOT verified, delete it and allow re-registration
      // This handles cases where user abandoned registration before verification
      if (!existing.is_verified && !existing.phone_verified && !existing.email_verified) {
        console.log(`[REGISTER] Deleting unverified account ${existing.id} for re-registration`);
        
        // Delete old verification codes
        await db.query('DELETE FROM verification_codes WHERE user_id = $1', [existing.id]);
        // Delete old sessions
        await db.query('DELETE FROM sessions WHERE user_id = $1', [existing.id]);
        // Delete the user
        await db.query('DELETE FROM users WHERE id = $1', [existing.id]);
        
        console.log(`[REGISTER] Unverified account ${existing.id} deleted successfully`);
      } else {
        // Account is verified, cannot re-register
        return res.status(409).json({
          success: false,
          error: 'User already exists with this email or phone'
        });
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    // Create user (removed full_name)
    const result = await db.query(
      `INSERT INTO users (email, phone, password_hash, username, is_verified)
       VALUES ($1, $2, $3, $4, FALSE)
       RETURNING id, email, phone, username, is_verified, created_at`,
      [email || null, phone || null, passwordHash, username || null]
    );

    const user = result.rows[0];

    // Generate verification code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    // For registration: SMS for phone, email for email-only accounts
    const verificationType = phone ? 'sms' : 'email';

    await db.query(
      `INSERT INTO verification_codes (user_id, code, type, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [user.id, code, verificationType, expiresAt]
    );

    // Send code via SMS if phone is available and type is sms
    if (phone && verificationType === 'sms') {
        try {
            await sendSMS(phone, `Seu codigo de verificacao Arcade Lunar: ${code}`);
            console.log(`📨 SMS sent to ${phone}`);
        } catch (smsError) {
            console.error('Failed to send SMS:', smsError);
            // Don't fail the request, just log error. User might need to resend.
        }
    }

    // Send code via Email if email is available and type is email
    if (email && verificationType === 'email') {
        try {
            await sendVerificationEmail(email, code);
            console.log(`📧 Email sent to ${email}`);
        } catch (emailError) {
            console.error('Failed to send email:', emailError);
            // Don't fail the request, just log error. User might need to resend.
        }
    }

    // In production, send code via email/SMS
    console.log(`🔐 Verification code for ${email || phone}: ${code}`);

    res.status(201).json({
      success: true,
      message: 'User registered. Please verify your account.',
      data: {
        userId: user.id,
        verificationType,
        // Only include code in development
        verificationCode: process.env.NODE_ENV !== 'production' ? code : undefined
      }
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to register user'
    });
  }
};

/**
 * Verify user account
 * POST /api/auth/verify
 */
const verify = async (req, res) => {
  try {
    const { userId, code } = req.body;

    if (!userId || !code) {
      return res.status(400).json({
        success: false,
        error: 'User ID and verification code are required'
      });
    }

    // Find valid verification code
    const verificationResult = await db.query(
      `SELECT id, type FROM verification_codes 
       WHERE user_id = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()`,
      [userId, code]
    );

    // Dev mode: accept code "1234" as fallback when SMS service isn't available
    let isDevCode = false;
    if (verificationResult.rows.length === 0 && code === '1234' && process.env.NODE_ENV !== 'production') {
      console.log(`[DEV] Accepting dev code 1234 for user ${userId}`);
      isDevCode = true;
    } else if (verificationResult.rows.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid or expired verification code'
      });
    }
    
    // Mark real code as used (skip if using dev code)
    if (!isDevCode && verificationResult.rows.length > 0) {
      await db.query(
        'UPDATE verification_codes SET used = TRUE WHERE id = $1',
        [verificationResult.rows[0].id]
      );
    }

    // Mark user and specific verification type as verified
    const verificationType = isDevCode ? 'sms' : verificationResult.rows[0].type;
    const updateField = verificationType === 'sms' ? 'phone_verified' : 'email_verified';
    
    const userResult = await db.query(
      `UPDATE users SET is_verified = TRUE, ${updateField} = TRUE, updated_at = NOW()
       WHERE id = $1
       RETURNING id, email, phone, username, avatar_url, is_verified, email_verified, phone_verified`,
      [userId]
    );

    const user = userResult.rows[0];

    // Generate session token
    const token = generateToken(user.id);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await db.query(
      `INSERT INTO sessions (user_id, token, expires_at)
       VALUES ($1, $2, $3)`,
      [user.id, token, expiresAt]
    );

    res.json({
      success: true,
      message: 'Account verified successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          phone: user.phone,
          username: user.username,
          avatarUrl: user.avatar_url,
          isVerified: user.is_verified,
          emailVerified: user.email_verified,
          phoneVerified: user.phone_verified
        },
        token
      }
    });

  } catch (error) {
    console.error('Verify error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify account'
    });
  }
};

/**
 * Login user
 * POST /api/auth/login
 */
const login = async (req, res) => {
  try {
    const { emailOrPhone, password } = req.body;

    if (!emailOrPhone || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email/phone and password are required'
      });
    }

    // Find user by email or phone
    const isEmail = emailOrPhone.includes('@');
    const userResult = await db.query(
      `SELECT id, email, phone, password_hash, username, avatar_url, is_verified, email_verified, phone_verified
       FROM users WHERE ${isEmail ? 'email' : 'phone'} = $1`,
      [emailOrPhone]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const user = userResult.rows[0];

    // Verify password
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Check verification status
    // Phone users: must be verified (we send SMS on register)
    // Email users: can login without email verification (can verify later in settings)
    const requiresPhoneVerification = user.phone && !user.phone_verified;
    
    if (requiresPhoneVerification) {
      // Generate new verification code for phone
      const code = generateVerificationCode();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

      await db.query(
        `INSERT INTO verification_codes (user_id, code, type, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [user.id, code, 'sms', expiresAt]
      );

      // Send SMS
      if (user.phone) {
        try {
          await sendSMS(user.phone, `Seu codigo de verificacao Arcade Lunar: ${code}`);
        } catch(e) { console.error('SMS Error login:', e); }
      }

      console.log(`🔐 Verification code for ${user.phone}: ${code}`);

      return res.json({
        success: true,
        requiresVerification: true,
        data: {
          userId: user.id,
          verificationType: 'sms',
          verificationCode: process.env.NODE_ENV !== 'production' ? code : undefined
        }
      });
    }

    // Generate session token
    const token = generateToken(user.id);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await db.query(
      `INSERT INTO sessions (user_id, token, expires_at)
       VALUES ($1, $2, $3)`,
      [user.id, token, expiresAt]
    );

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          phone: user.phone,
          username: user.username,
          avatarUrl: user.avatar_url,
          isVerified: user.is_verified,
          emailVerified: user.email_verified,
          phoneVerified: user.phone_verified,
          pendingEmailVerification: user.email && !user.email_verified
        },
        token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to login'
    });
  }
};

/**
 * Resend verification code
 * POST /api/auth/resend-code
 */
const resendCode = async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required'
      });
    }

    // Get user
    const userResult = await db.query(
      'SELECT id, email, phone, is_verified FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = userResult.rows[0];

    if (user.is_verified) {
      return res.status(400).json({
        success: false,
        error: 'User is already verified'
      });
    }

    // Invalidate previous codes
    await db.query(
      'UPDATE verification_codes SET used = TRUE WHERE user_id = $1 AND used = FALSE',
      [userId]
    );

    // Generate new code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    const verificationType = user.email ? 'email' : 'sms';

    await db.query(
      `INSERT INTO verification_codes (user_id, code, type, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [userId, code, verificationType, expiresAt]
    );

    // Send SMS
    if (user.phone && verificationType === 'sms') {
        try {
            await sendSMS(user.phone, `Seu codigo de verificacao Arcade Lunar: ${code}`);
        } catch(e) { console.error('SMS Error resend:', e); }
    }

    // Send Email
    if (user.email && verificationType === 'email') {
        try {
            await sendVerificationEmail(user.email, code);
        } catch(e) { console.error('Email Error resend:', e); }
    }

    console.log(`🔐 New verification code for ${user.email || user.phone}: ${code}`);

    res.json({
      success: true,
      message: 'Verification code sent',
      data: {
        verificationType,
        verificationCode: process.env.NODE_ENV !== 'production' ? code : undefined
      }
    });

  } catch (error) {
    console.error('Resend code error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to resend verification code'
    });
  }
};

/**
 * Get current user (requires auth)
 * GET /api/auth/me
 */
const getMe = async (req, res) => {
  try {
    // User is attached by auth middleware
    res.json({
      success: true,
      data: req.user
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user'
    });
  }
};

/**
 * Logout user
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (token) {
      await db.query('DELETE FROM sessions WHERE token = $1', [token]);
    }

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to logout'
    });
  }
};

/**
 * Request email verification (for deferred verification from settings)
 * POST /api/auth/request-email-verification
 */
const requestEmailVerification = async (req, res) => {
  try {
    const userId = req.user?.id;
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    // Get user
    const userResult = await db.query(
      'SELECT id, email, email_verified FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const user = userResult.rows[0];

    if (!user.email) {
      return res.status(400).json({ success: false, error: 'No email associated with this account' });
    }

    if (user.email_verified) {
      return res.status(400).json({ success: false, error: 'Email is already verified' });
    }

    // Invalidate previous email codes
    await db.query(
      `UPDATE verification_codes SET used = TRUE WHERE user_id = $1 AND type = 'email' AND used = FALSE`,
      [userId]
    );

    // Generate new code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await db.query(
      `INSERT INTO verification_codes (user_id, code, type, expires_at)
       VALUES ($1, $2, 'email', $3)`,
      [userId, code, expiresAt]
    );

    // Send email
    try {
      await sendVerificationEmail(user.email, code);
      console.log(`📧 Verification email sent to ${user.email}`);
    } catch (emailError) {
      console.error('Email send error:', emailError);
      return res.status(500).json({ success: false, error: 'Failed to send verification email' });
    }

    res.json({
      success: true,
      message: 'Verification email sent',
      data: {
        email: user.email,
        verificationCode: process.env.NODE_ENV !== 'production' ? code : undefined
      }
    });

  } catch (error) {
    console.error('Request email verification error:', error);
    res.status(500).json({ success: false, error: 'Failed to request email verification' });
  }
};

/**
 * Forgot Password - Send reset code via email or SMS
 * POST /api/auth/forgot-password
 */
const forgotPassword = async (req, res) => {
  try {
    const { emailOrPhone } = req.body;

    if (!emailOrPhone) {
      return res.status(400).json({ success: false, error: 'Email or phone is required' });
    }

    // Find user by email or phone
    const userResult = await db.query(
      'SELECT id, email, phone FROM users WHERE email = $1 OR phone = $1',
      [emailOrPhone]
    );

    if (userResult.rows.length === 0) {
      // Don't reveal if user exists - return success anyway for security
      return res.json({
        success: true,
        message: 'If an account exists, a reset code has been sent'
      });
    }

    const user = userResult.rows[0];

    // Determine send method: SMS if phone was used, email otherwise
    const isPhoneLogin = emailOrPhone === user.phone;
    const sendMethod = isPhoneLogin ? 'sms' : 'email';

    // Invalidate previous reset codes
    await db.query(
      `UPDATE password_resets SET used = TRUE WHERE user_id = $1 AND used = FALSE`,
      [user.id]
    );

    // Generate 4-digit code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Save to password_resets table
    await db.query(
      `INSERT INTO password_resets (user_id, code, expires_at)
       VALUES ($1, $2, $3)`,
      [user.id, code, expiresAt]
    );

    // Send code via appropriate method
    if (sendMethod === 'sms' && user.phone) {
      try {
        await sendSMS(user.phone, `Seu código de reset de senha Arcade Lunar: ${code}`);
        console.log(`📱 Reset code sent via SMS to ${user.phone}`);
      } catch (e) {
        console.error('SMS send error:', e);
      }
    } else if (user.email) {
      try {
        await sendPasswordResetEmail(user.email, code);
        console.log(`📧 Reset code sent via email to ${user.email}`);
      } catch (e) {
        console.error('Email send error:', e);
      }
    }

    res.json({
      success: true,
      message: 'Reset code sent',
      data: {
        userId: user.id,
        method: sendMethod,
        destination: sendMethod === 'sms' 
          ? user.phone?.replace(/(\+\d{2})\d{6}(\d{4})/, '$1******$2')
          : user.email?.replace(/(.{2}).*(@.*)/, '$1***$2'),
        resetCode: process.env.NODE_ENV !== 'production' ? code : undefined
      }
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ success: false, error: 'Failed to process password reset' });
  }
};

/**
 * Reset Password - Verify code and set new password
 * POST /api/auth/reset-password
 */
const resetPassword = async (req, res) => {
  try {
    const { userId, code, newPassword } = req.body;

    if (!userId || !code || !newPassword) {
      return res.status(400).json({ success: false, error: 'User ID, code, and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, error: 'Password must be at least 6 characters' });
    }

    // Find valid reset code
    const resetResult = await db.query(
      `SELECT id, user_id FROM password_resets 
       WHERE user_id = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [userId, code]
    );

    if (resetResult.rows.length === 0) {
      return res.status(400).json({ success: false, error: 'Invalid or expired code' });
    }

    const resetRecord = resetResult.rows[0];

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);

    // Update user's password
    await db.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [passwordHash, userId]
    );

    // Mark reset code as used
    await db.query(
      'UPDATE password_resets SET used = TRUE WHERE id = $1',
      [resetRecord.id]
    );

    // Invalidate all sessions (force re-login)
    await db.query('DELETE FROM sessions WHERE user_id = $1', [userId]);

    console.log(`🔐 Password reset successful for user ${userId}`);

    res.json({
      success: true,
      message: 'Password reset successful. Please login with your new password.'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, error: 'Failed to reset password' });
  }
};

/**
 * Social Login (Google/Facebook)
 * POST /api/auth/social-login
 */
const socialLogin = async (req, res) => {
  try {
    const { provider, accessToken, profile } = req.body;

    if (!provider || !profile) {
      return res.status(400).json({ success: false, error: 'Provider and profile are required' });
    }

    if (!['google', 'facebook'].includes(provider)) {
      return res.status(400).json({ success: false, error: 'Invalid provider' });
    }

    const { id: providerId, email, name, picture } = profile;

    if (!providerId) {
      return res.status(400).json({ success: false, error: 'Provider ID is required' });
    }

    // Check if user exists by provider ID
    const providerField = `${provider}_id`;
    let userResult = await db.query(
      `SELECT * FROM users WHERE ${providerField} = $1`,
      [providerId]
    );

    let user;
    let isNewUser = false;

    if (userResult.rows.length === 0) {
      // Check if email already exists
      if (email) {
        userResult = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        
        if (userResult.rows.length > 0) {
          // Link social account to existing user
          user = userResult.rows[0];
          await db.query(
            `UPDATE users SET ${providerField} = $1, auth_provider = $2, updated_at = NOW() WHERE id = $3`,
            [providerId, provider, user.id]
          );
        }
      }

      if (!user) {
        // Create new user
        const username = name?.replace(/\s+/g, '').toLowerCase().slice(0, 20) || `user_${Date.now()}`;
        const placeholderPassword = await bcrypt.hash(Math.random().toString(36), SALT_ROUNDS);

        const newUserResult = await db.query(
          `INSERT INTO users (email, password_hash, username, avatar_url, is_verified, email_verified, ${providerField}, auth_provider)
           VALUES ($1, $2, $3, $4, TRUE, $5, $6, $7)
           RETURNING *`,
          [email || null, placeholderPassword, username, picture || null, !!email, providerId, provider]
        );

        user = newUserResult.rows[0];
        isNewUser = true;

        // Create user profile
        await db.query(
          `INSERT INTO user_profiles (user_id, display_name, is_profile_complete)
           VALUES ($1, $2, FALSE)
           ON CONFLICT (user_id) DO NOTHING`,
          [user.id, name || username]
        );

        console.log(`🆕 New ${provider} user created: ${user.id}`);
      }
    } else {
      user = userResult.rows[0];
    }

    // Generate token
    const token = generateToken(user.id);

    // Save session
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    await db.query(
      `INSERT INTO sessions (user_id, token, expires_at) VALUES ($1, $2, $3)`,
      [user.id, token, expiresAt]
    );

    res.json({
      success: true,
      message: isNewUser ? 'Account created successfully' : 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          avatarUrl: user.avatar_url,
          isVerified: user.is_verified,
          emailVerified: user.email_verified,
          authProvider: user.auth_provider,
          isNewUser
        },
        token
      }
    });

  } catch (error) {
    console.error('Social login error:', error);
    res.status(500).json({ success: false, error: 'Social login failed' });
  }
};

module.exports = {
  register,
  verify,
  login,
  resendCode,
  getMe,
  logout,
  requestEmailVerification,
  forgotPassword,
  resetPassword,
  socialLogin
};
