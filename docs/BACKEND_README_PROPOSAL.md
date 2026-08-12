# Proposed README Update for Spring Boot Backend Repository

*(Copy and paste this section into the main `README.md` of the backend repository: [https://github.com/DJoseph77/expenseTraker](https://github.com/DJoseph77/expenseTraker))*

---

```markdown
# Expense Tracker — Spring Boot RESTful API

A stateless, production-ready Java Spring Boot REST API for personal expense management, connected to a PostgreSQL database with Flyway schema migrations and Docker containerization.

---

## 📱 Mobile Client Application

This API is actively consumed by the cross-platform **Flutter Expense Tracker Mobile Application**:
👉 **Flutter Client Repository**: [https://github.com/DJoseph77/expense-tracker-flutter](https://github.com/DJoseph77/expense-tracker-flutter)

---

## 🌐 Production Deployment

- **Live Base URL**: `https://expense-tracker-api-x8nw.onrender.com`
- **Hosting Platform**: Render (Docker container)
- **Database**: PostgreSQL (Neon DB Cloud)

---

## 🛠️ Main Features & Architecture

- **Stateless JWT Security**: Custom `JwtAuthenticationFilter` validates incoming Bearer tokens.
- **Role-Based Access Control**:
  - `USER`: Full ownership and CRUD over own income/expenses; read-only access to categories.
  - `ADMIN`: Full transaction CRUD + exclusive rights to create, update, and delete categories (`/api/categories`).
- **Database Layer**: Spring Data JPA with Flyway migration scripts (`src/main/resources/db/migration`).
- **Monetary Precision**: Uses `BigDecimal` for exact financial calculations without floating-point inaccuracies.
- **Multi-User Data Scoping**: All transaction endpoints filter by authenticated user ID (`WHERE user_id = :id`) to prevent unauthorized cross-user access.

---

## 🚀 Local Development & Setup

### Option 1: Run with Docker Compose
```bash
docker-compose up --build
```

### Option 2: Run with Local Maven & PostgreSQL
```bash
# Configure application.properties with local PostgreSQL credentials
mvn spring-boot:run
```

---

## 🧪 Testing

```bash
mvn test
```

---

## ⚠️ Known Limitations

- **ADMIN Statistics Scope**: Administrative requests to `/api/statistics/summary` compute system-wide aggregated metrics on the backend. USER statistics remain strictly isolated to the requesting user.
```
