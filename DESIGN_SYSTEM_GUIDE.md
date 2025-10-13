# 🎨 Design System Guide

## Overview

This is a comprehensive, cross-platform design system built for **Rails Fast Epost** that works seamlessly across:
- 🌐 **Web browsers** (desktop & mobile)
- 📱 **iOS** (mobile Safari & Turbo Native apps)
- 🤖 **Android** (mobile Chrome & Turbo Native apps)
- 🌍 **4 languages** (English, Arabic, Russian, Hebrew with RTL support)
- 🌓 **Light & Dark modes**

## 📁 File Structure

```
app/assets/stylesheets/
├── design-system/
│   ├── variables.css      # Design tokens (colors, spacing, typography)
│   ├── components.css     # Reusable UI components
│   └── mobile.css         # Mobile-specific patterns
└── application.css        # Main stylesheet (imports design system)
```

## 🎨 Design Tokens

### Colors

```css
/* Primary Colors (Blue - Trust & Professional) */
--color-primary-500: #3b82f6;  /* Main primary color */

/* Semantic Colors */
--color-success: #10b981;      /* Green - success states */
--color-warning: #f59e0b;      /* Amber - warnings */
--color-error: #ef4444;        /* Red - errors */
--color-info: #3b82f6;         /* Blue - informational */

/* Neutral Colors */
--color-gray-50 to --color-gray-900  /* Gray scale */
```

**Usage:**
```html
<div class="btn-primary">Primary Button</div>
<span class="badge-success">Completed</span>
<div class="alert-error">Error message</div>
```

### Spacing Scale

```css
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
```

**Usage:**
```html
<div class="p-4">Padding 16px</div>
<div class="mt-6 mb-4">Margin top 24px, bottom 16px</div>
<div class="gap-3">Gap 12px</div>
```

### Typography

```css
/* Font Sizes */
--text-xs: 0.75rem;     /* 12px */
--text-sm: 0.875rem;    /* 14px */
--text-base: 1rem;      /* 16px - default */
--text-lg: 1.125rem;    /* 18px */
--text-xl: 1.25rem;     /* 20px */
--text-2xl: 1.5rem;     /* 24px */

/* Font Weights */
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

**Usage:**
```html
<h1 class="text-2xl font-bold">Large Heading</h1>
<p class="text-base">Normal text</p>
<small class="text-sm text-secondary">Small text</small>
```

## 🔘 Components

### Buttons

```html
<!-- Primary Button -->
<button class="btn btn-primary">Save Changes</button>

<!-- Secondary Button -->
<button class="btn btn-secondary">Cancel</button>

<!-- Success/Danger -->
<button class="btn btn-success">Approve</button>
<button class="btn btn-danger">Delete</button>

<!-- Sizes -->
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary">Default</button>
<button class="btn btn-primary btn-lg">Large</button>

<!-- Full Width -->
<button class="btn btn-primary btn-block">Full Width</button>

<!-- Icon Button -->
<button class="btn btn-primary btn-icon">
  <span class="material-icons">add</span>
</button>

<!-- Ghost & Link -->
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-link">Link Button</button>
```

**Features:**
- ✅ Touch-optimized (44px minimum height)
- ✅ Hover/active states
- ✅ Disabled states
- ✅ Icon support
- ✅ Loading states

### Forms

```html
<!-- Input Field -->
<div class="form-group">
  <label class="form-label form-label-required">Email</label>
  <input type="email" class="form-input" placeholder="Enter email">
  <span class="form-helper">We'll never share your email</span>
</div>

<!-- With Error -->
<div class="form-group">
  <label class="form-label">Password</label>
  <input type="password" class="form-input error">
  <span class="form-error">Password is required</span>
</div>

<!-- Select -->
<select class="form-select">
  <option>Choose option</option>
  <option>Option 1</option>
</select>

<!-- Textarea -->
<textarea class="form-textarea" rows="4"></textarea>

<!-- Checkbox -->
<label class="form-check-label">
  <input type="checkbox" class="form-checkbox">
  <span>I agree to terms</span>
</label>

<!-- Radio -->
<label class="form-check-label">
  <input type="radio" class="form-radio" name="option">
  <span>Option 1</span>
</label>
```

**Features:**
- ✅ Focus states with blue glow
- ✅ Error states with red styling
- ✅ Disabled states
- ✅ Helper text support
- ✅ Required field indicator

### Cards

```html
<!-- Basic Card -->
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Card Title</h3>
  </div>
  <div class="card-body">
    <p>Card content goes here...</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-primary">Action</button>
  </div>
</div>

<!-- Hover Card -->
<div class="card card-hover">
  <!-- Elevates on hover -->
</div>

<!-- Compact Card -->
<div class="card card-compact">
  <!-- Less padding -->
</div>
```

**Features:**
- ✅ Elevation/shadows
- ✅ Hover effects
- ✅ Header/body/footer sections
- ✅ Compact variant

### Badges & Pills

```html
<!-- Badges -->
<span class="badge badge-primary">New</span>
<span class="badge badge-success">Active</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-error">Failed</span>

<!-- Large Badge -->
<span class="badge badge-success badge-lg">Completed</span>

<!-- With Icon -->
<span class="badge badge-primary">
  <span class="material-icons" style="font-size: 14px;">check</span>
  Verified
</span>
```

### Alerts

```html
<!-- Success Alert -->
<div class="alert alert-success">
  <span class="material-icons alert-icon">check_circle</span>
  <div class="alert-content">
    <div class="alert-title">Success!</div>
    <div class="alert-message">Your changes have been saved.</div>
  </div>
</div>

<!-- Error Alert -->
<div class="alert alert-error">
  <span class="material-icons alert-icon">error</span>
  <div class="alert-content">
    <div class="alert-title">Error</div>
    <div class="alert-message">Something went wrong.</div>
  </div>
</div>

<!-- Warning & Info -->
<div class="alert alert-warning">...</div>
<div class="alert alert-info">...</div>
```

### Toast Notifications

```html
<!-- Success Toast -->
<div class="toast toast-success">
  <div class="flex items-center gap-3">
    <span class="material-icons">check_circle</span>
    <div>Task completed successfully!</div>
  </div>
</div>

<!-- Error Toast -->
<div class="toast toast-error">...</div>

<!-- Positioned automatically at bottom-right (mobile: full-width bottom) -->
```

**Features:**
- ✅ Auto-positioning
- ✅ Slide-in animation
- ✅ Mobile-responsive
- ✅ Can be dismissed

### Lists

```html
<!-- Standard List -->
<ul class="list">
  <li class="list-item list-item-clickable">
    <span class="material-icons list-item-icon">folder</span>
    <div class="list-item-content">
      <div class="list-item-title">Project Files</div>
      <div class="list-item-subtitle">Last modified 2 hours ago</div>
    </div>
    <span class="material-icons list-item-action">chevron_right</span>
  </li>
  <!-- More items... -->
</ul>
```

### Loading States

```html
<!-- Spinner -->
<div class="spinner"></div>
<div class="spinner spinner-lg"></div>

<!-- Skeleton (for loading content) -->
<div class="skeleton skeleton-title"></div>
<div class="skeleton skeleton-text"></div>
<div class="skeleton skeleton-text"></div>
<div class="skeleton skeleton-avatar"></div>
```

## 📱 Mobile Components

### Mobile Navigation

```html
<nav class="mobile-nav">
  <a href="/" class="mobile-nav-item active">
    <span class="material-icons mobile-nav-icon">home</span>
    <span class="mobile-nav-label">Home</span>
  </a>
  <a href="/tasks" class="mobile-nav-item">
    <span class="material-icons mobile-nav-icon">task</span>
    <span class="mobile-nav-label">Tasks</span>
  </a>
  <a href="/customers" class="mobile-nav-item">
    <span class="material-icons mobile-nav-icon">people</span>
    <span class="mobile-nav-label">Customers</span>
  </a>
  <a href="/settings" class="mobile-nav-item">
    <span class="material-icons mobile-nav-icon">settings</span>
    <span class="mobile-nav-label">Settings</span>
  </a>
</nav>
```

**Features:**
- ✅ Fixed to bottom
- ✅ Safe area support (iOS notch)
- ✅ Active state
- ✅ Icon + label

### Bottom Sheet

```html
<!-- Bottom Sheet -->
<div class="bottom-sheet open" id="myBottomSheet">
  <div class="bottom-sheet-handle"></div>
  <div class="bottom-sheet-header">
    <h3>Options</h3>
  </div>
  <div class="bottom-sheet-body">
    <!-- Content -->
  </div>
</div>

<!-- Backdrop -->
<div class="bottom-sheet-backdrop open"></div>
```

**JavaScript to control:**
```javascript
// Open
document.getElementById('myBottomSheet').classList.add('open');
document.querySelector('.bottom-sheet-backdrop').classList.add('open');

// Close
document.getElementById('myBottomSheet').classList.remove('open');
document.querySelector('.bottom-sheet-backdrop').classList.remove('open');
```

### Floating Action Button (FAB)

```html
<!-- Standard FAB -->
<button class="fab">
  <span class="material-icons fab-icon">add</span>
</button>

<!-- Extended FAB with label -->
<button class="fab fab-extended">
  <span class="material-icons fab-icon">add</span>
  <span class="fab-label">New Task</span>
</button>
```

**Features:**
- ✅ Fixed positioning
- ✅ Mobile nav offset
- ✅ Safe area support
- ✅ Hover/active animations

### Swipeable Items

```html
<div class="swipeable" data-controller="swipeable">
  <div class="swipeable-content">
    <div class="list-item">
      <span>Swipe left to see actions</span>
    </div>
  </div>
  <div class="swipeable-actions swipeable-actions-right">
    <button class="swipeable-action swipeable-action-edit">
      <span class="material-icons">edit</span>
    </button>
    <button class="swipeable-action swipeable-action-delete">
      <span class="material-icons">delete</span>
    </button>
  </div>
</div>
```

**Requires Stimulus controller for gesture handling**

### Segmented Control (iOS-style)

```html
<div class="segmented-control">
  <button class="segmented-control-item active">All</button>
  <button class="segmented-control-item">Active</button>
  <button class="segmented-control-item">Completed</button>
</div>
```

### Native-Like List

```html
<div class="list-mobile">
  <div class="list-mobile-item">
    <div class="list-mobile-item-icon">
      <span class="material-icons">folder</span>
    </div>
    <div class="list-mobile-item-content">
      <div class="list-mobile-item-title">Documents</div>
      <div class="list-mobile-item-subtitle">23 files</div>
    </div>
    <span class="material-icons list-mobile-item-chevron">chevron_right</span>
  </div>
  <!-- More items... -->
</div>
```

### Empty States

```html
<div class="empty-state-mobile">
  <div class="empty-state-icon">
    <span class="material-icons">inbox</span>
  </div>
  <div class="empty-state-title">No tasks yet</div>
  <div class="empty-state-message">
    Create your first task to get started
  </div>
  <button class="btn btn-primary">Create Task</button>
</div>
```

## 🌓 Dark Mode

### Enable Dark Mode

```html
<!-- Add to <html> or <body> tag -->
<html data-theme="dark">

<!-- Or toggle with JavaScript -->
<script>
  document.documentElement.setAttribute('data-theme', 'dark');
  // or 'light'
</script>
```

### Dark Mode Toggle Component

```html
<button onclick="toggleDarkMode()">
  <span class="material-icons">dark_mode</span>
</button>

<script>
function toggleDarkMode() {
  const html = document.documentElement;
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('theme', next);
}

// Load saved preference
const saved = localStorage.getItem('theme');
if (saved) {
  document.documentElement.setAttribute('data-theme', saved);
}
</script>
```

**What changes automatically:**
- Background colors
- Text colors
- Border colors
- Shadows (darker/lighter)
- Component colors

## 🌍 RTL Support

### Enable RTL

```html
<!-- For Arabic & Hebrew -->
<html dir="rtl">

<!-- For English & Russian -->
<html dir="ltr">
```

### RTL-Safe Utilities

```html
<!-- Use logical properties -->
<div class="safe-area-left">  <!-- Adapts to direction -->
<div class="safe-area-right"> <!-- Adapts to direction -->
```

**What adapts automatically:**
- Margin/padding directions
- Text alignment
- Icon positions
- Layout flow

## 🎯 Utility Classes

### Spacing

```html
<!-- Margin -->
<div class="mt-4">    <!-- margin-top: 1rem -->
<div class="mb-6">    <!-- margin-bottom: 1.5rem -->
<div class="mt-8">    <!-- margin-top: 2rem -->

<!-- Padding -->
<div class="p-4">     <!-- padding: 1rem -->
<div class="p-6">     <!-- padding: 1.5rem -->
```

### Text

```html
<p class="text-sm">Small text</p>
<p class="text-base">Normal text</p>
<p class="text-lg">Large text</p>
<p class="text-xl">Extra large</p>

<p class="font-medium">Medium weight</p>
<p class="font-semibold">Semibold</p>
<p class="font-bold">Bold</p>

<p class="text-primary">Primary color</p>
<p class="text-secondary">Secondary color</p>
<p class="text-success">Success green</p>
<p class="text-error">Error red</p>
```

### Layout

```html
<div class="flex">            <!-- display: flex -->
<div class="flex-col">        <!-- flex-direction: column -->
<div class="items-center">    <!-- align-items: center -->
<div class="justify-between"> <!-- justify-content: space-between -->
<div class="gap-4">           <!-- gap: 1rem -->
```

### Misc

```html
<div class="rounded">         <!-- border-radius: 0.75rem -->
<div class="rounded-full">    <!-- border-radius: 9999px -->
<div class="shadow">          <!-- box-shadow: medium -->
<div class="shadow-lg">       <!-- box-shadow: large -->
```

### Responsive

```html
<!-- Show only on mobile (<768px) -->
<div class="mobile-only">Mobile content</div>

<!-- Hide on mobile -->
<div class="mobile-hidden">Desktop content</div>
```

## 🎨 Using Components in Rails Views

### Example: Task Card

```erb
<!-- app/views/tasks/_task_card.html.erb -->
<div class="card card-hover">
  <div class="card-body">
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-lg font-semibold"><%= task.title %></h3>
      <span class="badge <%= task.completed? ? 'badge-success' : 'badge-warning' %>">
        <%= task.status %>
      </span>
    </div>
    
    <p class="text-secondary mb-4"><%= task.description %></p>
    
    <div class="flex gap-2">
      <%= link_to task_path(task), class: "btn btn-primary btn-sm" do %>
        <span class="material-icons" style="font-size: 16px;">visibility</span>
        View
      <% end %>
      
      <%= link_to edit_task_path(task), class: "btn btn-secondary btn-sm" do %>
        <span class="material-icons" style="font-size: 16px;">edit</span>
        Edit
      <% end %>
    </div>
  </div>
</div>
```

### Example: Mobile Task List

```erb
<!-- app/views/tasks/index.mobile.erb -->
<div class="mobile-content">
  <!-- Search Bar -->
  <div class="search-bar-mobile">
    <div style="position: relative;">
      <span class="material-icons search-icon-mobile">search</span>
      <input type="text" class="search-input-mobile" placeholder="Search tasks...">
    </div>
  </div>
  
  <!-- Task List -->
  <div class="list-mobile">
    <% @tasks.each do |task| %>
      <%= link_to task_path(task), class: "list-mobile-item" do %>
        <div class="list-mobile-item-icon">
          <span class="material-icons">
            <%= task.completed? ? 'check_circle' : 'radio_button_unchecked' %>
          </span>
        </div>
        <div class="list-mobile-item-content">
          <div class="list-mobile-item-title"><%= task.title %></div>
          <div class="list-mobile-item-subtitle">
            Due <%= task.due_date&.strftime('%b %d') %>
          </div>
        </div>
        <span class="material-icons list-mobile-item-chevron">chevron_right</span>
      <% end %>
    <% end %>
  </div>
  
  <!-- FAB for new task -->
  <%= link_to new_task_path, class: "fab" do %>
    <span class="material-icons fab-icon">add</span>
  <% end %>
</div>

<!-- Mobile Navigation -->
<nav class="mobile-nav">
  <%= link_to root_path, class: "mobile-nav-item #{'active' if current_page?(root_path)}" do %>
    <span class="material-icons mobile-nav-icon">home</span>
    <span class="mobile-nav-label">Home</span>
  <% end %>
  
  <%= link_to tasks_path, class: "mobile-nav-item #{'active' if current_page?(tasks_path)}" do %>
    <span class="material-icons mobile-nav-icon">task</span>
    <span class="mobile-nav-label">Tasks</span>
  <% end %>
  
  <%= link_to customers_path, class: "mobile-nav-item" do %>
    <span class="material-icons mobile-nav-icon">people</span>
    <span class="mobile-nav-label">Customers</span>
  <% end %>
  
  <%= link_to settings_path, class: "mobile-nav-item" do %>
    <span class="material-icons mobile-nav-icon">settings</span>
    <span class="mobile-nav-label">Settings</span>
  <% end %>
</nav>
```

### Example: Form

```erb
<!-- app/views/tasks/_form.html.erb -->
<div class="card">
  <div class="card-body">
    <%= form_with(model: task, class: "form") do |form| %>
      <div class="form-group">
        <%= form.label :title, class: "form-label form-label-required" %>
        <%= form.text_field :title, class: "form-input #{'error' if task.errors[:title].any?}", placeholder: "Enter task title" %>
        <% if task.errors[:title].any? %>
          <span class="form-error"><%= task.errors[:title].first %></span>
        <% end %>
      </div>
      
      <div class="form-group">
        <%= form.label :description, class: "form-label" %>
        <%= form.text_area :description, class: "form-textarea", rows: 4 %>
        <span class="form-helper">Optional description for this task</span>
      </div>
      
      <div class="form-group">
        <%= form.label :status, class: "form-label" %>
        <%= form.select :status, 
            [['Pending', 'pending'], ['In Progress', 'in_progress'], ['Completed', 'completed']], 
            {}, 
            class: "form-select" %>
      </div>
      
      <div class="form-group">
        <label class="form-check-label">
          <%= form.check_box :priority, class: "form-checkbox" %>
          <span>High Priority</span>
        </label>
      </div>
      
      <div class="flex gap-3 mt-6">
        <%= form.submit "Save Task", class: "btn btn-primary" %>
        <%= link_to "Cancel", tasks_path, class: "btn btn-secondary" %>
      </div>
    <% end %>
  </div>
</div>
```

## 🎯 Best Practices

### 1. **Touch Targets**
Always ensure interactive elements are at least 44x44px:
```html
<!-- Good -->
<button class="btn">...</button>  <!-- Has min-height: 44px -->

<!-- Bad -->
<button style="padding: 2px;">...</button>  <!-- Too small -->
```

### 2. **Use Semantic HTML**
```html
<!-- Good -->
<button class="btn btn-primary">Submit</button>
<nav class="mobile-nav">...</nav>

<!-- Bad -->
<div onclick="submit()" class="btn">Submit</div>  <!-- Not keyboard accessible -->
```

### 3. **Responsive Images**
```html
<img src="..." alt="..." style="width: 100%; height: auto;">
<!-- Or use aspect-ratio utilities -->
<div class="aspect-ratio-16-9">...</div>
```

### 4. **Loading States**
Always show loading feedback:
```html
<!-- Before load -->
<div class="skeleton skeleton-text"></div>
<div class="skeleton skeleton-text"></div>

<!-- After load -->
<p>Actual content...</p>
```

### 5. **Empty States**
Provide helpful empty states:
```html
<div class="empty-state-mobile">
  <div class="empty-state-icon">
    <span class="material-icons">inbox</span>
  </div>
  <div class="empty-state-title">No items yet</div>
  <div class="empty-state-message">Get started by creating your first item</div>
  <button class="btn btn-primary">Create Item</button>
</div>
```

### 6. **Performance**
Use GPU acceleration for animations:
```html
<div class="gpu-accelerated">...</div>
```

## 🚀 Testing on Mobile

### Quick Test
1. Start Rails server: `bin/dev`
2. Open your Codespace PORTS tab
3. Find forwarded URL (e.g., `https://your-codespace-url.app.github.dev`)
4. Open URL on your phone's browser
5. Test responsiveness and touch interactions

### Add to Home Screen (iOS)
1. Open URL in Safari
2. Tap Share button
3. Select "Add to Home Screen"
4. App-like experience!

### Add to Home Screen (Android)
1. Open URL in Chrome
2. Tap menu (3 dots)
3. Select "Add to Home screen"
4. App-like experience!

## 📚 Additional Resources

- **Material Icons**: https://fonts.google.com/icons
- **CSS Variables**: https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties
- **Safe Area Insets**: https://webkit.org/blog/7929/designing-websites-for-iphone-x/
- **Touch Events**: https://developer.mozilla.org/en-US/docs/Web/API/Touch_events

## 🎉 What's Included

- ✅ **50+ utility classes** for rapid development
- ✅ **15+ reusable components** (buttons, cards, forms, etc.)
- ✅ **10+ mobile-specific patterns** (bottom sheet, FAB, swipe, etc.)
- ✅ **Dark mode** with automatic color switching
- ✅ **RTL support** for Arabic & Hebrew
- ✅ **Safe area support** for iOS notch/home indicator
- ✅ **Touch-optimized** with 44px minimum tap targets
- ✅ **Accessible** with ARIA support
- ✅ **Performant** with GPU acceleration
- ✅ **Cross-platform** works on web, iOS, Android

## 🛠️ Customization

To customize colors, spacing, or typography:

1. Edit `app/assets/stylesheets/design-system/variables.css`
2. Change CSS variable values
3. Restart Rails server (`bin/dev`)
4. All components update automatically!

Example:
```css
:root {
  /* Change primary color from blue to purple */
  --color-primary-500: #a855f7;  /* Was #3b82f6 */
}
```

---

**Built with ❤️ for Rails Fast Epost**
