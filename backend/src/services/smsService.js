/**
 * SMS Service - Infobip Integration
 * Uses environment variables for API credentials
 */

const https = require('https');

// SECURITY: Use environment variables
const API_KEY = process.env.INFOBIP_API_KEY;
const BASE_URL = process.env.INFOBIP_BASE_URL || '4e6np1.api.infobip.com';
const SENDER_ID = process.env.SMS_SENDER_ID || 'ArcadeLunar';

// Validate on startup
if (!API_KEY) {
    console.warn('⚠️  WARNING: INFOBIP_API_KEY not set. SMS will fail.');
}

const sendSMS = (to, text) => {
    if (!API_KEY) {
        return Promise.reject(new Error('INFOBIP_API_KEY environment variable not set'));
    }

    // Clean phone number to E.164 format (digits only)
    const cleanPhone = to.replace(/\D/g, '');

    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            messages: [
                {
                    destinations: [{ to: cleanPhone }],
                    from: SENDER_ID,
                    text: text
                }
            ]
        });

        const options = {
            hostname: BASE_URL,
            path: '/sms/2/text/advanced',
            method: 'POST',
            headers: {
                'Authorization': `App ${API_KEY}`,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(body));
                    } catch (e) {
                        resolve(body);
                    }
                } else {
                    reject(new Error(`Infobip API Error: ${res.statusCode} ${body}`));
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.write(data);
        req.end();
    });
};

module.exports = { sendSMS };
