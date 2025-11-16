# CRM & Social Media Integration Guide

## 📱 Social Media Links - Landing Page

### Configuration
Social media links are now **fully functional** and configured in:
- **Config File**: `config/social_media.yml`
- **Initializer**: `config/initializers/social_media.rb`

### Current URLs (Update These!)
```yaml
facebook: "https://facebook.com/fastepost"
twitter: "https://twitter.com/fastepost"
linkedin: "https://linkedin.com/company/fastepost"
whatsapp: "https://wa.me/972123456789"  # ⚠️ Replace with your WhatsApp Business number
telegram: "https://t.me/fastepost"
instagram: "https://instagram.com/fastepost"
tiktok: "https://tiktok.com/@fastepost"
```

### How to Update
1. Edit `config/social_media.yml`
2. Replace placeholder URLs with your actual social media profiles
3. Leave blank to hide icons: `facebook: ""`
4. Restart server to apply changes

### Features
- ✅ Dynamic visibility (icons only show if URL is configured)
- ✅ Opens in new tab with security attributes
- ✅ "Chat Now" button links to WhatsApp if configured
- ✅ Falls back to contact page if WhatsApp not set

---

## 🔗 CRM Integration Points

### Where CRMs Connect to the System

#### 1. **HubSpot CRM** (Free Tier)
**Webhook Endpoint**: `POST /api/v1/integrations/hubspot`

**Authentication**: 
- Header: `X-HubSpot-Signature`
- Verified against: `ENV['HUBSPOT_APP_SECRET']`

**Setup Instructions**:
1. Go to HubSpot Settings → Integrations → Private Apps
2. Create a new app and copy the App Secret
3. Add to your `.env` file:
   ```bash
   HUBSPOT_APP_SECRET=your_secret_here
   ```
4. Configure webhook in HubSpot to POST to:
   ```
   https://yourdomain.com/api/v1/integrations/hubspot
   ```

**What it does**:
- Syncs contacts to `Customer` model
- Tracks deals and opportunities
- Logs all events in `integration_events` table
- Links to existing tasks via barcode matching

**Controller**: `app/controllers/api/v1/integrations/hubspot_controller.rb`
**Service**: `app/services/integrations/hubspot_service.rb`

---

#### 2. **Odoo CRM** (Open Source)
**Webhook Endpoint**: `POST /api/v1/integrations/odoo`

**Authentication**:
- Header: `X-Odoo-Api-Key`
- Verified against: `ENV['ODOO_API_KEY']`

**Setup Instructions**:
1. Generate a secure API key:
   ```bash
   openssl rand -hex 32
   ```
2. Add to your `.env` file:
   ```bash
   ODOO_API_KEY=your_generated_key_here
   ```
3. In Odoo, create an Automated Action:
   - **Model**: `res.partner` or `crm.lead`
   - **Trigger**: On Create/Update
   - **Action**: Execute Python Code
   - **Code**:
     ```python
     import requests
     import json
     
     url = 'https://yourdomain.com/api/v1/integrations/odoo'
     headers = {
         'Content-Type': 'application/json',
         'X-Odoo-Api-Key': 'your_generated_key_here'
     }
     
     data = {
         'id': record.id,
         'name': record.name,
         'email': record.email,
         'phone': record.phone,
         'model': 'res.partner'
     }
     
     requests.post(url, headers=headers, json=data)
     ```

**What it does**:
- Syncs contacts from `res.partner` model
- Syncs leads/opportunities from `crm.lead` model
- Creates `Customer` records automatically
- Links notes to `Remarks` in tasks
- Full event logging

**Controller**: `app/controllers/api/v1/integrations/odoo_controller.rb`
**Service**: `app/services/integrations/odoo_service.rb`

---

#### 3. **Social Media Integrations** (WhatsApp, Facebook, Instagram, Telegram, TikTok)

These are webhook receivers for customer inquiries and messages from social platforms.

##### **WhatsApp Business API**
**Endpoint**: 
- `GET /api/v1/integrations/whatsapp` (verification)
- `POST /api/v1/integrations/whatsapp` (receive messages)

**Authentication**:
```bash
META_VERIFY_TOKEN=your_verification_token
META_APP_SECRET=your_app_secret
```

**Setup**: Configure in Meta Business Suite (Facebook for Developers)

##### **Facebook Messenger**
**Endpoint**:
- `GET /api/v1/integrations/facebook` (verification)
- `POST /api/v1/integrations/facebook` (receive messages)

**Authentication**: Same as WhatsApp (Meta platform)

##### **Instagram Direct**
**Endpoint**:
- `GET /api/v1/integrations/instagram` (verification)
- `POST /api/v1/integrations/instagram` (receive messages)

**Authentication**: Same as WhatsApp (Meta platform)

##### **Telegram Bot**
**Endpoint**: `POST /api/v1/integrations/telegram`

**Authentication**:
```bash
TELEGRAM_SECRET_TOKEN=your_bot_secret
```

**Setup**: Configure webhook in Telegram Bot API

##### **TikTok**
**Endpoint**: `POST /api/v1/integrations/tiktok`

**Setup**: Configure in TikTok for Business Developer Portal

**Controller Files**:
- `app/controllers/api/v1/integrations/whatsapp_controller.rb`
- `app/controllers/api/v1/integrations/facebook_controller.rb`
- `app/controllers/api/v1/integrations/instagram_controller.rb`
- `app/controllers/api/v1/integrations/telegram_controller.rb`
- `app/controllers/api/v1/integrations/tiktok_controller.rb`

**Service Files**:
- `app/services/integrations/whatsapp_service.rb`
- `app/services/integrations/facebook_service.rb`
- `app/services/integrations/instagram_service.rb`
- `app/services/integrations/telegram_service.rb`
- `app/services/integrations/tiktok_service.rb`

---

## 🎛️ CRM Dashboard

**Access**: `/admin/crm` (Admin users only)

**Features**:
- Real-time statistics for HubSpot and Odoo
- Success rate monitoring
- Last 24-hour activity tracking
- Recent integration events log (20 most recent)
- Customer sync statistics
- Setup instructions with webhook URLs

**View File**: `app/views/admin/crm/index.html.erb`
**Controller**: `app/controllers/admin/crm_controller.rb`

---

## 📊 Database Management Dashboard

**Access**: `/admin/database` (Admin users only)

**Features**:
- Export data (SQL, CSV, JSON)
- Import CSV files
- Create SQL backups with `pg_dump`
- View database statistics
- Per-table record counts and sizes
- Download backup files

**View File**: `app/views/admin/database/index.html.erb`
**Controller**: `app/controllers/admin/database_controller.rb`

---

## 🔄 Integration Flow

```
Social Media / CRM → Webhook → FastEpost API → Service → Database
                                                            ↓
                                                       Integration Event Log
                                                            ↓
                                                       Customer Record
                                                            ↓
                                                        Task (if matched)
```

### Data Models Involved:
1. **IntegrationEvent** - Logs all webhook calls
2. **Customer** - Stores synced contact data
3. **Task** - Links to customer and integrations via barcode
4. **Remark** - Stores notes and comments from CRM

---

## 🔐 Required Environment Variables

Create a `.env` file in the project root with:

```bash
# HubSpot CRM
HUBSPOT_APP_SECRET=your_hubspot_app_secret

# Odoo CRM
ODOO_API_KEY=your_secure_api_key

# Meta Platforms (WhatsApp, Facebook, Instagram)
META_VERIFY_TOKEN=your_meta_verify_token
META_APP_SECRET=your_meta_app_secret

# Telegram
TELEGRAM_SECRET_TOKEN=your_telegram_bot_secret

# Note: TikTok integration may require additional credentials
```

---

## ✅ Testing Integrations

### Test HubSpot Webhook
```bash
curl -X POST https://yourdomain.com/api/v1/integrations/hubspot \
  -H "Content-Type: application/json" \
  -H "X-HubSpot-Signature: your_signature" \
  -d '{"email": "test@example.com", "firstname": "Test", "lastname": "User"}'
```

### Test Odoo Webhook
```bash
curl -X POST https://yourdomain.com/api/v1/integrations/odoo \
  -H "Content-Type: application/json" \
  -H "X-Odoo-Api-Key: your_api_key" \
  -d '{"id": 123, "name": "Test Customer", "email": "test@example.com", "model": "res.partner"}'
```

### Monitor Integration Events
1. Log in as admin
2. Navigate to `/admin/crm`
3. Check "Recent Integration Events" section
4. View success/failure rates

---

## 📝 Next Steps

1. **Update Social Media URLs** in `config/social_media.yml`
2. **Set up CRM webhooks** (HubSpot or Odoo) with proper environment variables
3. **Configure Meta platforms** for WhatsApp/Facebook/Instagram if needed
4. **Test integrations** using the CRM dashboard
5. **Monitor events** in the admin panel

---

## 🆘 Troubleshooting

**Social media icons not showing?**
- Check `config/social_media.yml` URLs are not empty
- Restart server after editing config

**CRM webhooks failing?**
- Verify environment variables are set
- Check authentication headers match configuration
- View error logs in `/admin/crm` dashboard
- Check `IntegrationEvent` table for detailed error messages

**Database exports not working?**
- Ensure admin user privileges
- Check file permissions on `tmp/backups/` directory
- Verify PostgreSQL is accessible for `pg_dump` commands
