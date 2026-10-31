# Codemagic Deployment & Firebase Google Auth Guide
# SW2627: Diagnostic Lab Management (LabTrack)

This guide walks you through deploying **LabTrack** using **Codemagic CI/CD** with fully working **Firebase Services (Firestore, Auth, Storage)** and **Google Sign-In**.

---

## 📋 Table of Contents
1. [Prerequisites & Repository Structure](#1-prerequisites--repository-structure)
2. [Firebase Console Configuration Checklist](#2-firebase-console-configuration-checklist)
3. [Connecting & Deploying on Codemagic](#3-connecting--deploying-on-codemagic)
4. [Codemagic Workflows Overview](#4-codemagic-workflows-overview)
5. [Environment Variables & Custom Keystore (Optional)](#5-environment-variables--custom-keystore-optional)
6. [Troubleshooting Google Sign-In](#6-troubleshooting-google-sign-in)

---

## 1. Prerequisites & Repository Structure

- The project is configured with a root [`codemagic.yaml`](../codemagic.yaml) that Codemagic detects automatically.
- **App Package Name**: `com.labtrack.lab_track`
- **Firebase Project ID**: `lab-track-f8a33`
- **Bundled Firebase Configuration**:
  - Android: [`lab_track/android/app/google-services.json`](../lab_track/android/app/google-services.json)
  - Dart/Web/Android Options: [`lab_track/lib/config/firebase_options.dart`](../lab_track/lib/config/firebase_options.dart)
  - Bundled Keystore: [`lab_track/android/app/debug.keystore`](../lab_track/android/app/debug.keystore)

---

## 2. Firebase Console Configuration Checklist

To guarantee that **Google Sign-In** and **Firebase Auth** function properly in your built APK, AAB, and Web release:

### 2.1 Enable Google Sign-In Provider
1. Open the [Firebase Console](https://console.firebase.google.com/project/lab-track-f8a33/authentication/providers).
2. Go to **Build** ➔ **Authentication** ➔ **Sign-in method**.
3. Under **Sign-in providers**, click **Google**:
   - Toggle **Enable** to ON.
   - Select your **Project support email**.
   - Click **Save**.

### 2.2 Register Android Signing Certificate SHA-1 & SHA-256
Google Sign-In requires your app's signing key fingerprints to be registered under your Android app in Firebase:

1. In Firebase Console, click the **Gear Icon ⚙️** (Project Settings) ➔ **General**.
2. Scroll down to **Your apps** and select **Android App (`com.labtrack.lab_track`)**.
3. Under **SHA certificate fingerprints**, verify or click **Add fingerprint**:
   
   **Default Pre-Configured SHA-1 (from bundled `debug.keystore`):**
   ```text
   7F:E2:A0:37:CB:81:E7:B5:B7:04:E2:33:0D:48:09:AE:A3:CB:51:18
   ```
   *(This exact hash is already present in `google-services.json`).*

4. Run the Codemagic build once or run `./gradlew signingReport` locally to view the matching **SHA-256** and add it to Firebase Console as well.

> [!IMPORTANT]
> If you create or upload a custom release keystore in Codemagic, add the new keystore's SHA-1 and SHA-256 to Firebase Console. The Codemagic build script automatically prints these fingerprints in Step 7 of the build log!

### 2.3 Web Authorized Domains (For Web Release)
If deploying the Web build:
1. In Firebase Console ➔ **Authentication** ➔ **Settings** ➔ **Authorized domains**.
2. Ensure your hosting domain (e.g. `your-app.web.app`, `your-domain.com`, or Codemagic static domain) is listed. `localhost` is authorized by default.

---

## 3. Connecting & Deploying on Codemagic

### Step 1: Sign In & Add Application
1. Go to [Codemagic](https://codemagic.io) and log in (with GitHub, GitLab, or Bitbucket).
2. Click **Add application**.
3. Select **Git provider** and choose your repository: `SW2627-Diagnostic-Lab-Management`.
4. Select **Flutter App** as the project type.

### Step 2: Select `codemagic.yaml` Configuration
1. Codemagic will detect the [`codemagic.yaml`](../codemagic.yaml) file at the root of the repository.
2. Select **codemagic.yaml** as your build specification (instead of Flutter workflow editor).

### Step 3: Trigger a Build
1. Click **Start new build**.
2. Select your branch (e.g., `main` or `master`).
3. Select your desired workflow:
   - **`android-workflow`**: Compiles the release APK and Google Play AAB.
   - **`web-workflow`**: Compiles the production Web SPA bundle.
4. Click **Start build**.

---

## 4. Codemagic Workflows Overview

### 📱 `android-workflow`
- **Instance**: Mac mini M2 (`mac_mini_m2`) — *500 free build minutes/month on Codemagic Free Tier*
- **Environment**: Flutter `stable`, Java `17`, Android NDK `27.0.12077973`
- **Build Steps**:
  1. Sets up `local.properties` and verifies `google-services.json`.
  2. Runs `flutter pub get`.
  3. Executes `flutter analyze --no-fatal-infos`.
  4. Runs the cross-role unit and integration test suite (`flutter test`).
  5. Builds the production **Release APK**: `lab_track/build/app/outputs/flutter-apk/app-release.apk`.
  6. Builds the **Android App Bundle (AAB)**: `lab_track/build/app/outputs/bundle/release/app-release.aab`.
  7. Runs `./gradlew signingReport` and outputs SHA-1 & SHA-256 fingerprints in the build log.
- **Artifacts Generated**: Direct download link in Codemagic UI for both APK and AAB.

### 🌐 `web-workflow`
- **Instance**: Mac mini M2 (`mac_mini_m2`) — *Free Tier compatible*
- **Build Steps**:
  1. Runs `flutter pub get`.
  2. Executes `flutter analyze` and tests.
  3. Compiles production Flutter Web bundle via `flutter build web --release`.
- **Artifacts Generated**: Web distribution zip bundle (`lab_track/build/web/**`).

---

## 5. Environment Variables & Custom Keystore (Optional)

If you prefer **not** to commit `google-services.json` to public Git or wish to use a custom production keystore:

### Option A: Storing `google-services.json` in Codemagic
1. In Codemagic dashboard, navigate to **Teams** or **Applications** ➔ **Environment variables**.
2. Create variable:
   - **Variable name**: `GOOGLE_SERVICES_JSON`
   - **Variable value**: Base64-encoded string of your `google-services.json` file.
     *To encode on Linux/macOS:* `base64 -w 0 google-services.json`
     *To encode on Windows (PowerShell):* `[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))`
   - **Group**: `firebase_config`
   - Check **Secure**.

### Option B: Custom Production Keystore (Google Play Release)
If using your own upload keystore:
1. In Codemagic dashboard ➔ **Environment variables**:
   - `CM_KEYSTORE`: Base64-encoded `.keystore` or `.jks` file.
   - `CM_KEYSTORE_PASSWORD`: Keystore password.
   - `CM_KEY_ALIAS`: Key alias.
   - `CM_KEY_PASSWORD`: Key password.
   - Check **Secure**.
2. The [`build.gradle.kts`](../lab_track/android/app/build.gradle.kts) and [`codemagic.yaml`](../codemagic.yaml) automatically detect these variables and sign your release builds.

---

## 6. Troubleshooting Google Sign-In

| Issue / Error Code | Root Cause | Solution |
|---|---|---|
| **`10: DEVELOPER_ERROR`** or **`invalid-credential`** | The SHA-1 fingerprint of the signing key is missing from Firebase Console. | Go to **Firebase Console ➔ Project Settings ➔ Your Android App**, and add the SHA-1 printed in Step 7 of your Codemagic build log. |
| **`12500: Sign-in failed`** | Google Sign-In provider is disabled in Firebase Console or OAuth consent screen is incomplete. | Enable Google provider in **Firebase Console ➔ Authentication ➔ Sign-in method** and select a support email. |
| **`operation-not-allowed`** | Google Auth provider is turned off in Firebase Console. | Toggle Google Sign-In to **Enabled** in Firebase Console. |
| **`popup-closed-by-user`** / **`web-context-cancelled`** | User dismissed the sign-in modal/tab before completing. | Handled gracefully in `auth_repository.dart`; prompt user to retry. |
| **`network-request-failed`** | Device cannot reach Firebase authentication endpoints. | Ensure device has an active Wi-Fi or cellular data connection. |
