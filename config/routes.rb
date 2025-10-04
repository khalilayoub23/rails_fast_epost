Rails.application.routes.draw do
  # Root route
  root "dashboard#index"
  get "/dashboard", to: "dashboard#index", as: :dashboard

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
  resources :tasks, only: [ :index, :show, :edit, :update, :destroy ] do
    member do
      patch :update_status
      patch :update_delivery
    end
  end

  # Payments have polymorphic relationship (payable)
  resources :payments do
    member do
      post :refund
      post :capture
      post :cancel
      post :sync
    end
  end
  # Local checkout simulator
  get "/pay/local/:id", to: "payments/checkout#show"
  get "/pay/success", to: "payments/checkout#success"
  get "/pay/cancel", to: "payments/checkout#cancel"

  # Join table routes for payments_tasks
  resources :payments_tasks, only: [ :create, :destroy ]

  # API routes if needed
  namespace :api do
    namespace :v1 do
      resources :tasks
      resources :carriers
      resources :customers

      post "payments", to: "payments#create"
      post "payments/:provider/webhook", to: "payments#webhook"
  post "payments/:id/refund", to: "payments#refund"
  post "payments/:id/capture", to: "payments#capture"
  post "payments/:id/cancel", to: "payments#cancel"
  post "payments/:id/sync", to: "payments#sync"

      namespace :integrations do
        # Meta platforms: GET verify + POST receive
        get  "whatsapp",  to: "whatsapp#verify"
        post "whatsapp",  to: "whatsapp#receive"
        get  "instagram", to: "instagram#verify"
        post "instagram", to: "instagram#receive"
        get  "facebook",  to: "facebook#verify"
        post "facebook",  to: "facebook#receive"

        # Telegram: POST receive with secret token header
        post "telegram", to: "telegram#receive"

        # TikTok: POST receive
        post "tiktok", to: "tiktok#receive"

        # Generic websites: POST receive
        post "websites", to: "websites#receive"

        # HubSpot Free CRM style webhook
        post "hubspot", to: "hubspot#receive"
      end
    end
  end

  namespace :admin do
    resource :pdfs, only: [ :new ] do
      post :merge
      post :stamp
      post :insert
      post :rotate
      post :crop
    end
  end

  # User Profile and Settings
  resource :profile, only: [ :show ]
  resources :settings, only: [ :index ]
end
