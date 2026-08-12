# Expense Tracker (Flutter Mobile Application)

A modern, resilient, cross-platform mobile expense tracking client built with Flutter and Riverpod, connected to a RESTful Spring Boot backend.

---

## 📱 Project Overview

Expense Tracker empowers users to record income and expenses, monitor real-time balance metrics, organize transaction categories, and analyze financial health. It provides role-based access control (USER vs ADMIN), strict multi-user data isolation, adaptive dark/light Material 3 themes, offline resilience, and secure JWT authentication.

---

## ✨ Features & Screens

- **Authentication (`/login`, `/register`)**: JWT-based session security, profile restoration on cold start, and 401 session expiration handling.
- **Statistics Dashboard (`/home`)**: Real-time Net Balance hero card, Income and Expense metric cards, pull-to-refresh, adaptive layout, and theme mode toggle.
- **Transaction Management (`/transactions`, `/transactions/new`, `/transactions/:id/edit`)**: Paginated infinite scroll, Income/Expense record creation, pre-filled editing, confirmation dialogs, and robust client validation.
- **Advanced Filtering Sheet**: Multi-field filter by type (INCOME/EXPENSE), category dropdown, start/end dates (`YYYY-MM-DD`), and min/max monetary bounds.
- **Category Management (`/categories`)**: Administrative category CRUD for `ADMIN` roles; read-only category picker for `USER` roles.

---

## 🛠️ Technology Stack & Architecture

- **UI & Design**: Flutter (Material 3), Light & Dark Themes, Responsive Adaptive Layouts.
- **State Management**: Riverpod 2.x (`StateNotifier`, `ProviderScope`).
- **Networking**: Dio with `JwtInterceptor` and centralized `ApiException` mapping.
- **Routing**: GoRouter with authentication guards and deep link protection.
- **Security**: `flutter_secure_storage` for JWT tokens; non-sensitive preferences stored via `shared_preferences`.
- **Validation**: Strict positive monetary validation via `MoneyUtils` (no binary floating-point calculations).

---

## 🔗 Backend Services & Repositories

- **Spring Boot Backend Repository**: [https://github.com/DJoseph77/expenseTraker](https://github.com/DJoseph77/expenseTraker)
- **Deployed Production API Base URL**: `https://expense-tracker-api-x8nw.onrender.com`

---

## 📁 Project Structure

```text
lib/
├── core/
│   ├── config/          # ApiConfig and environment settings
│   ├── network/         # Dio client, JwtInterceptor, ApiException, AuthSessionEvent
│   ├── router/          # GoRouter configuration & route guards
│   ├── storage/         # SecureStorageService (JWT/User profile)
│   ├── theme/           # AppTheme (M3 Light/Dark) & ThemeProvider (shared_preferences)
│   └── utils/           # MoneyUtils, AppDateUtils
└── features/
    ├── auth/            # AuthRepository, AuthNotifier, Login & Register screens
    ├── categories/      # CategoryRepository, CategoryNotifier, Categories screen & picker
    ├── dashboard/       # HomeScreen (Statistics Dashboard)
    ├── statistics/      # StatisticsRepository, StatisticsNotifier, models
    └── transactions/    # TransactionRepository, TransactionNotifier, screens & filter sheet
```

---

## 🚀 Setup & Installation Instructions

### Prerequisites
- **Flutter SDK**: `>= 3.11.4` (Stable channel)
- **Dart SDK**: `>= 3.11.4`
- **CocoaPods** (for iOS builds): `sudo gem install cocoapods`
- **Android Studio / Xcode** for mobile builds.

### Quick Start
```bash
# Clone the repository
git clone https://github.com/DJoseph77/expense-tracker-flutter.git
cd expenseTrackerFlutter

# Fetch dependencies
flutter pub get

# Run the app locally (Production API is set by default)
flutter run
```

---

## 🧪 Testing

The codebase includes an extensive suite of 80 unit and widget tests covering models, repositories, Riverpod providers, router redirect rules, network timeouts, multi-viewport responsiveness (300px to 768px), and 2.0 text scaling.

```bash
# Execute static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Re-run tests to confirm non-flakiness
flutter test
```

---

## 📦 Production Build Commands

To build production release artifacts with a custom or default API base URL:

### Android Release App Bundle (AAB)
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://expense-tracker-api-x8nw.onrender.com
```

### Android Release APK
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://expense-tracker-api-x8nw.onrender.com
```

### iOS Simulator Build
```bash
flutter build ios --simulator \
  --dart-define=API_BASE_URL=https://expense-tracker-api-x8nw.onrender.com
```

### iOS Release Build (Unsigned)
```bash
flutter build ios --release --no-codesign \
  --dart-define=API_BASE_URL=https://expense-tracker-api-x8nw.onrender.com
```

---

## 🔒 Security Notes & Best Practices

- JWT tokens reside exclusively in `flutter_secure_storage`.
- Authentication requests (`/api/auth/login`, `/api/auth/register`) do not attach Bearer tokens.
- Debug logging redacts tokens, authorization headers, passwords, and sensitive bodies.
- Release builds enforce `kDebugMode` checks for zero log leakage.

---

## ⚠️ Known Limitations

- **ADMIN Backend Statistics**: The Spring Boot backend aggregates system-wide statistics for `ADMIN` accounts on `/api/statistics/summary`. USER accounts remain strictly isolated to their own records.
- **Refresh Tokens**: Not supported by backend contract; session expiration (HTTP 401) safely redirects users to login.

---

## 📸 Screenshots

*(Screenshots to be attached prior to App Store / Play Store store submission)*
| Dashboard (Light) | Dashboard (Dark) | Transactions List | Add Transaction |
| :---: | :---: | :---: | :---: |
| *[Screenshot Placeholder]* | *[Screenshot Placeholder]* | *[Screenshot Placeholder]* | *[Screenshot Placeholder]* |
