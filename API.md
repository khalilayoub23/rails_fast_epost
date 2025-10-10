# Fast Epost 3 - API Documentation

## Authentication

Most web routes require authentication via Devise. API endpoints under `/api/v1` do NOT require authentication by default (for external integration use cases).

### Web Authentication
- **Sign In**: `POST /users/sign_in`
- **Sign Out**: `DELETE /users/sign_out`
- **Sign Up**: `POST /users/sign_up`
- **Password Reset**: `POST /users/password`

**Example Sign In**:
```bash
curl -X POST https://your-domain.com/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "password"
    }
  }'
```

## Base URL

```
Development: http://localhost:3000
Production: https://your-domain.com
```

## Response Format

All API responses follow this structure:

**Success Response**:
```json
{
  "data": { ... },
  "status": "success"
}
```

**Error Response**:
```json
{
  "errors": ["Error message 1", "Error message 2"],
  "status": "error"
}
```

## Endpoints

### Carriers

#### List All Carriers
```
GET /api/v1/carriers
```

**Response**:
```json
[
  {
    "id": 1,
    "name": "DHL Express",
    "email": "contact@dhl.com",
    "carrier_type": "express",
    "address": "123 Logistics Ave",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
]
```

#### Get Single Carrier
```
GET /api/v1/carriers/:id
```

#### Create Carrier
```
POST /api/v1/carriers
Content-Type: application/json

{
  "carrier": {
    "name": "New Carrier",
    "email": "info@carrier.com",
    "carrier_type": "express",
    "address": "123 Street"
  }
}
```

#### Update Carrier
```
PATCH /api/v1/carriers/:id
Content-Type: application/json

{
  "carrier": {
    "name": "Updated Name"
  }
}
```

#### Delete Carrier
```
DELETE /api/v1/carriers/:id
```

### Customers

#### List All Customers
```
GET /api/v1/customers
```

**Response**:
```json
[
  {
    "id": 1,
    "name": "Acme Corporation",
    "email": "orders@acme.com",
    "category": 0,
    "address": "100 Business Park Dr",
    "phones": ["+1-555-0101", "+1-555-0102"],
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

#### Create Customer
```
POST /api/v1/customers
Content-Type: application/json

{
  "customer": {
    "name": "New Customer",
    "email": "customer@example.com",
    "category": 0,
    "address": "123 Main St",
    "phones": ["+1-555-0100"]
  }
}
```

### Tasks

#### List All Tasks
```
GET /api/v1/tasks
```

**Response**:
```json
[
  {
    "id": 1,
    "customer_id": 1,
    "carrier_id": 1,
    "package_type": "Package",
    "start": "New York, NY",
    "target": "Los Angeles, CA",
    "status": "in_transit",
    "barcode": "TRACK123456",
    "delivery_time": "2025-01-15T10:00:00Z",
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

#### Create Task
```
POST /api/v1/tasks
Content-Type: application/json

{
  "task": {
    "customer_id": 1,
    "carrier_id": 1,
    "package_type": "Package",
    "start": "New York, NY",
    "target": "Los Angeles, CA",
    "status": "pending",
    "barcode": "TRACK123456"
  }
}
```

#### Update Task Status
```
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "status": "delivered"
  }
}
```

### Payments

#### Create Payment
```
POST /api/v1/payments
Content-Type: application/json

{
  "provider": "stripe",
  "amount_cents": 10000,
  "currency": "USD",
  "task_id": 1,
  "metadata": {
    "customer_email": "customer@example.com"
  }
}
```

**Providers**: `local`, `stripe`

**Response**:
```json
{
  "id": 1,
  "provider": "stripe",
  "amount_cents": 10000,
  "currency": "USD",
  "gateway_status": "created",
  "payment_url": "https://checkout.stripe.com/...",
  "external_id": "pi_xxxxx",
  "created_at": "2025-01-01T00:00:00Z"
}
```

#### Refund Payment
```
POST /api/v1/payments/:id/refund
Content-Type: application/json

{
  "amount_cents": 10000,
  "reason": "Customer request"
}
```

#### Capture Payment
```
POST /api/v1/payments/:id/capture
```

#### Cancel Payment
```
POST /api/v1/payments/:id/cancel
```

#### Sync Payment Status
```
POST /api/v1/payments/:id/sync
```

**Note**: This fetches latest status from the payment provider.

### Webhooks

All webhook endpoints are under `/api/v1/integrations/`.

#### Stripe Webhook
```
POST /api/v1/payments/stripe/webhook
X-Stripe-Signature: stripe_signature_here
Content-Type: application/json

{...stripe event payload...}
```

#### Telegram Webhook
```
POST /api/v1/integrations/telegram
X-Telegram-Bot-Api-Secret-Token: your_secret_token
Content-Type: application/json

{
  "update_id": 123456789,
  "message": {
    "message_id": 1,
    "from": {...},
    "text": "Hello"
  }
}
```

#### Meta (Facebook/Instagram/WhatsApp) Webhook

**Verification (GET)**:
```
GET /api/v1/integrations/whatsapp?hub.mode=subscribe&hub.verify_token=your_token&hub.challenge=challenge_string
```

**Receive (POST)**:
```
POST /api/v1/integrations/whatsapp
X-Hub-Signature-256: sha256=signature
Content-Type: application/json

{...meta event payload...}
```

Same pattern for:
- `/api/v1/integrations/facebook`
- `/api/v1/integrations/instagram`

#### TikTok Webhook
```
POST /api/v1/integrations/tiktok
X-TikTok-Signature: hmac_signature
Content-Type: application/json

{...tiktok event payload...}
```

#### Generic Website Webhook
```
POST /api/v1/integrations/websites
X-Website-Secret: your_shared_secret
Content-Type: application/json

{...custom payload...}
```

## Status Codes

- `200 OK` - Success
- `201 Created` - Resource created successfully
- `204 No Content` - Success with no response body
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

## Rate Limiting

Currently no rate limiting is implemented. For production use, consider adding rack-attack or similar middleware.

## Pagination

Not currently implemented. All list endpoints return all records. For large datasets, consider adding kaminari or pagy gems.

## Testing

Use these test credentials after running `bin/rails db:seed`:

- **Admin**: admin@example.com / password
- **Manager**: manager@example.com / password
- **Viewer**: viewer@example.com / password

## Examples

### Create a complete workflow

```bash
# 1. Create a customer
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Test Customer",
      "email": "test@example.com",
      "category": 0,
      "address": "123 Test St",
      "phones": ["+1-555-0100"]
    }
  }'

# 2. Create a task
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "customer_id": 1,
      "carrier_id": 1,
      "package_type": "Package",
      "start": "New York",
      "target": "Boston",
      "status": "pending"
    }
  }'

# 3. Create a payment
curl -X POST http://localhost:3000/api/v1/payments \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "local",
    "amount_cents": 5000,
    "currency": "USD",
    "task_id": 1
  }'

# 4. Update task status
curl -X PATCH http://localhost:3000/api/v1/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "status": "delivered"
    }
  }'
```

## Support

For questions or issues, please refer to the README.md or open an issue on GitHub.
