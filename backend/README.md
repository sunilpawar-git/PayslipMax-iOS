# Firebase Backend for PayslipMax

This directory contains Firebase Cloud Functions for the PayslipMax LLM proxy.

## Features

- **Google Authentication**: Users must sign in with Google
- **Rate Limiting**:
  - Production: 5 calls/hour, 50 calls/year
  - Development: Unlimited (emulator mode)
- **Usage Tracking**: Firestore tracks all LLM usage
- **Secure API Key**: Gemini API key stored in Firebase config, never in app

## Local Development

### Prerequisites

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Setup

```bash
# Install dependencies
cd functions
npm install

# Set environment variable for local testing
export GEMINI_API_KEY="your-gemini-api-key-here"
```

### Run Emulators

```bash
# Start all emulators (from backend directory)
npm run serve

# Emulator UI will be available at:
# http://localhost:4000
```

### Test Functions Locally

```bash
# In another terminal, test the function
curl -X POST http://localhost:5001/payslipmax-ios/us-central1/parseLLM \
  -H "Content-Type: application/json" \
  -d '{"data": {"prompt": "Test prompt"}}'
```

## Deployment

### Set Production API Key

```bash
# Set Gemini API key (one-time setup)
firebase functions:config:set gemini.key="YOUR_PRODUCTION_GEMINI_API_KEY"

# Verify it's set
firebase functions:config:get
```

### Deploy Functions

```bash
# Deploy all functions
npm run deploy

# Or deploy specific function
firebase deploy --only functions:parseLLM
```

### Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

## Monitoring

### View Logs

```bash
# Real-time logs
npm run logs

# Or in Firebase Console:
# Functions > Logs
```

### Check Usage

```bash
# Firebase Console > Firestore Database > llm_usage collection
```

## Security

- ✅ API key stored in Firebase config (not in code)
- ✅ Google Authentication required
- ✅ Rate limiting enforced
- ✅ Firestore security rules protect user data
- ✅ Input validation on all requests

## Cost Estimation

### Firebase Costs (Blaze Plan)
- **Cloud Functions**: ~$0.40 per 1M invocations
- **Firestore**: ~$0.18 per 100K reads/writes
- **Authentication**: Free

### Gemini API Costs
- **gemini-2.0-flash-exp**: Free (experimental)
- **gemini-2.5-flash-lite**: ~$0.075 per 1M input tokens

### Monthly Estimate (100 active users, 50 calls/year each)
- Total calls: 5,000/year = ~417/month
- Firebase: ~$0.02/month
- Gemini: ~$0.05/month
- **Total: ~$0.07/month** (negligible)

## Troubleshooting

### "Unauthenticated" Error
- Ensure user is signed in with Google
- Check Firebase Authentication is enabled

### "Resource Exhausted" Error
- User has hit rate limit
- Check Firestore `llm_usage` collection for user's usage

### Function Not Found
- Ensure function is deployed: `firebase deploy --only functions`
- Check function name matches in iOS app

### Emulator Not Starting
- Check ports are not in use (4000, 5001, 8080, 9099)
- Run `firebase emulators:start --only functions` to test individually
