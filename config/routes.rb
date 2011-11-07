Lowdown::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  resources :customers, :only => [:show, :update]
  resources :allocations
  resources :providers
  resources :projects
  
  resources :reports do
    collection do
      get :show_create_quarterly
      get :quarterly_narrative_report
      get :show_ride_purpose_report
      get :ride_purpose_report
      get :show_create_age_and_ethnicity
      get :age_and_ethnicity
      get :show_create_active_rider
      post :sort
    end
  end
  
  resource :admin, :only => [:index]

  devise_for :users, :controllers=>{:sessions=>"users"} do
    get "new_user" => "users#new_user"
    get "users/show_create" => "users#show_create"
    post "users/create_user" => "users#create_user"
    get "init" => "users#show_init"
    post "init" => "users#init"
    post "logout", :to => "users#sign_out"
    get "users/index" => "users#index"
    get "users/show_change_password" => "users#show_change_password"
    match "users/change_password"  => "users#change_password"
    post "users/update" => "users#update"
  end
  root :to => 'dashboard#index'
  
  match "summaries/delete_version/:id" => "summaries#delete_version", :as => :delete_summary_version, :via => :post
  match "summaries/delete/:id" => "summaries#delete", :as => :delete_summary, :via => :delete
  
  get "dashboard/index"

  match "test_exception_notification" => "application#test_exception_notification"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  
  match ':controller(/:action(/:id(.:format)))'
end
