# Android Deployment Guide

This guide covers how to set up release signing and deploy MentorMe to the Google Play Store using GitHub Actions.

## Overview

The deployment pipeline:
1. **Create a release keystore** (one-time setup)
2. **Configure GitHub secrets** (one-time setup)
3. **Create the app in Play Console** (one-time setup)
4. **Tag a release** → GitHub Actions builds signed AAB → Upload to Play Store

---

## 1. Keystore Setup

### Create a New Keystore

If you don't have a keystore, create one:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password (save this!)
- **Key password**: Can be the same as keystore password
- **Your name**: Your name or organization
- **Organizational unit**: e.g., "Development"
- **Organization**: Your company name
- **City, State, Country**: Your location

### Store Your Keystore Safely

> **CRITICAL**: If you lose your keystore, you cannot update your app on Play Store!

- Store the `.jks` file in a secure location (password manager, encrypted drive)
- Never commit the keystore to git
- Back up the keystore in multiple secure locations
- Document the passwords securely

### Convert Keystore to Base64

For GitHub secrets, encode the keystore as base64:

```bash
# macOS - copies to clipboard
base64 -i upload-keystore.jks | pbcopy

# Linux - prints to terminal
base64 -w 0 upload-keystore.jks

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

---

## 2. GitHub Secrets Setup

Go to your repository: **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file | (long base64 string) |
| `KEYSTORE_PASSWORD` | Password for the keystore | `your-keystore-password` |
| `KEY_ALIAS` | Alias name for the key | `upload` |
| `KEY_PASSWORD` | Password for the key | `your-key-password` |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | (Optional) Service account JSON for Play Store uploads | (JSON contents) |

> **Note:** The `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret is optional. Without it, the workflow still builds and uploads the AAB to GitHub Releases - you just need to upload to Play Store manually.

### Verifying Secrets

After adding secrets, they appear masked in the repository settings. You cannot view them again, only replace them.

---

## 3. Google Play Console Setup

### Create the App (First Time Only)

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **All apps → Create app**
3. Fill in:
   - App name: `MentorMe`
   - Default language
   - App or game: `App`
   - Free or paid: `Free`
4. Accept the declarations and create

### Complete Store Listing

Before you can upload, complete these sections:
- **Main store listing**: Description, screenshots, icons
- **Content rating**: Complete the questionnaire
- **Target audience**: Select age groups
- **Privacy policy**: Add a URL to your privacy policy

### First Manual Upload

> **Important**: You must upload the first AAB manually before automation works.

1. Go to **Release → Testing → Internal testing**
2. Click **Create new release**
3. Upload your first AAB (built locally or from GitHub Actions)
4. Add release notes
5. Save and roll out

After this, GitHub Actions can upload subsequent versions automatically.

### Set Up Play App Signing (Recommended)

Google Play App Signing lets Google manage your release key:

1. Go to **Release → Setup → App signing**
2. Choose **Use Google-generated key**
3. Your keystore becomes the "upload key"
4. Google re-signs with their key for distribution

**Benefits:**
- Google protects your release key
- You can reset your upload key if compromised
- Required for app bundles (AAB)

---

## 4. GitHub Actions Workflow

The release workflow is defined in `.github/workflows/android-release.yml`.

### Trigger a Release

Create and push a version tag:

```bash
# Create tag
git tag v1.0.0

# Push tag to trigger workflow
git push origin v1.0.0
```

Or trigger manually:
1. Go to **Actions → Android Release**
2. Click **Run workflow**
3. Enter version (e.g., `v1.0.0`)

### What the Workflow Does

1. **Checkout code** and generate build info
2. **Set up signing** from GitHub secrets
3. **Build release APKs** (split by architecture)
4. **Build release AAB** (for Play Store)
5. **Create GitHub Release** with all artifacts
6. **Clean up** signing files

### Workflow Configuration

```yaml
name: Android Release

on:
  push:
    tags:
      - 'v*.*.*'  # Triggers on version tags like v1.0.0
  workflow_dispatch:  # Allow manual triggers
    inputs:
      version:
        description: 'Release version (e.g., v1.0.0)'
        required: true
        type: string

jobs:
  create-release:
    name: Create GitHub Release with APK
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version from tag or input
        id: version
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            VERSION="${{ github.event.inputs.version }}"
          else
            VERSION=${GITHUB_REF#refs/tags/}
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "version_number=${VERSION#v}" >> $GITHUB_OUTPUT

      - name: Generate build info
        run: |
          mkdir -p lib/config
          GIT_COMMIT_HASH=$(git rev-parse HEAD)
          GIT_COMMIT_SHORT=$(git rev-parse --short HEAD)
          BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
          cat > lib/config/build_info.dart <<EOF
          class BuildInfo {
            static const String gitCommitHash = '$GIT_COMMIT_HASH';
            static const String gitCommitShort = '$GIT_COMMIT_SHORT';
            static const String buildTimestamp = '$BUILD_TIMESTAMP';
            static const String version = '${{ steps.version.outputs.version }}';
          }
          EOF

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.1'
          channel: 'stable'
          cache: true

      - name: Get Flutter dependencies
        run: flutter pub get

      - name: Set up release signing
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks
          echo "storePassword=$KEYSTORE_PASSWORD" > android/key.properties
          echo "keyPassword=$KEY_PASSWORD" >> android/key.properties
          echo "keyAlias=$KEY_ALIAS" >> android/key.properties
          echo "storeFile=upload-keystore.jks" >> android/key.properties

      - name: Build release APK
        run: flutter build apk --release --split-per-abi --shrink

      - name: Build App Bundle (AAB)
        run: flutter build appbundle --release

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ steps.version.outputs.version }}
          name: MentorMe ${{ steps.version.outputs.version }}
          files: |
            build/app/outputs/flutter-apk/*-release.apk
            build/app/outputs/bundle/release/app-release.aab
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Upload to Google Play Store
        uses: r0adkll/upload-google-play@v1
        continue-on-error: true  # Don't fail if Play Store upload fails
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
          packageName: com.example.ai_mentor_coach
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed

      - name: Clean up signing files
        if: always()
        run: |
          rm -f android/app/upload-keystore.jks
          rm -f android/key.properties
```

---

## 5. Uploading to Play Store

### Option A: Manual Upload (Simple)

1. Download the AAB from the GitHub Release
2. Go to Play Console → Release → Production (or testing track)
3. Create new release
4. Upload the AAB
5. Add release notes
6. Review and roll out

### Option B: Automated Upload (Advanced)

Add automatic Play Store upload using `r0adkll/upload-google-play`:

#### Set Up Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Google Play Android Developer API**
3. Create a service account:
   - IAM & Admin → Service accounts → Create
   - No permissions needed at this step
   - Create JSON key and download
4. In Play Console:
   - Users and permissions → Invite new users
   - Add service account email
   - Grant **Release manager** permission for your app

#### Add to Workflow

Add this step after the build:

```yaml
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
          packageName: com.example.ai_mentor_coach
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal  # internal, alpha, beta, or production
          status: completed
          whatsNewDirectory: distribution/whatsnew
```

#### Required Secret

Add `PLAY_STORE_SERVICE_ACCOUNT_JSON` with the contents of the service account JSON file.

---

## 6. Release Tracks

| Track | Purpose | Audience |
|-------|---------|----------|
| `internal` | Internal testing | Up to 100 testers |
| `alpha` | Closed testing | Invited testers |
| `beta` | Open testing | Anyone can join |
| `production` | Public release | All users |

**Recommended flow:**
1. Upload to `internal` first
2. Test thoroughly
3. Promote to `beta` for wider testing
4. Promote to `production` for public release

---

## 7. Troubleshooting

### "APK signed in debug mode"

**Cause:** GitHub secrets not configured or not accessible.

**Fix:**
1. Verify all 4 secrets are set in GitHub
2. Check secret names match exactly (case-sensitive)
3. Verify base64 encoding is correct

### "Package name not found"

**Cause:** App not created in Play Console yet.

**Fix:** Create the app and upload first AAB manually.

### "Version code already exists"

**Cause:** Trying to upload same version twice.

**Fix:** Increment `versionCode` in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # +2 is the versionCode
```

### "Upload key rejected"

**Cause:** Using wrong keystore or Play App Signing not set up.

**Fix:**
1. If using Play App Signing, upload certificate to Play Console
2. Verify you're using the correct upload keystore
3. Check keystore passwords are correct

### Build fails with signing error

Check the workflow logs for:
- "Keystore file exists: no" → Base64 decoding failed
- "Key properties exists: no" → Secrets not passed correctly

---

## 8. Security Best Practices

1. **Never commit keystores or passwords to git**
2. **Use GitHub secrets for all sensitive data**
3. **Enable branch protection** for main branch
4. **Require PR reviews** before merging
5. **Use Play App Signing** to let Google manage release keys
6. **Rotate upload key** periodically if possible
7. **Limit secret access** to necessary workflows only

---

## 9. Quick Reference

### Create a Release

```bash
# Bump version in pubspec.yaml first
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"
git tag v1.0.1
git push origin main --tags
```

### Check Build Status

Go to **Actions** tab in GitHub to see workflow progress.

### Download Artifacts

1. Go to the GitHub Release page
2. Download APK or AAB from assets
3. Verify checksums if needed

---

## Related Files

- `.github/workflows/android-release.yml` - Release workflow
- `.github/workflows/android-build.yml` - CI build workflow
- `android/app/build.gradle.kts` - Android build configuration
- `android/key.properties` - Local signing config (not in git)
- `pubspec.yaml` - App version configuration
