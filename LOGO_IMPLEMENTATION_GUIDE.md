# 🎨 Logo & Branding Implementation Guide

## 📦 What's Included

### Files Created
1. **`app/assets/stylesheets/design-system/logo.css`** - Logo component styles
2. **`app/views/shared/_logo.html.erb`** - Reusable logo partial
3. **`app/views/shared/_brand_bar.html.erb`** - Mobile brand bar with logo
4. **`app/views/shared/_splash_screen.html.erb`** - Loading screen with logo

### Current Logo
- **Location**: `/public/icon.svg` and `/public/icon.png`
- **Design**: Simple red circle (placeholder)
- **Size**: 512x512px

## 🎯 How to Use the Logo

### 1. Basic Logo (Default)
```erb
<%= render 'shared/logo' %>
```
**Output**: Medium logo with icon + text, clickable to home

### 2. Different Sizes
```erb
<%= render 'shared/logo', size: 'sm' %>   <!-- Small (32px icon) -->
<%= render 'shared/logo', size: 'md' %>   <!-- Medium (40px icon) - default -->
<%= render 'shared/logo', size: 'lg' %>   <!-- Large (56px icon) -->
<%= render 'shared/logo', size: 'xl' %>   <!-- Extra large (80px icon) -->
```

### 3. Icon Only (No Text)
```erb
<%= render 'shared/logo', text: false %>
```

### 4. Non-Clickable Logo
```erb
<%= render 'shared/logo', link: false %>
```

### 5. Custom Classes
```erb
<%= render 'shared/logo', class: 'my-custom-class' %>
```

### 6. Combined Options
```erb
<%= render 'shared/logo', size: 'lg', text: true, link: true, class: 'mx-auto' %>
```

## 📱 Components with Logo

### Brand Bar (Mobile Header)
```erb
<!-- Add to layout or specific views -->
<%= render 'shared/brand_bar' %>
```
**Features**:
- ✅ Logo in center
- ✅ Menu button on left
- ✅ Notifications + settings on right
- ✅ Mobile-only (hidden on desktop)
- ✅ Sticky to top

### Splash Screen (Loading)
```erb
<!-- Add to layout for branded loading screen -->
<%= render 'shared/splash_screen' %>
```
**Features**:
- ✅ Full-screen overlay
- ✅ Large logo
- ✅ Spinner animation
- ✅ Auto-hides after load
- ✅ Smooth fade out

## 🎨 Logo Customization

### Change Logo Image
Replace files:
- `/public/icon.svg` - Vector logo (recommended)
- `/public/icon.png` - Raster logo (fallback)

**Recommended Sizes**:
- SVG: Any size (scales perfectly)
- PNG: 512x512px minimum

### Change Logo Text
Edit `app/views/shared/_logo.html.erb`:
```erb
<div class="logo-text">
  <div class="logo-title">Your App Name</div>
  <div class="logo-subtitle">Your Tagline</div>
</div>
```

### Change Logo Colors
Edit `app/assets/stylesheets/design-system/logo.css`:
```css
.logo-title {
  color: #your-color;
}

.logo-subtitle {
  color: #your-color;
}
```

## 🌓 Dark Mode Logo

### Option 1: Auto Invert
Add class to logo in `_logo.html.erb`:
```erb
<div class="logo-icon logo-auto-invert">
  <%= image_tag 'icon.svg', alt: 'Fast Epost' %>
</div>
```

### Option 2: Separate Logos (Recommended)
1. Create dark mode logo: `/public/icon-dark.svg`
2. Update `_logo.html.erb`:
```erb
<div class="logo-icon">
  <%= image_tag 'icon.svg', alt: 'Fast Epost', class: 'logo-light' %>
  <%= image_tag 'icon-dark.svg', alt: 'Fast Epost', class: 'logo-dark' %>
</div>
```

## 📍 Where to Add Logo

### Sidebar (Desktop)
Edit `app/views/shared/_sidebar.html.erb`:
```erb
<div class="sidebar-logo">
  <%= render 'shared/logo', size: 'md' %>
</div>
```

### Topbar (Desktop)
Edit `app/views/shared/_topbar.html.erb`:
```erb
<div class="flex items-center gap-4">
  <%= render 'shared/logo', size: 'sm' %>
</div>
```

### Login Page
```erb
<div class="login-brand">
  <div class="login-logo">
    <%= render 'shared/logo', size: 'xl', link: false %>
  </div>
</div>
```

### Footer
```erb
<footer class="powered-by">
  <%= render 'shared/logo', size: 'sm', text: false %>
  <span>Powered by Fast Epost</span>
</footer>
```

### Mobile Navigation
```erb
<nav class="mobile-nav">
  <a href="/" class="mobile-nav-item">
    <%= render 'shared/logo', size: 'sm', text: false %>
  </a>
</nav>
```

## 🎯 Real-World Examples

### Example 1: Add Logo to Existing Sidebar
```erb
<!-- app/views/shared/_sidebar.html.erb -->
<aside class="sidebar">
  <!-- Add at top -->
  <div class="sidebar-logo">
    <%= render 'shared/logo', size: 'md' %>
  </div>
  
  <!-- Rest of sidebar content -->
  <nav>...</nav>
</aside>
```

### Example 2: Add Brand Bar to Mobile Layout
```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <!-- Add for mobile users -->
  <%= render 'shared/brand_bar' %>
  
  <div class="main-content">
    <%= yield %>
  </div>
</body>
```

### Example 3: Splash Screen on App Load
```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <!-- Add at beginning of body -->
  <%= render 'shared/splash_screen' %>
  
  <!-- Rest of app -->
  <%= yield %>
</body>
```

### Example 4: Login Page with Logo
```erb
<!-- app/views/sessions/new.html.erb -->
<div class="min-h-screen flex items-center justify-center">
  <div class="card" style="max-width: 400px; width: 100%;">
    <div class="card-body">
      <!-- Logo at top -->
      <div class="login-brand">
        <%= render 'shared/logo', size: 'lg', link: false %>
      </div>
      
      <!-- Login form -->
      <%= form_with url: session_path do |f| %>
        ...
      <% end %>
    </div>
  </div>
</div>
```

## 🔧 Advanced Customization

### Custom Logo Component
Create your own logo variant:
```erb
<!-- app/views/shared/_custom_logo.html.erb -->
<div class="logo logo-custom">
  <div class="logo-icon">
    <%= image_tag 'custom-icon.svg' %>
  </div>
  <div class="logo-text">
    <div class="logo-title">Custom Title</div>
    <div class="logo-subtitle">Custom Subtitle</div>
  </div>
</div>
```

### Animated Logo
Add to `logo.css`:
```css
.logo-animated .logo-icon {
  animation: rotate 3s linear infinite;
}

@keyframes rotate {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

Use:
```erb
<%= render 'shared/logo', class: 'logo-animated' %>
```

### Logo with Badge
```erb
<div class="logo" style="position: relative;">
  <%= render 'shared/logo', text: false %>
  <span class="badge badge-error" style="position: absolute; top: -4px; right: -4px;">
    New
  </span>
</div>
```

## 📱 PWA Icons (Add to Home Screen)

Your logo is automatically used for:
- ✅ Favicon (browser tab)
- ✅ Apple Touch Icon (iOS home screen)
- ✅ PWA icon (Android home screen)

### Create More Icon Sizes
For better quality, create multiple sizes:

1. **Create icons**:
   - `public/icon-192.png` (192x192)
   - `public/icon-512.png` (512x512)

2. **Update manifest** (future PWA setup):
```json
{
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

## 🎨 Logo Design Tips

### For Your Designer
**Logo Requirements**:
- SVG format (scalable)
- Square aspect ratio (1:1)
- Transparent background
- Simple design (works at small sizes)
- Works in dark mode

**Sizes to Create**:
- SVG: One file (scales to any size)
- PNG: 512x512px, 256x256px, 128x128px, 64x64px, 32x32px

**Test Logo At**:
- 16px (favicon)
- 32px (small logo)
- 40px (default logo)
- 56px (large logo)
- 80px (extra large logo)

### Colors to Consider
Match your brand:
```css
/* Edit in logo.css */
.logo-title {
  color: var(--color-primary-500); /* Your brand color */
}

.logo-icon {
  /* Background color for icon */
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  padding: 8px;
}
```

## 🚀 Quick Start

### 1. Replace Logo Files
```bash
# Upload your logo files to /public/
# - icon.svg (vector, recommended)
# - icon.png (raster, 512x512px)
```

### 2. Update Logo Text
```erb
<!-- Edit app/views/shared/_logo.html.erb -->
<div class="logo-title">Your App Name</div>
<div class="logo-subtitle">Your Tagline</div>
```

### 3. Add Logo to Layout
```erb
<!-- Add to app/views/layouts/application.html.erb -->
<%= render 'shared/brand_bar' %>
```

### 4. Test It!
- ✅ Check desktop sidebar
- ✅ Check mobile brand bar
- ✅ Check favicon in browser tab
- ✅ Test dark mode
- ✅ Test on real phone

## 📊 Logo Checklist

- [ ] Replace `/public/icon.svg` with your logo
- [ ] Replace `/public/icon.png` with PNG version
- [ ] Update logo text in `_logo.html.erb`
- [ ] Add logo to sidebar
- [ ] Add brand bar to mobile layout
- [ ] Test on desktop
- [ ] Test on mobile
- [ ] Test dark mode
- [ ] Test RTL (Arabic/Hebrew)
- [ ] Create favicon sizes (optional)
- [ ] Add splash screen (optional)
- [ ] Test "Add to Home Screen" on iOS
- [ ] Test "Add to Home Screen" on Android

## 🎉 You're Done!

Your logo is now integrated into the design system and appears:
- ✅ In browser tab (favicon)
- ✅ On mobile home screen (when installed)
- ✅ In sidebar (desktop)
- ✅ In brand bar (mobile)
- ✅ On login page
- ✅ On splash screen
- ✅ In navigation
- ✅ Everywhere you add it!

---

**Need help?** See examples in:
- `DESIGN_SYSTEM_EXAMPLES.md`
- `DESIGN_SYSTEM_GUIDE.md`
- `app/views/shared/_logo.html.erb`
