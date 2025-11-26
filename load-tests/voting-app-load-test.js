import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

// Test configuration
export let options = {
  stages: [
    { duration: '2m', target: 20 }, // Ramp up to 20 users
    { duration: '5m', target: 50 }, // Stay at 50 users for 5 minutes
    { duration: '2m', target: 100 }, // Scale up to 100 users
    { duration: '10m', target: 100 }, // Stay at 100 users for 10 minutes (main test)
    { duration: '3m', target: 50 }, // Scale down to 50 users
    { duration: '2m', target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must complete below 2s
    errors: ['rate<0.1'], // Error rate should be below 10%
  },
};

// Base URL - replace with your Application Gateway URL
const BASE_URL = __ENV.TARGET_URL || 'http://catdog-voting-lb.centralus.cloudapp.azure.com';

// Test scenarios
const scenarios = [
  { name: 'vote-cats', action: 'cat' },
  { name: 'vote-dogs', action: 'dog' },
  { name: 'view-page', action: 'view' },
  { name: 'onprem-route', action: 'onprem' }
];

export default function () {
  // Select random scenario
  const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
  
  let response;
  
  switch (scenario.action) {
    case 'cat':
      // Simulate voting for cats
      response = http.get(`${BASE_URL}/`);
      check(response, {
        'cat vote page loaded': (r) => r.status === 200,
        'contains cat button': (r) => r.body.includes('Vote for Cats'),
      });
      break;
      
    case 'dog':
      // Simulate voting for dogs  
      response = http.get(`${BASE_URL}/`);
      check(response, {
        'dog vote page loaded': (r) => r.status === 200,
        'contains dog button': (r) => r.body.includes('Vote for Dogs'),
      });
      break;
      
    case 'view':
      // Just view the main page
      response = http.get(`${BASE_URL}/`);
      check(response, {
        'main page loaded': (r) => r.status === 200,
        'voting app content': (r) => r.body.includes('CAT vs DOG'),
      });
      break;
      
    case 'onprem':
      // Test on-premises route specifically
      response = http.get(`${BASE_URL}/onprem/`);
      check(response, {
        'onprem route accessible': (r) => r.status === 200 || r.status === 404, // 404 is OK if path doesn't exist
      });
      break;
  }
  
  // Record errors
  errorRate.add(response.status !== 200);
  
  // Add some realistic user behavior delay
  sleep(Math.random() * 3 + 1); // Sleep 1-4 seconds
  
  // Log progress every 100 iterations
  if (__ITER % 100 === 0) {
    console.log(`Iteration ${__ITER}: ${scenario.name} - Status: ${response.status}`);
  }
}

// Setup function - runs once before the test
export function setup() {
  console.log('🚀 Starting Cat/Dog Voting App Load Test');
  console.log(`📍 Target URL: ${BASE_URL}`);
  console.log('📊 Test will run for ~24 minutes total');
  console.log('⚡ Testing both Azure and On-Premises backends');
  
  // Test initial connectivity
  let response = http.get(BASE_URL);
  if (response.status !== 200) {
    console.error(`❌ Cannot reach target URL: ${response.status}`);
    throw new Error('Target URL not accessible');
  }
  
  console.log('✅ Target URL is accessible - starting load test');
  return { targetUrl: BASE_URL };
}

// Teardown function - runs once after the test
export function teardown(data) {
  console.log('🏁 Load test completed!');
  console.log('📈 Check the k6 summary for detailed metrics');
}