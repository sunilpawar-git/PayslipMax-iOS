# Security Guidelines for PayslipMax

## API Key Management

### Protected Files
The following sensitive files are **NEVER** to be committed to the repository:
- `GoogleService-Info.plist` - Firebase configuration with API keys
- `google-services.json` - Google Cloud configuration
- `*.p8`, `*.p12`, `*.pfx` - Certificate files
- Service account keys (`*-firebase-adminsdk-*.json`)
- Any file containing API keys, tokens, or credentials

### Current API Key
**New API Key** (rotated on 2025-12-02):
- Key: `NEW_FIREBASE_API_KEY_PLACEHOLDER`
- Status: ✅ Active, restricted to iOS apps only
- Restrictions: Generative Language API

**Old API Key** (REVOKED):
- Key: `AIzaSyAl3ikzPinsCLziDxHxyfaTxjJo0pzbHnM`
- Status: ❌ Deleted from Google Cloud Console (2025-12-02)
- Reason: Accidentally committed to git history

## Security Features Implemented

### 1. .gitignore Rules
Enhanced `.gitignore` includes patterns for:
- Firebase configuration files
- AWS credentials
- Generic secret files (`*secret*`, `*credential*`, `*apikey*`)
- Certificate files (`.p8`, `.p12`, `.pem`, `.key`)

### 2. Pre-commit Hook
Automatic security checks run before every commit:
- Detects Google API Keys (`AIzaSy...`)
- Detects AWS Access Keys (`AKIA...`)
- Detects private key files
- Detects hardcoded passwords
- Blocks commits if secrets are found

**Hook Location**: `.git/hooks/pre-commit`

**To bypass** (NOT RECOMMENDED):
```bash
git commit --no-verify -m "message"
```

### 3. File Tracking
- `GoogleService-Info.plist` is **not tracked** by git (removed from tracking)
- It exists in your working directory but won't be committed
- Always exists locally with your actual API key

## Best Practices

### Do's ✅
- Use environment variables for secrets
- Use `.gitignore` for sensitive files
- Store credentials outside the repository
- Use Firebase Console to manage API keys
- Rotate API keys regularly
- Keep local `.plist` file with actual key

### Don'ts ❌
- Never hardcode API keys in code
- Never commit credential files
- Never use `--no-verify` unless absolutely necessary
- Never share API keys in messages/emails
- Never use the same key across projects

## If a Secret is Exposed

1. **Immediately rotate the key** in Google Cloud Console
2. **Delete the exposed key**
3. **Create a new key** with proper restrictions
4. **Use `git filter-repo`** to remove from history
5. **Force push** to update remote repository
6. **Notify team members** about the rotation

## Local Setup

When you clone this repository:

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in: `PayslipMax/GoogleService-Info.plist`
3. The file will be ignored by git (no risk of accidental commits)
4. Add your API key to the local file
5. Never commit this file

## Testing the Pre-commit Hook

Try committing a suspicious file:
```bash
# This WILL be blocked by the pre-commit hook
echo "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" > test.txt
git add test.txt
git commit -m "test"  # This will fail!
```

## Automated Checks

The following automated tools monitor the repository:
- GitHub Secret Scanning - Detects exposed tokens
- Pre-commit hooks - Prevents local commits with secrets
- `.gitignore` rules - Prevents file tracking

---

**Last Updated**: 2025-12-02
**Security Incident**: Resolved (API key rotated and removed from history)
