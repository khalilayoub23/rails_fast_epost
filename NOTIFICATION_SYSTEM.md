# Notification System Documentation

## Overview
The Notification System provides centralized email notification handling for task-related events in the FastePost delivery platform. It sends automated notifications to customers, messengers, senders, and administrators at key points in the delivery lifecycle.

## Architecture

### Components
1. **NotificationService** (`app/services/notification_service.rb`)
   - Central service for triggering notifications
   - Handles error logging and graceful failures
   - Coordinates with TaskMailer for email delivery

2. **TaskMailer** (`app/mailers/task_mailer.rb`)
   - Action Mailer class for email generation
   - 13 distinct email types for different scenarios
   - Includes HTML templates with responsive design

3. **Email Templates** (`app/views/task_mailer/`)
   - Professional HTML email templates
   - Responsive design with inline CSS
   - Branded with FastePost styling

4. **Model Integration** (`app/models/task.rb`)
   - Automatic notifications via Active Record callbacks
   - State machine integration with AASM
   - Status change tracking

## Notification Types

### 1. Task Assignment (`notify_task_assigned`)
**Triggered:** When a messenger is assigned to a task
**Recipients:** Messenger
**Template:** `task_assigned.html.erb`
**Contains:**
- Task tracking number
- Customer information
- Pickup and delivery addresses
- Priority level
- Scheduled pickup time (if set)

### 2. Status Change (`notify_status_changed`)
**Triggered:** When task status changes
**Recipients:** Customer, Messenger, Sender
**Templates:** 
- `status_changed.html.erb` (Customer)
- `messenger_status_update.html.erb` (Messenger)
- `sender_notification.html.erb` (Sender)
**Contains:**
- Old status → New status flow
- Tracking number
- Timestamp of change
- Status-specific messaging

### 3. Delivery Complete (`notify_delivery_complete`)
**Triggered:** When task is successfully delivered
**Recipients:** Customer, Sender, Messenger
**Templates:**
- `delivery_complete.html.erb` (Customer)
- `sender_delivery_complete.html.erb` (Sender)
- `messenger_delivery_complete.html.erb` (Messenger)
**Contains:**
- Delivery confirmation
- Messenger name
- Delivery timestamp
- Recipient signature status

### 4. Pickup Request (`notify_pickup_requested`)
**Triggered:** When pickup is requested
**Recipients:** Messenger
**Template:** `pickup_requested.html.erb`
**Contains:**
- Sender information and contact
- Pickup address
- Scheduled pickup time
- Delivery address
- Urgency indicators

### 5. Delivery Failed (`notify_delivery_failed`)
**Triggered:** When delivery attempt fails
**Recipients:** Customer, Sender, Admin
**Templates:**
- `delivery_failed.html.erb` (Customer)
- `sender_delivery_failed.html.erb` (Sender)
- `admin_delivery_alert.html.erb` (Admin)
**Contains:**
- Failure reason/code
- Attempted delivery time
- Next steps for resolution
- Admin alert with full details

### 6. Location Update Reminder (`notify_location_update_requested`)
**Triggered:** Manually or via scheduled job
**Recipients:** Messenger
**Template:** `location_update_reminder.html.erb`
**Contains:**
- Reminder to update location
- Benefits of location updates
- Call to action

### 7. Pending Tasks Alert (`notify_available_messengers_about_pending_tasks`)
**Triggered:** When tasks are available for pickup
**Recipients:** Available messengers
**Template:** `pending_tasks_alert.html.erb`
**Contains:**
- Number of available tasks
- List of tasks with addresses
- Priority indicators
- Call to action to view tasks

## Usage Examples

### Basic Notification Sending

```ruby
# Notify messenger about task assignment
task = Task.find(123)
NotificationService.notify_task_assigned(task)

# Notify all parties about status change
NotificationService.notify_status_changed(task, "pending")

# Notify about successful delivery
NotificationService.notify_delivery_complete(task)

# Notify about failed delivery
NotificationService.notify_delivery_failed(task)
```

### Automatic Notifications (via Task Model)

```ruby
# Creating a task with messenger automatically sends assignment notification
task = Task.create!(
  customer: customer,
  messenger: messenger,
  barcode: "TASK-12345",
  # ... other attributes
)
# → Automatically triggers NotificationService.notify_task_assigned(task)

# Changing status triggers notifications
task.ship!
# → Triggers notify_customer_shipped → NotificationService.notify_status_changed

task.deliver!
# → Triggers notify_customer_delivered → NotificationService.notify_delivery_complete

task.mark_failed!
# → Triggers notify_customer_failed → NotificationService.notify_delivery_failed
```

### Bulk Notifications

```ruby
# Alert all available messengers about pending tasks
pending_tasks = Task.where(status: :pending)
available_messengers = Messenger.where(status: :available)

available_messengers.each do |messenger|
  NotificationService.notify_available_messengers_about_pending_tasks(
    messenger,
    pending_tasks
  )
end
```

## Configuration

### Development Environment
```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

Emails open automatically in browser using `letter_opener` gem.

### Production Environment
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              ENV['SMTP_ADDRESS'],
  port:                 587,
  domain:               ENV['SMTP_DOMAIN'],
  user_name:            ENV['SMTP_USERNAME'],
  password:             ENV['SMTP_PASSWORD'],
  authentication:       'plain',
  enable_starttls_auto: true
}
```

### Environment Variables
```bash
# .env
SMTP_ADDRESS=smtp.gmail.com
SMTP_DOMAIN=fastepost.com
SMTP_USERNAME=your-email@fastepost.com
SMTP_PASSWORD=your-app-specific-password
```

## Error Handling

All notification methods include error handling:
- Exceptions are caught and logged
- Failed notifications don't break the application flow
- Errors are logged with context for debugging

```ruby
def notify_task_assigned(task)
  # ... notification logic
rescue => e
  Rails.logger.error("[NotificationService] Failed to send task_assigned: #{e.message}")
  Rails.logger.error(e.backtrace.join("\n"))
end
```

## Testing

### Running Tests
```bash
# Test NotificationService
bin/rails test test/services/notification_service_test.rb

# Test TaskMailer
bin/rails test test/mailers/task_mailer_test.rb

# Test all notification-related tests
bin/rails test test/services/ test/mailers/
```

### Test Coverage
- ✅ Each notification type has dedicated tests
- ✅ Email content validation (subject, recipients, body)
- ✅ Error handling and graceful failures
- ✅ Missing data scenarios (nil messenger, sender, etc.)
- ✅ Email template structure validation
- ✅ Bulk notification testing

## Email Template Customization

### Template Structure
All email templates follow this structure:
```html
<!DOCTYPE html>
<html>
<head>
  <style>/* Inline CSS for email compatibility */</style>
</head>
<body>
  <div class="container">
    <div class="header"><!-- Branded header --></div>
    <div class="content"><!-- Main content --></div>
    <div class="footer"><!-- Footer with contact info --></div>
  </div>
</body>
</html>
```

### Styling Guide
- **Primary Color:** `#2563eb` (Blue)
- **Success Color:** `#10b981` (Green)
- **Warning Color:** `#f59e0b` (Amber)
- **Error Color:** `#ef4444` (Red)
- **Max Width:** 600px
- **Font:** Arial, sans-serif

### Adding Custom Templates
1. Create new method in `TaskMailer`
2. Create corresponding `.html.erb` template
3. Add method to `NotificationService`
4. Add tests
5. Update documentation

## Monitoring and Analytics

### Email Delivery Tracking
```ruby
# Check recent email deliveries (development)
ActionMailer::Base.deliveries.count
ActionMailer::Base.deliveries.last

# Production: Use SendGrid/Mailgun webhooks for tracking
```

### Logs
```ruby
# Notification logs
Rails.logger.info("[NotificationService] Task assigned notification sent: Task #123")

# Error logs
Rails.logger.error("[NotificationService] Failed to send notification: SMTP Error")
```

## Future Enhancements

### Phase 1 - SMS Notifications
- [ ] Integrate Twilio for SMS
- [ ] Add SMS templates for critical events
- [ ] User preference for email vs SMS

### Phase 2 - Push Notifications
- [ ] Web push notifications
- [ ] Mobile app push (iOS/Android)
- [ ] Real-time delivery updates

### Phase 3 - Advanced Features
- [ ] Notification preferences (frequency, types)
- [ ] Digest emails (daily/weekly summaries)
- [ ] Multi-language support
- [ ] Notification templates management UI
- [ ] A/B testing for email content
- [ ] Analytics dashboard for open/click rates

## Troubleshooting

### Emails Not Sending (Development)
```ruby
# Check delivery method
Rails.application.config.action_mailer.delivery_method
# => :letter_opener

# Check perform_deliveries
Rails.application.config.action_mailer.perform_deliveries
# => true

# Check logs
tail -f log/development.log | grep -i mail
```

### Emails Not Sending (Production)
```bash
# Check SMTP credentials
echo $SMTP_USERNAME
echo $SMTP_PASSWORD

# Test SMTP connection
telnet smtp.gmail.com 587

# Check logs
tail -f log/production.log | grep -i "NotificationService"
```

### Template Rendering Issues
```ruby
# Test template rendering in console
task = Task.last
email = TaskMailer.task_assigned(task)
puts email.body.to_s
```

## API Reference

### NotificationService Methods

#### `notify_task_assigned(task)`
Sends assignment notification to messenger.
- **Parameters:** `task` (Task object)
- **Returns:** nil
- **Side Effects:** Sends 1 email to messenger

#### `notify_status_changed(task, old_status)`
Sends status update to customer, messenger, and sender.
- **Parameters:** 
  - `task` (Task object)
  - `old_status` (String) - previous status
- **Returns:** nil
- **Side Effects:** Sends up to 3 emails

#### `notify_delivery_complete(task)`
Sends delivery confirmation to all parties.
- **Parameters:** `task` (Task object)
- **Returns:** nil
- **Side Effects:** Sends up to 3 emails

#### `notify_pickup_requested(task)`
Notifies messenger about pickup request.
- **Parameters:** `task` (Task object)
- **Returns:** nil
- **Side Effects:** Sends 1 email to messenger

#### `notify_delivery_failed(task)`
Notifies all parties and admin about failure.
- **Parameters:** `task` (Task object)
- **Returns:** nil
- **Side Effects:** Sends up to 3 emails including admin alert

#### `notify_location_update_requested(messenger)`
Reminds messenger to update location.
- **Parameters:** `messenger` (Messenger object)
- **Returns:** nil
- **Side Effects:** Sends 1 email to messenger

#### `notify_available_messengers_about_pending_tasks(messenger, pending_tasks)`
Alerts messenger about available tasks.
- **Parameters:** 
  - `messenger` (Messenger object)
  - `pending_tasks` (ActiveRecord::Relation)
- **Returns:** nil
- **Side Effects:** Sends 1 email with task list

## Support

For issues or questions about the notification system:
- **Technical Lead:** Check documentation first
- **Logs:** `/log/development.log` or `/log/production.log`
- **Email Tests:** `bin/rails test test/mailers/task_mailer_test.rb`
- **Service Tests:** `bin/rails test test/services/notification_service_test.rb`

---

**Last Updated:** October 2025
**Version:** 1.0.0
**Status:** ✅ Production Ready
