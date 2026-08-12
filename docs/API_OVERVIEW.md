# Expense Tracker — API Specification & Overview

This document describes the RESTful API endpoints exposed by the Spring Boot backend service, consumed by the Expense Tracker Flutter client application.

---

## 🌐 Base URL & Header Requirements

- **Production API Base URL**: `https://expense-tracker-api-x8nw.onrender.com`
- **Content-Type**: `application/json`
- **Authorization Header**: `Authorization: Bearer <JWT_TOKEN>` (required for all endpoints except Auth)

---

## 🔐 1. Authentication Endpoints

### Register User
- **Endpoint**: `POST /api/auth/register`
- **Access**: Public
- **Request Body**:
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "Password123!"
}
```
- **Response (`200 OK` or `201 Created`)**:
```json
{
  "id": 42,
  "name": "Jane Doe",
  "email": "jane@example.com",
  "role": "USER"
}
```

### Login User
- **Endpoint**: `POST /api/auth/login`
- **Access**: Public
- **Request Body**:
```json
{
  "email": "jane@example.com",
  "password": "Password123!"
}
```
- **Response (`200 OK`)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.REDACTED_JWT_TOKEN",
  "user": {
    "id": 42,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "USER"
  }
}
```

---

## 🏷️ 2. Category Endpoints

### List Categories
- **Endpoint**: `GET /api/categories`
- **Access**: `USER` or `ADMIN`
- **Response (`200 OK`)**:
```json
[
  { "id": 1, "name": "Food" },
  { "id": 2, "name": "Transport" },
  { "id": 3, "name": "Housing" }
]
```

### Create Category
- **Endpoint**: `POST /api/categories`
- **Access**: `ADMIN` only (returns `403 Forbidden` for `USER`)
- **Request Body**: `{ "name": "Utilities" }`
- **Response (`201 Created`)**: `{ "id": 4, "name": "Utilities" }`

### Update Category
- **Endpoint**: `PUT /api/categories/{id}`
- **Access**: `ADMIN` only
- **Request Body**: `{ "name": "Bills & Utilities" }`
- **Response (`200 OK`)**: `{ "id": 4, "name": "Bills & Utilities" }`

### Delete Category
- **Endpoint**: `DELETE /api/categories/{id}`
- **Access**: `ADMIN` only
- **Response (`204 No Content`)**

---

## 💸 3. Transaction Endpoints

### List Transactions (Paginated)
- **Endpoint**: `GET /api/transactions?page=0&size=10&sort=date,desc`
- **Access**: Authenticated User
- **Response (`200 OK`)**:
```json
{
  "content": [
    {
      "id": 101,
      "description": "Weekly Groceries",
      "amount": 145.50,
      "date": "2026-08-13",
      "type": "EXPENSE",
      "category": { "id": 1, "name": "Food" },
      "notes": "Supermarket trip"
    }
  ],
  "pageable": { "pageNumber": 0, "pageSize": 10 },
  "totalPages": 1,
  "totalElements": 1,
  "last": true
}
```

### Search / Filter Transactions
- **Endpoint**: `GET /api/transactions/search`
- **Query Parameters**:
  - `type`: `INCOME` or `EXPENSE` (optional)
  - `categoryId`: integer (optional)
  - `startDate`: `YYYY-MM-DD` (optional)
  - `endDate`: `YYYY-MM-DD` (optional)
  - `minAmount`: numeric (optional)
  - `maxAmount`: numeric (optional)
  - `page`: integer (default `0`)
  - `size`: integer (default `10`)

### Create Transaction
- **Endpoint**: `POST /api/transactions`
- **Access**: Authenticated User
- **Request Body**:
```json
{
  "description": "Salary Deposit",
  "amount": 3500.00,
  "date": "2026-08-13",
  "type": "INCOME",
  "categoryId": 1,
  "notes": "Monthly payroll"
}
```

### Update Transaction
- **Endpoint**: `PUT /api/transactions/{id}`
- **Access**: Authenticated Owner

### Delete Transaction
- **Endpoint**: `DELETE /api/transactions/{id}`
- **Access**: Authenticated Owner (`204 No Content`)

---

## 📊 4. Statistics Endpoints

### Get Statistics Summary
- **Endpoint**: `GET /api/statistics/summary`
- **Access**: Authenticated User
- **Response (`200 OK`)**:
```json
{
  "income": 3500.00,
  "expenses": 450.00,
  "balance": 3050.00
}
```

---

## ⚠️ Error Responses & HTTP Status Meanings

| Status Code | Meaning | Cause |
| :--- | :--- | :--- |
| `200 OK` | Success | Request succeeded. |
| `201 Created` | Resource Created | Transaction or Category created. |
| `204 No Content` | Deleted | Resource successfully removed. |
| `400 Bad Request` | Validation Error | Blank name, negative amount, or invalid date. |
| `401 Unauthorized` | Invalid / Expired Token | Missing or expired Bearer token. |
| `403 Forbidden` | Access Denied | `USER` role attempted ADMIN category action. |
| `404 Not Found` | Resource Missing | Non-existent transaction ID or wrong owner. |
| `500 Server Error` | Backend Failure | Internal server exception. |

### Standard Error Response Format
```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Transaction description cannot be blank",
  "timestamp": "2026-08-13T01:00:00Z"
}
```
