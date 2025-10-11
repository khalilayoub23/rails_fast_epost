# TailAdmin Design System Reference

This document serves as a quick reference for the TailAdmin design system implemented in Rails Fast Epost.

## 🎨 Color Palette

### Primary Colors
| Color | Hex | CSS Variable | Usage |
|-------|-----|--------------|-------|
| Primary | `#3c50e0` | `--primary` | Buttons, links, active states |
| Secondary | `#80caee` | `--secondary` | Charts, secondary actions |
| Success | `#219653` | `--success` | Success badges, positive indicators |
| Danger | `#d34053` | `--danger` | Error states, delete actions |
| Warning | `#ffa70b` | `--warning` | Warnings, pending states |
| Info | `#8fbaf9` | `--info` | Information notices |

### Neutral Colors
| Color | CSS Variable | Usage |
|-------|--------------|-------|
| Dark | `--dark` (#1c2434) | Headings, important text |
| Body | `--body` (#64748b) | Body text, descriptions |
| Bodydark | `--bodydark` (#aeb7c0) | Disabled text |
| Stroke | `--stroke` (#e2e8f0) | Borders, dividers |
| Whiten | `--whiten` (#f1f5f9) | Page background |
| Whiter | `--whiter` (#f7f9fc) | Card backgrounds |
| Gray-2 | `--gray` (#eff4fb) | Table headers |

---

## 📦 Component Patterns

### Card
```html
<div class="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default">
  <div class="border-b border-stroke px-5 py-4">
    <h3 class="text-title-md font-semibold text-dark">Card Title</h3>
  </div>
  <div class="px-5 pt-6 pb-6">
    <!-- Card content -->
  </div>
</div>
```

### Data Table
```html
<table class="w-full table-auto">
  <thead>
    <tr class="bg-gray-2 text-left">
      <th class="min-w-[160px] px-4 py-4 font-medium text-dark">Column</th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-b border-stroke hover:bg-gray-2">
      <td class="px-4 py-4 text-sm text-dark">Data</td>
    </tr>
  </tbody>
</table>
```

### Primary Button
```html
<button class="inline-flex items-center rounded bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90">
  Button Text
</button>
```

### Secondary Button
```html
<button class="inline-flex items-center rounded border border-stroke bg-white px-4 py-2 text-sm font-medium text-dark hover:bg-whiter">
  Button Text
</button>
```

### Form Input
```html
<label class="mb-3 block text-sm font-medium text-dark">Label</label>
<input
  type="text"
  placeholder="Enter text"
  class="w-full rounded border border-stroke bg-white px-4 py-2.5 text-dark focus:border-primary focus:outline-none"
/>
```

### Form Select
```html
<label class="mb-3 block text-sm font-medium text-dark">Label</label>
<select class="w-full rounded border border-stroke bg-white px-4 py-2.5 text-dark focus:border-primary focus:outline-none">
  <option>Option 1</option>
</select>
```

### Toggle Switch
```html
<label class="relative inline-flex cursor-pointer items-center">
  <input type="checkbox" class="sr-only peer" />
  <div class="peer h-6 w-11 rounded-full bg-gray after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white"></div>
</label>
```

### Breadcrumb Navigation
```html
<nav class="flex text-sm text-body" aria-label="Breadcrumb">
  <ol class="inline-flex items-center space-x-1 md:space-x-3">
    <li class="inline-flex items-center">
      <%= link_to root_path, class: "text-body hover:text-dark" do %>
        <span class="material-icons text-sm mr-1">home</span>
        Home
      <% end %>
    </li>
    <li>
      <div class="flex items-center">
        <span class="material-icons text-sm text-body mx-1">chevron_right</span>
        <span class="text-dark font-medium">Current Page</span>
      </div>
    </li>
  </ol>
</nav>
```

### Status Badge
```html
<!-- Success -->
<span class="inline-flex rounded-full bg-success bg-opacity-10 px-3 py-1 text-sm font-medium text-success">
  Active
</span>

<!-- Warning -->
<span class="inline-flex rounded-full bg-warning bg-opacity-10 px-3 py-1 text-sm font-medium text-warning">
  Pending
</span>

<!-- Danger -->
<span class="inline-flex rounded-full bg-danger bg-opacity-10 px-3 py-1 text-sm font-medium text-danger">
  Failed
</span>
```

### Info Notice
```html
<div class="rounded-sm border border-stroke bg-whiten px-4 py-3">
  <div class="flex items-start gap-3">
    <span class="material-icons text-warning text-xl">info</span>
    <div>
      <p class="text-sm font-medium text-dark">Notice Title</p>
      <p class="text-sm text-body mt-1">Notice description text.</p>
    </div>
  </div>
</div>
```

### Empty State
```html
<div class="px-6 py-8 text-center">
  <span class="material-icons text-body text-4xl mb-2">icon_name</span>
  <h3 class="text-sm font-medium text-dark mb-1">No items found</h3>
  <p class="text-sm text-body">Description text here.</p>
  <%= link_to "Create New", path, class: "mt-4 inline-flex items-center rounded bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90" %>
</div>
```

### Icon Card (System Info)
```html
<div class="flex items-center gap-3">
  <div class="flex h-12 w-12 items-center justify-center rounded-full bg-whiter">
    <span class="material-icons text-primary">icon_name</span>
  </div>
  <div>
    <p class="text-sm text-body">Label</p>
    <p class="font-medium text-dark">Value</p>
  </div>
</div>
```

---

## 📱 Responsive Grid Layouts

### Two-Column Layout
```html
<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
  <div><!-- Column 1 --></div>
  <div><!-- Column 2 --></div>
</div>
```

### Three-Column Layout
```html
<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
  <div class="lg:col-span-1"><!-- Sidebar --></div>
  <div class="lg:col-span-2"><!-- Main content --></div>
</div>
```

### Four-Column Grid
```html
<div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
  <div><!-- Item 1 --></div>
  <div><!-- Item 2 --></div>
  <div><!-- Item 3 --></div>
  <div><!-- Item 4 --></div>
</div>
```

---

## 🔤 Typography Scale

| Class | Font Size | Usage |
|-------|-----------|-------|
| `text-title-md2` | 1.75rem (28px) | Page titles |
| `text-title-md` | 1.25rem (20px) | Section headings |
| `text-xl` | 1.25rem (20px) | Subheadings |
| `text-base` | 1rem (16px) | Body text |
| `text-sm` | 0.875rem (14px) | Labels, descriptions |

### Font Weights
- `font-bold` - 700 (Page titles)
- `font-semibold` - 600 (Section headings)
- `font-medium` - 500 (Labels, buttons)
- `font-normal` - 400 (Body text)

---

## 🎯 Spacing System

### Padding/Margin Scale
| Class | Size | Usage |
|-------|------|-------|
| `p-2` | 0.5rem (8px) | Tight spacing |
| `p-4` | 1rem (16px) | Standard spacing |
| `p-5` | 1.25rem (20px) | Card padding |
| `p-6` | 1.5rem (24px) | Section padding |
| `p-8` | 2rem (32px) | Large spacing |

### Gap Utilities
| Class | Size | Usage |
|-------|------|-------|
| `gap-2` | 0.5rem | Tight gaps |
| `gap-4` | 1rem | Standard gaps |
| `gap-6` | 1.5rem | Large gaps |

---

## 🎨 Material Icons Integration

### Icon in Button
```html
<button class="inline-flex items-center gap-2 rounded bg-primary px-4 py-2 text-white">
  <span class="material-icons text-base">add</span>
  Add Item
</button>
```

### Icon in Table Cell
```html
<td class="px-4 py-4">
  <div class="flex items-center gap-2">
    <span class="material-icons text-primary text-lg">check_circle</span>
    <span class="text-sm text-dark">Status</span>
  </div>
</td>
```

### Icon in Navigation
```html
<li>
  <%= link_to path, class: "flex items-center gap-2.5 rounded-md py-2 px-4" do %>
    <span class="material-icons text-lg">dashboard</span>
    Dashboard
  <% end %>
</li>
```

### Commonly Used Icons
- `home` - Home/Dashboard
- `people` - Customers/Users
- `task` - Tasks/Jobs
- `payment` - Payments
- `local_shipping` - Carriers/Shipping
- `settings` - Settings
- `person` - Profile
- `info` - Information
- `warning` - Warnings
- `error` - Errors
- `check_circle` - Success
- `chevron_right` - Navigation
- `add` - Add/Create
- `edit` - Edit
- `delete` - Delete
- `visibility` - View

---

## 🌐 CSS Variables Usage in Rails

### In View Templates
```erb
<div class="bg-primary text-white">Primary Background</div>
<div class="text-body">Body Text Color</div>
<div class="border-stroke">Bordered Element</div>
```

### In Custom Styles
```css
.custom-component {
  background-color: var(--whiter);
  border: 1px solid var(--stroke);
  color: var(--dark);
}

.custom-component:hover {
  background-color: var(--whiten);
}
```

---

## 📋 Form Patterns

### Standard Form Layout
```html
<div class="rounded-sm border border-stroke bg-white shadow-default">
  <div class="border-b border-stroke px-5 py-4">
    <h3 class="text-title-md font-semibold text-dark">Form Title</h3>
  </div>
  <div class="px-5 pt-6 pb-6">
    <%= form_with model: @model do |f| %>
      <div class="mb-5">
        <%= f.label :field, class: "mb-3 block text-sm font-medium text-dark" %>
        <%= f.text_field :field, class: "w-full rounded border border-stroke bg-white px-4 py-2.5 text-dark focus:border-primary focus:outline-none" %>
      </div>
      
      <div class="flex justify-end gap-4">
        <%= link_to "Cancel", path, class: "flex justify-center rounded border border-stroke px-6 py-2 font-medium text-dark hover:shadow-1" %>
        <%= f.submit "Submit", class: "flex justify-center rounded bg-primary px-6 py-2 font-medium text-white hover:opacity-90" %>
      </div>
    <% end %>
  </div>
</div>
```

---

## 🔍 Shadow Utilities

| Class | Shadow | Usage |
|-------|--------|-------|
| `shadow-default` | Standard card shadow | Cards, panels |
| `shadow-card` | Light card shadow | Hover states |
| `shadow-1` | Button shadow | Interactive elements |
| `hover:shadow-1` | Hover shadow | Button hover |

---

## 🎭 Hover & Focus States

### Hover Effects
```html
<!-- Background change -->
<tr class="hover:bg-gray-2">...</tr>

<!-- Opacity change -->
<button class="hover:opacity-90">...</button>

<!-- Shadow change -->
<button class="hover:shadow-1">...</button>
```

### Focus States
```html
<!-- Input focus -->
<input class="focus:border-primary focus:outline-none" />

<!-- Button focus -->
<button class="focus:ring-4 focus:ring-blue-300">...</button>
```

---

## 📚 Additional Resources

- **TailAdmin Documentation**: Design patterns and components
- **Tailwind CSS Docs**: https://tailwindcss.com/docs
- **Material Icons**: https://fonts.google.com/icons
- **Rails View Helpers**: Form helpers and link helpers

---

## ✅ Checklist for New Views

When creating new views, ensure:

- [ ] Breadcrumb navigation is present
- [ ] TailAdmin color tokens are used (not generic colors)
- [ ] Cards use `rounded-sm border border-stroke bg-white shadow-default`
- [ ] Tables use `bg-gray-2` for headers
- [ ] Buttons use primary/secondary styling
- [ ] Form inputs have proper labels and focus states
- [ ] Empty states include icon, message, and CTA
- [ ] Material Icons are used consistently
- [ ] Responsive classes are applied (`md:`, `lg:`, etc.)
- [ ] Hover effects are added where appropriate
