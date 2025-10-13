# Hotwire Turbo Integration Guide

## Overview
This document shows how to use Turbo Frames and Turbo Streams for dynamic, SPA-like interactions in Rails Fast Epost.

## 1. Turbo Frames (Partial Page Updates)

### What are Turbo Frames?
Turbo Frames let you update specific parts of the page without a full reload. Perfect for inline editing, modals, and lazy loading.

### Basic Usage

#### In Views:
```erb
<!-- Wrap content in a turbo_frame_tag -->
<%= turbo_frame_tag "my_frame" do %>
  <p>This content can be replaced</p>
<% end %>

<!-- Link that updates the frame -->
<%= link_to "Update", some_path, data: { turbo_frame: "my_frame" } %>
```

#### In Controllers:
```ruby
def edit
  @task = Task.find(params[:id])
  # Automatically renders within the frame
  render :edit
end
```

### Common Patterns

#### 1. Inline Editing
```erb
<!-- Task show view -->
<%= turbo_frame_tag task do %>
  <%= render "tasks/task", task: task %>
<% end %>

<!-- Edit link replaces the frame with the form -->
<%= link_to "Edit", edit_task_path(task), data: { turbo_frame: dom_id(task) } %>
```

#### 2. Modal Dialogs
```erb
<!-- Modal container at bottom of layout -->
<%= turbo_frame_tag "modal" %>

<!-- Link that loads content into modal -->
<%= link_to "New Task", new_task_path, data: { turbo_frame: "modal" } %>
```

#### 3. Lazy Loading
```erb
<!-- Load content when visible -->
<%= turbo_frame_tag "lazy_content", src: lazy_load_path, loading: :lazy do %>
  <p>Loading...</p>
<% end %>
```

#### 4. Pagination
```erb
<%= turbo_frame_tag "tasks_list" do %>
  <%= render @tasks %>
  <%= link_to "Load More", tasks_path(page: @tasks.next_page), 
      data: { turbo_frame: "tasks_list", turbo_action: "advance" } %>
<% end %>
```

## 2. Turbo Streams (Real-time Updates)

### What are Turbo Streams?
Turbo Streams enable real-time, targeted updates to multiple parts of the page. Great for live notifications, status updates, and collaborative features.

### 7 Stream Actions

1. **append** - Add content to the end
2. **prepend** - Add content to the beginning
3. **replace** - Replace entire element
4. **update** - Replace element's content only
5. **remove** - Delete element
6. **before** - Insert before element
7. **after** - Insert after element

### Usage in Controllers

```ruby
def create
  @task = Task.create(task_params)
  
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        # Add new task to top of list
        turbo_stream.prepend("tasks_list", partial: "tasks/task", locals: { task: @task }),
        
        # Show success message
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Task created!" }),
        
        # Clear the form
        turbo_stream.update("task_form", partial: "tasks/form", locals: { task: Task.new })
      ]
    end
  end
end

def update
  @task = Task.find(params[:id])
  @task.update(task_params)
  
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(@task, partial: "tasks/task", locals: { task: @task })
    end
  end
end

def destroy
  @task = Task.find(params[:id])
  @task.destroy
  
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.remove(@task)
    end
  end
end
```

### Broadcasting (Real-time Updates)

#### 1. Setup Model Broadcasting
```ruby
class Task < ApplicationRecord
  include TurboStreamsBroadcasting
  
  # Callbacks will broadcast changes automatically
end
```

#### 2. Subscribe in Views
```erb
<!-- Subscribe to task updates -->
<%= turbo_stream_from "tasks_list" %>

<div id="tasks_list">
  <%= render @tasks %>
</div>
```

#### 3. Manual Broadcasting
```ruby
# Broadcast a single stream action
Turbo::StreamsChannel.broadcast_append_to(
  "tasks_list",
  target: "tasks_list",
  partial: "tasks/task",
  locals: { task: @task }
)

# Or use helper methods
broadcast_prepend_to("tasks_list", target: "tasks_list", partial: "tasks/task", locals: { task: @task })
broadcast_replace_to("tasks_list", target: @task, partial: "tasks/task", locals: { task: @task })
broadcast_remove_to("tasks_list", target: @task)
```

## 3. Stimulus Controllers

### Available Controllers

#### form_validation_controller.js
Validates forms in real-time with visual feedback.

```erb
<%= form_with model: @task, data: { controller: "form-validation" } do |f| %>
  <%= f.text_field :title, 
      required: true,
      minlength: 3,
      data: { 
        form_validation_target: "input",
        action: "blur->form-validation#validateField"
      } %>
  <span class="text-red-500 hidden" data-form-validation-target="error"></span>
<% end %>
```

#### autocomplete_controller.js
Autocomplete search with debouncing.

```erb
<div data-controller="autocomplete" data-autocomplete-url-value="<%= search_users_path %>">
  <input type="text" 
         data-autocomplete-target="input"
         data-action="input->autocomplete#search">
  <div data-autocomplete-target="results"></div>
</div>
```

#### notification_controller.js
Auto-dismissing notifications.

```erb
<%= notification_tag(:success, "Task created!", timeout: 5000) %>
```

#### modal_controller.js
Modal dialogs with backdrop and keyboard support.

```erb
<%= turbo_modal_tag "my_modal", data: { modal_open_value: false } do %>
  <div class="p-6">
    <h2>Modal Title</h2>
    <button data-action="click->modal#close">Close</button>
  </div>
<% end %>
```

#### file_upload_controller.js
File upload with preview and validation.

```erb
<div data-controller="file-upload" 
     data-file-upload-max-size-value="10485760"
     data-file-upload-accepted-types-value='["image/*", "application/pdf"]'>
  <input type="file" data-action="change->file-upload#selectFiles">
  <div data-file-upload-target="preview"></div>
</div>
```

## 4. Helper Methods

### Hotwire Helpers

```ruby
# Check if request is from Turbo Frame
turbo_frame_request? # => true/false
turbo_frame_id # => "task_123"

# Check if request expects Turbo Stream
turbo_stream_request? # => true/false

# Create modal with Turbo support
<%= turbo_modal_tag "my_modal" do %>
  <p>Content</p>
<% end %>

# Create notification
<%= notification_tag(:success, "Action completed!") %>
```

### RTL Helpers

```ruby
rtl? # => true/false for current locale
text_direction # => "rtl" or "ltr"
margin_start_class("4") # => "mr-4" (RTL) or "ml-4" (LTR)
```

## 5. Best Practices

### When to Use Turbo Frames
- ✅ Inline editing
- ✅ Modal dialogs
- ✅ Lazy loading sections
- ✅ Pagination
- ✅ Search results
- ❌ Full page navigation (use Turbo Drive instead)

### When to Use Turbo Streams
- ✅ Multiple simultaneous updates
- ✅ Real-time notifications
- ✅ Live status updates
- ✅ Collaborative features
- ✅ After form submissions
- ❌ Simple page replacements (use Frames)

### Performance Tips
1. Use `loading: :lazy` for below-the-fold frames
2. Keep Turbo Stream responses small (< 10 actions)
3. Use broadcasting for real-time features
4. Add loading states with Stimulus
5. Cache frame partials with Russian Doll caching

## 6. Common Patterns

### Search with Autocomplete
```erb
<%= form_with url: search_path, method: :get, data: { turbo_frame: "results" } do |f| %>
  <%= f.text_field :q, data: { 
    controller: "autocomplete",
    autocomplete_url_value: search_path,
    action: "input->autocomplete#search"
  } %>
<% end %>

<%= turbo_frame_tag "results" do %>
  <%= render @results %>
<% end %>
```

### Inline Editing
```erb
<%= turbo_frame_tag @task do %>
  <div class="flex items-center justify-between">
    <h3><%= @task.title %></h3>
    <%= link_to "Edit", edit_task_path(@task), data: { turbo_frame: dom_id(@task) } %>
  </div>
<% end %>
```

### Modal Form
```erb
<!-- Trigger -->
<%= link_to "New Task", new_task_path, data: { turbo_frame: "modal" } %>

<!-- Modal container -->
<%= turbo_frame_tag "modal", data: { controller: "modal" } %>

<!-- In new.html.erb -->
<%= turbo_frame_tag "modal" do %>
  <%= turbo_modal_tag "task_modal" do %>
    <%= render "form", task: @task %>
  <% end %>
<% end %>
```

### Live Status Updates
```erb
<!-- Subscribe to updates -->
<%= turbo_stream_from "task_#{@task.id}_status" %>

<div id="task_status_<%= @task.id %>">
  <%= @task.status %>
</div>

<!-- In controller/job -->
Turbo::StreamsChannel.broadcast_update_to(
  "task_#{task.id}_status",
  target: "task_status_#{task.id}",
  html: task.status
)
```

## 7. Debugging

### Enable Turbo Debug Logging
```javascript
// In application.js
Turbo.session.drive = true
console.log("Turbo Drive enabled")

document.addEventListener("turbo:before-fetch-request", (event) => {
  console.log("Turbo fetch:", event.detail.url)
})
```

### Common Issues

**Frame not updating?**
- Check frame IDs match exactly
- Ensure controller responds to `format.turbo_stream`
- Verify `data-turbo-frame` attribute on links

**Streams not working?**
- Check target element exists with correct ID
- Verify `respond_to` block includes `format.turbo_stream`
- Ensure Solid Cable is running for broadcasts

**Form validation not showing?**
- Add `data-controller="form-validation"` to form
- Include `data-form-validation-target="input"` on fields
- Check error spans have `data-form-validation-target="error"`

## Resources

- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Turbo Rails Gem](https://github.com/hotwired/turbo-rails)
- Rails Fast Epost specific: See example files in `app/views/tasks/_*_example.html.erb`
