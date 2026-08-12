# Portfolio Case Study — Cross-Platform Expense Tracker

## 📌 Executive Summary
**Project**: Expense Tracker (Flutter Client + Spring Boot REST API)  
**Role**: Full-Stack Mobile Engineer & Architect  
**Tech Stack**: Flutter, Dart, Riverpod 2.x, Dio, GoRouter, Spring Boot, Spring Security, PostgreSQL (Neon DB), Flyway, Render, Docker  

---

## 🎯 Problem Statement & Product Goals
Managing personal finances requires a simple, reliable, and secure application that operates across devices. Existing solutions are often cluttered with advertisements or suffer from slow rendering, imprecise floating-point calculations, and weak data isolation.

**Product Goals**:
1. Build an intuitive, cross-platform mobile client with clean financial metrics.
2. Guarantee strict multi-user data isolation and role-based access control.
3. Ensure exact two-decimal monetary precision without rounding bugs.
4. Support fast paginated transaction feeds with dynamic multi-parameter filters.
5. Provide adaptive dark/light Material 3 aesthetics and responsive layout scaling across small phones and tablets.

---

## 🏗️ Technical Decisions & Architecture
- **Feature-First Structure**: Organizes modules (`auth`, `dashboard`, `transactions`, `categories`, `statistics`) independently, ensuring code maintainability and scalability.
- **Riverpod 2.x State Management**: Employs immutable state models (`StateNotifierProvider`) for unidirectional data flow and predictable state mutations.
- **Dio & Custom Interceptors**: Encapsulates HTTP transport, automatic JWT token attachment, redacted logging, and centralized error mapping (`ApiException`).
- **Encrypted Local Storage**: Persists sensitive tokens via `flutter_secure_storage` and non-sensitive user preferences via `shared_preferences`.

---

## ⚡ Main Technical Challenges & Solutions

### 1. Provider Initialization & Auth Event Decoupling
*Challenge*: The initial implementation caused a runtime Flutter crash (`Providers are not allowed to modify other providers during their initialization`) when `AuthNotifier` tried to directly mutate an unauthenticated callback provider.  
*Solution*: Replaced the mutable provider callback with a clean, decoupled one-directional event stream service (`AuthSessionEvent`). `JwtInterceptor` broadcasts HTTP 401 events to the stream upon token revocation, allowing `AuthNotifier` to update its state cleanly without cyclic provider dependencies.

### 2. Multi-User Data Isolation & Backend Query Enforcement
*Challenge*: Relying solely on client-side UI filtering creates severe security vulnerabilities if a user modifies network parameters or IDs.  
*Solution*: Enforced data ownership strictly at the database layer. All Spring Data JPA queries append explicit user ownership filters (`WHERE t.user.id = :authenticatedUserId`). Multi-user automated integration tests verified that User B cannot query, update, or delete User A's transactions or alter User A's statistics.

### 3. Responsive Layout & Font Scale Resilience
*Challenge*: Small devices (<340px width) and large accessibility text scaling (1.5x / 2.0x) caused horizontal `RenderFlex` overflows on metric cards and header badges.  
*Solution*: Refactored `HomeScreen` and card components using adaptive `LayoutBuilder` boundaries. When width or font scaling exceeds thresholds, horizontal button pairs and metric cards dynamically stack into vertical `Column`s, eliminating layout clipping.

### 4. Monetary Calculations
*Challenge*: Binary floating-point arithmetic (`0.1 + 0.2 = 0.30000000000000004`) causes financial rounding errors.  
*Solution*: All client inputs are validated as exact positive two-decimal formatted strings or numeric `BigDecimal` values on the backend.

---

## 🧪 Testing & Quality Assurance Strategy
- **Unit & Widget Testing**: Comprehensive 80-test suite covering JSON deserialization, Riverpod state transitions, GoRouter redirect protection, financial filter parameter formatting, and multi-viewport widget rendering.
- **Flakiness Verification**: Every test run was executed multiple consecutive times (`flutter test`) to ensure zero non-deterministic assertion failures.
- **Live Production Smoke Testing**: Validated 23 end-to-end user journeys against the deployed production backend (`https://expense-tracker-api-x8nw.onrender.com`).

---

## 📈 Key Results
- **80/80 Unit & Widget Tests Passing** with 0 warnings or analyzer errors.
- **100% Data Isolation** verified across multi-user security tests.
- **Production Artifacts Built**: Verified Android App Bundle (`appbundle`), Debug APK, and iOS Simulator builds (`Runner.app`).
- **Sub-Second API Response Times** hosted on Render with automated Flyway database migrations.

---

## 🤖 Responsible AI Disclosure
AI-assisted development tools were utilized during planning, code review, and initial debugging, while system architecture decisions, backend security validation, state management decoupling, test design, and live integration were manually verified and implemented.

---

## 🚀 Lessons Learned & Future Roadmap
- Decoupling networking interceptors from UI state using event streams eliminates Flutter initialization crashes.
- Designing for small viewports and large font accessibility upfront prevents UI overflow refactoring late in the release cycle.

**Future Roadmap**:
1. Biometric Authentication (FaceID / Fingerprint) via `local_auth`.
2. CSV / PDF Export of filtered transaction reports.
3. Offline queueing with background sync via `Isar` or `sqflite`.
