# Odoo CRM Setup Guide - Primary CRM System

## 🎯 Why Odoo?

- ✅ **100% Free** - No subscription fees, ever
- ✅ **Open Source** - Full control and customization
- ✅ **Self-Hosted** - Your data stays with you
- ✅ **Complete CRM** - Contacts, leads, opportunities, pipelines
- ✅ **Extensible** - Part of full ERP suite if you need more

---

## 📋 Prerequisites

1. Odoo instance (Community Edition) installed and running
2. Admin access to your FastEpost Rails application
3. Ability to set environment variables

---

## 🚀 Quick Setup (5 Steps)

### Step 1: Generate API Key

Generate a secure API key for webhook authentication:

```bash
openssl rand -hex 32
```

Copy the output (example: `a1b2c3d4e5f6...`)

### Step 2: Configure Environment Variable

Add to your `.env` file:

```bash
ODOO_API_KEY=paste_your_generated_key_here
```

Restart your Rails server to load the new variable.

### Step 3: Get Your Webhook URL

Your webhook endpoint is:
```
https://yourdomain.com/api/v1/integrations/odoo
```

For local testing:
```
http://localhost:3000/api/v1/integrations/odoo
```

### Step 4: Create Automated Action in Odoo

1. **Go to Odoo**: Settings → Technical → Automation → Automated Actions
2. **Click "Create"**
3. **Fill in the form**:

**For Contact Sync (res.partner):**

```
Name: Sync Contact to FastEpost
Model: Contact (res.partner)
Trigger: On Creation & Update
Action To Do: Execute Python Code
```

**Python Code:**
```python
import requests
import json

# FastEpost webhook URL
url = 'https://yourdomain.com/api/v1/integrations/odoo'

# Your API key from .env file
api_key = 'paste_your_api_key_here'

# Prepare headers
headers = {
    'Content-Type': 'application/json',
    'X-Odoo-Api-Key': api_key
}

# Prepare contact data
data = {
    'id': record.id,
    'model': 'res.partner',
    'name': record.name or '',
    'email': record.email or '',
    'phone': record.phone or record.mobile or '',
    'street': record.street or '',
    'city': record.city or '',
    'zip': record.zip or '',
    'country': record.country_id.name if record.country_id else '',
}

# Send to FastEpost
try:
    response = requests.post(url, headers=headers, json=data, timeout=10)
    if response.status_code == 200:
        log('Contact synced successfully')
    else:
        log('Sync failed: %s' % response.text)
except Exception as e:
    log('Error syncing contact: %s' % str(e))
```

**For Lead/Opportunity Sync (crm.lead):**

Create another Automated Action:

```
Name: Sync Lead to FastEpost
Model: Lead/Opportunity (crm.lead)
Trigger: On Creation & Update
Action To Do: Execute Python Code
```

**Python Code:**
```python
import requests
import json

url = 'https://yourdomain.com/api/v1/integrations/odoo'
api_key = 'paste_your_api_key_here'

headers = {
    'Content-Type': 'application/json',
    'X-Odoo-Api-Key': api_key
}

data = {
    'id': record.id,
    'model': 'crm.lead',
    'name': record.name or '',
    'email': record.email_from or '',
    'phone': record.phone or record.mobile or '',
    'description': record.description or '',
    'expected_revenue': float(record.expected_revenue) if record.expected_revenue else 0,
    'probability': record.probability or 0,
    'stage': record.stage_id.name if record.stage_id else '',
    'partner_name': record.partner_name or '',
}

try:
    response = requests.post(url, headers=headers, json=data, timeout=10)
    if response.status_code == 200:
        log('Lead synced successfully')
    else:
        log('Sync failed: %s' % response.text)
except Exception as e:
    log('Error syncing lead: %s' % str(e))
```

### Step 5: Test the Integration

1. **Create a test contact** in Odoo
2. **Check FastEpost**:
   - Log in as admin
   - Go to `/admin/crm`
   - Look for "Odoo CRM" statistics
   - Check "Recent Integration Events"

3. **Verify data synced**:
   - Go to `/customers`
   - Look for your test contact

---

## 📊 Monitor Integration

### CRM Dashboard
Access: `/admin/crm`

You'll see:
- **Total Events**: All webhook calls received
- **Last 24 Hours**: Recent activity
- **Success Rate**: Percentage of successful syncs
- **Last Event**: Most recent sync timestamp
- **Recent Integration Events**: Detailed log of last 20 events

### Check Integration Logs

All webhook calls are logged in the `integration_events` table:

```ruby
# Rails console
IntegrationEvent.where("payload->>'source' = 'odoo'").last(10)
```

---

## 🔍 What Gets Synced?

### From Odoo Contacts (res.partner) → FastEpost Customers

- Name
- Email
- Phone
- Address (street, city, zip, country)
- Company info
- Notes

### From Odoo Leads (crm.lead) → FastEpost Tasks & Remarks

- Lead name → Task title
- Description → Remarks
- Expected revenue
- Probability
- Stage/pipeline info
- Contact details

---

## 🛠️ Troubleshooting

### Issue: "403 Forbidden" Response

**Cause**: API key mismatch

**Fix**: 
1. Verify API key in `.env` matches key in Odoo automation
2. Restart Rails server after updating `.env`
3. Check for typos or extra spaces

### Issue: "Connection Refused"

**Cause**: Can't reach your FastEpost server

**Fix**:
1. Ensure FastEpost is running and accessible
2. For local testing, use ngrok or expose port
3. Check firewall rules

### Issue: "No events showing up"

**Cause**: Automation not triggering

**Fix**:
1. Verify Automated Action is active in Odoo
2. Check Odoo logs for Python errors
3. Manually trigger by creating/updating a contact
4. Check Odoo technical settings → Scheduled Actions

### Issue: Data not appearing in Customers

**Cause**: Email or name missing

**Fix**:
- Ensure contacts have at least email or name
- Check validation rules in Customer model
- View integration_events for error messages

---

## 🔐 Security Best Practices

1. **Use HTTPS** in production (not http://)
2. **Keep API key secret** - Never commit to git
3. **Rotate API key** periodically
4. **Monitor failed attempts** in CRM dashboard
5. **Set up IP whitelist** if possible

---

## 📈 Advanced: Bidirectional Sync

Want to sync changes FROM FastEpost TO Odoo?

You can use Odoo's API to update records:

```ruby
# In FastEpost, create a service
class OdooSyncService
  def self.update_contact(customer)
    odoo_url = ENV['ODOO_URL']
    db = ENV['ODOO_DB']
    username = ENV['ODOO_USERNAME']
    password = ENV['ODOO_PASSWORD']
    
    # Authenticate and update via XML-RPC
    # (Implementation details in Odoo API docs)
  end
end
```

---

## 🎓 Learning Resources

- **Odoo Documentation**: https://www.odoo.com/documentation
- **Odoo API**: https://www.odoo.com/documentation/16.0/developer/api.html
- **Automated Actions**: Settings → Technical → Automation
- **Odoo Community**: https://www.odoo.com/forum

---

## ✅ Quick Checklist

- [ ] Odoo installed and running
- [ ] API key generated
- [ ] Environment variable set in `.env`
- [ ] Rails server restarted
- [ ] Automated Actions created in Odoo
- [ ] Test contact created
- [ ] Data visible in `/admin/crm`
- [ ] Customer record created in `/customers`

---

## 🚀 Next Steps

1. **Configure your real Odoo instance** (replace localhost URLs)
2. **Set up SSL/HTTPS** for production
3. **Create automation for both contacts and leads**
4. **Monitor the `/admin/crm` dashboard regularly
5. **Consider HubSpot later** if you need marketing automation

---

## 💡 Need Help?

- Check integration logs: `/admin/crm`
- View detailed events in Rails console
- Test with curl to verify webhook works
- Check Odoo system logs for automation errors

**Note**: HubSpot integration is available and ready if you need it later. Just set `HUBSPOT_APP_SECRET` in your `.env` file and follow similar webhook setup in HubSpot.
