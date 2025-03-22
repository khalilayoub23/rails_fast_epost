Rails.application.routes.draw do
  # Root route
  root 'home#index'

  get "up" => "rails/health#show", as: :rails_health_check

  # Main resources
  resources :carriers do
    resources :documents
    resources :phones
    resources :preferences
  end

  resources :customers do
    resources :forms
    resources :tasks, shallow: true do
      resources :cost_calcs
      resources :remarks
    end
  end

  # Form templates have many-to-many relationship
  resources :form_templates

  # Tasks are nested under customers but also need standalone routes
  resources :tasks, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :update_status
      patch :update_delivery
    end
  end

  # Payments have polymorphic relationship (payable)
  resources :payments
  
  # Join table routes for payments_tasks
  resources :payments_tasks, only: [:create, :destroy]

  # API routes if needed
  namespace :api do
    namespace :v1 do
      resources :tasks
      resources :carriers
      resources :customers
    end
  end
end
