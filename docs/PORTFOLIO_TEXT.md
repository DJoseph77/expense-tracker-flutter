# Portfolio Text, CV Bullet Points & Interview Guide

This document provides ready-to-use descriptions for GitHub, CVs, LinkedIn, and interview preparation.

---

## 📌 A. GitHub Repository Description (Max 350 Chars)

> A resilient cross-platform Expense Tracker mobile application built with Flutter, Riverpod 2.x, Dio, and GoRouter, powered by a Spring Boot REST API, PostgreSQL, and Docker. Features JWT security, strict multi-user data isolation, M3 dark/light themes, paginated feeds, dynamic filters, and 80 unit/widget tests.

*(Length: 307 characters)*

---

## 📄 B. Resume / CV Bullet Points

- **Full-Stack Architecture**: Architected a production-ready mobile financial tracking client in Flutter using Riverpod 2.x and Dio, integrated with a Spring Boot REST API, PostgreSQL, and Render cloud hosting.
- **Security & Data Ownership**: Enforced strict multi-user data isolation and role-based access control (USER/ADMIN) via JWT authentication, encrypted `flutter_secure_storage`, and database-level query ownership scoping.
- **Testing & Quality Assurance**: Implemented an automated test suite of 80 unit and widget tests covering state management, network resilience, route protection, and multi-viewport accessibility layout scaling.

---

## 💼 C. LinkedIn Project Description

### 📱 Expense Tracker — Cross-Platform Financial Mobile Application

**Overview**: Built an end-to-end mobile financial management platform connecting a Flutter client to a Spring Boot backend database.

**Key Accomplishments**:
- Developed a reactive, feature-first mobile interface in Flutter using Riverpod 2.x, Dio, and GoRouter.
- Built a stateless authentication pipeline featuring JWT token interception, 401 session expiry handling, and encrypted local token storage.
- Engineered dynamic multi-parameter search, paginated infinite scroll feeds, and real-time dashboard financial summary metrics.
- Designed Material 3 adaptive UI themes supporting dark/light mode and screen viewports from 300px phones to tablets.
- Achieved 100% test pass rate across 80 unit and widget tests with automated verification.

**Technologies**: Flutter, Dart, Riverpod, Dio, GoRouter, Spring Boot, Spring Security, PostgreSQL, Docker, Render.

---

## 🗣️ D. Concise 2-Minute Interview Explanation

1. **What the Project Does**:  
   "Expense Tracker is a mobile financial tracking app where users record income and expenses, monitor real-time balance metrics, apply multi-parameter filters, and organize categories securely."

2. **Architecture**:  
   "The app follows a Feature-First Layered Architecture in Flutter. Presentation UI widgets observe Riverpod `StateNotifier`s. Repositories manage Dio HTTP transport, deserialization, and error mapping into `ApiException`s. The backend is a Spring Boot REST API backed by PostgreSQL."

3. **Hardest Problem Solved**:  
   "Decoupling token revocation from UI providers. Initially, mutating an unauthenticated state provider inside the network interceptor caused Flutter provider initialization crashes. I resolved this by introducing a unidirectional event stream (`AuthSessionEvent`). The Dio interceptor emits 401 events, and `AuthNotifier` subscribes independently to revoke sessions cleanly."

4. **Security Model**:  
   "Tokens are stored encrypted in `flutter_secure_storage`. All network requests automatically inject `Authorization: Bearer <token>`. The backend enforces user ownership at the database level (`WHERE user_id = :id`), preventing any user from accessing or modifying another's data."

5. **What I Would Improve Next**:  
   "I would add biometric authentication (FaceID/Fingerprint) using `local_auth` and implement local offline caching with background synchronization via Isar database."

---

## ❓ E. 10 Likely Interview Questions & Answer Outlines

### 1. Why did you choose Riverpod over Provider or Bloc for state management?
*Outline*: Riverpod is compile-safe, does not rely on the Flutter widget tree context (`BuildContext`), and allows accessing providers anywhere cleanly. `StateNotifier` provides immutable state updates.

### 2. How did you handle JWT authentication and token expiration?
*Outline*: Tokens are saved in `flutter_secure_storage`. `JwtInterceptor` automatically attaches the Bearer token to requests. Upon receiving HTTP 401, it clears secure storage and broadcasts an event on `AuthSessionEvent` so `AuthNotifier` transitions to unauthenticated state.

### 3. How did you prevent floating-point inaccuracies in financial values?
*Outline*: We avoided double arithmetic for currency calculations, storing and displaying values as exact formatted strings on the client and using `BigDecimal` / numeric precision on the backend.

### 4. How did you ensure multi-user data privacy?
*Outline*: Security isn't just client-side UI filtering. The Spring Boot backend extracts user ID from the signed JWT and appends `WHERE t.user.id = :authUserId` to all JPA repository queries.

### 5. How did you fix UI layout overflow bugs on small devices?
*Outline*: Replaced fixed `Row` layouts with `LayoutBuilder` boundaries. When screen width drops below 340px or text scaling exceeds 1.1x, metric cards and action buttons dynamically stack into vertical `Column`s.

### 6. What is the role of GoRouter in your application?
*Outline*: GoRouter provides declarative URL-based navigation and route guards. Its `redirect` builder inspects `AuthState` and routes unauthenticated users away from `/home`, `/categories`, and `/transactions` back to `/login`.

### 7. How did you handle network error propagation?
*Outline*: Catch Dio network exceptions (`DioExceptionType`) in the repository layer and map them into custom domain `ApiException` objects with user-friendly error messages before passing them to Riverpod notifiers.

### 8. How are role-based permissions (USER vs ADMIN) implemented?
*Outline*: The user profile returned on login contains a `role` string (`USER` or `ADMIN`). In the UI, administrative features like category creation buttons are hidden for `USER` roles, and backend Spring Security enforces HTTP 403 Forbidden on `POST /api/categories`.

### 9. How do you test Riverpod providers and widgets?
*Outline*: Override Riverpod providers in widget tests using `ProviderScope(overrides: [...])` with fake repositories (`FakeAuthNotifier`, `FakeCategoryRepository`), testing state transitions without real HTTP requests.

### 10. How is the app configured for production deployments?
*Outline*: Base API URL is centralized in `ApiConfig`, supporting compile-time overrides (`--dart-define=API_BASE_URL=...`) with safe production fallbacks. Debug logging is wrapped in `kDebugMode` to prevent token leakage in release builds.
