/**
 * Email Service - Gmail SMTP + Infobip Support
 * Uses Gmail SMTP for development, can switch to Infobip for production
 * 
 * Gmail SMTP Config (via .env):
 *   SMTP_HOST=smtp.gmail.com
 *   SMTP_PORT=587
 *   SMTP_USER=matheusmschumacher@gmail.com
 *   SMTP_PASS=gjgdqsuvnanprrxh
 *   EMAIL_FROM=matheusmschumacher@gmail.com
 *   EMAIL_FROM_NAME=Arcade Lunar
 */

const nodemailer = require('nodemailer');

// SMTP Configuration from environment variables
const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '587');
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const FROM_EMAIL = process.env.EMAIL_FROM || SMTP_USER || 'noreply@arcadelunar.com';
const FROM_NAME = process.env.EMAIL_FROM_NAME || 'Arcade Lunar';

// Create reusable transporter
let transporter = null;

if (SMTP_USER && SMTP_PASS) {
    transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port: SMTP_PORT,
        secure: SMTP_PORT === 465, // true for 465, false for 587
        auth: {
            user: SMTP_USER,
            pass: SMTP_PASS,
        },
    });
    console.log('✅ Email service configured with Gmail SMTP');
} else {
    console.warn('⚠️  WARNING: SMTP credentials not set. Emails will be logged to console only.');
}

/**
 * Generate HTML email template
 */
const getEmailTemplate = (title, message, code) => {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; background: #0D0D0F; color: #fff; padding: 20px; margin: 0; }
            .container { max-width: 500px; margin: 0 auto; background: linear-gradient(135deg, #1A0A2E, #0D0D0F); padding: 30px; border-radius: 16px; border: 1px solid #8B5CF6; }
            .logo { text-align: center; font-size: 28px; font-weight: bold; background: linear-gradient(90deg, #8B5CF6, #EC4899); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
            .code { font-size: 36px; font-weight: bold; text-align: center; letter-spacing: 8px; color: #8B5CF6; margin: 30px 0; padding: 20px; background: rgba(139, 92, 246, 0.1); border-radius: 12px; }
            .footer { text-align: center; color: #888; font-size: 12px; margin-top: 30px; }
            p { color: #ccc; line-height: 1.6; }
            h2 { text-align: center; color: #fff; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">ARCADE LUNAR</div>
            <h2>${title}</h2>
            <p>${message}</p>
            <div class="code">${code}</div>
            <p>Este código expira em 10 minutos.</p>
            <p>Se você não solicitou isso, ignore este email.</p>
            <div class="footer">
                © 2026 Arcade Lunar. Todos os direitos reservados.
            </div>
        </div>
    </body>
    </html>
    `;
};

/**
 * Send a verification email
 * @param {string} to - Recipient email address
 * @param {string} code - Verification code
 * @returns {Promise<object>} - Send result
 */
const sendVerificationEmail = async (to, code) => {
    const subject = 'Arcade Lunar - Código de Verificação';
    const title = 'Verifique sua Conta';
    const message = 'Use o código abaixo para completar seu cadastro:';
    const text = `Seu código de verificação Arcade Lunar é: ${code}. Este código expira em 10 minutos.`;
    const html = getEmailTemplate(title, message, code);

    return sendEmail(to, subject, text, html);
};

/**
 * Send a password reset email
 * @param {string} to - Recipient email address
 * @param {string} code - Reset code
 * @returns {Promise<object>} - Send result
 */
const sendPasswordResetEmail = async (to, code) => {
    const subject = 'Arcade Lunar - Recuperação de Senha';
    const title = 'Recupere sua Senha';
    const message = 'Use o código abaixo para redefinir sua senha:';
    const text = `Seu código de recuperação de senha Arcade Lunar é: ${code}. Este código expira em 10 minutos.`;
    const html = getEmailTemplate(title, message, code);

    return sendEmail(to, subject, text, html);
};

/**
 * Send an email
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} text - Plain text content
 * @param {string} html - HTML content
 * @returns {Promise<object>}
 */
const sendEmail = async (to, subject, text, html) => {
    if (!transporter) {
        // Log to console in development when no SMTP configured
        console.log('📧 [DEV MODE] Email would be sent:');
        console.log(`   To: ${to}`);
        console.log(`   Subject: ${subject}`);
        console.log(`   Text: ${text}`);
        return { messageId: 'dev-mode-no-smtp', success: true };
    }

    try {
        const info = await transporter.sendMail({
            from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
            to: to,
            subject: subject,
            text: text,
            html: html,
        });

        console.log(`📧 Email sent successfully to ${to}: ${info.messageId}`);
        return { messageId: info.messageId, success: true };
    } catch (error) {
        console.error(`📧 Email send failed to ${to}:`, error.message);
        throw error;
    }
};

module.exports = { 
    sendVerificationEmail, 
    sendPasswordResetEmail,
    sendEmail 
};
