Lowdown::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  resources :admin,                 only: [:index]
  resources :providers,             only: [:index, :new, :create, :edit, :update, :destroy]
  resources :projects,              only: [:index, :new, :create, :edit, :update, :destroy]
  resources :programs,              only: [:index, :new, :create, :edit, :update, :destroy]
  resources :trimet_providers,      only: [:index, :new, :create, :edit, :update, :destroy]
  resources :trimet_programs,       only: [:index, :new, :create, :edit, :update, :destroy]
  resources :trimet_report_groups,  only: [:index, :new, :create, :edit, :update, :destroy]
  resources :overrides,             only: [:index, :new, :create, :edit, :update, :destroy]
  resources :funding_sources,       only: [:index, :new, :create, :edit, :update, :destroy]
  resources :report_categories,     only: [:index, :new, :create, :edit, :update, :destroy]

  resources :allocations, only: [:index, :new, :create, :edit, :update, :destroy] do
    get :trimet_report_groups, on: :collection
  end

  resources :flex_reports
  resources :predefined_reports, only: [:index] do
    collection do
      get :premium_service_billing
      get :spd
      get :trip_purpose
      get :quarterly_narrative
      get :trimet_export
      get :age_and_ethnicity
      get :bpa_invoice
      get :allocation_summary
    end
  end

  resources :summaries, only: [:index, :new, :create, :edit, :update] do
    get    :adjustments,    on: :collection
    get    :bulk_update,    on: :collection
    delete :delete,         on: :member
    delete :delete_version, on: :member
  end
  resources :trips, only: [:index, :show, :update] do
    collection do
      get  :adjustments
      get  :show_import
      post :import
      get  :show_update_allocation
      post :update_allocation
    end
  end
  resources :runs, only: [:index, :show, :update] 
  resources :customers, only: [:show, :update]

  devise_for :users, controllers: {sessions: "users"}
  devise_scope :user do
    get  "users/show_create" => "users#show_create", as: :new_user
    post "users/create_user" => "users#create_user", as: :create_user
    get  "init" => "users#show_init"
    post "init" => "users#init"
    post "logout" => "users#sign_out", as: :logout
    get  "users/index" => "users#index", as: :users
    get  "users/change_password" => "users#show_change_password", as: :change_password
    put  "users/change_password"  => "users#change_password"
    post "users/update" => "users#update", as: :update_users
  end

  root to: 'dashboard#index'

  get "test_exception_notification" => "application#test_exception_notification"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  
  # match ':controller(/:action(/:id(.:format)))'
end
