# Database Schema Summary

## Tables and Relationships

### Carriers (STI - Single Table Inheritance)
- **Fields**: id, type, name, email, address
- **Relationships**: 
  - has_many :phones
  - has_many :documents
  - has_many :form_templates
  - has_many :tasks
  - has_one :preference

### Customers
- **Fields**: id, name, phones (serialized array), category (enum), address, email
- **Enums**: category (individual: 0, business: 1, government: 2)
- **Relationships**:
  - has_many :form_templates
  - has_many :forms
  - has_many :tasks

### Tasks
- **Fields**: id, customer_id, carrier_id, package_type, start, target, failure_code (enum), delivery_time, status (enum), barcode, filled_form_url
- **Enums**: 
  - failure_code (no_failure: 0, address_not_found: 1, recipient_unavailable: 2, package_damaged: 3, refused_delivery: 4)
  - status (pending: 0, in_transit: 1, delivered: 2, failed: 3, returned: 4)
- **Relationships**:
  - belongs_to :customer
  - belongs_to :carrier
  - has_many :payments_tasks
  - has_many :payments, through: :payments_tasks
  - has_one :cost_calc
  - has_many :remarks

### Payments (Polymorphic)
- **Fields**: id, category (enum), task_id, payable_id, payable_type, payment_type (enum), interval_start, interval_end
- **Enums**:
  - category (service_fee: 0, delivery_fee: 1, insurance: 2, penalty: 3)
  - payment_type (per_task: 0, lump_sum: 1)
- **Relationships**:
  - has_many :payments_tasks
  - has_many :tasks, through: :payments_tasks
  - belongs_to :payable, polymorphic: true

### Remarks (Polymorphic)
- **Fields**: id, task_id, remarkable_id, remarkable_type, content (text)
- **Relationships**:
  - belongs_to :task
  - belongs_to :remarkable, polymorphic: true

### Preferences
- **Fields**: id, carrier_id, bank_account (serialized hash), avatar, background_mode (enum)
- **Enums**: background_mode (light: 0, dark: 1, auto: 2)
- **Relationships**:
  - belongs_to :carrier

### Phones
- **Fields**: id, carrier_id, number, primary (boolean)
- **Relationships**:
  - belongs_to :carrier

### Forms
- **Fields**: id, address, customer_id, form_default_url
- **Relationships**:
  - belongs_to :customer

### FormTemplates
- **Fields**: id, carrier_id, customer_id
- **Relationships**:
  - belongs_to :carrier
  - belongs_to :customer

### Documents
- **Fields**: id, carrier_id, id_document, signature
- **Relationships**:
  - belongs_to :carrier

### CostCalcs
- **Fields**: id, task_id
- **Relationships**:
  - belongs_to :task

### PaymentsTasks (Join Table)
- **Fields**: id, task_id, payment_id
- **Relationships**:
  - belongs_to :task
  - belongs_to :payment

## Key Features Implemented:
✅ STI for Carriers table
✅ Polymorphic associations for Payments and Remarks
✅ Serialized attributes for phones array and bank_account hash
✅ Enums for all specified fields
✅ Many-to-many relationship between Tasks and Payments via PaymentsTasks
✅ All foreign key constraints and validations
