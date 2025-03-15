Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  
  # Nested routes for relationships
  resources :customers do
    resources :phones, only: [:index, :create] # A customer can have multiple phones
    resources :payments, only: [:index, :create] # Payments associated with customers
    resources :remarks, only: [:index, :create] # Remarks tied to customers
  end

  resources :tasks do
    resources :payments_tasks, only: [:index, :create] # Nested under tasks
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
