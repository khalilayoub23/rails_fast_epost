# Public Tracking API Documentation

## Overview
The Public Tracking API allows you to retrieve tracking information for packages without authentication. This is useful for mobile apps, third-party integrations, and customer-facing applications.

## Base URL
```
http://yourdomain.com/api/v1/public
```

## Endpoints

### Track Package
Retrieve tracking information for a specific package by barcode.

**Endpoint:** `GET /track/:barcode`

**Parameters:**
- `barcode` (string, required) - The tracking number/barcode of the package (case-insensitive)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/public/track/BC1000000"
```

**Example Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "barcode": "BC1000000",
    "status": "in_transit",
    "status_label": "In Transit",
    "package_type": "document",
    "delivery_time": "2025-11-20T10:00:00Z",
    "pickup_address": {
      "street": "123 Main St",
      "city": "Tel Aviv",
      "state": "IL",
      "country": "Israel",
      "postal_code": "12345"
    },
    "delivery_address": {
      "street": "456 Oak Ave",
      "city": "Jerusalem",
      "state": "IL",
      "country": "Israel",
      "postal_code": "67890"
    },
    "carrier": {
      "id": 1,
      "name": "Express Delivery Co"
    },
    "created_at": "2025-11-15T08:00:00Z",
    "updated_at": "2025-11-15T14:30:00Z",
    "estimated_delivery": "2025-11-20T10:00:00Z"
  }
}
```

**Example Error Response (404 Not Found):**
```json
{
  "success": false,
  "error": "Tracking number not found",
  "message": "The tracking number 'BC9999999' could not be found in our system."
}
```

**Example Error Response (500 Internal Server Error):**
```json
{
  "success": false,
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

## Status Codes
- `200 OK` - Successfully retrieved tracking information
- `404 Not Found` - Tracking number does not exist
- `500 Internal Server Error` - Server error occurred

## Package Status Values
The `status` field can have the following values:
- `pending` - Package is awaiting pickup
- `picked_up` - Package has been picked up
- `in_transit` - Package is on the way
- `out_for_delivery` - Package is out for delivery
- `delivered` - Package has been delivered
- `cancelled` - Delivery was cancelled
- `returned` - Package was returned to sender

## Rate Limiting
Currently no rate limiting is applied, but it may be implemented in future versions.

## CORS
The API supports CORS for all origins in development. In production, configure allowed origins in `config/initializers/cors.rb`.

## Integration Examples

### JavaScript/Fetch
```javascript
fetch('http://localhost:3000/api/v1/public/track/BC1000000')
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      console.log('Package Status:', data.data.status_label);
      console.log('Estimated Delivery:', data.data.estimated_delivery);
    } else {
      console.error('Error:', data.message);
    }
  });
```

### Python/Requests
```python
import requests

response = requests.get('http://localhost:3000/api/v1/public/track/BC1000000')
data = response.json()

if data['success']:
    print(f"Package Status: {data['data']['status_label']}")
    print(f"Carrier: {data['data']['carrier']['name']}")
else:
    print(f"Error: {data['message']}")
```

### cURL
```bash
# Basic request
curl http://localhost:3000/api/v1/public/track/BC1000000

# With formatted output
curl -s http://localhost:3000/api/v1/public/track/BC1000000 | python3 -m json.tool
```

### Mobile Apps (React Native)
```javascript
const trackPackage = async (barcode) => {
  try {
    const response = await fetch(
      `https://yourdomain.com/api/v1/public/track/${barcode}`
    );
    const data = await response.json();
    
    if (data.success) {
      return data.data;
    } else {
      throw new Error(data.message);
    }
  } catch (error) {
    console.error('Tracking error:', error);
    return null;
  }
};

// Usage
trackPackage('BC1000000').then(trackingInfo => {
  if (trackingInfo) {
    console.log('Status:', trackingInfo.status_label);
  }
});
```

## Notes
- Barcodes are case-insensitive (automatically converted to uppercase)
- Leading/trailing whitespace is automatically trimmed
- No authentication required
- Response times are typically under 100ms
