# Firebase Project Setup Guide for PayslipMax

## Step 1: Create New Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: **`payslipmax-ios`**
4. Click **Continue**
5. **Google Analytics**: Enable (recommended for monitoring)
   - Select your existing Analytics account or create new
6. Click **Create project**
7. Wait for project creation (~30 seconds)
8. Click **Continue** when ready

## Step 2: Enable Required Services

### 2.1 Enable Authentication

1. In Firebase Console, click **Authentication** in left sidebar
2. Click **Get started**
3. Click **Google** sign-in method
4. Toggle **Enable**
5. Enter **Project support email**: [your email]
6. Click **Save**

### 2.2 Enable Firestore Database

1. Click **Firestore Database** in left sidebar
2. Click **Create database**
3. Select **Start in production mode** (we'll add security rules later)
4. Choose location: **us-central1** (or closest to your users)
5. Click **Enable**

### 2.3 Upgrade to Blaze Plan (Already Done)

Since you're already on Blaze plan for your other project, this project will automatically use the same billing account.

## Step 3: Install Firebase CLI

```bash
# Install Firebase CLI globally (if not already installed)
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase
firebase login
```

## Step 4: Initialize Firebase in Project

```bash
# Navigate to PayslipMax project root
cd /Users/sunil/Downloads/PayslipMax

# Create backend directory
mkdir -p backend
cd backend

# Initialize Firebase
firebase init

# Select the following options:
# ? Which Firebase features do you want to set up?
#   ◉ Functions: Configure a Cloud Functions directory
#   ◉ Firestore: Configure security rules and indexes
#   ◉ Emulators: Set up local emulators

# ? Please select an option:
#   > Use an existing project
#
# ? Select a Firebase project:
#   > payslipmax-ios (select the project you just created)

# ? What language would you like to use to write Cloud Functions?
#   > JavaScript

# ? Do you want to use ESLint?
#   > Yes

# ? Do you want to install dependencies with npm now?
#   > Yes

# ? What file should be used for Firestore Rules?
#   > firestore.rules

# ? What file should be used for Firestore indexes?
#   > firestore.indexes.json

# ? Which Firebase emulators do you want to set up?
#   ◉ Authentication Emulator
#   ◉ Functions Emulator
#   ◉ Firestore Emulator

# ? Which port do you want to use for the auth emulator?
#   > 9099 (default)

# ? Which port do you want to use for the functions emulator?
#   > 5001 (default)

# ? Which port do you want to use for the firestore emulator?
#   > 8080 (default)

# ? Would you like to enable the Emulator UI?
#   > Yes

# ? Which port do you want to use for the Emulator UI?
#   > 4000 (default)

# ? Would you like to download the emulators now?
#   > Yes
```

## Step 5: Project Structure

After initialization, you should have:

```
backend/
├── .firebaserc              # Firebase project configuration
├── firebase.json            # Firebase features configuration
├── firestore.rules          # Firestore security rules
├── firestore.indexes.json   # Firestore indexes
└── functions/
    ├── .eslintrc.js         # ESLint configuration
    ├── index.js             # Cloud Functions code
    ├── package.json         # Node.js dependencies
    └── node_modules/        # Installed packages
```

## Step 6: Get Firebase Project Configuration

1. In Firebase Console, click **Project Settings** (gear icon)
2. Scroll down to **Your apps**
3. Click **iOS** icon to add iOS app
4. Enter iOS bundle ID: `com.payslipmax.app` (or your actual bundle ID)
5. Click **Register app**
6. Download **GoogleService-Info.plist**
7. **Save this file** - we'll add it to the iOS project later

## Step 7: Set Gemini API Key in Firebase

```bash
# Set the Gemini API key as a Firebase environment variable
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY_HERE"

# Verify it's set
firebase functions:config:get
```

## Next Steps

✅ Firebase project created: `payslipmax-ios`
✅ Authentication enabled (Google Sign-In)
✅ Firestore database created
✅ Firebase CLI initialized
✅ Local emulators configured
✅ Gemini API key stored securely

**Ready to proceed with Cloud Function implementation!**
