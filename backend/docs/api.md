# StudyTodoList API Documentation (OpenAPI 3.0 Format)

## 1. Get Wallet Information & Transactions
- **Endpoint**: `GET /api/wallet`
- **Security**: Bearer Token (JWT) required in Authorization header.
- **Request Headers**:
  - `Authorization: Bearer <JWT_TOKEN>`
- **Response Success (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "wallet": {
        "id": "wallet_uuid",
        "userId": "user_uuid",
        "balance": 250,
        "createdAt": "2026-03-30T00:00:00.000Z",
        "updatedAt": "2026-03-30T00:00:00.000Z"
      },
      "transactions": [
        {
          "id": "tx_uuid",
          "walletId": "wallet_uuid",
          "amount": 50,
          "type": "EARNED",
          "description": "Completed task: Flutter PRM393",
          "referenceId": "task_uuid",
          "createdAt": "2026-03-30T12:00:00.000Z"
        }
      ]
    },
    "error": null
  }
  ```
- **Response Failure (401 Unauthorized)**:
  ```json
  {
    "success": false,
    "data": null,
    "error": "Unauthorized"
  }
  ```

---

## 2. Create Order / Purchase Product
- **Endpoint**: `POST /api/orders`
- **Security**: Bearer Token (JWT) required in Authorization header.
- **Request Headers**:
  - `Authorization: Bearer <JWT_TOKEN>`
  - `Content-Type: application/json`
- **Request Body Payload**:
  ```json
  {
    "productId": "product_uuid",
    "quantity": 1
  }
  ```
- **Response Success (201 Created)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "order_uuid",
      "userId": "user_uuid",
      "totalAmount": 100,
      "status": "completed",
      "items": [
        {
          "id": "order_item_uuid",
          "orderId": "order_uuid",
          "productId": "product_uuid",
          "quantity": 1,
          "price": 100
        }
      ],
      "createdAt": "2026-03-30T14:00:00.000Z"
    },
    "error": null
  }
  ```
- **Response Failure (400 Bad Request / Insufficient Tokens)**:
  ```json
  {
    "success": false,
    "data": null,
    "error": "Insufficient token balance"
  }
  ```
