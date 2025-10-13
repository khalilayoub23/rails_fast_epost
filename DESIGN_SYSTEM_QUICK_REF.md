# 🎨 Design System - Quick Reference Card

## 📋 Most Common Components

### Buttons
```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-success">Success</button>
<button class="btn btn-danger">Danger</button>
<button class="btn btn-ghost">Ghost</button>

<!-- Sizes -->
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary btn-lg">Large</button>
<button class="btn btn-primary btn-block">Full Width</button>
```

### Forms
```html
<div class="form-group">
  <label class="form-label form-label-required">Label</label>
  <input type="text" class="form-input" placeholder="Placeholder">
  <span class="form-helper">Helper text</span>
  <span class="form-error">Error message</span>
</div>

<select class="form-select">...</select>
<textarea class="form-textarea">...</textarea>

<label class="form-check-label">
  <input type="checkbox" class="form-checkbox">
  <span>Checkbox label</span>
</label>
```

### Cards
```html
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Title</h3>
  </div>
  <div class="card-body">Content</div>
  <div class="card-footer">Footer</div>
</div>
```

### Badges
```html
<span class="badge badge-primary">New</span>
<span class="badge badge-success">Active</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-error">Failed</span>
```

### Alerts
```html
<div class="alert alert-success">
  <span class="material-icons alert-icon">check_circle</span>
  <div class="alert-content">
    <div class="alert-title">Success!</div>
    <div class="alert-message">Message here</div>
  </div>
</div>
```

### Lists
```html
<ul class="list">
  <li class="list-item">
    <span class="material-icons list-item-icon">folder</span>
    <div class="list-item-content">
      <div class="list-item-title">Title</div>
      <div class="list-item-subtitle">Subtitle</div>
    </div>
  </li>
</ul>
```

## 📱 Mobile Components

### Bottom Nav
```html
<nav class="mobile-nav">
  <a href="/" class="mobile-nav-item active">
    <span class="material-icons mobile-nav-icon">home</span>
    <span class="mobile-nav-label">Home</span>
  </a>
  <!-- More items... -->
</nav>
```

### FAB
```html
<button class="fab">
  <span class="material-icons fab-icon">add</span>
</button>

<button class="fab fab-extended">
  <span class="material-icons fab-icon">add</span>
  <span class="fab-label">New Task</span>
</button>
```

### Mobile List
```html
<div class="list-mobile">
  <div class="list-mobile-item">
    <div class="list-mobile-item-icon">
      <span class="material-icons">task</span>
    </div>
    <div class="list-mobile-item-content">
      <div class="list-mobile-item-title">Title</div>
      <div class="list-mobile-item-subtitle">Subtitle</div>
    </div>
    <span class="material-icons list-mobile-item-chevron">chevron_right</span>
  </div>
</div>
```

### Bottom Sheet
```html
<div class="bottom-sheet" id="sheet">
  <div class="bottom-sheet-handle"></div>
  <div class="bottom-sheet-header">
    <h3>Options</h3>
  </div>
  <div class="bottom-sheet-body">
    Content
  </div>
</div>
<div class="bottom-sheet-backdrop"></div>

<!-- Open with JS -->
<script>
document.getElementById('sheet').classList.add('open');
document.querySelector('.bottom-sheet-backdrop').classList.add('open');
</script>
```

### Empty State
```html
<div class="empty-state-mobile">
  <div class="empty-state-icon">
    <span class="material-icons">inbox</span>
  </div>
  <div class="empty-state-title">No items yet</div>
  <div class="empty-state-message">Description here</div>
  <button class="btn btn-primary">Create Item</button>
</div>
```

## 🎨 Utility Classes

### Spacing
```html
<!-- Margin -->
mt-1, mt-2, mt-3, mt-4, mt-6, mt-8
mb-1, mb-2, mb-3, mb-4, mb-6, mb-8

<!-- Padding -->
p-2, p-3, p-4, p-6, p-8
```

### Typography
```html
<!-- Size -->
text-xs, text-sm, text-base, text-lg, text-xl, text-2xl

<!-- Weight -->
font-medium, font-semibold, font-bold

<!-- Color -->
text-primary, text-secondary, text-success, text-error
```

### Layout
```html
flex, flex-col
items-center, justify-center, justify-between
gap-2, gap-3, gap-4
```

### Misc
```html
rounded, rounded-full
shadow, shadow-lg
mobile-only, mobile-hidden
```

## 🌓 Dark Mode

```html
<!-- Enable dark mode -->
<html data-theme="dark">

<!-- Toggle with JS -->
<script>
const html = document.documentElement;
const current = html.getAttribute('data-theme');
html.setAttribute('data-theme', current === 'dark' ? 'light' : 'dark');
</script>
```

## 🌍 RTL Support

```html
<!-- Enable RTL for Arabic/Hebrew -->
<html dir="rtl">

<!-- For English/Russian -->
<html dir="ltr">
```

## 🎨 CSS Variables

### Colors
```css
--color-primary-500
--color-success, --color-warning, --color-error, --color-info
--text-primary, --text-secondary, --text-tertiary
--bg-primary, --bg-secondary, --bg-elevated
--border-light, --border-medium, --border-dark
```

### Spacing
```css
--space-1  /* 4px */
--space-2  /* 8px */
--space-3  /* 12px */
--space-4  /* 16px */
--space-6  /* 24px */
--space-8  /* 32px */
```

### Typography
```css
--font-sans, --font-mono
--text-xs through --text-5xl
--font-normal, --font-medium, --font-semibold, --font-bold
```

### Shadows
```css
--shadow-sm, --shadow-md, --shadow-lg, --shadow-xl
```

### Border Radius
```css
--radius-sm, --radius-md, --radius-lg, --radius-xl, --radius-full
```

## 📱 Responsive

### Breakpoints
```css
--breakpoint-sm: 640px;
--breakpoint-md: 768px;   /* mobile/desktop split */
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;
```

### Usage
```html
<!-- Show only on mobile (<768px) -->
<div class="mobile-only">Mobile content</div>

<!-- Hide on mobile -->
<div class="mobile-hidden">Desktop content</div>
```

## 🚀 Common Patterns

### Page Layout
```html
<div class="mobile-content">
  <div class="sticky-header">
    <h1 class="text-2xl font-bold">Page Title</h1>
  </div>
  
  <!-- Content here -->
  
  <button class="fab mobile-only">
    <span class="material-icons fab-icon">add</span>
  </button>
</div>
```

### Card with Actions
```html
<div class="card">
  <div class="card-body">
    <h3 class="text-lg font-semibold mb-2">Title</h3>
    <p class="text-secondary mb-4">Description</p>
    <div class="flex gap-2">
      <button class="btn btn-primary btn-sm">View</button>
      <button class="btn btn-secondary btn-sm">Edit</button>
    </div>
  </div>
</div>
```

### Form with Validation
```html
<div class="form-group">
  <%= form.label :field, class: "form-label form-label-required" %>
  <%= form.text_field :field, class: "form-input #{'error' if @model.errors[:field].any?}" %>
  <% if @model.errors[:field].any? %>
    <span class="form-error"><%= @model.errors[:field].first %></span>
  <% else %>
    <span class="form-helper">Helper text</span>
  <% end %>
</div>
```

### Loading State
```html
<!-- Before load -->
<div class="skeleton skeleton-title"></div>
<div class="skeleton skeleton-text"></div>
<div class="skeleton skeleton-text"></div>

<!-- After load -->
<h1>Actual Title</h1>
<p>Actual content...</p>
```

## 📄 Files Reference

- **Variables**: `app/assets/stylesheets/design-system/variables.css`
- **Components**: `app/assets/stylesheets/design-system/components.css`
- **Mobile**: `app/assets/stylesheets/design-system/mobile.css`
- **Guide**: `DESIGN_SYSTEM_GUIDE.md`
- **Examples**: `DESIGN_SYSTEM_EXAMPLES.md`
- **Summary**: `DESIGN_SYSTEM_SUMMARY.md`

## 🎯 Pro Tips

1. **Always use CSS variables** for colors/spacing (easy to customize)
2. **Mobile-first approach** (design for mobile, enhance for desktop)
3. **44px minimum tap targets** for touch interfaces
4. **Use semantic HTML** (button, nav, header, etc.)
5. **Show loading states** (skeletons, spinners)
6. **Provide empty states** when no content
7. **Test on real devices** (iOS Safari, Android Chrome)

---

**Quick Reference v1.0** | Rails Fast Epost Design System
