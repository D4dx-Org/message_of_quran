# Flutter CLI Release Toolkit — Full Implementation Guide

> **One-command releases** to Play Store, App Store, and GitHub from any Flutter project.
> No manual uploads. No GUI. Just terminal.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Setup for a New Flutter Project](#setup-for-a-new-flutter-project)
   - [Step 1: Copy Scripts](#step-1-copy-scripts)
   - [Step 2: Configure Gradle Play Publisher (Android)](#step-2-configure-gradle-play-publisher-android)
   - [Step 3: Authenticate Google Cloud (Play Store)](#step-3-authenticate-google-cloud-play-store)
   - [Step 4: Configure Apple Credentials (App Store)](#step-4-configure-apple-credentials-app-store)
   - [Step 5: Create project.env](#step-5-create-projectenv)
   - [Step 6: Update .gitignore](#step-6-update-gitignore)
5. [Usage — Release Commands](#usage--release-commands)
   - [Android (Play Store)](#android-play-store)
   - [iOS (App Store)](#ios-app-store)
   - [Both Stores](#both-stores)
   - [Git Only](#git-only-version-bump--tag--push)
6. [How It Works — Step by Step](#how-it-works--step-by-step)
7. [File Reference](#file-reference)
8. [project.env Reference](#projectenv-reference)
9. [Gradle Play Publisher Setup (Detailed)](#gradle-play-publisher-setup-detailed)
10. [Apple App Store Setup (Detailed)](#apple-app-store-setup-detailed)
11. [GitHub Actions (CI/CD)](#github-actions-cicd)
12. [Troubleshooting](#troubleshooting)

---

## Overview

This toolkit gives you **single-command releases** for Flutter apps:

```bash
# Release Android to Play Store (production)
./scripts/release.sh android production

# Release iOS to App Store Connect
./scripts/release.sh ios

# Release to both stores at once
./scripts/release.sh both production

# Just bump version + tag + push (no build)
./scripts/release.sh git minor
```

Each command handles the **full pipeline**:
1. Bump version in `pubspec.yaml` (patch/minor/major)
2. Generate release notes from git commits
3. Git commit → tag → push
4. Build release artifact (AAB / IPA)
5. Upload to store (Play Store / App Store Connect)

---

## Architecture

```
your-flutter-project/
├── scripts/
│   ├── release.sh           # Master release script (git + android + ios)
│   ├── init_project.sh      # One-time setup wizard
│   ├── release_android.sh   # Standalone Android release
│   ├── release_ios.sh       # Standalone iOS release
│   ├── version_bump.sh      # Version bump utility
│   └── generate_changelog.sh # Changelog generator
├── project.env              # Credentials & config (git-ignored)
├── project.env.example      # Committable template
├── .github/workflows/
│   ├── ci.yml               # CI: analyze + test on every push
│   └── release.yml          # CD: full release via GitHub Actions
└── android/
    ├── settings.gradle       # ← Gradle Play Publisher plugin declared here
    └── app/
        └── build.gradle      # ← Plugin applied + play {} block configured
```

**Auth flow:**
- **Play Store** → `gcloud` Application Default Credentials (no service account key needed)
- **App Store** → Apple ID + App-Specific Password via `xcrun altool`
- **Git** → Standard SSH/HTTPS credentials already on your machine

---

## Prerequisites

Install these tools **once** on your Mac:

### 1. Flutter SDK

```bash
# Verify installation
flutter --version
```

### 2. Google Cloud CLI (for Play Store)

```bash
# Install
brew install --cask google-cloud-sdk

# Verify
gcloud --version
```

### 3. Xcode (for App Store)

```bash
# Install from Mac App Store, then:
sudo xcode-select --switch /Applications/Xcode.app

# Verify
xcodebuild -version
xcrun altool --version
```

### 4. Ruby + Bundler (optional, for Fastlane in CI)

```bash
brew install ruby
gem install bundler
```

### 5. Android SDK + signing key

Your project must already have a release signing config with `key.properties` and your upload keystore.

---

## Setup for a New Flutter Project

### Step 1: Copy Scripts

Copy the entire `scripts/` folder into your new Flutter project:

```bash
cp -r /path/to/hisaabi/scripts/ /path/to/new-project/scripts/
chmod +x scripts/*.sh
```

Also copy:
```bash
cp /path/to/hisaabi/project.env.example /path/to/new-project/project.env.example
```

### Step 2: Configure Gradle Play Publisher (Android)

This plugin uploads your AAB directly to Play Store from Gradle — **no manual upload needed**.

#### 2a. Add plugin to `android/settings.gradle`

In the `plugins { }` block, add:

```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version '8.6.0' apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
    // ↓ ADD THIS LINE ↓
    id "com.github.triplet.play" version "3.12.1" apply false
}
```

#### 2b. Apply plugin in `android/app/build.gradle`

At the top, in the `plugins { }` block:

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    // ↓ ADD THIS LINE ↓
    id "com.github.triplet.play"
}
```

#### 2c. Add play {} config block at the end of `android/app/build.gradle`

```groovy
// ── Play Store upload configuration ─────────────────────────────────
play {
    track.set(project.findProperty("play.track")?.toString() ?: "internal")
    defaultToAppBundles.set(true)
    releaseStatus.set(
        com.github.triplet.gradle.androidpublisher.ReleaseStatus.valueOf(
            project.findProperty("play.releaseStatus")?.toString() ?: "COMPLETED"
        )
    )

    // Use gcloud ADC credentials
    def adcFile = file("${System.getProperty('user.home')}/.config/gcloud/application_default_credentials.json")
    if (adcFile.exists()) {
        serviceAccountCredentials.set(adcFile)
    }
}
```

### Step 3: Authenticate Google Cloud (Play Store)

```bash
# 1. Login to your Google account (with Play Console access)
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/androidpublisher,https://www.googleapis.com/auth/cloud-platform

# 2. Set your GCP project
gcloud config set project YOUR_GCP_PROJECT_ID

# 3. Set quota project
gcloud auth application-default set-quota-project YOUR_GCP_PROJECT_ID

# 4. Enable the Android Publisher API
gcloud services enable androidpublisher.googleapis.com --project=YOUR_GCP_PROJECT_ID
```

**How to find your GCP project ID:**
- Open [Google Cloud Console](https://console.cloud.google.com)
- Check your `android/app/google-services.json` → look for `"project_id"`
- Or create a new project at [console.cloud.google.com/projectcreate](https://console.cloud.google.com/projectcreate)

**Important:** The Google account you authenticate with must have **Admin** or **Release Manager** access in [Google Play Console](https://play.google.com/console) → Users & Permissions.

### Step 4: Configure Apple Credentials (App Store)

#### 4a. Get your Apple ID

Your Apple Developer email (e.g., `your@email.com`).

#### 4b. Generate an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign In → **App-Specific Passwords** → **Generate**
3. Name it "CLI Release" → Copy the password (format: `xxxx-xxxx-xxxx-xxxx`)

#### 4c. Get your Apple Team ID

```bash
# From your Xcode project:
grep 'DEVELOPMENT_TEAM' ios/Runner.xcodeproj/project.pbxproj | head -1
```

Or find it at [developer.apple.com/account](https://developer.apple.com/account) → Membership Details.

### Step 5: Create project.env

**Option A: Run the setup wizard (recommended)**

```bash
./scripts/init_project.sh
```

This auto-detects your project info and walks you through each field.

**Option B: Copy and fill manually**

```bash
cp project.env.example project.env
```

Then edit `project.env`:

```env
# ── App Identity ─────────────────────────────────────────────────────
APP_NAME="MyApp"
ANDROID_PACKAGE_NAME="com.example.myapp"
IOS_BUNDLE_ID="com.example.myapp"

# ── Apple Credentials ────────────────────────────────────────────────
APPLE_TEAM_ID="ABC1234DEF"
APPLE_ID="your@email.com"
APP_SPECIFIC_PWD="xxxx-xxxx-xxxx-xxxx"

# ── Google Cloud (Play Store) ────────────────────────────────────────
GCP_PROJECT="my-gcp-project-id"

# ── GitHub ───────────────────────────────────────────────────────────
GITHUB_REPO_SLUG="your-org/your-repo"
```

### Step 6: Update .gitignore

Add these lines to your `.gitignore`:

```gitignore
# ── Release Toolkit ──────────────────────────────────────────────────
project.env
*.jks
*.keystore
key.properties
**/release-notes/
build/
*.aab
*.apk
*.ipa
```

**Critical:** `project.env` contains credentials and must NEVER be committed.

---

## Usage — Release Commands

### Android (Play Store)

```bash
# Patch bump → build AAB → upload to internal track
./scripts/release.sh android

# Patch bump → build AAB → upload to production
./scripts/release.sh android production

# Minor version bump → production
./scripts/release.sh android production minor

# Major version bump → production with custom notes
./scripts/release.sh android production major --notes "Complete redesign with new UI"

# Rebuild and upload without version bump
./scripts/release.sh android production --no-bump

# Build and upload without git commit/push
./scripts/release.sh android production --no-git
```

### iOS (App Store)

```bash
# Patch bump → build IPA → upload to App Store Connect
./scripts/release.sh ios

# With custom release notes
./scripts/release.sh ios production minor --notes "New features and bug fixes"

# Rebuild current version
./scripts/release.sh ios --no-bump
```

### Both Stores

```bash
# Release to Play Store AND App Store in one command
./scripts/release.sh both production

# With custom notes
./scripts/release.sh both production patch --notes "Performance improvements"
```

### Git Only (Version Bump + Tag + Push)

```bash
# Patch bump + commit + tag + push (no build)
./scripts/release.sh git

# Minor version bump
./scripts/release.sh git minor

# Major version bump
./scripts/release.sh git major
```

### Command Syntax

```
./scripts/release.sh <target> [track] [bump_type] [flags]
```

| Parameter   | Values                              | Default      |
|-------------|-------------------------------------|--------------|
| `target`    | `git`, `android`, `ios`, `both`     | *(required)* |
| `track`     | `internal`, `production`            | `internal`   |
| `bump_type` | `patch`, `minor`, `major`, `none`   | `patch`      |

| Flag         | Effect                                    |
|--------------|-------------------------------------------|
| `--notes "…"` | Use custom release notes instead of git log |
| `--no-bump`  | Skip version bump, use current version    |
| `--no-git`   | Skip git commit, tag, and push            |

---

## How It Works — Step by Step

Here's exactly what happens when you run `./scripts/release.sh android production`:

### 1. Load Configuration
```
Reads project.env → gets APP_NAME, ANDROID_PACKAGE_NAME, APPLE_ID, etc.
```

### 2. Bump Version
```
pubspec.yaml: version: 2.0.9+35  →  version: 2.0.10+36
```
- `patch`: 2.0.9 → 2.0.10 (build code always increments)
- `minor`: 2.0.9 → 2.1.0
- `major`: 2.0.9 → 3.0.0

### 3. Generate Release Notes
```
Auto-generates from git commits since last tag:
  • Fixed prayer time notification
  • Added dark mode support
  • Updated Quran reader
```
Writes to:
- `android/app/src/main/play/release-notes/en-US/default.txt` (Play Store reads this)
- `CHANGELOG.md` (project history)

### 4. Git Commit + Tag + Push
```bash
git add -A
git commit -m "release: v2.0.10+36"
git tag -a "v2.0.10+36" -m "Release 2.0.10+36"
git push origin HEAD
git push origin v2.0.10+36
```

### 5. Build AAB (Android)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 6. Upload to Play Store
```bash
cd android
./gradlew publishReleaseBundle -Pplay.track=production -Pplay.releaseStatus=COMPLETED
```
The Gradle Play Publisher plugin:
- Reads the AAB from the build output
- Reads release notes from `play/release-notes/en-US/default.txt`
- Authenticates using gcloud ADC (`~/.config/gcloud/application_default_credentials.json`)
- Uploads to the specified track (internal/production)

### 7. Build IPA (iOS)
```bash
flutter build ipa --release
# Output: build/ios/ipa/YourApp.ipa
```

### 8. Upload to App Store Connect
```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/YourApp.ipa \
  -u "your@email.com" \
  -p "xxxx-xxxx-xxxx-xxxx"
```

---

## File Reference

### `scripts/release.sh` — Master Release Script

The main entry point. Handles all targets: `git`, `android`, `ios`, `both`.

**What it does:**
1. Parses arguments and flags
2. Sources `project.env`
3. Bumps version in `pubspec.yaml`
4. Generates release notes from git log
5. Commits, tags, and pushes to git
6. Builds and uploads to the target store(s)

### `scripts/init_project.sh` — Setup Wizard

Interactive one-time setup. Run this when adding the toolkit to a new project.

**What it does:**
1. Auto-detects package name, bundle ID, team ID from project files
2. Prompts for Apple credentials and GCP project
3. Creates `project.env`
4. Checks that required tools are installed
5. Optionally runs `gcloud auth`

### `scripts/release_android.sh` — Standalone Android Release

If you only need Android, use this instead of `release.sh`.

### `scripts/release_ios.sh` — Standalone iOS Release

If you only need iOS, use this instead of `release.sh`.

### `scripts/version_bump.sh` — Version Bump Utility

Standalone version bump: increments version in `pubspec.yaml`, commits, tags, and pushes.

### `scripts/generate_changelog.sh` — Changelog Generator

Generates `CHANGELOG.md` and Play Store release notes from git commits.

---

## project.env Reference

| Variable                | Description                                      | Example                       |
|-------------------------|--------------------------------------------------|-------------------------------|
| `APP_NAME`              | Display name for logs                            | `"Hisaabi"`                   |
| `ANDROID_PACKAGE_NAME`  | Android applicationId                            | `"app.muhasabah"`             |
| `IOS_BUNDLE_ID`         | iOS bundle identifier                            | `"com.muhasabah.app"`         |
| `IOS_EXTENSION_BUNDLE_IDS` | Comma-separated extension bundle IDs          | `"com.app.widget"`            |
| `APPLE_TEAM_ID`         | Apple Developer Team ID                          | `"4SL3SA6P9W"`               |
| `APPLE_ID`              | Apple ID email for uploads                       | `"dev@example.com"`           |
| `APP_SPECIFIC_PWD`      | App-specific password from appleid.apple.com     | `"xxxx-xxxx-xxxx-xxxx"`       |
| `GCP_PROJECT`           | Google Cloud project ID                          | `"my-project-12345"`          |
| `FLUTTER_VERSION`       | Flutter version (for CI)                         | `"3.24.0"`                    |
| `JAVA_VERSION`          | Java version (for CI)                            | `"17"`                        |
| `RUBY_VERSION`          | Ruby version (for CI)                            | `"3.3"`                       |
| `IOS_MIN_DEPLOYMENT`    | iOS minimum deployment target                    | `"15.0"`                      |
| `GITHUB_REPO_SLUG`      | GitHub repo (for CI)                             | `"org/repo"`                  |

---

## Gradle Play Publisher Setup (Detailed)

We use [Gradle Play Publisher](https://github.com/Triple-T/gradle-play-publisher) v3.12.1 to upload AABs directly from the CLI. It avoids the need for Fastlane's `supply` and works with `gcloud` credentials.

### Why not Fastlane?

Fastlane's `supply` requires a **Google Service Account JSON key**. Many organizations block key creation via the `iam.disableServiceAccountKeyCreation` org policy. Gradle Play Publisher supports **Application Default Credentials** from `gcloud auth`, which uses OAuth2 tokens instead.

### Full `android/app/build.gradle` Configuration

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.github.triplet.play"            // ← Add this
}

// ... android { } block ...

// ── Add this at the very end of the file ──

play {
    track.set(project.findProperty("play.track")?.toString() ?: "internal")
    defaultToAppBundles.set(true)
    releaseStatus.set(
        com.github.triplet.gradle.androidpublisher.ReleaseStatus.valueOf(
            project.findProperty("play.releaseStatus")?.toString() ?: "COMPLETED"
        )
    )

    def adcFile = file("${System.getProperty('user.home')}/.config/gcloud/application_default_credentials.json")
    if (adcFile.exists()) {
        serviceAccountCredentials.set(adcFile)
    }
}
```

### Full `android/settings.gradle` Configuration

```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version '8.6.0' apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
    id "com.github.triplet.play" version "3.12.1" apply false   // ← Add this
}
```

### Release Notes Location

The plugin reads release notes from:
```
android/app/src/main/play/release-notes/en-US/default.txt
```

The `release.sh` script auto-generates this file from git commits. You can also write it manually.

### Manual Gradle Commands

```bash
# Upload to internal track
cd android && ./gradlew publishReleaseBundle

# Upload to production
cd android && ./gradlew publishReleaseBundle -Pplay.track=production

# Promote from internal to production
cd android && ./gradlew promoteArtifact --from-track internal --promote-track production
```

---

## Apple App Store Setup (Detailed)

### Upload Method: `xcrun altool`

We use Apple's built-in `xcrun altool` to upload IPAs. No additional tools needed.

```bash
xcrun altool --upload-app \
  --type ios \
  -f build/ios/ipa/YourApp.ipa \
  -u "your@email.com" \
  -p "your-app-specific-password"
```

### Generating an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Sign-In and Security** → **App-Specific Passwords**
4. Click **Generate an app-specific password**
5. Name it (e.g., "CLI Release")
6. Copy the password (format: `xxxx-xxxx-xxxx-xxxx`)
7. Save it in your `project.env` as `APP_SPECIFIC_PWD`

### iOS Signing

The IPA build uses Xcode's automatic signing. Make sure:

1. Your Apple Developer account is added in Xcode → Settings → Accounts
2. Your `ios/Runner.xcodeproj` has:
   - Correct **Bundle Identifier**
   - Correct **Team** selected
   - **Automatically manage signing** enabled
3. Valid provisioning profiles are downloaded

### After Upload

After `xcrun altool` uploads the IPA:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Your build will appear under **TestFlight** (processing takes 5-30 minutes)
3. Add it to a release and submit for review

---

## GitHub Actions (CI/CD)

Two workflows are included for automated CI/CD via GitHub:

### `.github/workflows/ci.yml` — Continuous Integration

Runs on every push and pull request to `main`:
- Flutter analyze (lint checks)
- Flutter test (unit tests)
- Debug builds for Android and iOS

### `.github/workflows/release.yml` — Release Pipeline

Triggered manually via `workflow_dispatch`:
- Bumps version
- Builds release AAB and IPA
- Uploads to Play Store and App Store
- Creates GitHub Release with changelog

**Required GitHub Secrets** (Settings → Secrets → Actions):

| Secret                   | Value                                    |
|--------------------------|------------------------------------------|
| `KEYSTORE_BASE64`        | Base64-encoded upload keystore           |
| `KEY_PROPERTIES`         | Contents of `key.properties`             |
| `PLAY_STORE_CREDENTIALS` | gcloud ADC JSON contents                 |
| `APPLE_ID`               | Apple ID email                           |
| `APP_SPECIFIC_PASSWORD`  | App-specific password                    |
| `APPLE_TEAM_ID`          | Apple Developer Team ID                  |
| `MATCH_PASSWORD`         | Fastlane match passphrase (if using)     |

---

## Troubleshooting

### "gcloud credentials not found"

```bash
# Re-authenticate
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/androidpublisher,https://www.googleapis.com/auth/cloud-platform

# Verify credentials exist
ls -la ~/.config/gcloud/application_default_credentials.json
```

### "Android Publisher API not enabled"

```bash
gcloud services enable androidpublisher.googleapis.com --project=YOUR_PROJECT_ID
```

### "403 Forbidden" on Play Store upload

- Ensure your Google account has **Admin** or **Release Manager** role in Play Console
- Check the GCP project matches what's in `google-services.json`
- Run: `gcloud auth application-default set-quota-project YOUR_PROJECT_ID`

### "No IPA found" after iOS build

- Check Xcode signing: `open ios/Runner.xcworkspace` → Signing & Capabilities
- Make sure a valid provisioning profile is installed
- Try: `flutter clean && flutter build ipa --release`

### "xcrun altool" returns authentication error

- Verify Apple ID and app-specific password in `project.env`
- Regenerate the app-specific password at [appleid.apple.com](https://appleid.apple.com)
- Ensure 2FA is enabled on your Apple ID (required for app-specific passwords)

### Build fails with Java errors

```bash
# Check Java version
java -version

# Flutter expects Java 17 for Gradle 8.x
brew install openjdk@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

### "Version code already used" on Play Store

The build number (e.g., `+35`) must be higher than any previously uploaded version:
```bash
# Check current version
grep '^version:' pubspec.yaml

# Manually set a higher build number if needed
# Edit pubspec.yaml: version: 2.1.0+100
```

### CocoaPods issues on iOS

```bash
cd ios && pod deintegrate && pod install --repo-update && cd ..
```

---

## Quick Start Checklist

Use this checklist when setting up a **new Flutter project**:

- [ ] Copy `scripts/` folder into your project
- [ ] Copy `project.env.example` into your project
- [ ] `chmod +x scripts/*.sh`
- [ ] Run `./scripts/init_project.sh` (or manually create `project.env`)
- [ ] Add `project.env` to `.gitignore`
- [ ] Add Gradle Play Publisher to `android/settings.gradle`
- [ ] Add Gradle Play Publisher to `android/app/build.gradle`
- [ ] Run `gcloud auth application-default login --scopes=...`
- [ ] Enable Android Publisher API: `gcloud services enable androidpublisher.googleapis.com`
- [ ] Generate App-Specific Password at appleid.apple.com
- [ ] Verify: `./scripts/release.sh android` → uploads to Play Store internal track
- [ ] Verify: `./scripts/release.sh ios` → uploads to App Store Connect

**Done! You now have one-command releases.** 🚀

---

## Version History

| Date       | Change                                      |
|------------|---------------------------------------------|
| 2026-04-17 | Initial toolkit creation                    |
| 2026-04-17 | Switched from Fastlane supply to Gradle Play Publisher (org policy blocked service account keys) |
| 2026-04-17 | Added universal release.sh + init_project.sh |
