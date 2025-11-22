# Google Drive Backup Setup Guide

This guide walks you through setting up Google Drive integration for MentorMe auto-backups.

## Why Google Drive?

✅ **Benefits:**
- No Google Play Protect warnings (uses official Google APIs)
- Backups accessible from any device
- Survives device loss/replacement
- Cloud sync across devices
- No local storage used

## Prerequisites

- Google account
- Google Cloud Console access
- Android app built and ready to test

## Setup Steps

### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
   - Project name: `MentorMe` (or your preferred name)
   - Click **Create**

### 2. Enable Google Drive API

1. In your project, go to **APIs & Services** → **Library**
2. Search for "Google Drive API"
3. Click **Google Drive API**
4. Click **Enable**

### 3. Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** (unless you have Google Workspace)
3. Click **Create**
4. Fill in required fields:
   - **App name:** `MentorMe`
   - **User support email:** Your email
   - **Developer contact email:** Your email
5. Click **Save and Continue**
6. **Scopes:** Click **Add or Remove Scopes**
   - Search for and add: `.../auth/drive.file` (View and manage Google Drive files created by this app)
   - Click **Update** → **Save and Continue**
7. **Test users:** Add your Google account email
   - Click **Add Users**
   - Enter your email
   - Click **Save and Continue**
8. Click **Back to Dashboard**

### 4. Create OAuth 2.0 Credentials

#### For Android:

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Android** as application type
4. **Package name:** `com.mentorme.app` (or your package name from `AndroidManifest.xml`)
5. **SHA-1 certificate fingerprint:** Get this from your debug/release keystore

#### Getting SHA-1 Fingerprint:

**Debug keystore (for development):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release keystore (for production):**
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias_name
```

Copy the **SHA-1** value and paste it into the OAuth client ID form.

6. Click **Create**
7. **Important:** Copy the **Client ID** (you'll need it later)

#### For Web (Optional - if you want web support later):

1. Create another OAuth client ID
2. Select **Web application**
3. **Authorized JavaScript origins:** Add `http://localhost` (for local testing)
4. Click **Create**

### 5. Configure Android App

**No code changes needed!** The `google_sign_in` package automatically finds your OAuth credentials using the package name and SHA-1 fingerprint.

### 6. Test the Integration

1. Build and install the app:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

2. Open the app → Settings → Backup & Restore
3. Change **Auto-Backup Destination** to **Google Drive**
4. Click **Sign in to Google Drive**
5. Select your Google account
6. Grant permissions to access Drive files
7. Verify you see "Signed in as [your-email]"

### 7. Verify Backup Works

1. Make a change in the app (add a goal, habit, or journal entry)
2. Wait 30 seconds for auto-backup to trigger
3. Go to [Google Drive](https://drive.google.com)
4. You should see a folder named `MentorMe_Backups` with your backup files

### 8. Publishing to Google Play (When Ready)

When you're ready to publish your app:

1. Generate a release keystore (if you haven't already):
   ```bash
   keytool -genkey -v -keystore ~/mentorme-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mentorme
   ```

2. Get the release SHA-1:
   ```bash
   keytool -list -v -keystore ~/mentorme-release-key.jks -alias mentorme
   ```

3. Add the release SHA-1 to your OAuth client ID:
   - Go to **APIs & Services** → **Credentials**
   - Click your Android OAuth client ID
   - Add the release SHA-1 fingerprint
   - Click **Save**

4. Update OAuth consent screen to **In Production** (in OAuth consent screen settings)

## Troubleshooting

### "Sign in failed" or "PlatformException"

**Cause:** SHA-1 fingerprint mismatch or OAuth not configured correctly.

**Fix:**
1. Verify your package name matches exactly: `com.mentorme.app`
2. Regenerate SHA-1 fingerprint and update in Google Cloud Console
3. Wait 5-10 minutes for changes to propagate
4. Uninstall and reinstall the app

### "Error 10: Developer Error"

**Cause:** SHA-1 fingerprint not added or incorrect.

**Fix:**
```bash
# Get current SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Add it to Google Cloud Console → Credentials → OAuth client ID
```

### "Cannot backup to Drive: not signed in"

**Cause:** User hasn't signed in to Google account.

**Fix:**
- Go to Settings → Backup & Restore
- Click "Sign in to Google Drive"
- Complete the sign-in flow

### Backups not appearing in Drive

**Cause:** Auto-backup disabled or insufficient permissions.

**Fix:**
1. Verify auto-backup is enabled in Settings
2. Make a data change to trigger backup
3. Check Debug Console for error messages
4. Verify Drive API is enabled in Google Cloud Console

### "Access Not Configured" Error

**Cause:** Google Drive API not enabled.

**Fix:**
- Go to Google Cloud Console
- Navigate to APIs & Services → Library
- Search for "Google Drive API"
- Click Enable

## Security Notes

- **Scope:** App only requests `.../auth/drive.file` scope (can only access files it created)
- **Privacy:** Backups are stored in a dedicated `MentorMe_Backups` folder
- **No data sharing:** App does not share data with third parties
- **User control:** Users can sign out and delete backups anytime

## Support

If you encounter issues not covered here:

1. Check Debug Console in app (Settings → Debug Settings → View Logs)
2. Look for errors containing "DriveBackupService" or "GoogleSignIn"
3. Verify all setup steps completed correctly
4. Check [Google Sign-In documentation](https://pub.dev/packages/google_sign_in)

## Next Steps

Once setup is complete, you can:

- ✅ Enable auto-backup to Google Drive
- ✅ Restore from Drive backups
- ✅ Access backups from any device
- ✅ No more Play Protect warnings!
