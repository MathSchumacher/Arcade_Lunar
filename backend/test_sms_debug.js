/**
 * SMS DEBUG TOOL - Infobip Testing
 * 
 * Test Infobip SMS integration independently
 * Run: node test_sms_debug.js
 */

const https = require('https');

const API_KEY = '59abc7c15b17176378209a6c39464b60-d804e2ac-e0cd-4357-8756-114c38a40841';
const BASE_URL = '4e6np1.api.infobip.com';

// Test Configuration
const TEST_PHONE = '+5551981381793'; // User's test phone number
const TEST_MESSAGE = 'DEBUG TEST: Codigo 1234 - Arcade Lunar SMS funcionando!';

console.log('='.repeat(60));
console.log('🔍 INFOBIP SMS DEBUG TEST');
console.log('='.repeat(60));
console.log(`📱 Sending to: ${TEST_PHONE}`);
console.log(`📝 Message: ${TEST_MESSAGE}`);
console.log(`🔑 API Key: ${API_KEY.substring(0, 20)}...`);
console.log(`🌐 Base URL: ${BASE_URL}`);
console.log('='.repeat(60));

function sendTestSMS(to, text) {
    const cleanPhone = to.replace(/\D/g, '');
    
    console.log(`\n📞 Cleaned phone: ${cleanPhone}`);
    
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            messages: [
                {
                    destinations: [{ to: cleanPhone }],
                    from: "ArcadeLunar",
                    text: text
                }
            ]
        });

        console.log(`\n📦 Request payload:\n${data}\n`);

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

        console.log(`\n🌐 Request options:\n`, JSON.stringify(options, null, 2));

        const req = https.request(options, (res) => {
            console.log(`\n📡 Response Status Code: ${res.statusCode}`);
            console.log(`📋 Response Headers:`, res.headers);
            
            let responseBody = '';
            
            res.on('data', (chunk) => {
                responseBody += chunk;
            });
            
            res.on('end', () => {
                console.log(`\n📥 Response Body:\n${responseBody}\n`);
                
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        const parsed = JSON.parse(responseBody);
                        console.log('✅ SUCCESS! SMS API responded positively');
                        console.log('📊 Parsed Response:', JSON.stringify(parsed, null, 2));
                        resolve(parsed);
                    } catch (e) {
                        console.log('✅ SUCCESS! (Response not JSON)');
                        resolve(responseBody);
                    }
                } else {
                    console.log('❌ ERROR! Non-success status code');
                    reject(new Error(`Infobip returned ${res.statusCode}: ${responseBody}`));
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

// Run the test
console.log('\n🚀 Starting SMS test...\n');

sendTestSMS(TEST_PHONE, TEST_MESSAGE)
    .then((result) => {
        console.log('\n' + '='.repeat(60));
        console.log('✅ TEST COMPLETED SUCCESSFULLY');
        console.log('='.repeat(60));
        console.log('📱 Check your phone for the SMS!');
        console.log('='.repeat(60));
        process.exit(0);
    })
    .catch((error) => {
        console.log('\n' + '='.repeat(60));
        console.log('❌ TEST FAILED');
        console.log('='.repeat(60));
        console.error('Error:', error.message);
        console.log('\n💡 Troubleshooting tips:');
        console.log('1. Check if phone number is in E.164 format (+5511999999999)');
        console.log('2. Verify API Key is correct');
        console.log('3. Check Infobip account balance');
        console.log('4. Ensure BASE_URL is correct');
        console.log('5. Check if "ArcadeLunar" sender is registered');
        console.log('='.repeat(60));
        process.exit(1);
    });
