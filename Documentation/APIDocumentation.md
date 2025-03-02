# API Documentation

## Overview

Payslip Max interacts with a backend API to fetch and update data. This document outlines the API endpoints used by the application, the expected request and response formats, and how API interactions are handled in the codebase.

## Base URL

The base URL for all API requests is:

```
https://api.payslipmax.com/v1
```

This can be configured in the application's environment settings.

## Authentication

Most API endpoints require authentication. Authentication is handled using JWT (JSON Web Tokens).

### Login

**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "string",
  "user": {
    "id": "string",
    "username": "string",
    "email": "string",
    "firstName": "string",
    "lastName": "string"
  }
}
```

### Logout

**Endpoint:** `POST /auth/logout`

**Request:**
```json
{
  "token": "string"
}
```

**Response:**
```json
{
  "success": true
}
```

## Payslips

### Get Payslips

**Endpoint:** `GET /payslips`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "payslips": [
    {
      "id": "string",
      "date": "string (ISO 8601)",
      "grossSalary": "number",
      "netSalary": "number",
      "deductions": [
        {
          "id": "string",
          "name": "string",
          "amount": "number",
          "type": "string"
        }
      ]
    }
  ]
}
```

### Get Payslip by ID

**Endpoint:** `GET /payslips/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": "string",
  "date": "string (ISO 8601)",
  "grossSalary": "number",
  "netSalary": "number",
  "deductions": [
    {
      "id": "string",
      "name": "string",
      "amount": "number",
      "type": "string"
    }
  ]
}
```

## User Profile

### Get User Profile

**Endpoint:** `GET /profile`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string",
  "address": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "country": "string"
  }
}
```

### Update User Profile

**Endpoint:** `PUT /profile`

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string",
  "address": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "country": "string"
  }
}
```

**Response:**
```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string",
  "address": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "country": "string"
  }
}
```

## Error Handling

API errors are returned with appropriate HTTP status codes and error messages.

**Error Response:**
```json
{
  "error": {
    "code": "string",
    "message": "string"
  }
}
```

Common error codes:
- `401`: Unauthorized - Invalid or expired token
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource not found
- `422`: Unprocessable Entity - Invalid request data
- `500`: Internal Server Error - Server-side error

## Implementation in Codebase

API interactions in Payslip Max are handled through the `NetworkService` class, which provides methods for making HTTP requests.

```swift
protocol NetworkServiceProtocol: ServiceProtocol {
    func get<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void)
    func post<T: Decodable>(url: URL, body: [String: Any], completion: @escaping (Result<T, Error>) -> Void)
    func put<T: Decodable>(url: URL, body: [String: Any], completion: @escaping (Result<T, Error>) -> Void)
    func delete<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void)
}
```

Higher-level services, such as `AuthService` and `DataService`, use the `NetworkService` to interact with specific API endpoints.

```swift
class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/auth/login")!
        let body = ["username": username, "password": password]
        
        networkService.post(url: url, body: body) { (result: Result<LoginResponse, Error>) in
            switch result {
            case .success(let response):
                // Save token and return user
                TokenManager.shared.saveToken(response.token)
                completion(.success(response.user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Other auth methods...
}
```

## API Models

API models in Payslip Max are defined as Swift structs that conform to the `Codable` protocol for easy JSON serialization and deserialization.

```swift
struct User: Codable {
    let id: String
    let username: String
    let email: String
    let firstName: String
    let lastName: String
}

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct Payslip: Codable {
    let id: String
    let date: Date
    let grossSalary: Double
    let netSalary: Double
    let deductions: [Deduction]
}

struct Deduction: Codable {
    let id: String
    let name: String
    let amount: Double
    let type: String
}
```

## Best Practices

When working with the API in Payslip Max, follow these best practices:

1. **Use the NetworkService**: Always use the `NetworkService` for API interactions rather than making direct HTTP requests.
2. **Handle Errors**: Always handle API errors appropriately and provide meaningful feedback to the user.
3. **Parse Responses**: Use Swift's `Codable` protocol to parse API responses into model objects.
4. **Validate Input**: Validate user input before sending it to the API.
5. **Use Proper HTTP Methods**: Use the appropriate HTTP method for each API interaction (GET, POST, PUT, DELETE).
6. **Secure Sensitive Data**: Never store sensitive data, such as passwords or tokens, in plain text.
7. **Test API Interactions**: Write tests for API interactions using mock responses.
8. **Document API Changes**: Document any changes to the API contract to ensure all team members are aware of the changes.
