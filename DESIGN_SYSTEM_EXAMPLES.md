# 🎨 Design System Implementation Example

## Overview
This file shows practical examples of applying the new design system to existing Rails Fast Epost views.

## 📋 Before & After Examples

### Example 1: Tasks Index Page

#### ❌ **BEFORE** (Generic HTML)
```erb
<!-- app/views/tasks/index.html.erb -->
<div>
  <h1>Tasks</h1>
  <a href="<%= new_task_path %>">New Task</a>
  
  <ul>
    <% @tasks.each do |task| %>
      <li>
        <strong><%= task.title %></strong>
        <p><%= task.description %></p>
        <span><%= task.status %></span>
        <a href="<%= task_path(task) %>">View</a>
        <a href="<%= edit_task_path(task) %>">Edit</a>
      </li>
    <% end %>
  </ul>
</div>
```

#### ✅ **AFTER** (With Design System)
```erb
<!-- app/views/tasks/index.html.erb -->
<div class="mobile-content">
  <!-- Header with action button -->
  <div class="sticky-header">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold">Tasks</h1>
      <%= link_to new_task_path, class: "btn btn-primary btn-sm mobile-hidden" do %>
        <span class="material-icons" style="font-size: 16px;">add</span>
        New Task
      <% end %>
    </div>
  </div>
  
  <!-- Search Bar (Mobile) -->
  <div class="search-bar-mobile mobile-only">
    <div style="position: relative;">
      <span class="material-icons search-icon-mobile">search</span>
      <input type="text" class="search-input-mobile" placeholder="Search tasks..." 
             data-controller="autocomplete" data-autocomplete-url="<%= tasks_path(format: :json) %>">
    </div>
  </div>
  
  <!-- Desktop: Card Grid -->
  <div class="mobile-hidden" style="padding: 1.5rem;">
    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem;">
      <% @tasks.each do |task| %>
        <div class="card card-hover">
          <div class="card-body">
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-lg font-semibold"><%= task.title %></h3>
              <span class="badge <%= task.status == 'completed' ? 'badge-success' : 'badge-warning' %>">
                <%= task.status&.humanize %>
              </span>
            </div>
            
            <p class="text-secondary mb-4" style="min-height: 3rem;">
              <%= truncate(task.description, length: 100) %>
            </p>
            
            <div class="flex gap-2">
              <%= link_to task_path(task), class: "btn btn-primary btn-sm" do %>
                <span class="material-icons" style="font-size: 16px;">visibility</span>
                View
              <% end %>
              
              <%= link_to edit_task_path(task), class: "btn btn-secondary btn-sm" do %>
                <span class="material-icons" style="font-size: 16px;">edit</span>
                Edit
              <% end %>
              
              <%= button_to task_path(task), method: :delete, class: "btn btn-danger btn-sm",
                  data: { turbo_confirm: "Are you sure?" } do %>
                <span class="material-icons" style="font-size: 16px;">delete</span>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
  </div>
  
  <!-- Mobile: Native-like List -->
  <div class="mobile-only list-mobile">
    <% if @tasks.any? %>
      <% @tasks.each do |task| %>
        <%= link_to task_path(task), class: "list-mobile-item" do %>
          <div class="list-mobile-item-icon">
            <span class="material-icons">
              <%= task.status == 'completed' ? 'check_circle' : 'radio_button_unchecked' %>
            </span>
          </div>
          <div class="list-mobile-item-content">
            <div class="list-mobile-item-title"><%= task.title %></div>
            <div class="list-mobile-item-subtitle">
              Due <%= task.due_date&.strftime('%b %d, %Y') || 'No due date' %>
            </div>
          </div>
          <span class="material-icons list-mobile-item-chevron">chevron_right</span>
        <% end %>
      <% end %>
    <% else %>
      <div class="empty-state-mobile">
        <div class="empty-state-icon">
          <span class="material-icons">task</span>
        </div>
        <div class="empty-state-title">No tasks yet</div>
        <div class="empty-state-message">
          Create your first task to get started with your work.
        </div>
        <%= link_to new_task_path, class: "btn btn-primary" do %>
          <span class="material-icons" style="font-size: 18px;">add</span>
          Create Task
        <% end %>
      </div>
    <% end %>
  </div>
  
  <!-- FAB for Mobile -->
  <%= link_to new_task_path, class: "fab mobile-only" do %>
    <span class="material-icons fab-icon">add</span>
  <% end %>
</div>
```

---

### Example 2: Task Form

#### ❌ **BEFORE**
```erb
<!-- app/views/tasks/_form.html.erb -->
<%= form_with(model: task) do |form| %>
  <div>
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>
  
  <div>
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>
  
  <%= form.submit "Save" %>
<% end %>
```

#### ✅ **AFTER**
```erb
<!-- app/views/tasks/_form.html.erb -->
<div class="card">
  <div class="card-header">
    <h2 class="card-title">
      <%= task.persisted? ? "Edit Task" : "New Task" %>
    </h2>
  </div>
  
  <div class="card-body">
    <%= form_with(model: task, data: { controller: "form-validation" }) do |form| %>
      <!-- Title -->
      <div class="form-group">
        <%= form.label :title, class: "form-label form-label-required" %>
        <%= form.text_field :title, 
            class: "form-input #{'error' if task.errors[:title].any?}", 
            placeholder: "Enter task title",
            data: { form_validation_target: "field" } %>
        <% if task.errors[:title].any? %>
          <span class="form-error"><%= task.errors[:title].first %></span>
        <% else %>
          <span class="form-helper">A clear, concise title for your task</span>
        <% end %>
      </div>
      
      <!-- Description -->
      <div class="form-group">
        <%= form.label :description, class: "form-label" %>
        <%= form.text_area :description, 
            class: "form-textarea", 
            rows: 4,
            placeholder: "Describe the task in detail..." %>
        <span class="form-helper">Optional: Add more context about this task</span>
      </div>
      
      <!-- Status -->
      <div class="form-group">
        <%= form.label :status, class: "form-label form-label-required" %>
        <%= form.select :status, 
            [
              ['Pending', 'pending'],
              ['In Progress', 'in_progress'],
              ['Completed', 'completed']
            ], 
            {},
            class: "form-select #{'error' if task.errors[:status].any?}" %>
        <% if task.errors[:status].any? %>
          <span class="form-error"><%= task.errors[:status].first %></span>
        <% end %>
      </div>
      
      <!-- Due Date -->
      <div class="form-group">
        <%= form.label :due_date, class: "form-label" %>
        <%= form.date_field :due_date, class: "form-input" %>
      </div>
      
      <!-- Priority Checkbox -->
      <div class="form-group">
        <label class="form-check-label">
          <%= form.check_box :priority, class: "form-checkbox" %>
          <span>Mark as high priority</span>
        </label>
      </div>
      
      <!-- Submit Buttons -->
      <div class="flex gap-3 mt-6">
        <%= form.submit task.persisted? ? "Update Task" : "Create Task", 
            class: "btn btn-primary",
            data: { disable_with: "Saving..." } %>
        
        <%= link_to "Cancel", 
            task.persisted? ? task_path(task) : tasks_path, 
            class: "btn btn-secondary" %>
      </div>
    <% end %>
  </div>
</div>
```

---

### Example 3: Customer Card Component

#### ❌ **BEFORE**
```erb
<!-- app/views/customers/_customer.html.erb -->
<div>
  <h3><%= customer.name %></h3>
  <p><%= customer.email %></p>
  <a href="<%= customer_path(customer) %>">View</a>
</div>
```

#### ✅ **AFTER**
```erb
<!-- app/views/customers/_customer_card.html.erb -->
<%= turbo_frame_tag dom_id(customer) do %>
  <div class="card card-hover">
    <div class="card-body">
      <!-- Header with Avatar -->
      <div class="flex items-center gap-4 mb-4">
        <div style="width: 48px; height: 48px; border-radius: 50%; background: var(--color-primary-100); 
                    display: flex; align-items: center; justify-content: center; font-weight: 600; 
                    color: var(--color-primary-700); font-size: 1.25rem;">
          <%= customer.name&.first&.upcase || '?' %>
        </div>
        <div style="flex: 1;">
          <h3 class="text-lg font-semibold"><%= customer.name %></h3>
          <p class="text-sm text-secondary"><%= customer.email %></p>
        </div>
        <% if customer.active? %>
          <span class="badge badge-success">Active</span>
        <% else %>
          <span class="badge badge-error">Inactive</span>
        <% end %>
      </div>
      
      <!-- Info Grid -->
      <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; margin-bottom: 1rem;">
        <div>
          <span class="text-sm text-secondary">Phone</span>
          <p class="font-medium"><%= customer.phone || 'N/A' %></p>
        </div>
        <div>
          <span class="text-sm text-secondary">Company</span>
          <p class="font-medium"><%= customer.company || 'N/A' %></p>
        </div>
      </div>
      
      <!-- Actions -->
      <div class="flex gap-2">
        <%= link_to customer_path(customer), class: "btn btn-primary btn-sm" do %>
          <span class="material-icons" style="font-size: 16px;">visibility</span>
          View
        <% end %>
        
        <%= link_to edit_customer_path(customer), class: "btn btn-secondary btn-sm" do %>
          <span class="material-icons" style="font-size: 16px;">edit</span>
          Edit
        <% end %>
        
        <%= button_to customer_path(customer), method: :delete, 
            class: "btn btn-danger btn-sm",
            data: { turbo_confirm: "Delete #{customer.name}?" } do %>
          <span class="material-icons" style="font-size: 16px;">delete</span>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

---

### Example 4: Flash Messages

#### ❌ **BEFORE**
```erb
<!-- app/views/layouts/application.html.erb -->
<% flash.each do |type, message| %>
  <div class="flash-<%= type %>">
    <%= message %>
  </div>
<% end %>
```

#### ✅ **AFTER**
```erb
<!-- app/views/layouts/application.html.erb -->
<% flash.each do |type, message| %>
  <div class="toast toast-<%= flash_type_to_class(type) %>" 
       data-controller="notification" 
       data-notification-duration-value="5000">
    <div class="flex items-center gap-3">
      <span class="material-icons">
        <%= flash_icon(type) %>
      </span>
      <div style="flex: 1;"><%= message %></div>
      <button onclick="this.closest('.toast').remove()" class="btn btn-ghost btn-sm btn-icon">
        <span class="material-icons" style="font-size: 18px;">close</span>
      </button>
    </div>
  </div>
<% end %>

<!-- Add to ApplicationHelper -->
<%
# app/helpers/application_helper.rb
def flash_type_to_class(type)
  case type.to_sym
  when :notice then 'success'
  when :alert then 'error'
  when :warning then 'warning'
  else 'info'
  end
end

def flash_icon(type)
  case type.to_sym
  when :notice then 'check_circle'
  when :alert then 'error'
  when :warning then 'warning'
  else 'info'
  end
end
%>
```

---

### Example 5: Mobile Navigation

#### ❌ **BEFORE**
```erb
<!-- No mobile-specific navigation -->
```

#### ✅ **AFTER**
```erb
<!-- app/views/layouts/_mobile_nav.html.erb -->
<nav class="mobile-nav mobile-only">
  <%= link_to root_path, class: "mobile-nav-item #{'active' if current_page?(root_path)}" do %>
    <span class="material-icons mobile-nav-icon">home</span>
    <span class="mobile-nav-label"><%= t('navigation.home') %></span>
  <% end %>
  
  <%= link_to tasks_path, class: "mobile-nav-item #{'active' if controller_name == 'tasks'}" do %>
    <span class="material-icons mobile-nav-icon">task</span>
    <span class="mobile-nav-label"><%= t('navigation.tasks') %></span>
  <% end %>
  
  <%= link_to customers_path, class: "mobile-nav-item #{'active' if controller_name == 'customers'}" do %>
    <span class="material-icons mobile-nav-icon">people</span>
    <span class="mobile-nav-label"><%= t('navigation.customers') %></span>
  <% end %>
  
  <%= link_to payments_path, class: "mobile-nav-item #{'active' if controller_name == 'payments'}" do %>
    <span class="material-icons mobile-nav-icon">payments</span>
    <span class="mobile-nav-label"><%= t('navigation.payments') %></span>
  <% end %>
  
  <%= link_to settings_path, class: "mobile-nav-item #{'active' if controller_name == 'settings'}" do %>
    <span class="material-icons mobile-nav-icon">settings</span>
    <span class="mobile-nav-label"><%= t('navigation.settings') %></span>
  <% end %>
</nav>

<!-- Add to app/views/layouts/application.html.erb before </body> -->
<%= render 'layouts/mobile_nav' %>
```

---

## 🎯 Quick Migration Checklist

Use this checklist when updating existing views:

### For List/Index Pages
- [ ] Wrap content in `<div class="mobile-content">`
- [ ] Add search bar with `search-bar-mobile` class
- [ ] Create desktop grid layout with cards
- [ ] Create mobile list with `list-mobile` class
- [ ] Add FAB button for mobile
- [ ] Show empty state when no items
- [ ] Add loading skeletons

### For Forms
- [ ] Wrap form in card component
- [ ] Use `form-group` for each field
- [ ] Add `form-label` with `form-label-required` if needed
- [ ] Use appropriate input classes (`form-input`, `form-select`, etc.)
- [ ] Show error states with `error` class
- [ ] Add helper text with `form-helper`
- [ ] Style submit buttons with `btn btn-primary`

### For Cards/Components
- [ ] Use `card` class for containers
- [ ] Add `card-hover` for interactive cards
- [ ] Include proper header/body/footer structure
- [ ] Use badges for status indicators
- [ ] Add icons with Material Icons
- [ ] Include action buttons at bottom

### For Mobile
- [ ] Ensure touch targets are 44px minimum
- [ ] Add mobile navigation if needed
- [ ] Create mobile-specific layouts with `mobile-only`
- [ ] Hide desktop content with `mobile-hidden`
- [ ] Add safe area support for iOS

---

## 📊 Impact Metrics

### Before Design System
- ❌ Inconsistent spacing and colors
- ❌ No mobile-optimized components
- ❌ No touch target optimization
- ❌ No dark mode support
- ❌ No RTL support
- ❌ Generic HTML with inline styles

### After Design System
- ✅ **Consistent** spacing (8px scale) and colors
- ✅ **50+ utility classes** for rapid development
- ✅ **15+ mobile-optimized** components
- ✅ **Touch-friendly** (44px minimum targets)
- ✅ **Dark mode** ready
- ✅ **RTL support** for Arabic/Hebrew
- ✅ **Semantic components** with proper accessibility

---

## 🚀 Next Steps

1. **Update layouts/application.html.erb**
   - Import design system CSS
   - Add mobile navigation
   - Update flash messages

2. **Migrate one controller at a time**
   - Start with Tasks (most used)
   - Then Customers
   - Then Payments
   - etc.

3. **Test on actual devices**
   - iPhone Safari
   - Android Chrome
   - Desktop browsers

4. **Add more components as needed**
   - Pagination
   - Tabs
   - Dropdowns
   - Date pickers

---

**💡 Pro Tip**: Start with the mobile-first approach. Design for mobile, then enhance for desktop!
