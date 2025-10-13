# Hotwire Quick Start Template

## 🚀 Apply Hotwire to ANY Controller in 5 Steps

This template lets you add Turbo Streams to any controller in under 10 minutes!

---

## Step 1: Update Controller Actions

### Create Action
```ruby
def create
  @model = Model.new(model_params)
  if @model.save
    respond_to do |format|
      format.html { redirect_to @model, notice: "#{Model.model_name.human} created." }
      format.json { render json: @model, status: :created }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("models_list", partial: "models/model_card", locals: { model: @model }),
          turbo_stream.update("model_form", partial: "models/form", locals: { model: Model.new }),
          turbo_stream.append("flash-messages", partial: "shared/flash_message",
                             locals: { type: :success, message: t("models.created_successfully") })
        ]
      end
    end
  else
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: @model.errors.full_messages }, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "model_form",
          partial: "models/form",
          locals: { model: @model }
        ), status: :unprocessable_entity
      end
    end
  end
end
```

### Update Action
```ruby
def update
  if @model.update(model_params)
    respond_to do |format|
      format.html { redirect_to @model, notice: "#{Model.model_name.human} updated." }
      format.json { render json: @model }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@model, partial: "models/model_card", locals: { model: @model }),
          turbo_stream.append("flash-messages", partial: "shared/flash_message",
                             locals: { type: :success, message: t("models.updated_successfully") })
        ]
      end
    end
  else
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: @model.errors.full_messages }, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @model,
          partial: "models/form",
          locals: { model: @model }
        ), status: :unprocessable_entity
      end
    end
  end
end
```

### Destroy Action
```ruby
def destroy
  @model.destroy
  respond_to do |format|
    format.html { redirect_to models_path, notice: "#{Model.model_name.human} deleted." }
    format.json { head :no_content }
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove(@model),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("models.deleted_successfully") })
      ]
    end
  end
end
```

---

## Step 2: Create Card Partial

### `app/views/models/_model_card.html.erb`
```erb
<%= turbo_frame_tag model do %>
  <tr class="border-b border-stroke hover:bg-gray-2 dark:border-strokedark dark:hover:bg-meta-4">
    <td class="px-4 py-4">
      <%= link_to model_path(model), class: "text-sm font-medium text-primary hover:underline" do %>
        <%= model.name %>
      <% end %>
    </td>
    
    <!-- Add more columns here -->
    
    <td class="px-4 py-4 text-right">
      <div class="flex items-center justify-end gap-3">
        <%= link_to model_path(model),
            class: "text-primary hover:text-primary/80",
            title: t('common.view') do %>
          <span class="material-icons text-xl">visibility</span>
        <% end %>
        
        <%= link_to edit_model_path(model),
            data: { turbo_frame: dom_id(model) },
            class: "text-warning hover:text-warning/80",
            title: t('common.edit') do %>
          <span class="material-icons text-xl">edit</span>
        <% end %>
        
        <%= button_to model_path(model),
            method: :delete,
            form: { data: { turbo_confirm: t('common.confirm_delete') } },
            class: "text-danger hover:text-danger/80",
            title: t('common.delete') do %>
          <span class="material-icons text-xl">delete</span>
        <% end %>
      </div>
    </td>
  </tr>
<% end %>
```

---

## Step 3: Create List Partial

### `app/views/models/_list.html.erb`
```erb
<div id="models_list">
  <% models.each do |model| %>
    <%= render "models/model_card", model: model %>
  <% end %>
  
  <% if models.empty? %>
    <tr>
      <td colspan="5" class="px-4 py-10 text-center">
        <div class="flex flex-col items-center justify-center">
          <span class="material-icons text-5xl text-bodydark1 dark:text-bodydark mb-3">inbox</span>
          <p class="text-body dark:text-bodydark"><%= t('models.no_models') %></p>
        </div>
      </td>
    </tr>
  <% end %>
</div>
```

---

## Step 4: Update Index View

### `app/views/models/index.html.erb`
```erb
<% content_for :page_title, t('models.title') %>

<div class="space-y-6">
  <!-- Breadcrumb -->
  <div class="flex items-center justify-between">
    <div>
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
              <span class="text-dark font-medium"><%= t('models.title') %></span>
            </div>
          </li>
        </ol>
      </nav>
    </div>
  </div>

  <!-- Subscribe to real-time updates -->
  <%= turbo_stream_from "models" %>

  <!-- Main content -->
  <div class="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark">
    <div class="mb-6 flex items-center justify-between">
      <h2 class="text-title-md font-semibold text-dark dark:text-white">
        <%= t('models.title') %>
      </h2>
      <%= link_to new_model_path,
          class: "inline-flex items-center justify-center rounded-md bg-primary py-2 px-4 text-center font-medium text-white hover:bg-opacity-90" do %>
        <span class="material-icons <%= margin_end_class('2') %> text-xl">add</span>
        <%= t('models.new') %>
      <% end %>
    </div>

    <!-- Search form (optional) -->
    <div class="mb-5">
      <%= form_with url: models_path, method: :get,
          data: { turbo_frame: "models_table", turbo_action: "advance" },
          class: "flex gap-3" do |f| %>
        <%= f.text_field :q,
            value: params[:q],
            placeholder: t('common.search'),
            class: "flex-1 rounded border-[1.5px] border-stroke bg-transparent py-2 px-4 text-black outline-none transition focus:border-primary active:border-primary disabled:cursor-default disabled:bg-whiter dark:border-form-strokedark dark:bg-form-input dark:text-white dark:focus:border-primary" %>
        <%= f.submit t('common.search'),
            class: "inline-flex items-center justify-center rounded-md bg-primary py-2 px-6 text-center font-medium text-white hover:bg-opacity-90" %>
      <% end %>
    </div>

    <!-- Turbo Frame for table -->
    <%= turbo_frame_tag "models_table" do %>
      <div class="max-w-full overflow-x-auto">
        <table class="w-full table-auto">
          <thead>
            <tr class="bg-gray-2 text-left dark:bg-meta-4">
              <th class="min-w-[160px] px-4 py-4 font-medium text-dark dark:text-white">Name</th>
              <!-- Add more columns -->
              <th class="px-4 py-4 text-right font-medium text-dark dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody id="models_list">
            <%= render partial: "models/model_card", collection: @models, as: :model %>
          </tbody>
        </table>
        
        <% if @models.empty? %>
          <div class="px-6 py-10 text-center">
            <span class="material-icons text-bodydark1 dark:text-bodydark text-5xl mb-3">inbox</span>
            <h3 class="text-sm font-medium text-dark dark:text-white mb-1"><%= t('models.no_models') %></h3>
            <p class="text-sm text-body dark:text-bodydark">Get started by creating a new <%= Model.model_name.human.downcase %>.</p>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

---

## Step 5: Add Translations

### `config/locales/en.yml`
```yaml
en:
  models:
    title: "Models"
    new: "New Model"
    no_models: "No models found"
    created_successfully: "Model created successfully!"
    updated_successfully: "Model updated successfully!"
    deleted_successfully: "Model deleted successfully!"
```

### `config/locales/ar.yml`
```yaml
ar:
  models:
    title: "النماذج"
    new: "نموذج جديد"
    no_models: "لا توجد نماذج"
    created_successfully: "تم إنشاء النموذج بنجاح!"
    updated_successfully: "تم تحديث النموذج بنجاح!"
    deleted_successfully: "تم حذف النموذج بنجاح!"
```

### `config/locales/ru.yml`
```yaml
ru:
  models:
    title: "Модели"
    new: "Новая модель"
    no_models: "Модели не найдены"
    created_successfully: "Модель успешно создана!"
    updated_successfully: "Модель успешно обновлена!"
    deleted_successfully: "Модель успешно удалена!"
```

### `config/locales/he.yml`
```yaml
he:
  models:
    title: "מודלים"
    new: "מודל חדש"
    no_models: "לא נמצאו מודלים"
    created_successfully: "המודל נוצר בהצלחה!"
    updated_successfully: "המודל עודכן בהצלחה!"
    deleted_successfully: "המודל נמחק בהצלחה!"
```

---

## Bonus: Search Action (Optional)

### Add to controller:
```ruby
def search
  @models = if params[:q].present?
    Model.where("name ILIKE ?", "%#{params[:q]}%").limit(10)
  else
    Model.limit(10)
  end

  respond_to do |format|
    format.json do
      render json: @models.map { |m| { id: m.id, name: m.name, text: m.name } }
    end
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "models_list",
        partial: "models/list",
        locals: { models: @models }
      )
    end
  end
end
```

### Add route:
```ruby
resources :models do
  collection do
    get :search
  end
end
```

---

## Testing Checklist

- [ ] Create: New record appears at top without page reload
- [ ] Update: Card updates inline when edited
- [ ] Delete: Card disappears without page reload
- [ ] Flash messages: Success messages appear and auto-dismiss
- [ ] Search: Results filter without page reload (if implemented)
- [ ] Validation: Errors show inline without page reload
- [ ] Dark mode: All elements styled with `dark:` classes
- [ ] RTL: Layout flips correctly for Arabic/Hebrew
- [ ] Mobile: Touch targets are large enough
- [ ] Accessibility: Proper ARIA labels and keyboard navigation

---

## Common Customizations

### For Nested Resources
```ruby
def create
  @parent = Parent.find(params[:parent_id])
  @model = @parent.models.new(model_params)
  # ... rest of create action
  
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.prepend("parent_#{@parent.id}_models_list", ...),
      # ... other streams
    ]
  end
end
```

### For Status Badge
```erb
<td class="px-4 py-4">
  <span class="text-xs px-2.5 py-0.5 rounded <%= model.status_badge_class %>">
    <%= model.status %>
  </span>
</td>
```

### For Timestamps
```erb
<td class="px-4 py-4 text-sm text-body dark:text-bodydark">
  <%= l(model.created_at, format: :short) %>
</td>
```

### For Associations
```erb
<td class="px-4 py-4 text-sm text-dark dark:text-white">
  <%= model.parent&.name || "-" %>
</td>
```

---

## Material Icons Reference

| Icon | Use Case |
|------|----------|
| `add` | New/Create buttons |
| `visibility` | View/Show actions |
| `edit` | Edit actions |
| `delete` | Delete actions |
| `search` | Search functionality |
| `inbox` | Empty states |
| `check_circle` | Success states |
| `error` | Error states |
| `warning` | Warning states |
| `info` | Info states |
| `play_arrow` | Start/Activate actions |
| `pause` | Pause actions |
| `stop` | Stop actions |
| `done` | Complete actions |
| `close` | Close/Cancel actions |
| `arrow_back` | Back navigation |
| `arrow_forward` | Forward navigation |

---

## Real-World Examples in This App

Fully implemented with Turbo Streams:
- ✅ **TasksController** - See `app/controllers/tasks_controller.rb`
- ✅ **CustomersController** - See `app/controllers/customers_controller.rb`
- ✅ **RemarksController** - See `app/controllers/remarks_controller.rb`
- ✅ **CarriersController** - See `app/controllers/carriers_controller.rb`

Study these for patterns and best practices!

---

## Troubleshooting

### Turbo Stream not working?
1. Check `format.turbo_stream` block exists in controller
2. Verify partial paths are correct
3. Check target IDs exist in DOM
4. Look in Network tab for `turbo-stream` responses

### Flash messages not showing?
1. Ensure `<div id="flash-messages">` exists in layout
2. Check `shared/_flash_message.html.erb` partial exists
3. Verify notification controller is loaded

### Inline editing not working?
1. Check `turbo_frame_tag` wraps the card
2. Verify edit link has `data: { turbo_frame: dom_id(model) }`
3. Ensure form is inside matching turbo_frame_tag

### Tests failing?
1. Add `format.turbo_stream` AFTER existing formats
2. Keep `format.html` responses unchanged
3. Turbo Streams are additive, not replacing

---

## Performance Tips

1. **Use `prepend` for new items** - Adds to top of list
2. **Use `append` for flash messages** - Stacks notifications
3. **Use `replace` for updates** - Swaps entire element
4. **Use `update` for content only** - Faster than replace
5. **Use `remove` for deletes** - Smooth animations
6. **Limit stream actions to 3-5** - Avoid overwhelming browser
7. **Cache partials** - Use Russian Doll caching
8. **Lazy load frames** - Use `loading: :lazy` for below fold

---

## Next Level: Real-Time Broadcasting

Once basic Turbo Streams work, enable real-time updates:

### 1. Add concern to model:
```ruby
class Model < ApplicationRecord
  include TurboStreamsBroadcasting
end
```

### 2. Subscribe in view:
```erb
<%= turbo_stream_from "models" %>
```

### 3. Now changes broadcast automatically!
When User A creates/updates/deletes, User B sees it instantly!

---

## Summary

This template gives you:
- ✅ No page reloads for CRUD operations
- ✅ Inline editing and deleting
- ✅ Real-time flash messages
- ✅ Search without page reload
- ✅ Multi-language support (4 languages)
- ✅ RTL support (Arabic, Hebrew)
- ✅ Dark mode support
- ✅ Mobile-friendly
- ✅ Accessible
- ✅ **10 minutes to implement per controller!**

Copy, customize, ship! 🚀
