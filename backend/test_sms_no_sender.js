/**
 * SMS DEBUG TOOL v2 - Without Custom Sender ID
 * 
 * Testing without "ArcadeLunar" sender to see if that's the issue
 * Run: node test_sms_no_sender.js
 */

const https = require('https');

const API_KEY = '59abc7c15b17176378209a6c39464b60-d804e2ac-e0cd-4357-8756-114c38a40841';
const BASE_URL = '4e6np1.api.infobip.com';

// Test Configuration
const TEST_PHONE = '+5551981381793';
const TEST_MESSAGE = 'Codigo: 1234 - Teste Arcade Lunar';

console.log('='.repeat(60));
console.log('🔍 INFOBIP SMS TEST (NO CUSTOM SENDER)');
console.log('='.repeat(60));
console.log(`📱 Phone: ${TEST_PHONE}`);
console.log(`📝 Message: ${TEST_MESSAGE}`);
console.log('='.repeat(60));

function sendTestSMS(to, text) {
    const cleanPhone = to.replace(/\D/g, '');
    
    return new Promise((resolve, reject) => {
        // Try WITHOUT custom sender ID (let Infobip use default)
        const data = JSON.stringify({
            messages: [
                {
                    destinations: [{ to: cleanPhone }],
                    // NO "from" field - let Infobip use default
                    text: text
                }
            ]
        });

        console.log(`\n📦 Payload (no sender):\n${data}\n`);

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
            console.log(`\n📡 Status: ${res.statusCode}`);
            
            let responseBody = '';
            res.on('data', (chunk) => responseBody += chunk);
            res.on('end', () => {
                console.log(`\n📥 Response:\n${responseBody}\n`);
                
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    console.log('✅ SUCCESS!');
                    resolve(JSON.parse(responseBody));
                } else {
                    console.log(`❌ FAILED with ${res.statusCode}`);
                    reject(new Error(`Status ${res.statusCode}: ${responseBody}`));
                }
            });
        });

        req.on('error', (error) => {
            console.log('\n❌ REQUEST ERROR!');
            console.error(error);
            reject(error);
        });

        req.write(data);
        req.end();
    });
}

sendTestSMS(TEST_PHONE, TEST_MESSAGE)
    .then(() => {
        console.log('='.repeat(60));
        console.log('✅ SMS SENT - Check your phone!');
        console.log('='.repeat(60));
        process.exit(0);
    })
    .catch((error) => {
        console.log('='.repeat(60));
        console.log('❌ STILL FAILING');
        console.log('='.repeat(60));
        console.log('\n💡 Next steps:');
        console.log('1. Check account balance in Infobip portal');
        console.log('2. Verify if trial account has phone number whitelisted');
        console.log('3. Check if account status is "Active" not "Trial"');
        console.log('='.repeat(60));
        process.exit(1);
    });
