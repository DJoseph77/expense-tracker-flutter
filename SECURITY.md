# Security Policy — Expense Tracker

This document outlines the security architecture, token handling policies, and vulnerability reporting procedures for the Expense Tracker application.

---

## 🔒 Security Architecture Overview

1. **Token Security**: JWT tokens are stored exclusively in encrypted storage using `flutter_secure_storage` (iOS Keychain / Android EncryptedSharedPreferences). Tokens are never written to `shared_preferences` or plain text files.
2. **Transport Security**: All API communications require HTTPS.
3. **Log Sanitization**: `DioClient` logs strictly in `kDebugMode` and redacts JWT tokens, authorization headers, passwords, and sensitive response bodies.
4. **Backend Ownership Enforcement**: Spring Security validates JWT signatures. JPA database queries enforce `WHERE user.id = :authUserId` to ensure complete data isolation between users.
5. **Role Security**: Administrative actions (`POST /api/categories`) return `HTTP 403 Forbidden` for non-ADMIN user roles.

---

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability or credential exposure risk:

1. **Do NOT open a public issue on GitHub.**
2. Send a security report to the repository maintainer.
3. **Never include real production JWT tokens, passwords, or live user credentials in your report.**
4. Include steps to reproduce the issue using synthetic test data.

---

## 🛡️ Known Security Limitations

- **Token Expiration**: The current API implementation does not issue refresh tokens. Upon token expiration (HTTP 401), the application revokes local session tokens and prompts the user to re-authenticate.
- **Biometrics**: Biometric unlock (FaceID/TouchID) is currently on the roadmap and not yet enabled in v1.0.0.
