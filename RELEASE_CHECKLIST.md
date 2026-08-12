# Release Readiness Checklist — Expense Tracker v1.0.0+1

This document tracks release checklist items required before submitting Expense Tracker to Apple App Store or Google Play Store.

---

## 📋 Release Checklist Status

| Task / Item | Status | Notes |
| :--- | :---: | :--- |
| **Version & Build Number** | ✅ COMPLETED | Set to `1.0.0+1` in `pubspec.yaml`. |
| **App Identity** | ✅ COMPLETED | Name: `Expense Tracker`<br>Android ID: `com.youssefathimini.expensetracker`<br>iOS ID: `com.youssefathimini.expensetracker`. |
| **Static Code Analysis** | ✅ COMPLETED | `flutter analyze` passed with 0 errors and 0 warnings. |
| **Automated Test Suite** | ✅ COMPLETED | All 80 unit/widget tests passed deterministically across multiple runs. |
| **Security Audit** | ✅ COMPLETED | Verified 0 hardcoded JWTs, passwords, or secrets. Logging sanitized. |
| **App Icon & Assets** | ✅ COMPLETED | Native adaptive icons and launch configurations set. |
| **Production API Health** | ✅ COMPLETED | Centralized in `ApiConfig` pointing to `https://expense-tracker-api-x8nw.onrender.com`. |
| **Android Release Artifacts** | ✅ COMPLETED | Verified `flutter build appbundle --release` and `flutter build apk --release`. |
| **iOS Release Artifacts** | ✅ COMPLETED | Verified `flutter build ios --simulator` and `flutter build ios --release --no-codesign`. |
| **Manual Production Smoke Test** | ✅ COMPLETED | 23 end-to-end workflow steps verified against production backend. |
| **Android Keystore Signing** | ⏳ PENDING | Production keystore required prior to Google Play upload. |
| **Apple Developer Team Signing** | ⏳ PENDING | Apple Developer Team Certificate & Provisioning Profile required for App Store upload. |
| **Privacy Policy URL** | ⏳ PENDING | Required by Apple & Google prior to store submission. |
| **Store Screenshots & Marketing** | ⏳ PENDING | High-resolution store graphics to be uploaded to App Store Connect / Play Console. |

---

## 🔑 Production Keystore & Signing Instructions

### Android Keystore Setup
1. Generate release keystore:
   ```bash
   keytool -genkey -v -keystore android/app/release.keystore \
     -alias key -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Create `android/key.properties` (excluded by `.gitignore`):
   ```properties
   storePassword=<PASSWORD>
   keyPassword=<PASSWORD>
   keyAlias=key
   storeFile=release.keystore
   ```
3. Update `android/app/build.gradle.kts` to load `key.properties` for release signing.

### Apple Signing Setup
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Under **Signing & Capabilities**, select your **Apple Developer Team**.
3. Choose **Automatically manage signing** and select your provisioning profile.
