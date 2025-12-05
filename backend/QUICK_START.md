# Quick Start Guide - Using Existing Firebase Project

You already have a Firebase project set up! Here's what you need to do:

## Step 1: Verify Firebase CLI Installation

```bash
# Check if Firebase CLI is installed
firebase --version

# If not installed, install it
npm install -g firebase-tools

# Login to Firebase (if not already logged in)
firebase login
```

## Step 2: Navigate to Backend Directory

```bash
cd /Users/sunil/Downloads/PayslipMax/backend
```

## Step 3: Install Dependencies

```bash
cd functions
npm install
cd ..
```

## Step 4: Enable Required Services in Firebase Console

### 4.1 Enable Google Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **PayslipApp** (`payslip-app-47be1`)
3. Click **Authentication** in left sidebar
4. If not already set up, click **Get started**
5. Click **Google** sign-in method
6. Toggle **Enable**
7. Enter **Project support email**: [your email]
8. Click **Save**

### 4.2 Enable Firestore Database

1. Click **Firestore Database** in left sidebar
2. If not already created, click **Create database**
3. Select **Start in production mode**
4. Choose location: **us-central** (or closest to your users)
5. Click **Enable**

### 4.3 Verify Blaze Plan

✅ You're already on the Blaze plan (as shown in screenshot)

## Step 5: Set Gemini API Key

```bash
# Set the Gemini API key as a Firebase environment variable
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY_HERE"

# Verify it's set
firebase functions:config:get
```

## Step 6: Test Locally with Emulators

```bash
# Set environment variable for local testing
export GEMINI_API_KEY="your-gemini-api-key-here"

# Start Firebase emulators
npm run serve

# This will start:
# - Functions Emulator: http://localhost:5001
# - Firestore Emulator: http://localhost:8080
# - Auth Emulator: http://localhost:9099
# - Emulator UI: http://localhost:4000
```

## Step 7: Deploy to Firebase (After Testing)

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Or deploy everything
firebase deploy
```

## Step 8: Get iOS Configuration

1. In Firebase Console, click **Project Settings** (gear icon)
2. Scroll down to **Your apps**
3. If you don't see an iOS app, click **iOS** icon to add one
4. Enter iOS bundle ID: `com.payslipmax.app` (check your Xcode project for exact bundle ID)
5. Click **Register app**
6. Download **GoogleService-Info.plist**
7. **Save this file** - we'll add it to the iOS project in Phase 3.2

## Verification Checklist

Before proceeding to Phase 3.2:

- [ ] Firebase CLI installed and logged in
- [ ] Dependencies installed (`npm install` in functions/)
- [ ] Google Authentication enabled
- [ ] Firestore database created
- [ ] Gemini API key set in Firebase config
- [ ] Local emulators tested successfully
- [ ] Functions deployed to Firebase
- [ ] GoogleService-Info.plist downloaded

## Next Steps

Once you've completed these steps, we'll proceed to **Phase 3.2: iOS Client Integration** where we'll:
- Add Firebase SDK to iOS project
- Implement Google Sign-In
- Create LLMProxyService to call your Cloud Functions
- Remove hardcoded API key from the app

Let me know when you're ready to proceed!
