# Technical Privacy Notes — Expense Tracker

This document provides a technical explanation of how data is processed, stored, and protected within the Expense Tracker application.

---

## 📊 Data Collection & Processing

1. **Account Profile Data**: User name and email address collected during registration (`POST /api/auth/register`) for account identification and authentication.
2. **Financial Data**: Transaction entries (amount, transaction type, category, date, description, notes) entered by the user to calculate statistics and display feeds.
3. **Local Authentication Credentials**: Encrypted JSON Web Token (JWT) stored locally on the device using OS-level secure storage (`flutter_secure_storage`).

---

## 💾 Backend Storage & Retention

- Account and financial transaction data are transmitted via TLS/HTTPS to the Spring Boot API and stored in a PostgreSQL database (Neon DB).
- Data is processed strictly to perform user authentication, calculate real-time net balance metrics, and render historical financial records.
- **Third-Party Analytics & Advertising**: The application contains **zero** third-party tracking, advertising SDKs, telemetry, or analytics packages.

---

## 🔒 User Responsibilities & Disclaimer

- Users are responsible for keeping their account credentials (passwords) secure.
- **Portfolio Project Disclaimer**: This document provides a technical architecture note for portfolio demonstration purposes and does not constitute formal legal counsel or a formal store-ready Privacy Policy document.
