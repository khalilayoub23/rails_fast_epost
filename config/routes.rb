Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check

  resources :carriers
  resources :customers
  


  # Defines the root path route ("/")
  # root "posts#index"

  
  # Nested routes for relationships
  resources :customers do
    resources :phones, only: [:index, :create] # A customer can have multiple phones
    resources :remarks, only: [:index, :create] # Remarks tied to customers
  end

  resources :tasks do
    resources :payments_tasks, only: [:index, :create] # Nested under tasks
    resources :payments, only: [:index, :create] # Payments associated with customers
  end

  # Other resources that are independent or don't require nesting
  resources :preferences, only: [:index, :show, :create, :update, :destroy]
  resources :documents, only: [:index, :show, :create, :update, :destroy]
  resources :carriers, only: [:index, :show, :create, :update, :destroy]
  resources :form_templates, only: [:index, :show, :create, :update, :destroy]
  resources :forms, only: [:index, :show, :create, :update, :destroy]
  resources :cost_calcs, only: [:index, :show, :create, :update, :destroy]
  
    # Additional custom routes (if needed)
    # e.g., /tasks/:task_id/payments for payments tied to tasks
  
  
end
