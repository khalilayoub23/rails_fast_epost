# Manual Testing Checklist

## Date: Post-Cleanup Verification
## Status: 🔄 Pending Manual Tests

---

## 1. View Layer Tests (Home Page)

### Social Icons Section
- [ ] Navigate to `/home` or root path
- [ ] Scroll to footer social icons section
- [ ] **Verify:** All 7 social icons render correctly (Facebook, Twitter, LinkedIn, WhatsApp, Telegram, Instagram, TikTok)
- [ ] **Verify:** Icons have yellow hover effect
- [ ] **Verify:** Icons are clickable (even if links are placeholder #)
- [ ] **Verify:** No console errors in browser DevTools

### Feature Cards Section
- [ ] View the "Why Choose Us" or features section on home page
- [ ] **Verify:** 4 feature cards display (Verified, Tracking, Secure, Live Support)
- [ ] **Verify:** Each card has yellow circular background with black SVG icon
- [ ] **Verify:** Icons are centered and sized correctly (w-8 h-8 = 32x32px)
- [ ] **Verify:** Headings use correct i18n translations
- [ ] **Verify:** Cards are responsive in grid layout (1 column mobile, 4 columns desktop)

### Checklist Sections
- [ ] View services sections (Legal/Ecommerce)
- [ ] **Verify:** Checkmark icons appear in yellow
- [ ] **Verify:** Text items display correctly with translations
- [ ] **Verify:** Items are properly spaced and aligned

---

## 2. Controller Tests (Preferences)

### Index Action
```bash
# Navigate to a carrier's preferences
# URL: /carriers/:carrier_id/preferences
```
- [ ] Can view preferences index page
- [ ] **HTML format:** Page renders without errors
- [ ] **JSON format:** Append `.json` to URL, verify JSON response

### Show Action
```bash
# URL: /carriers/:carrier_id/preferences/:id
```
- [ ] Can view individual preference
- [ ] **HTML format:** Page renders preference details
- [ ] **JSON format:** Append `.json` to URL, verify JSON response

### Create Action
```bash
# Navigate to /carriers/:carrier_id/preferences/new
```
- [ ] Form displays correctly
- [ ] **Success case:** Fill form, submit, verify redirect to show page
- [ ] **Success case:** Check notice message: "Preference created."
- [ ] **Failure case:** Submit invalid data, verify form re-renders with errors
- [ ] **JSON format:** Test with API client (curl/Postman), verify status 201 on success

### Update Action
```bash
# Navigate to /carriers/:carrier_id/preferences/:id/edit
```
- [ ] Form displays with existing data
- [ ] **Success case:** Modify data, submit, verify redirect and notice
- [ ] **Failure case:** Submit invalid data, verify errors display
- [ ] **JSON format:** Test with API client, verify JSON response

### Destroy Action
```bash
# Click delete button on preference
```
- [ ] Delete confirmation dialog appears (if implemented)
- [ ] **Success case:** Confirm delete, verify redirect to index
- [ ] **Success case:** Check notice message: "Preference deleted."
- [ ] **JSON format:** Test with API client, verify 204 No Content response

---

## 3. Controller Tests (Cost Calcs)

### Index Action
```bash
# URL: /tasks/:task_id/cost_calcs
```
- [ ] Can view cost calcs index
- [ ] **Verify:** Shows task's cost_calc or empty array
- [ ] **HTML/JSON formats:** Both work correctly

### Show Action
```bash
# URL: /tasks/:task_id/cost_calcs/:id
```
- [ ] Can view individual cost calc
- [ ] **HTML/JSON formats:** Both work correctly

### Create Action
```bash
# URL: /tasks/:task_id/cost_calcs/new
```
- [ ] **Success case:** Create new cost calc, verify redirect and notice "Cost calc created."
- [ ] **Failure case:** Verify error handling
- [ ] **JSON format:** Verify status 201 on success

### Update Action
```bash
# URL: /tasks/:task_id/cost_calcs/:id/edit
```
- [ ] **Success case:** Update cost calc, verify redirect and notice "Cost calc updated."
- [ ] **Failure case:** Verify error handling

### Destroy Action
- [ ] **Success case:** Delete cost calc, verify redirect and notice "Cost calc deleted."
- [ ] **JSON format:** Verify 204 No Content

---

## 4. Cross-Browser Testing

### Desktop Browsers
- [ ] **Chrome/Edge** - Test home page, preferences CRUD, cost_calcs CRUD
- [ ] **Firefox** - Test home page, preferences CRUD, cost_calcs CRUD
- [ ] **Safari** (if Mac available) - Test home page, preferences CRUD, cost_calcs CRUD

### Mobile/Responsive
- [ ] **Chrome DevTools** - Toggle device toolbar, test 375px (mobile), 768px (tablet), 1024px (desktop)
- [ ] **Real device** - Test on actual mobile phone if possible

---

## 5. Internationalization (i18n) Tests

### Language Switching
- [ ] Switch to **Hebrew** - Verify RTL layout, social icons, feature cards, checklists
- [ ] Switch to **Russian** - Verify Cyrillic text displays correctly
- [ ] Switch to **English** - Verify default translations
- [ ] **Verify:** All partials respect current locale
- [ ] **Verify:** Feature card headings use correct i18n keys

---

## 6. Performance Checks

### Page Load Times
- [ ] **Home page:** Open DevTools Network tab, measure load time
  - **Target:** < 2 seconds on 3G connection
- [ ] **Preferences index:** Measure load time
- [ ] **Cost calcs index:** Measure load time

### Asset Loading
- [ ] **Verify:** No missing images or broken SVG paths
- [ ] **Verify:** Tailwind CSS classes apply correctly
- [ ] **Verify:** No 404 errors in Network tab

---

## 7. Regression Tests (Ensure Nothing Broke)

### Other Controllers (Not Refactored)
- [ ] **Documents:** Test CRUD operations, verify turbo_stream updates work
- [ ] **Phones:** Test CRUD operations, verify turbo_stream updates work
- [ ] **Carriers:** Test CRUD operations
- [ ] **Customers:** Test CRUD operations
- [ ] **Tasks:** Test CRUD operations
- [ ] **Forms:** Test CRUD operations
- [ ] **Remarks:** Test CRUD operations

### Authentication Flow
- [ ] **Sign up:** Create new user account
- [ ] **Sign in:** Login with credentials
- [ ] **Sign out:** Logout successfully
- [ ] **Password reset:** Test forgot password flow

### Dashboard
- [ ] **Authenticated user:** Access `/dashboard`, verify page loads
- [ ] **Guest user:** Access root `/`, verify redirects to home page

---

## 8. API Endpoints (If Used)

### API V1 Carriers
```bash
curl -X GET http://localhost:3000/api/v1/carriers.json
```
- [ ] Returns JSON array of carriers
- [ ] No errors from Respondable concern affecting API

### API V1 Customers
```bash
curl -X GET http://localhost:3000/api/v1/customers.json
```
- [ ] Returns JSON array of customers
- [ ] API endpoints unaffected by controller refactoring

### API V1 Tasks
```bash
curl -X GET http://localhost:3000/api/v1/tasks.json
```
- [ ] Returns JSON array of tasks
- [ ] API endpoints working correctly

---

## 9. Error Handling

### 404 Not Found
- [ ] Navigate to `/nonexistent-route`
- [ ] **Verify:** Proper 404 page displays

### 500 Server Error
- [ ] Trigger server error (e.g., access invalid ID)
- [ ] **Verify:** Error page displays or gets logged appropriately

### Validation Errors
- [ ] Submit forms with invalid data
- [ ] **Verify:** Error messages display in red
- [ ] **Verify:** Form fields highlight validation errors

---

## 10. Console Checks

### Rails Console Tests
```bash
bin/rails console
```

```ruby
# Test Respondable concern is loaded
PreferencesController.new.respond_to?(:respond_with_index)
# => true

CostCalcsController.new.respond_to?(:respond_with_create)
# => true

# Test partials exist
ActionController::Base.helpers.asset_path('shared/social_icon')
# Should not raise error

# Test ActiveRecord models work
Carrier.first
Customer.first
Task.first
# Should return records or nil, no errors
```

### Browser Console Checks
- [ ] Open browser DevTools Console (F12)
- [ ] **Verify:** No JavaScript errors on page load
- [ ] **Verify:** No uncaught exceptions during navigation
- [ ] **Verify:** Stimulus controllers load correctly (if used)

---

## Test Results Summary

| Test Category | Status | Notes |
|--------------|--------|-------|
| View Layer (Home Page) | ⬜ Pending | |
| Preferences Controller | ⬜ Pending | |
| Cost Calcs Controller | ⬜ Pending | |
| Cross-Browser | ⬜ Pending | |
| Internationalization | ⬜ Pending | |
| Performance | ⬜ Pending | |
| Regression Tests | ⬜ Pending | |
| API Endpoints | ⬜ Pending | |
| Error Handling | ⬜ Pending | |
| Console Checks | ⬜ Pending | |

**Status Legend:**
- ⬜ Pending - Not yet tested
- ✅ Passed - Test successful
- ❌ Failed - Issue found, needs fixing
- ⚠️ Warning - Minor issue, non-blocking

---

## Issues Found During Testing

### Issue Template
```markdown
**Issue #1: [Title]**
- **Severity:** Critical / High / Medium / Low
- **Component:** View / Controller / Route / etc.
- **Description:** 
- **Steps to Reproduce:**
  1. 
  2. 
  3. 
- **Expected Behavior:** 
- **Actual Behavior:** 
- **Fix Required:** 
```

---

## Sign-off

- **Tested by:** _________________
- **Date:** _________________
- **Environment:** Development / Staging / Production
- **Rails version:** 8.0.1
- **Ruby version:** 3.3.4

**Overall Status:** ⬜ All tests passed / ⬜ Issues found (see above)

**Recommendation:** ⬜ Ready to deploy / ⬜ Requires fixes before deployment
