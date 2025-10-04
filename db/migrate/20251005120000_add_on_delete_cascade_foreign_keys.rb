class AddOnDeleteCascadeForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Replace existing foreign keys with ON DELETE CASCADE where appropriate

    if foreign_key_exists?(:cost_calcs, :tasks)
      remove_foreign_key :cost_calcs, :tasks
    end
    add_foreign_key :cost_calcs, :tasks, on_delete: :cascade

    if foreign_key_exists?(:documents, :carriers)
      remove_foreign_key :documents, :carriers
    end
    add_foreign_key :documents, :carriers, on_delete: :cascade

    if foreign_key_exists?(:form_templates, :carriers)
      remove_foreign_key :form_templates, :carriers
    end
    add_foreign_key :form_templates, :carriers, on_delete: :cascade

    if foreign_key_exists?(:form_templates, :customers)
      remove_foreign_key :form_templates, :customers
    end
    add_foreign_key :form_templates, :customers, on_delete: :cascade

    if foreign_key_exists?(:forms, :customers)
      remove_foreign_key :forms, :customers
    end
    add_foreign_key :forms, :customers, on_delete: :cascade

    if foreign_key_exists?(:payments, :tasks)
      remove_foreign_key :payments, :tasks
    end
    add_foreign_key :payments, :tasks, on_delete: :cascade

    if foreign_key_exists?(:payments_tasks, :payments)
      remove_foreign_key :payments_tasks, :payments
    end
    add_foreign_key :payments_tasks, :payments, on_delete: :cascade

    if foreign_key_exists?(:payments_tasks, :tasks)
      remove_foreign_key :payments_tasks, :tasks
    end
    add_foreign_key :payments_tasks, :tasks, on_delete: :cascade

    if foreign_key_exists?(:phones, :carriers)
      remove_foreign_key :phones, :carriers
    end
    add_foreign_key :phones, :carriers, on_delete: :cascade

    if foreign_key_exists?(:preferences, :carriers)
      remove_foreign_key :preferences, :carriers
    end
    add_foreign_key :preferences, :carriers, on_delete: :cascade

    if foreign_key_exists?(:remarks, :tasks)
      remove_foreign_key :remarks, :tasks
    end
    add_foreign_key :remarks, :tasks, on_delete: :cascade

    if foreign_key_exists?(:tasks, :carriers)
      remove_foreign_key :tasks, :carriers
    end
    add_foreign_key :tasks, :carriers, on_delete: :cascade

    if foreign_key_exists?(:tasks, :customers)
      remove_foreign_key :tasks, :customers
    end
    add_foreign_key :tasks, :customers, on_delete: :cascade
  end
end
