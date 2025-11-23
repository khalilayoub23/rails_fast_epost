Rails.application.routes.draw do
  # Prevent noisy 404s from browsers requesting the default favicon
  get "/favicon.ico", to: "static#favicon"

  # Locale switcher
  get "/locale/:id", to: "locales#update", as: :set_locale
  # Public pages
  get "home", to: "pages#home", as: :landing_page

  controller :pages do
    %i[home about services track_parcel law_firms ecommerce privacy_policy icons].each do |action|
      get "pages/#{action}", action: action
    end

    match "pages/contact", action: :contact, via: [ :get, :post ]
  end

  # Public checkout
  get "/checkout", to: "checkout#new", as: :new_checkout
  post "/checkout", to: "checkout#create", as: :checkout
  get "/checkout/success", to: "checkout#success", as: :checkout_success
  get "/checkout/cancel", to: "checkout#cancel", as: :checkout_cancel
  
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  
  # Root route - public homepage for non-authenticated users
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end
  
  root "pages#home"
  
  # Dashboard for authenticated users
  get "/dashboard", to: "dashboard#index", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  # Main resources
  resources :carriers do
    resources :documents
    resources :phones
    resources :preferences
    resource :signature, module: :carriers, only: [ :new, :create, :edit, :update ]
  end

  # Payments for tasks require dedicated success/cancel handlers
  get "/tasks/payment/success", to: "tasks#payment_success", as: :task_payment_success
  get "/tasks/payment/cancel", to: "tasks#payment_cancel", as: :task_payment_cancel

  # Tasks are nested under customers but also need standalone routes.
  # The standalone routes must be defined before the shallow routes
  # generated below so that /tasks/new does not get captured by /tasks/:id.
  resources :tasks, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      patch :update_status
      patch :update_delivery
    end
  end

  resources :customers do
    collection do
      get :search
    end
    resources :forms
    resources :notification_preferences, module: :customers
    resources :tasks, shallow: true do
      resources :cost_calcs
      resources :remarks
    end
  end

  resources :carrier_ratings, only: :create

  # Form templates have many-to-many relationship
  resources :form_templates

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

  resources :messengers, only: [] do
    resources :notification_preferences, module: :messengers
  end

  resources :senders, only: [] do
    resources :notification_preferences, module: :senders
  end

  # API routes if needed
  namespace :api do
    namespace :v1 do
      # Public API (no authentication required)
      namespace :public do
        get "track/:barcode", to: "tracking#show"
      end

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

        # Free CRM Integrations
        post "hubspot", to: "hubspot#receive"  # HubSpot Free CRM
        post "odoo", to: "odoo#receive"        # Odoo (Open Source CRM)
      end
    end
  end

  namespace :admin do
    resources :document_templates do
      member do
        get :download
        get :preview
        get :new_generate
        post :generate
      end
    end

    resources :contact_inquiries, only: [:index, :show, :update]

    root to: "dashboard#index", as: :root
    get "dashboard", to: "dashboard#index", as: :dashboard
    post "dashboard_layout", to: "dashboard_layouts#update", as: :dashboard_layout
    resource :branding, only: [ :show, :update ]
    resource :pdfs, only: [ :new ] do
      post :merge
      post :stamp
      post :insert
      post :rotate
      post :crop
    end

    # Sender, Messenger, and Lawyer Management
    resources :senders
    resources :messengers do
      member do
        patch :update_status
        patch :update_location
      end
    end
    resources :lawyers do
      member do
        patch :activate
        patch :deactivate
      end
    end

    # Monitoring dashboard
    get "monitoring", to: "monitoring#index", as: :monitoring
    get "monitoring/jobs", to: "monitoring#jobs", as: :monitoring_jobs
    get "monitoring/jobs/:id", to: "monitoring#job_details", as: :monitoring_job_details
    get "monitoring/webhooks", to: "monitoring#webhooks", as: :monitoring_webhooks
    get "monitoring/health", to: "monitoring#health_check", as: :monitoring_health

    # Database management
    get "database", to: "database#index", as: :database
    post "database/export", to: "database#export", as: :database_export
    post "database/import", to: "database#import", as: :database_import
    get "database/backup", to: "database#backup", as: :database_backup

    # CRM integrations dashboard
    get "crm", to: "crm#index", as: :crm
  end

  # User Profile and Settings
  resource :profile, only: [ :show ]
  resources :settings, only: [ :index ]
end
